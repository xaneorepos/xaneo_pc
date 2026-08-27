import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/playback_provider.dart';
import '../services/api_service.dart';
import '../services/runtime_translations.dart';
import '../utils/audio_metadata.dart';
import 'base_custom_modal.dart';
import 'package:xaneo/l10n/app_localizations.dart';

class _MusicPlaylistL10n {
  static const Map<String, Map<String, String>> _strings = {
    'playlist': {
      'ru': 'Плейлист',
      'en': 'Playlist',
      'es': 'Lista de reproducción',
      'fr': 'Liste de lecture',
      'de': 'Wiedergabeliste',
      'it': 'Playlist',
      'pt': 'Lista de reprodução',
      'zh': '播放列表',
      'ja': 'プレイリスト',
      'ko': '재생목록',
      'ar': 'قائمة التشغيل',
      'tr': 'Çalma listesi',
    },
    'empty_playlist': {
      'ru': 'Музыкальные треки отсутствуют',
      'en': 'No music tracks found',
      'es': 'No hay pistas de música',
      'fr': 'Aucune piste musicale',
      'de': 'Keine Musiktitel gefunden',
      'it': 'Nessun brano musicale trovato',
      'pt': 'Nenhuma faixa de música encontrada',
      'zh': '未找到音乐曲目',
      'ja': '音楽トラックが見つかりません',
      'ko': '음악 트랙이 없습니다',
      'ar': 'لا توجد مقاطع صوتية',
      'tr': 'Müzik parçası bulunamadı',
    },
    'unknown_artist': {
      'ru': 'Неизвестный исполнитель',
      'en': 'Unknown artist',
      'es': 'Artista desconocido',
      'fr': 'Artiste inconnu',
      'de': 'Unbekannter Künstler',
      'it': 'Artista sconosciuto',
      'pt': 'Artista desconhecido',
      'zh': '未知艺术家',
      'ja': '不明なアーティスト',
      'ko': '알 수 없는 아티스트',
      'ar': 'فنان غير معروف',
      'tr': 'Bilinmeyen sanatçı',
    },
    'audio_track': {
      'ru': 'Аудиозапись',
      'en': 'Audio track',
      'es': 'Pista de audio',
      'fr': 'Piste audio',
      'de': 'Audiospur',
      'it': 'Traccia audio',
      'pt': 'Faixa de áudio',
      'zh': '音频曲目',
      'ja': 'オーディオトラック',
      'ko': '오디오 트랙',
      'ar': 'مسار صوتي',
      'tr': 'Ses parçası',
    },
    'prev_track': {
      'ru': 'Предыдущий трек',
      'en': 'Previous track',
      'es': 'Pista anterior',
      'fr': 'Piste précédente',
      'de': 'Vorheriger Titel',
      'it': 'Traccia precedente',
      'pt': 'Faixa anterior',
      'zh': '上一首',
      'ja': '前のトラック',
      'ko': '이전 트랙',
      'ar': 'المسار السابق',
      'tr': 'Önceki parça',
    },
    'next_track': {
      'ru': 'Следующий трек',
      'en': 'Next track',
      'es': 'Pista siguiente',
      'fr': 'Piste suivante',
      'de': 'Nächster Titel',
      'it': 'Traccia successiva',
      'pt': 'Próxima faixa',
      'zh': '下一首',
      'ja': '次のトラック',
      'ko': '다음 트랙',
      'ar': 'المسار التالي',
      'tr': 'Sonraki parça',
    },
    'shuffle_on': {
      'ru': 'Случайный порядок включен',
      'en': 'Shuffle on',
      'es': 'Aleatorio activado',
      'fr': 'Aléatoire activé',
      'de': 'Zufallswiedergabe ein',
      'it': 'Riproduzione casuale attiva',
      'pt': 'Aleatório ativado',
      'zh': '随机播放开启',
      'ja': 'シャッフル オン',
      'ko': '순서 섞기 켜짐',
      'ar': 'الخلط مفعّل',
      'tr': 'Karışık çalma açık',
    },
    'shuffle_off': {
      'ru': 'Случайный порядок выключен',
      'en': 'Shuffle off',
      'es': 'Aleatorio desactivado',
      'fr': 'Aléatoire désactivé',
      'de': 'Zufallswiedergabe aus',
      'it': 'Riproduzione casuale disattivata',
      'pt': 'Aleatório desativado',
      'zh': '随机播放关闭',
      'ja': 'シャッフル オフ',
      'ko': '순서 섞기 꺼짐',
      'ar': 'الخلط معطّل',
      'tr': 'Karışık çalma kapalı',
    },
    'repeat_one': {
      'ru': 'Повтор одного трека',
      'en': 'Repeat one track',
      'es': 'Repetir una pista',
      'fr': 'Répéter une pista',
      'de': 'Einen Titel wiederholen',
      'it': 'Ripeti un brano',
      'pt': 'Repetir uma faixa',
      'zh': '单曲循环',
      'ja': '1曲リピート',
      'ko': '한 곡 반복',
      'ar': 'تكرار مسار واحد',
      'tr': 'Tek parçayı tekrarla',
    },
    'repeat_all': {
      'ru': 'Повтор всех треков',
      'en': 'Repeat all tracks',
      'es': 'Repetir todas las pistas',
      'fr': 'Répéter toutes les pistes',
      'de': 'Alle Titel wiederholen',
      'it': 'Ripeti tutti i brani',
      'pt': 'Repetir todas as faixas',
      'zh': '全部循环',
      'ja': '全曲リピート',
      'ko': '전체 반복',
      'ar': 'تكرار الكل',
      'tr': 'Tümünü tekrarla',
    },
    'repeat_off': {
      'ru': 'Без повтора',
      'en': 'Repeat off',
      'es': 'Sin repetición',
      'fr': 'Pas de répétition',
      'de': 'Keine Wiederholung',
      'it': 'Nessuna ripetizione',
      'pt': 'Sem repetição',
      'zh': '关闭循环',
      'ja': 'リピート オフ',
      'ko': '반복 없음',
      'ar': 'إيقاف التكرار',
      'tr': 'Tekrar kapalı',
    },
  };

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? _strings[key]?['ru'] ?? key;
  }
}

