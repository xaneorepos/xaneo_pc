import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:just_audio/just_audio.dart';

import '../api_service.dart';
import 'webrtc_signaling_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xaneo/services/notification_service.dart';

enum CallState {
  idle,
  outgoing,
  incoming,
  connected,
}

class CallManager extends ChangeNotifier {
  final ApiService _apiService;
  final WebRTCSignalingService _signalingService;
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  CallState _state = CallState.idle;
  CallState get state => _state;

  String? _activeCallId;
  String? get activeCallId => _activeCallId;

  String? _targetUserId;
  String? get targetUserId => _targetUserId;

  String? _targetName;
  String? get targetName => _targetName;

  String? _targetAvatar;
  String? get targetAvatar => _targetAvatar;

  String? _targetGradient;
  String? get targetGradient => _targetGradient;

  String _callType = 'audio'; // 'audio' or 'video'
  String get callType => _callType;

  Room? _room;
  Room? get room => _room;

  VideoTrack? _localVideoTrack;
  VideoTrack? get localVideoTrack => _localVideoTrack;

  VideoTrack? _remoteVideoTrack;
  VideoTrack? get remoteVideoTrack => _remoteVideoTrack;

  VideoTrack? _remoteScreenShareTrack;
  VideoTrack? get remoteScreenShareTrack => _remoteScreenShareTrack;

  bool _isMicrophoneMuted = false;
  bool get isMicrophoneMuted => _isMicrophoneMuted;

  bool _isCameraOff = false;
  bool get isCameraOff => _isCameraOff;

  bool _isScreenSharing = false;
  bool get isScreenSharing => _isScreenSharing;

  bool _isGroupCall = false;
  bool get isGroupCall => _isGroupCall;

  String? _groupCallId;
  String? get groupCallId => _groupCallId;

  EventsListener<RoomEvent>? _roomListener;

  CallManager({
    ApiService? apiService,
    required WebRTCSignalingService signalingService,
  })  : _apiService = apiService ?? ApiService(),
        _signalingService = signalingService {
    // Подписываемся на события сигнального WebSocket
    _signalingService.onIncomingCall = _handleIncomingCall;
    _signalingService.onCallAnswered = _handleCallAnswered;
    _signalingService.onCallRejected = _handleCallRejected;
    _signalingService.onCallEnded = _handleCallEnded;
    _signalingService.onCallOfferSent = _handleCallOfferSent;
    _signalingService.onCallAnsweredElsewhere = _handleCallAnsweredElsewhere;
    _signalingService.onIncomingGroupCall = _handleIncomingGroupCall;
    _signalingService.onGroupCallOfferSent = _handleGroupCallOfferSent;
    _signalingService.onGroupCallEnded = _handleGroupCallEnded;
    _signalingService.onGroupParticipantJoined = _handleGroupParticipantJoined;
    _signalingService.onGroupParticipantLeft = _handleGroupParticipantLeft;
  }

  /// Инициировать исходящий групповой звонок
  Future<void> startOutgoingGroupCall({
    required String groupId,
    required String groupName,
    String? groupAvatar,
    String? groupGradient,
    required String callType,
  }) async {
    try {
      if (_state != CallState.idle) return;

      _state = CallState.outgoing;
      _isGroupCall = true;
      _targetUserId = groupId;
      _targetName = groupName;
      _targetAvatar = groupAvatar;
      _targetGradient = groupGradient;
      _callType = callType;
      _isMicrophoneMuted = false;
      _isCameraOff = false;
      notifyListeners();

      _signalingService.startGroupCall(
        groupId: groupId,
        callType: callType,
      );
    } catch (e, stack) {
      debugPrint('CallManager: error starting outgoing group call: $e\n$stack');
      rethrow;
    }
  }

  final Map<String, Map<String, dynamic>> _groupParticipants = {};
  Map<String, Map<String, dynamic>> get groupParticipants => _groupParticipants;

