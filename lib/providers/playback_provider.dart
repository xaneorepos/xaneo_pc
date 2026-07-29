import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../services/api_service.dart';

class PlaybackItem {
  final String url;
  final String title;
  final String subtitle;
  final String? mimeType;
  final Duration? duration;
  final Map<String, dynamic>? payload;

  PlaybackItem({
    required this.url,
    required this.title,
    required this.subtitle,
    this.mimeType,
    this.duration,
    this.payload,
  });
}

/// Глобальный провайдер воспроизведения голосовых и музыкальных сообщений.
class PlaybackProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  String? _currentAudioUrl;
  String _title = '';
  String _subtitle = '';
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isSeeking = false;
  bool _isSimulated = false;
  bool _isVideo = false;
  Timer? _simulatedTimer;

  List<PlaybackItem> _playlist = [];
  int _currentIndex = -1;

  String? get currentAudioUrl => _currentAudioUrl;
  String get title => _title;
  String get subtitle => _subtitle;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  bool get isVideo => _isVideo;

  List<PlaybackItem> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  bool get hasNext => _playlist.isNotEmpty && _currentIndex >= 0 && _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;

  PlaybackProvider() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _position = Duration.zero;
        if (hasNext) {
          playNext();
        }
      }
      notifyListeners();
    });

    _positionSub = _player.positionStream.listen((pos) {
      // Во время драга слайдера position ведём из seekPreview, не из плеера.
      if (_isSeeking) return;
      _position = pos;
      notifyListeners();
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero && dur != _duration) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  void _startSimulatedTimer() {
    _simulatedTimer?.cancel();
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPlaying && !_isSeeking) {
        final nextPos = _position + const Duration(milliseconds: 100);
        if (nextPos >= _duration) {
          _position = Duration.zero;
          _isPlaying = false;
          _simulatedTimer?.cancel();
        } else {
          _position = nextPos;
        }
        notifyListeners();
      }
    });
  }

  /// Запускает воспроизведение [url]. Если это уже текущий трек — переключает play/pause.
  Future<void> play(
    String url,
    String title,
    String subtitle, {
    String? mimeType,
    Duration? duration,
  }) async {
    if (_currentAudioUrl == url && !_isVideo) {
      _togglePlay();
      return;
    }

    await stop();

    _isVideo = false;
    _currentAudioUrl = url;
    _title = title;
    _subtitle = subtitle;
    _duration = duration ?? Duration.zero;

    final isSimulated = url.contains('voice_') || url.contains('video_');
    if (isSimulated) {
      _isLoading = false;
      _isInitialized = true;
      _isPlaying = true;
      _isSimulated = true;
      _position = Duration.zero;
      _duration = duration ?? const Duration(seconds: 10);
      notifyListeners();
      _startSimulatedTimer();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final tempDir = Directory.systemTemp;
      String ext = '.ogg';
      if (mimeType != null) {
        final mime = mimeType.toLowerCase();
        if (mime.contains('webm')) {
          ext = '.webm';
        } else if (mime.contains('ogg') || mime.contains('opus')) {
          ext = '.ogg';
        } else if (mime.contains('mp3')) {
          ext = '.mp3';
        } else if (mime.contains('wav')) {
          ext = '.wav';
        } else if (mime.contains('m4a') || mime.contains('aac')) {
          ext = '.m4a';
        }
      }

      final safeName = url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final localFilePath = '${tempDir.path}/xaneo_voice_$safeName$ext';
      final file = File(localFilePath);

      if (!await file.exists()) {
        final freshToken = await ApiService().getAccessToken();
        final dio = Dio();
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };

        final response = await dio.download(
          url,
          localFilePath,
          options: Options(
            headers: freshToken != null && freshToken.isNotEmpty
                ? {'Authorization': 'Bearer $freshToken'}
                : {},
          ),
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to download audio file: ${response.statusCode}');
        }
      }

      await _player.setAudioSource(AudioSource.file(localFilePath));

      _isInitialized = true;
      _isLoading = false;

      final playerDuration = _player.duration;
      if (playerDuration != null && playerDuration > Duration.zero) {
        _duration = playerDuration;
      } else if (duration != null) {
        _duration = duration;
      }

      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Playback error: $e');
      _isLoading = false;
      _isInitialized = false;
      _currentAudioUrl = null;
      notifyListeners();
    }
  }

  void _togglePlay() {
    if (_isVideo) {
      _isPlaying = !_isPlaying;
      notifyListeners();
      return;
    }

    if (_isSimulated) {
      if (_isPlaying) {
        _isPlaying = false;
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          _position = Duration.zero;
        }
        _isPlaying = true;
        _startSimulatedTimer();
      }
      notifyListeners();
      return;
    }

    if (!_isInitialized || _isSeeking) return;

    if (_isPlaying) {
      _player.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        _restartFrom(Duration.zero);
      } else {
        _player.play();
      }
    }
  }

  void pause() {
    if (_isSimulated) {
      if (_isPlaying) {
        _isPlaying = false;
        notifyListeners();
      }
      return;
    }
    if (_isVideo) {
      if (_isPlaying) {
        _isPlaying = false;
        notifyListeners();
      }
      return;
    }
    if (_isPlaying) {
      _player.pause();
    }
  }

  void resume() {
    if (_isSimulated) {
      if (!_isPlaying && _isInitialized && !_isSeeking) {
        if (_position >= _duration && _duration > Duration.zero) {
          _position = Duration.zero;
        }
        _isPlaying = true;
        _startSimulatedTimer();
        notifyListeners();
      }
      return;
    }
    if (_isVideo) {
      if (!_isPlaying) {
        _isPlaying = true;
        notifyListeners();
      }
      return;
    }
    if (!_isPlaying && _isInitialized && !_isSeeking) {
      if (_position >= _duration && _duration > Duration.zero) {
        _restartFrom(Duration.zero);
      } else {
        _player.play();
      }
    }
  }

  /// Лёгкое "превью" позиции во время драга слайдера — только UI, без плеера.
  void seekPreview(Duration pos) {
    if (!_isInitialized) return;
    if (_duration == Duration.zero) return;
    if (pos > _duration) pos = _duration;
    if (pos < Duration.zero) pos = Duration.zero;

    _isSeeking = true;
    _position = pos;
    notifyListeners();
  }

  /// Финальный seek по отпусканию пальца. На десктопе seek работает нативно.
  Future<void> seek(Duration pos) async {
    if (_isSimulated) {
      if (!_isInitialized) return;
      if (_duration == Duration.zero) return;
      if (pos > _duration) pos = _duration;
      if (pos < Duration.zero) pos = Duration.zero;
      _position = pos;
      _isSeeking = false;
      notifyListeners();
      return;
    }
    if (!_isInitialized) return;
    if (_duration == Duration.zero) return;
    if (pos > _duration) pos = _duration;
    if (pos < Duration.zero) pos = Duration.zero;

    _position = pos;
    notifyListeners();

    try {
      await _player.seek(pos);
    } catch (e) {
      debugPrint('❌ seek error: $e');
    } finally {
      _isSeeking = false;
    }
  }

  Future<void> _restartFrom(Duration pos) async {
    try {
      await _player.seek(pos);
      await _player.play();
    } catch (e) {
      debugPrint('❌ _restartFrom error: $e');
    }
  }

  void setPlaylist(List<PlaybackItem> items, {String? initialUrl}) {
    _playlist = List.from(items);
    if (initialUrl != null) {
      _currentIndex = _playlist.indexWhere((item) => item.url == initialUrl);
    } else if (_playlist.isNotEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = -1;
    }
    notifyListeners();
  }

  Future<void> playItemAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final item = _playlist[index];
    await play(
      item.url,
      item.title,
      item.subtitle,
      mimeType: item.mimeType,
      duration: item.duration,
    );
  }

  Future<void> playNext() async {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      await playItemAtIndex(_currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      await playItemAtIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> stop() async {
    _simulatedTimer?.cancel();
    _isSimulated = false;
    await _player.stop();

    _isVideo = false;
    _currentAudioUrl = null;
    _title = '';
    _subtitle = '';
    _isPlaying = false;
    _isInitialized = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isLoading = false;
    _isSeeking = false;
    notifyListeners();
  }

  Future<void> playVideo(
    String url,
    String title,
    String subtitle, {
    Duration? duration,
  }) async {
    if (_currentAudioUrl == url && _isVideo) {
      _togglePlay();
      return;
    }

    await stop();

    _isVideo = true;
    _currentAudioUrl = url;
    _title = title;
    _subtitle = subtitle;
    _isPlaying = true;
    _isInitialized = true;
    _duration = duration ?? Duration.zero;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _simulatedTimer?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
