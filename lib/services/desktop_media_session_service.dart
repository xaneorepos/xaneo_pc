import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/playback_provider.dart';

/// Desktop Media Session Service supporting MPRIS on Linux and SMTC on Windows.
/// This spawns the native system media player widget in the notification tray / sound panel / lock screen.
class DesktopMediaSessionService {
  static final DesktopMediaSessionService instance =
      DesktopMediaSessionService._internal();
  factory DesktopMediaSessionService() => instance;
  DesktopMediaSessionService._internal();

  bool _initialized = false;

  // Linux MPRIS DBus
  DBusClient? _dbusClient;
  _XaneoMprisObject? _mprisObject;

  // Windows SMTC
  SMTCWindows? _smtcWindows;
  StreamSubscription? _smtcSub;

  PlaybackProvider? _playbackProvider;

  void setPlaybackProvider(PlaybackProvider provider) {
    _playbackProvider = provider;
  }

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (Platform.isLinux) {
      await _initLinuxMpris();
    } else if (Platform.isWindows) {
      await _initWindowsSmtc();
    }
  }

  Future<void> _initLinuxMpris() async {
    try {
      _dbusClient = DBusClient.session();
      _mprisObject = _XaneoMprisObject(this);
      await _dbusClient!.registerObject(_mprisObject!);
      final res = await _dbusClient!.requestName('org.mpris.MediaPlayer2.xaneo');
      debugPrint('🎵 [MPRIS] DBus registered on org.mpris.MediaPlayer2.xaneo: $res');
    } catch (e) {
      debugPrint('❌ [MPRIS] Failed to initialize MPRIS on Linux: $e');
    }
  }

  Future<void> _initWindowsSmtc() async {
    try {
      await SMTCWindows.initialize();
      _smtcWindows = SMTCWindows(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );

      _smtcSub = _smtcWindows!.buttonPressStream.listen((button) {
        if (_playbackProvider == null) return;
        switch (button) {
          case PressedButton.play:
            _playbackProvider!.resume();
            break;
          case PressedButton.pause:
            _playbackProvider!.pause();
            break;
          case PressedButton.next:
            _playbackProvider!.playNext();
            break;
          case PressedButton.previous:
            _playbackProvider!.playPrevious();
            break;
          case PressedButton.stop:
            _playbackProvider!.stop();
            break;
          default:
            break;
        }
      });
      debugPrint('🎵 [SMTC] Windows SMTC initialized successfully');
    } catch (e) {
      debugPrint('❌ [SMTC] Failed to initialize Windows SMTC: $e');
    }
  }

  void updatePlaybackState({
    required String title,
    required String artist,
    required bool isPlaying,
    required bool hasTrack,
    required Duration position,
    required Duration duration,
    required bool hasNext,
    required bool hasPrevious,
    String? artUrl,
  }) {
    if (!_initialized) {
      init().then((_) {
        updatePlaybackState(
          title: title,
          artist: artist,
          isPlaying: isPlaying,
          hasTrack: hasTrack,
          position: position,
          duration: duration,
          hasNext: hasNext,
          hasPrevious: hasPrevious,
          artUrl: artUrl,
        );
      });
      return;
    }

    if (Platform.isLinux && _mprisObject != null) {
      _mprisObject!.updateState(
        title: title,
        artist: artist,
        isPlaying: isPlaying,
        hasTrack: hasTrack,
        position: position,
        duration: duration,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
        artUrl: artUrl,
      );
    }

    if (Platform.isWindows && _smtcWindows != null) {
      try {
        _smtcWindows!.setPlaybackStatus(
          isPlaying
              ? PlaybackStatus.playing
              : (hasTrack ? PlaybackStatus.paused : PlaybackStatus.stopped),
        );
        _smtcWindows!.updateMetadata(
          MusicMetadata(
            title: title.isNotEmpty ? title : 'Xaneo',
            artist: artist.isNotEmpty ? artist : 'Xaneo',
            thumbnail: artUrl != null && artUrl.isNotEmpty ? artUrl : null,
          ),
        );
        _smtcWindows!.updateTimeline(
          PlaybackTimeline(
            positionMs: position.inMilliseconds,
            startTimeMs: 0,
            endTimeMs: duration.inMilliseconds,
          ),
        );
      } catch (e) {
        debugPrint('❌ [SMTC] Error updating Windows SMTC state: $e');
      }
    }
  }

  void onPlay() => _playbackProvider?.resume();
  void onPause() => _playbackProvider?.pause();
  void onPlayPause() {
    if (_playbackProvider == null) return;
    if (_playbackProvider!.isPlaying) {
      _playbackProvider!.pause();
    } else {
      _playbackProvider!.resume();
    }
  }
  void onNext() => _playbackProvider?.playNext();
  void onPrevious() => _playbackProvider?.playPrevious();
  void onStop() => _playbackProvider?.stop();
  void onSeek(Duration offset) {
    if (_playbackProvider == null) return;
    _playbackProvider!.seek(_playbackProvider!.position + offset);
  }
  void onSetPosition(Duration position) {
    _playbackProvider?.seek(position);
  }

  void onRaise() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void onQuit() => exit(0);

  void dispose() {
    _smtcSub?.cancel();
    _dbusClient?.close();
  }
}