  void _handleIncomingGroupCall(Map<String, dynamic> data) {
    if (_state != CallState.idle) return;

    _state = CallState.incoming;
    _isGroupCall = true;
    _groupCallId = data['group_call_id']?.toString();
    _activeCallId = _groupCallId;
    _targetUserId = data['group_id']?.toString();
    _targetName = data['group_name']?.toString() ?? 'Групповой звонок';
    _targetAvatar = data['group_avatar']?.toString();
    _targetGradient = data['group_gradient']?.toString();
    _callType = data['call_type']?.toString() ?? 'video';
    _isMicrophoneMuted = false;
    _isCameraOff = false;
    _groupParticipants.clear();
    
    // Добавляем инициатора в список участников
    final initId = data['initiator_id']?.toString();
    if (initId != null) {
      _groupParticipants[initId] = {
        'user_id': initId,
        'name': data['initiator_name']?.toString() ?? 'Организатор',
        'avatar': data['initiator_avatar'],
        'gradient': data['initiator_gradient'],
        'status': 'connected',
      };
    }

    _startRingtone();
    notifyListeners();
  }

  void _handleGroupCallOfferSent(Map<String, dynamic> data) {
    final gCallId = data['group_call_id']?.toString();
    if (gCallId != null) {
      _groupCallId = gCallId;
      _activeCallId = gCallId;
      _state = CallState.connected;
      notifyListeners();
      _connectToLiveKit(gCallId);
    }
  }

  void _handleGroupCallEnded(Map<String, dynamic> data) {
    _groupParticipants.clear();
    _cleanup();
  }

  void _handleGroupParticipantJoined(Map<String, dynamic> data) {
    final uid = data['user_id']?.toString();
    if (uid != null) {
      final name = data['first_name']?.toString() ?? data['username']?.toString() ?? 'Участник $uid';
      _groupParticipants[uid] = {
        'user_id': uid,
        'name': name.isNotEmpty ? name : 'Участник $uid',
        'avatar': data['avatar'],
        'gradient': data['gradient'],
        'status': 'connected',
      };
    }
    if (data['connected_participants'] is Map) {
      final cp = data['connected_participants'] as Map;
      cp.forEach((key, val) {
        final kStr = key.toString();
        if (val is Map) {
          _groupParticipants[kStr] = {
            'user_id': kStr,
            'name': val['first_name'] ?? val['username'] ?? 'Участник $kStr',
            'avatar': val['avatar'],
            'gradient': val['gradient'],
            'status': val['status'] ?? 'connected',
          };
        }
      });
    }
    notifyListeners();
  }

  void _handleGroupParticipantLeft(Map<String, dynamic> data) {
    final uid = data['user_id']?.toString();
    if (uid != null) {
      _groupParticipants.remove(uid);
    }
    notifyListeners();
  }

  /// Инициировать исходящий звонок
  Future<void> startOutgoingCall({
    required String targetUserId,
    required String targetName,
    required String callerName,
    String? targetAvatar,
    String? targetGradient,
    required String callType,
  }) async {
    try {
      if (_state != CallState.idle) return;

      _state = CallState.outgoing;
      _targetUserId = targetUserId;
      _targetName = targetName;
      _targetAvatar = targetAvatar;
      _targetGradient = targetGradient;
      _callType = callType;
      _isMicrophoneMuted = false;
      _isCameraOff = false;
      notifyListeners();

      // Отправляем сигнальное сообщение о начале звонка
      _signalingService.startCall(
        targetUserId: targetUserId,
        callType: callType,
        callerName: callerName,
      );
    } catch (e, stack) {
      debugPrint('CallManager: error starting outgoing call: $e\n$stack');
      rethrow;
    }
  }

  /// Принять входящий звонок
  Future<void> acceptIncomingCall() async {
    final callId = _activeCallId;
    if (_state != CallState.incoming || callId == null) return;

    _stopRingtone();
    _state = CallState.connected;
    notifyListeners();

    // 1. Отвечаем по WebSocket
    if (_isGroupCall) {
      _signalingService.acceptGroupCall(callId);
    } else {
      _signalingService.acceptCall(callId);
    }

    // 2. Подключаемся к LiveKit
    try {
      await _connectToLiveKit(callId);
    } catch (e) {
      debugPrint('CallManager: accept error: $e');
      hangUp(reason: 'Ошибка подключения к LiveKit');
    }
  }

  /// Отклонить входящий звонок
  void rejectIncomingCall() {
    final callId = _activeCallId;
    if (_state != CallState.incoming || callId == null) return;

    if (_isGroupCall) {
      _signalingService.rejectGroupCall(callId);
    } else {
      _signalingService.rejectCall(callId);
    }
    _cleanup();
  }