/// Модальное окно плейлиста музыки на базе BaseCustomModal для Xaneo PC.
class MusicPlaylistModal extends BaseCustomModal {
  final List<dynamic> messages;

  const MusicPlaylistModal({
    super.key,
    required this.messages,
    super.modalTag = '',
    super.title = '',
  });

  static Future<void> show(BuildContext context, List<dynamic> messages) {
    return BaseCustomModal.show(
      context: context,
      modal: MusicPlaylistModal(messages: messages),
    );
  }

  @override
  State<MusicPlaylistModal> createState() => _MusicPlaylistModalState();
}

class _MusicPlaylistModalState extends BaseCustomModalState<MusicPlaylistModal> {
  double? _dragValue;

  String _getEffectiveLang(BuildContext context) {
    final active = RuntimeTranslations.instance.activeLocale;
    if (active != null && active.isNotEmpty) {
      return active.toLowerCase();
    }
    return Localizations.localeOf(context).languageCode.toLowerCase();
  }

  @override
  String getModalTitle(BuildContext context) {
    final lang = _getEffectiveLang(context);
    final l10n = AppLocalizations.of(context);
    final dynamicTitle = l10n?.pleylist_a04c ?? l10n?.muzyka_0660;
    if (dynamicTitle != null && dynamicTitle.isNotEmpty && dynamicTitle != 'Fallback' && dynamicTitle != 'ПЛЕЙЛИСТ') {
      return dynamicTitle.toUpperCase();
    }
    return _MusicPlaylistL10n.get('playlist', lang).toUpperCase();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic>? _getCustomPayload(Map<String, dynamic> msg) {
    final decryptedText = msg['decryptedText'] ?? msg['encrypted_text'] ?? '';
    if (decryptedText.toString().trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(decryptedText.toString());
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isAudioFile(Map<String, dynamic> payload) {
    final fileName = (payload['file_name'] ?? payload['name'] ?? '').toString().toLowerCase();
    final mime = (payload['mime_type'] ?? payload['type'] ?? '').toString().toLowerCase();

    final isVoice = payload['type'] == 'voice' ||
        payload['type'] == 'video_message' ||
        fileName.contains('voice') ||
        fileName.endsWith('.ogg') ||
        fileName.endsWith('.opus');
    if (isVoice) return false;

    return mime.startsWith('audio/') ||
        fileName.endsWith('.mp3') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.m4a') ||
        fileName.endsWith('.flac') ||
        fileName.endsWith('.aac') ||
        fileName.endsWith('.wma');
  }

  List<PlaybackItem> _getMusicPlaylistFromMessages() {
    final playlist = <PlaybackItem>[];
    final lang = _getEffectiveLang(context);

    for (final rawMsg in widget.messages) {
      if (rawMsg is! Map) continue;
      final msg = Map<String, dynamic>.from(rawMsg);
      final customPayload = _getCustomPayload(msg);
      final attachedFileId = msg['attached_file_id']?.toString() ?? msg['file_id']?.toString();

      final payload = customPayload ??
          (attachedFileId != null
              ? {
                  'type': msg['attached_file_type'] == 'audio' || msg['file_type'] == 'audio' ? 'audio' : 'file',
                  'file_id': attachedFileId,
                  'file_name': msg['attached_file_name'] ?? msg['file_name'] ?? _MusicPlaylistL10n.get('audio_track', lang),
                  'file_size': msg['attached_file_size'] ?? msg['file_size'] ?? 0,
                  'mime_type': msg['attached_file_type'] ?? 'audio/mp3',
                }
              : null);

      if (payload == null) continue;

      final type = payload['type']?.toString().toLowerCase() ?? '';
      if (type == 'voice' || type == 'video_message') continue;

      if (type == 'audio' || _isAudioFile(payload)) {
        final fileName = payload['file_name']?.toString() ?? payload['name']?.toString() ?? _MusicPlaylistL10n.get('audio_track', lang);
        final title = audioTrackTitle(payload, fileName);
        final rawArtist = audioTrackArtist(payload, fileName).trim();
        final unknownText = AppLocalizations.of(context)?.neizvestnyy_be89 ?? _MusicPlaylistL10n.get('unknown_artist', lang);
        final artist = rawArtist.isNotEmpty ? rawArtist : unknownText;
        final mimeType = payload['mime_type']?.toString() ?? 'audio/mp3';

        final fileId = payload['file_id']?.toString() ?? '';
        final uri = Uri.parse(ApiService.baseUrl);
        final port = uri.hasPort ? ':${uri.port}' : '';
        final host = '${uri.scheme}://${uri.host}$port';
        String? fileUrl = payload['file_url']?.toString();
        if (fileUrl != null && fileUrl.trim().isEmpty) fileUrl = null;
        final suffix = fileUrl ?? '/api/files/download/$fileId/';
        String audioUrl = suffix.startsWith('http') ? suffix : '$host${suffix.startsWith('/') ? '' : '/'}$suffix';
        final lowerName = fileName.toLowerCase();
        if (lowerName.endsWith('.mp3')) {
          audioUrl += audioUrl.contains('?') ? '&ext=.mp3' : '?ext=.mp3';
        } else if (lowerName.endsWith('.flac')) {
          audioUrl += audioUrl.contains('?') ? '&ext=.flac' : '?ext=.flac';
        } else if (lowerName.endsWith('.wav')) {
          audioUrl += audioUrl.contains('?') ? '&ext=.wav' : '?ext=.wav';
        } else if (lowerName.endsWith('.m4a') || lowerName.endsWith('.aac')) {
          audioUrl += audioUrl.contains('?') ? '&ext=.m4a' : '?ext=.m4a';
        }

        final coverUriStr = audioTrackCoverUri(payload);
        final artUri = coverUriStr != null && coverUriStr.isNotEmpty
            ? Uri.tryParse(
                coverUriStr.startsWith('http')
                    ? coverUriStr
                    : '$host${coverUriStr.startsWith('/') ? '' : '/'}$coverUriStr',
              )
            : null;
        final trackDurationSec = audioTrackDuration(payload);

        playlist.add(PlaybackItem(
          url: audioUrl,
          title: title,
          subtitle: artist,
          mimeType: mimeType,
          duration: trackDurationSec > 0 ? Duration(seconds: trackDurationSec) : null,
          artUri: artUri,
          payload: payload,
        ));
      }
    }
    return playlist;
  }

  @override
  Widget buildContent(BuildContext context, ScrollController scrollController, bool isDark, double scale) {
    final playlist = _getMusicPlaylistFromMessages();
    final lang = _getEffectiveLang(context);

    return Consumer<PlaybackProvider>(
      builder: (context, playback, child) {
        final items = playback.playlist.isNotEmpty ? playback.playlist : playlist;
        final hasActiveTrack = playback.currentAudioUrl != null && playback.currentAudioUrl!.isNotEmpty;
        final position = playback.position;
        final duration = playback.duration;
        final isPlaying = playback.isPlaying;

        final currentSliderPos = _dragValue ??
            (duration > Duration.zero
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0);

        final displayPos = _dragValue != null && duration > Duration.zero
            ? Duration(milliseconds: (_dragValue! * duration.inMilliseconds).round())
            : position;

        return Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0 * scale),
                        child: Text(
                          _MusicPlaylistL10n.get('empty_playlist', lang),
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14 * scale,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isCurrent = playback.currentAudioUrl == item.url;
                        final isItemPlaying = isCurrent && playback.isPlaying;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8 * scale),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.35) : Colors.blue.shade50)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(12 * scale),
                            border: Border.all(
                              color: isCurrent ? Colors.blue.withValues(alpha: 0.4) : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 38 * scale,
                              height: 38 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent ? Colors.blue.shade500 : (isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: Center(
                                child: FaIcon(
                                  isCurrent
                                      ? (isItemPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play)
                                      : FontAwesomeIcons.music,
                                  color: isCurrent ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                  size: 14 * scale,
                                ),
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                                    : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5 * scale,
                                fontFamily: 'Inter',
                              ),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11.5 * scale,
                                fontFamily: 'Inter',
                              ),
                            ),
                            onTap: () {
                              if (playback.playlist.isEmpty) {
                                playback.setPlaylist(items, initialUrl: item.url);
                              }
                              playback.playItemAtIndex(index);
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (hasActiveTrack) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141416) : const Color(0xFFF5F5F7),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32 * scale,
                          height: 32 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.music,
                              color: Colors.white,
                              size: 13 * scale,
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                playback.title.isNotEmpty ? playback.title : _MusicPlaylistL10n.get('audio_track', lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13 * scale,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (playback.subtitle.isNotEmpty) ...[
                                SizedBox(height: 1 * scale),
                                Text(
                                  playback.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 11 * scale,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * scale),
                    Row(
                      children: [
                        Text(
                          _formatDuration(displayPos),
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 10.5 * scale,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2.5 * scale,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.5 * scale),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 10 * scale),
                              activeTrackColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                              inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.12),
                              thumbColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                            ),
                            child: Slider(
                              value: currentSliderPos.clamp(0.0, 1.0),
                              onChanged: (val) {
                                setState(() => _dragValue = val);
                                if (duration > Duration.zero) {
                                  final targetMs = (val * duration.inMilliseconds).round();
                                  playback.seekPreview(Duration(milliseconds: targetMs));
                                }
                              },
                              onChangeEnd: (val) {
                                setState(() => _dragValue = null);
                                if (duration > Duration.zero) {
                                  final targetMs = (val * duration.inMilliseconds).round();
                                  playback.seek(Duration(milliseconds: targetMs));
                                }
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 10.5 * scale,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 36 * scale,
                            height: 36 * scale,
                          ),
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: playback.isShuffle
                                ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600)
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 20 * scale,
                          ),
                          onPressed: () => playback.toggleShuffle(),
                          tooltip: playback.isShuffle
                              ? _MusicPlaylistL10n.get('shuffle_on', lang)
                              : _MusicPlaylistL10n.get('shuffle_off', lang),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 38 * scale,
                            height: 38 * scale,
                          ),
                          icon: FaIcon(
                            FontAwesomeIcons.backwardStep,
                            color: (playback.hasPrevious || position.inSeconds > 3)
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white24 : Colors.black26),
                            size: 15 * scale,
                          ),
                          onPressed: (playback.hasPrevious || position.inSeconds > 3)
                              ? () => playback.playPrevious()
                              : null,
                          tooltip: _MusicPlaylistL10n.get('prev_track', lang),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              playback.pause();
                            } else {
                              playback.resume();
                            }
                          },
                          child: Container(
                            width: 38 * scale,
                            height: 38 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.blue.shade600 : Colors.blue.shade500,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 6 * scale,
                                  offset: Offset(0, 2 * scale),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FaIcon(
                                isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                color: Colors.white,
                                size: 14 * scale,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 38 * scale,
                            height: 38 * scale,
                          ),
                          icon: FaIcon(
                            FontAwesomeIcons.forwardStep,
                            color: playback.hasNext
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white24 : Colors.black26),
                            size: 15 * scale,
                          ),
                          onPressed: playback.hasNext
                              ? () => playback.playNext()
                              : null,
                          tooltip: _MusicPlaylistL10n.get('next_track', lang),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 36 * scale,
                            height: 36 * scale,
                          ),
                          icon: Icon(
                            playback.loopMode == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: playback.loopMode != LoopMode.off
                                ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600)
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 20 * scale,
                          ),
                          onPressed: () => playback.toggleLoopMode(),
                          tooltip: playback.loopMode == LoopMode.one
                              ? _MusicPlaylistL10n.get('repeat_one', lang)
                              : playback.loopMode == LoopMode.all
                                  ? _MusicPlaylistL10n.get('repeat_all', lang)
                                  : _MusicPlaylistL10n.get('repeat_off', lang),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

