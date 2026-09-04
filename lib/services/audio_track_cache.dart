import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AudioTrackMetadata {
  const AudioTrackMetadata({
    required this.sourceUrl,
    required this.title,
    required this.artist,
    this.album = '',
    this.mimeType,
    this.duration,
    this.artworkUri,
  });

  final String sourceUrl;
  final String title;
  final String artist;
  final String album;
  final String? mimeType;
  final Duration? duration;
  final Uri? artworkUri;
}

/// Persistent, bit-perfect SQLite cache for desktop audio and its metadata.
/// Zlib is used only when it makes the payload smaller; LRU keeps disk use bounded.
class AudioTrackCache {
  AudioTrackCache._();

  static final AudioTrackCache instance = AudioTrackCache._();
  static const int maxStoredBytes = 256 * 1024 * 1024;

  Future<Database>? _opening;

  Future<Database> _database() => _opening ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/audio_cache');
    await directory.create(recursive: true);
    final database = sqlite3.open('${directory.path}/tracks.sqlite');
    database.execute('PRAGMA journal_mode = WAL');
    database.execute('''
      CREATE TABLE IF NOT EXISTS audio_tracks (
        source_url TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        artist TEXT NOT NULL DEFAULT '',
        album TEXT NOT NULL DEFAULT '',
        mime_type TEXT,
        duration_ms INTEGER,
        artwork_uri TEXT,
        audio_data BLOB,
        compression TEXT,
        original_bytes INTEGER NOT NULL DEFAULT 0,
        stored_bytes INTEGER NOT NULL DEFAULT 0,
        last_accessed_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_audio_tracks_lru
      ON audio_tracks (last_accessed_at ASC)
    ''');
    return database;
  }

  Future<void> saveMetadata(AudioTrackMetadata metadata) async {
    final database = await _database();
    final now = DateTime.now().millisecondsSinceEpoch;
    database.execute(
      '''
      INSERT INTO audio_tracks (
        source_url, title, artist, album, mime_type, duration_ms,
        artwork_uri, last_accessed_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(source_url) DO UPDATE SET
        title = excluded.title,
        artist = excluded.artist,
        album = excluded.album,
        mime_type = excluded.mime_type,
        duration_ms = excluded.duration_ms,
        artwork_uri = excluded.artwork_uri,
        last_accessed_at = excluded.last_accessed_at,
        updated_at = excluded.updated_at
    ''',
      [
        metadata.sourceUrl,
        metadata.title,
        metadata.artist,
        metadata.album,
        metadata.mimeType,
        metadata.duration?.inMilliseconds,
        metadata.artworkUri?.toString(),
        now,
        now,
      ],
    );
  }

  Future<bool> hasAudio(String sourceUrl) async {
    final database = await _database();
    final rows = database.select(
      'SELECT stored_bytes FROM audio_tracks WHERE source_url = ?',
      [sourceUrl],
    );
    return rows.isNotEmpty && (rows.first['stored_bytes'] as int) > 0;
  }

  Future<void> storeFile(AudioTrackMetadata metadata, File source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) return;
    final compressed = Uint8List.fromList(zlib.encode(bytes));
    final shouldCompress = compressed.length < bytes.length;
    final stored = shouldCompress ? compressed : bytes;
    final database = await _database();
    final now = DateTime.now().millisecondsSinceEpoch;
    database.execute(
      '''
      INSERT INTO audio_tracks (
        source_url, title, artist, album, mime_type, duration_ms, artwork_uri,
        audio_data, compression, original_bytes, stored_bytes,
        last_accessed_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(source_url) DO UPDATE SET
        title = excluded.title,
        artist = excluded.artist,
        album = excluded.album,
        mime_type = excluded.mime_type,
        duration_ms = excluded.duration_ms,
        artwork_uri = excluded.artwork_uri,
        audio_data = excluded.audio_data,
        compression = excluded.compression,
        original_bytes = excluded.original_bytes,
        stored_bytes = excluded.stored_bytes,
        last_accessed_at = excluded.last_accessed_at,
        updated_at = excluded.updated_at
    ''',
      [
        metadata.sourceUrl,
        metadata.title,
        metadata.artist,
        metadata.album,
        metadata.mimeType,
        metadata.duration?.inMilliseconds,
        metadata.artworkUri?.toString(),
        stored,
        shouldCompress ? 'zlib' : null,
        bytes.length,
        stored.length,
        now,
        now,
      ],
    );
    _evictOldTracks(database);
  }

  Future<File?> restoreFile(
    String sourceUrl,
    Directory targetDirectory, {
    required String extension,
  }) async {
    final database = await _database();
    final rows = database.select(
      '''
      SELECT audio_data, compression FROM audio_tracks WHERE source_url = ?
    ''',
      [sourceUrl],
    );
    if (rows.isEmpty) return null;
    final stored = rows.first['audio_data'] as Uint8List?;
    if (stored == null || stored.isEmpty) return null;
    final bytes = rows.first['compression'] == 'zlib'
        ? Uint8List.fromList(zlib.decode(stored))
        : stored;
    await targetDirectory.create(recursive: true);
    final safeName = sourceUrl.hashCode.toUnsigned(32).toRadixString(16);
    final file = File('${targetDirectory.path}/$safeName$extension');
    await file.writeAsBytes(bytes, flush: true);
    database.execute(
      'UPDATE audio_tracks SET last_accessed_at = ? WHERE source_url = ?',
      [DateTime.now().millisecondsSinceEpoch, sourceUrl],
    );
    return file;
  }

  void _evictOldTracks(Database database) {
    final totalRows = database.select(
      'SELECT COALESCE(SUM(stored_bytes), 0) AS total FROM audio_tracks',
    );
    var total = totalRows.first['total'] as int;
    if (total <= maxStoredBytes) return;
    final rows = database.select('''
      SELECT source_url, stored_bytes FROM audio_tracks
      WHERE audio_data IS NOT NULL ORDER BY last_accessed_at ASC
    ''');
    for (final row in rows) {
      if (total <= maxStoredBytes) break;
      total -= row['stored_bytes'] as int;
      database.execute(
        '''
        UPDATE audio_tracks SET audio_data = NULL, compression = NULL,
          original_bytes = 0, stored_bytes = 0 WHERE source_url = ?
      ''',
        [row['source_url']],
      );
    }
  }
}