  /// Принять звонок по ID
  Future<void> acceptCallById(String callId, {String? callerName, String? callerId}) async {
    debugPrint('CallManager: acceptCallById $callId, callerName=$callerName, callerId=$callerId');
    
    _activeCallId = callId;
    _state = CallState.incoming;
    if (callerName != null) _targetName = callerName;
    if (callerId != null) _targetUserId = callerId;
    notifyListeners();

    try {
      // Инициализируем соединение, если необходимо
      if (!_signalingService.isConnected.value && _targetUserId != null) {
        await _signalingService.connect(_targetUserId!);
      }
      await acceptIncomingCall();
    } catch (e) {
      debugPrint('CallManager: acceptCallById error: $e');
      hangUp(reason: 'Ошибка принятия звонка при старте');
    }
  }

  /// Отклонить звонок по ID
  Future<void> rejectCallById(String callId) async {
    debugPrint('CallManager: rejectCallById $callId');
    if (_activeCallId == callId && _state == CallState.incoming) {
      rejectIncomingCall();
      return;
    }
    _cleanup();
  }

  /// Завершить текущий звонок (сброс)
  void hangUp({String reason = 'Звонок завершен'}) {
    final callId = _activeCallId;
    if (callId != null) {
      if (_isGroupCall) {
        if (_state == CallState.incoming) {
          _signalingService.rejectGroupCall(callId, reason: reason);
        } else {
          _signalingService.leaveGroupCall(callId, reason: reason);
        }
      } else {
        if (_state == CallState.incoming) {
          _signalingService.rejectCall(callId, reason: reason);
        } else {
          _signalingService.endCall(callId, reason: reason);
        }
      }
    }
    _cleanup();
  }

  /// Включить/выключить микрофон
  void toggleMicrophone() {
    _isMicrophoneMuted = !_isMicrophoneMuted;
    _room?.localParticipant?.setMicrophoneEnabled(!_isMicrophoneMuted);
    notifyListeners();
  }

  /// Включить/выключить камеру
  void toggleCamera() {
    if (_callType != 'video') return;
    _isCameraOff = !_isCameraOff;
    _room?.localParticipant?.setCameraEnabled(!_isCameraOff);
    notifyListeners();
  }

  /// Включить/выключить демонстрацию экрана
  void toggleScreenShare() {
    _isScreenSharing = !_isScreenSharing;
    _room?.localParticipant?.setScreenShareEnabled(_isScreenSharing);
    notifyListeners();
  }

  /// Завершить звонок (алиас для hangUp)
  void endCall() {
    hangUp();
  }

