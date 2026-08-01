package com.lancerabhi.still

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.Executors

private const val CHANNEL = "still/backup"
private const val PICK_TREE = 8411

class MainActivity : FlutterActivity() {

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> pickDirectory(result)
                    "hasAccess" -> result.success(hasAccess(call.arg("uri")))
                    "release" -> result.success(release(call.arg("uri")))
                    "readText" -> background(result) { readText(call.tree(), call.arg("path")) }
                    "write" -> background(result) { write(call.tree(), call.files()) }
                    "delete" -> background(result) { delete(call.tree(), call.paths()) }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        io.shutdown()
        super.onDestroy()
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A folder picker is already open.", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        try {
            pendingPick = result
            startActivityForResult(intent, PICK_TREE)
        } catch (e: Exception) {
            pendingPick = null
            result.error("unavailable", "This device has no folder picker.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_TREE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingPick ?: return
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (e: SecurityException) {
            result.error("no_permission", "That folder could not be kept open.", null)
            return
        }
        result.success(mapOf("uri" to uri.toString(), "name" to displayName(uri)))
    }

    private fun hasAccess(uri: String): Boolean {
        val target = Uri.parse(uri)
        return contentResolver.persistedUriPermissions.any {
            it.uri == target && it.isWritePermission
        }
    }

    private fun release(uri: String) {
        try {
            contentResolver.releasePersistableUriPermission(
                Uri.parse(uri),
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (e: SecurityException) {
            return
        }
    }

    private fun displayName(tree: Uri): String {
        val doc = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        contentResolver.query(
            doc,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { if (it.moveToFirst()) it.getString(0)?.let { name -> return name } }

        return Uri.decode(tree.lastPathSegment ?: "")
            .substringAfterLast('/')
            .substringAfterLast(':')
    }

    private fun readText(tree: Uri, path: String): String? {
        val doc = findDocument(TreeWalk(tree), path) ?: return null
        return try {
            contentResolver.openInputStream(doc)?.use { it.readBytes().toString(Charsets.UTF_8) }
        } catch (e: FileNotFoundException) {
            null
        }
    }

    private fun write(tree: Uri, files: List<Map<String, String>>): Int {
        val walk = TreeWalk(tree)
        var written = 0

        for (file in files) {
            val path = file["path"] ?: continue
            val content = file["content"] ?: ""
            val name = path.substringAfterLast('/')
            val dirId = walk.directory(path.substringBeforeLast('/', ""))
            val kids = walk.children(dirId)

            val doc = kids.find(name)?.let {
                DocumentsContract.buildDocumentUriUsingTree(tree, it)
            } ?: DocumentsContract.createDocument(
                contentResolver,
                DocumentsContract.buildDocumentUriUsingTree(tree, dirId),
                mimeOf(name),
                name,
            )?.also { kids.put(name, DocumentsContract.getDocumentId(it)) }
            ?: throw IllegalStateException("Could not create $path")

            contentResolver.openOutputStream(doc, "wt")?.use {
                it.write(content.toByteArray(Charsets.UTF_8))
            } ?: throw FileNotFoundException(path)
            written++
        }
        return written
    }

    private fun delete(tree: Uri, paths: List<String>): Int {
        val walk = TreeWalk(tree)
        var removed = 0
        for (path in paths) {
            val doc = findDocument(walk, path) ?: continue
            try {
                if (DocumentsContract.deleteDocument(contentResolver, doc)) removed++
            } catch (e: FileNotFoundException) {
                continue
            }
        }
        return removed
    }

    private fun findDocument(walk: TreeWalk, path: String): Uri? {
        var id = walk.root
        for (segment in path.split('/')) {
            if (segment.isEmpty()) continue
            id = walk.children(id).find(segment) ?: return null
        }
        return DocumentsContract.buildDocumentUriUsingTree(walk.tree, id)
    }

    private inner class TreeWalk(val tree: Uri) {
        val root: String = DocumentsContract.getTreeDocumentId(tree)

        private val dirs = hashMapOf("" to root)
        private val listings = hashMapOf<String, Children>()

        fun directory(path: String): String {
            dirs[path]?.let { return it }

            val parent = directory(path.substringBeforeLast('/', ""))
            val name = path.substringAfterLast('/')
            val kids = children(parent)
            val id = kids.find(name) ?: DocumentsContract.createDocument(
                contentResolver,
                DocumentsContract.buildDocumentUriUsingTree(tree, parent),
                DocumentsContract.Document.MIME_TYPE_DIR,
                name,
            )?.let { DocumentsContract.getDocumentId(it).also { id -> kids.put(name, id) } }
                ?: throw IllegalStateException("Could not create folder $path")

            dirs[path] = id
            return id
        }

        fun children(dirId: String): Children {
            listings[dirId]?.let { return it }

            val byName = hashMapOf<String, String>()
            contentResolver.query(
                DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId),
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                ),
                null,
                null,
                null,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(1) ?: continue
                    byName[name] = cursor.getString(0)
                }
            }
            return Children(byName).also { listings[dirId] = it }
        }
    }

    private class Children(private val byName: MutableMap<String, String>) {
        // Some document providers rewrite the extension on create, so a name that
        // went in as "2026-08-01.md" can come back as "2026-08-01.md.txt". Matching
        // on the stem as well stops the next export creating a duplicate.
        fun find(name: String): String? {
            byName[name]?.let { return it }
            if (!name.contains('.')) return null
            val stem = name.substringBeforeLast('.') + "."
            return byName.entries.firstOrNull { it.key.startsWith(stem) }?.value
        }

        fun put(name: String, id: String) {
            byName[name] = id
        }
    }

    private fun mimeOf(name: String) = when (name.substringAfterLast('.', "")) {
        "md" -> "text/markdown"
        "json" -> "application/json"
        else -> "text/plain"
    }

    private fun <T> background(result: MethodChannel.Result, work: () -> T) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("backup_failed", e.message ?: "Backup failed.", null) }
            }
        }
    }

    private fun MethodCall.arg(name: String): String =
        argument<String>(name) ?: throw IllegalArgumentException("Missing $name")

    private fun MethodCall.tree(): Uri = Uri.parse(arg("uri"))

    private fun MethodCall.files(): List<Map<String, String>> =
        argument<List<Map<String, String>>>("files") ?: emptyList()

    private fun MethodCall.paths(): List<String> =
        argument<List<String>>("paths") ?: emptyList()
}
