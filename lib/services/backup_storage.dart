import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class BackupFolder {
  const BackupFolder({required this.uri, required this.name});

  final String uri;

  final String name;
}

@immutable
class BackupFile {
  const BackupFile(this.path, this.content);

  final String path;

  final String content;

  Map<String, String> toArgs() => {'path': path, 'content': content};
}

class BackupStorageException implements Exception {
  const BackupStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupStorage {
  const BackupStorage();

  static const MethodChannel _channel = MethodChannel('still/backup');

  static const int writeChunk = 200;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<BackupFolder?> pickFolder() async {
    final picked = await _guard(
      () => _channel.invokeMapMethod<String, String>('pickDirectory'),
    );
    final uri = picked?['uri'];
    if (uri == null) return null;
    return BackupFolder(uri: uri, name: picked?['name'] ?? uri);
  }

  Future<bool> hasAccess(String uri) async {
    if (!isSupported) return false;
    final ok = await _guard(
      () => _channel.invokeMethod<bool>('hasAccess', {'uri': uri}),
    );
    return ok ?? false;
  }

  Future<void> release(String uri) =>
      _guard(() => _channel.invokeMethod<void>('release', {'uri': uri}));

  Future<String?> readText(String uri, String path) => _guard(
    () => _channel.invokeMethod<String>('readText', {'uri': uri, 'path': path}),
  );

  Future<int> write(String uri, List<BackupFile> files) async {
    var written = 0;
    for (var i = 0; i < files.length; i += writeChunk) {
      final batch = files.sublist(
        i,
        i + writeChunk > files.length ? files.length : i + writeChunk,
      );
      written +=
          await _guard(
            () => _channel.invokeMethod<int>('write', {
              'uri': uri,
              'files': [for (final f in batch) f.toArgs()],
            }),
          ) ??
          0;
    }
    return written;
  }

  Future<int> delete(String uri, List<String> paths) async {
    if (paths.isEmpty) return 0;
    return await _guard(
          () => _channel.invokeMethod<int>('delete', {
            'uri': uri,
            'paths': paths,
          }),
        ) ??
        0;
  }

  Future<T?> _guard<T>(Future<T?> Function() call) async {
    if (!isSupported) {
      throw const BackupStorageException(
        'Folder backup is only available on Android.',
      );
    }
    try {
      return await call();
    } on PlatformException catch (e) {
      throw BackupStorageException(e.message ?? 'The backup folder failed.');
    } on MissingPluginException {
      throw const BackupStorageException(
        'Folder backup is not available in this build.',
      );
    }
  }
}