  void _handleCallOfferSent(Map<String, dynamic> data) {
    if (_state != CallState.outgoing) return;
    _activeCallId = data['call_id']?.toString();
    
    // Подключаемся к LiveKit комнате сразу и ждем собеседника
    if (_activeCallId != null) {
      _connectToLiveKit(_activeCallId!);
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (_state != CallState.idle) {
      // Занято
      final callId = data['call_id']?.toString();
      if (callId != null) {
        _signalingService.rejectCall(callId, reason: 'Линия занята');
      }
      return;
    }

    _state = CallState.incoming;
    _activeCallId = data['call_id']?.toString();
    _targetUserId = data['caller_id']?.toString();
    _targetName = data['caller_first_name']?.toString() ?? data['caller_name']?.toString() ?? 'Пользователь';
    _targetAvatar = data['caller_avatar']?.toString();
    _targetGradient = data['caller_gradient']?.toString();
    _callType = data['call_type']?.toString() ?? 'audio';
    _isMicrophoneMuted = false;
    _isCameraOff = false;
    _startRingtone();
    notifyListeners();

    windowManager.isFocused().then((isFocused) {
      if (!isFocused) {
        NotificationService().showCallNotification(
          callId: _activeCallId ?? '',
          callerName: _targetName ?? 'Пользователь',
          callType: _callType,
          avatar: _targetAvatar,
          gradient: _targetGradient,
        );
      }
    });
  }

  void _handleCallAnswered(Map<String, dynamic> data) {
    if (_state != CallState.outgoing) return;
    _state = CallState.connected;
    notifyListeners();
  }

  void _handleCallRejected(Map<String, dynamic> data) {
    _cleanup();
  }

  void _handleCallEnded(Map<String, dynamic> data) {
    _cleanup();
  }

  void _handleCallAnsweredElsewhere(Map<String, dynamic> data) {
    if (_state == CallState.connected) return;
    _cleanup();
  }

  // ==================== LIVEKIT ПОДКЛЮЧЕНИЕ ====================

  Future<void> _connectToLiveKit(String roomName) async {
    try {
      // 1. Получаем токен с бэка через наш ApiService
      final response = await _apiService.getLiveKitToken(roomName);

      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Не удалось получить LiveKit токен');
      }

      final token = response.data!['token']?.toString() ?? '';
      var lkUrl = response.data!['url']?.toString() ?? '';

      final apiUri = Uri.parse(ApiService.baseUrl);
      final apiHost = apiUri.host;
      if (lkUrl.isNotEmpty) {
        final parsedLk = Uri.parse(lkUrl);
        if (apiHost != 'xaneo.ru') {
          final scheme = parsedLk.scheme == 'wss' ? 'ws' : parsedLk.scheme;
          final port = parsedLk.hasPort ? parsedLk.port : 7880;
          lkUrl = Uri(
            scheme: scheme,
            host: apiHost,
            port: port,
            path: parsedLk.path.isNotEmpty ? parsedLk.path : null,
          ).toString();
        }
      }
      debugPrint('CallManager: PC connecting to LiveKit URL: $lkUrl');

      // 2. Создаем комнату
      _room = Room();
      _roomListener = _room!.createListener();

      // Слушаем появление удаленных треков
      _roomListener!.on<TrackSubscribedEvent>((event) {
        if (event.track.kind == TrackType.VIDEO) {
          if (event.publication.source == TrackSource.screenShareVideo) {
            _remoteScreenShareTrack = event.track as VideoTrack;
          } else {
            _remoteVideoTrack = event.track as VideoTrack;
          }
          notifyListeners();
        }
      });

      _roomListener!.on<TrackUnsubscribedEvent>((event) {
        if (event.track.kind == TrackType.VIDEO) {
          if (event.publication.source == TrackSource.screenShareVideo) {
            _remoteScreenShareTrack = null;
          } else {
            _remoteVideoTrack = null;
          }
          notifyListeners();
        }
      });

      // 3. Подключаемся
      await _room!.connect(
        lkUrl,
        token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );

      // 4. Публикуем микрофон
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // 5. Публикуем камеру, если видеозвонок
      if (_callType == 'video') {
        await _room!.localParticipant?.setCameraEnabled(true);
        _localVideoTrack = _room!.localParticipant?.videoTrackPublications.firstOrNull?.track as VideoTrack?;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('CallManager: LiveKit connection error: $e');
      hangUp(reason: 'Ошибка подключения к комнате');
    }
  }

  void _startRingtone() async {
    try {
      await _ringtonePlayer.setAsset('assets/sounds/incoming-call.mp3');
      await _ringtonePlayer.setLoopMode(LoopMode.one);
      await _ringtonePlayer.setVolume(0.7);
      _ringtonePlayer.play();
    } catch (e) {
      debugPrint('CallManager: error playing ringtone: $e');
    }
  }

  void _stopRingtone() async {
    try {
      if (_ringtonePlayer.playing) {
        await _ringtonePlayer.stop();
      }
    } catch (e) {
      debugPrint('CallManager: error stopping ringtone: $e');
    }
  }

  void _cleanup() {
    _stopRingtone();
    _roomListener?.dispose();
    _roomListener = null;

    _room?.disconnect();
    _room = null;

    _localVideoTrack = null;
    _remoteVideoTrack = null;
    _remoteScreenShareTrack = null;
    _isScreenSharing = false;
    _activeCallId = null;
    _targetUserId = null;
    _targetName = null;
    _targetAvatar = null;
    _targetGradient = null;
    _state = CallState.idle;
    notifyListeners();

    NotificationService().dismissCallNotification();
  }

  Future<void> startScreenShare(DesktopCapturerSource source) async {
    if (_room == null) return;
    try {
      _isScreenSharing = true;
      await _room!.localParticipant?.setScreenShareEnabled(
        true,
        screenShareCaptureOptions: ScreenShareCaptureOptions(
          sourceId: source.id,
          maxFrameRate: 15.0,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('CallManager: error starting screen share: $e');
      _isScreenSharing = false;
      notifyListeners();
    }
  }

  Future<void> stopScreenShare() async {
    if (_room == null) return;
    try {
      _isScreenSharing = false;
      await _room!.localParticipant?.setScreenShareEnabled(false);
      notifyListeners();
    } catch (e) {
      debugPrint('CallManager: error stopping screen share: $e');
    }
  }

  @override
  void dispose() {
    _cleanup();
    _ringtonePlayer.dispose();
    super.dispose();
  }
}