class _XaneoMprisObject extends DBusObject {
  final DesktopMediaSessionService service;

  String _title = '';
  String _artist = '';
  bool _isPlaying = false;
  bool _hasTrack = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _hasNext = false;
  bool _hasPrevious = false;
  String? _artUrl;

  _XaneoMprisObject(this.service)
      : super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  void updateState({
    required String title,
    required String artist,
    required bool isPlaying,
    required bool hasTrack,
    required Duration position,
    required Duration duration,
    required bool hasNext,
    required bool hasPrevious,
    String? artUrl,
  }) {
    _title = title;
    _artist = artist;
    _isPlaying = isPlaying;
    _hasTrack = hasTrack;
    _position = position;
    _duration = duration;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _artUrl = artUrl;

    emitPropertiesChanged(
      'org.mpris.MediaPlayer2.Player',
      changedProperties: {
        'PlaybackStatus': DBusString(
          _isPlaying ? 'Playing' : (_hasTrack ? 'Paused' : 'Stopped'),
        ),
        'Metadata': _buildMetadataDict(),
        'CanGoNext': DBusBoolean(_hasNext),
        'CanGoPrevious': DBusBoolean(_hasPrevious),
        'CanPlay': DBusBoolean(_hasTrack),
        'CanPause': DBusBoolean(_isPlaying),
        'CanControl': DBusBoolean(true),
        'Position': DBusInt64(_position.inMicroseconds),
      },
    );
  }

  DBusDict _buildMetadataDict() {
    final map = <String, DBusValue>{
      'mpris:trackid': DBusObjectPath('/org/mpris/MediaPlayer2/track/1'),
      'mpris:length': DBusInt64(_duration.inMicroseconds),
      'xesam:title': DBusString(_title.isNotEmpty ? _title : 'Xaneo'),
      'xesam:artist': DBusArray.string([_artist.isNotEmpty ? _artist : 'Xaneo']),
    };
    if (_artUrl != null && _artUrl!.isNotEmpty) {
      map['mpris:artUrl'] = DBusString(_artUrl!);
    }
    return DBusDict.stringVariant(map);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2',
        methods: [
          DBusIntrospectMethod('Raise'),
          DBusIntrospectMethod('Quit'),
        ],
        properties: [
          DBusIntrospectProperty('CanQuit', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanRaise', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('HasTrackList', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Identity', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('DesktopEntry', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedUriSchemes', DBusSignature('as'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedMimeTypes', DBusSignature('as'), access: DBusPropertyAccess.read),
        ],
      ),
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2.Player',
        methods: [
          DBusIntrospectMethod('Next'),
          DBusIntrospectMethod('Previous'),
          DBusIntrospectMethod('Pause'),
          DBusIntrospectMethod('PlayPause'),
          DBusIntrospectMethod('Stop'),
          DBusIntrospectMethod('Play'),
          DBusIntrospectMethod(
            'Seek',
            args: [DBusIntrospectArgument(DBusSignature('x'), DBusArgumentDirection.in_, name: 'Offset')],
          ),
          DBusIntrospectMethod(
            'SetPosition',
            args: [
              DBusIntrospectArgument(DBusSignature('o'), DBusArgumentDirection.in_, name: 'TrackId'),
              DBusIntrospectArgument(DBusSignature('x'), DBusArgumentDirection.in_, name: 'Position'),
            ],
          ),
          DBusIntrospectMethod(
            'OpenUri',
            args: [DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'Uri')],
          ),
        ],
        properties: [
          DBusIntrospectProperty('PlaybackStatus', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('LoopStatus', DBusSignature('s'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Rate', DBusSignature('d'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Shuffle', DBusSignature('b'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Metadata', DBusSignature('a{sv}'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Volume', DBusSignature('d'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Position', DBusSignature('x'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('MinimumRate', DBusSignature('d'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('MaximumRate', DBusSignature('d'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoNext', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoPrevious', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPlay', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPause', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanSeek', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanControl', DBusSignature('b'), access: DBusPropertyAccess.read),
        ],
        signals: [
          DBusIntrospectSignal(
            'Seeked',
            args: [DBusIntrospectArgument(DBusSignature('x'), DBusArgumentDirection.out, name: 'Position')],
          ),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.mpris.MediaPlayer2') {
      switch (methodCall.name) {
        case 'Raise':
          service.onRaise();
          return DBusMethodSuccessResponse();
        case 'Quit':
          service.onQuit();
          return DBusMethodSuccessResponse();
      }
    } else if (methodCall.interface == 'org.mpris.MediaPlayer2.Player') {
      switch (methodCall.name) {
        case 'Next':
          service.onNext();
          return DBusMethodSuccessResponse();
        case 'Previous':
          service.onPrevious();
          return DBusMethodSuccessResponse();
        case 'Pause':
          service.onPause();
          return DBusMethodSuccessResponse();
        case 'PlayPause':
          service.onPlayPause();
          return DBusMethodSuccessResponse();
        case 'Stop':
          service.onStop();
          return DBusMethodSuccessResponse();
        case 'Play':
          service.onPlay();
          return DBusMethodSuccessResponse();
        case 'Seek':
          if (methodCall.values.isNotEmpty && methodCall.values.first is DBusInt64) {
            final offsetMicro = (methodCall.values.first as DBusInt64).value;
            service.onSeek(Duration(microseconds: offsetMicro));
          }
          return DBusMethodSuccessResponse();
        case 'SetPosition':
          if (methodCall.values.length >= 2 && methodCall.values[1] is DBusInt64) {
            final posMicro = (methodCall.values[1] as DBusInt64).value;
            service.onSetPosition(Duration(microseconds: posMicro));
          }
          return DBusMethodSuccessResponse();
        case 'OpenUri':
          return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.mpris.MediaPlayer2') {
      switch (name) {
        case 'CanQuit':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanRaise':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'HasTrackList':
          return DBusGetPropertyResponse(DBusBoolean(false));
        case 'Identity':
          return DBusGetPropertyResponse(DBusString('Xaneo'));
        case 'DesktopEntry':
          return DBusGetPropertyResponse(DBusString('xaneo'));
        case 'SupportedUriSchemes':
          return DBusGetPropertyResponse(DBusArray.string(['http', 'https', 'file']));
        case 'SupportedMimeTypes':
          return DBusGetPropertyResponse(DBusArray.string(['audio/mpeg', 'audio/mp3', 'audio/flac', 'audio/wav', 'audio/aac', 'audio/ogg']));
      }
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      switch (name) {
        case 'PlaybackStatus':
          return DBusGetPropertyResponse(
            DBusString(_isPlaying ? 'Playing' : (_hasTrack ? 'Paused' : 'Stopped')),
          );
        case 'LoopStatus':
          return DBusGetPropertyResponse(DBusString('None'));
        case 'Rate':
          return DBusGetPropertyResponse(DBusDouble(1.0));
        case 'Shuffle':
          return DBusGetPropertyResponse(DBusBoolean(false));
        case 'Metadata':
          return DBusGetPropertyResponse(_buildMetadataDict());
        case 'Volume':
          return DBusGetPropertyResponse(DBusDouble(1.0));
        case 'Position':
          return DBusGetPropertyResponse(DBusInt64(_position.inMicroseconds));
        case 'MinimumRate':
          return DBusGetPropertyResponse(DBusDouble(1.0));
        case 'MaximumRate':
          return DBusGetPropertyResponse(DBusDouble(1.0));
        case 'CanGoNext':
          return DBusGetPropertyResponse(DBusBoolean(_hasNext));
        case 'CanGoPrevious':
          return DBusGetPropertyResponse(DBusBoolean(_hasPrevious));
        case 'CanPlay':
          return DBusGetPropertyResponse(DBusBoolean(_hasTrack));
        case 'CanPause':
          return DBusGetPropertyResponse(DBusBoolean(_isPlaying));
        case 'CanSeek':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanControl':
          return DBusGetPropertyResponse(DBusBoolean(true));
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface == 'org.mpris.MediaPlayer2') {
      return DBusGetAllPropertiesResponse({
        'CanQuit': DBusBoolean(true),
        'CanRaise': DBusBoolean(true),
        'HasTrackList': DBusBoolean(false),
        'Identity': DBusString('Xaneo'),
        'DesktopEntry': DBusString('xaneo'),
        'SupportedUriSchemes': DBusArray.string(['http', 'https', 'file']),
        'SupportedMimeTypes': DBusArray.string(['audio/mpeg', 'audio/mp3', 'audio/flac', 'audio/wav', 'audio/aac', 'audio/ogg']),
      });
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      return DBusGetAllPropertiesResponse({
        'PlaybackStatus': DBusString(_isPlaying ? 'Playing' : (_hasTrack ? 'Paused' : 'Stopped')),
        'LoopStatus': DBusString('None'),
        'Rate': DBusDouble(1.0),
        'Shuffle': DBusBoolean(false),
        'Metadata': _buildMetadataDict(),
        'Volume': DBusDouble(1.0),
        'Position': DBusInt64(_position.inMicroseconds),
        'MinimumRate': DBusDouble(1.0),
        'MaximumRate': DBusDouble(1.0),
        'CanGoNext': DBusBoolean(_hasNext),
        'CanGoPrevious': DBusBoolean(_hasPrevious),
        'CanPlay': DBusBoolean(_hasTrack),
        'CanPause': DBusBoolean(_isPlaying),
        'CanSeek': DBusBoolean(true),
        'CanControl': DBusBoolean(true),
      });
    }
    return DBusGetAllPropertiesResponse({});
  }
}
