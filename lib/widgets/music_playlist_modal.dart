import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/playback_provider.dart';
import '../services/api_service.dart';
import 'base_custom_modal.dart';
import 'package:xaneo/l10n/app_localizations.dart';

/// Модальное окно плейлиста музыки на базе BaseCustomModal для Xaneo PC.
class MusicPlaylistModal extends BaseCustomModal {
  final List<dynamic> messages;

  MusicPlaylistModal({
    super.key,
    required this.messages,
  }) : super(
          modalTag: 'Fallback',
          title: 'Fallback',
        );

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
  Map<String, dynamic>? _getCustomPayload(Map<String, dynamic> msg) {
    final dynamic rawId = msg['id'];
    final decryptedText = msg['decryptedText'] ?? msg['encrypted_text'] ?? "";
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return (AppLocalizations.of(context)?.loc_0B_5a4d ?? 'Fallback');
    var suffixes = [(AppLocalizations.of(context)?.b_3b67 ?? 'Fallback'), (AppLocalizations.of(context)?.kb_419d ?? 'Fallback'), (AppLocalizations.of(context)?.mb_b808 ?? 'Fallback'), (AppLocalizations.of(context)?.gb_e572 ?? 'Fallback')];
    var i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  List<PlaybackItem> _getMusicPlaylistFromMessages() {
    final playlist = <PlaybackItem>[];

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
                  'file_name': msg['attached_file_name'] ?? msg['file_name'] ?? (AppLocalizations.of(context)?.audiozapis_867d ?? 'Fallback'),
                  'file_size': msg['attached_file_size'] ?? msg['file_size'] ?? 0,
                  'mime_type': msg['attached_file_type'] ?? 'audio/mp3',
                }
              : null);

      if (payload == null) continue;

      final type = payload['type']?.toString().toLowerCase() ?? '';
      if (type == 'voice' || type == 'video_message') continue;

      if (type == 'audio' || _isAudioFile(payload)) {
        final fileName = payload['file_name']?.toString() ?? payload['name']?.toString() ?? (AppLocalizations.of(context)?.muzykalnyyTrek_b15d ?? 'Fallback');
        final fileSize = payload['file_size'] as int? ?? 0;
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

        playlist.add(PlaybackItem(
          url: audioUrl,
          title: fileName,
          subtitle: _formatBytes(fileSize),
          mimeType: mimeType,
          payload: payload,
        ));
      }
    }
    return playlist;
  }

  @override
  Widget buildContent(BuildContext context, ScrollController scrollController, bool isDark, double scale) {
    final playlist = _getMusicPlaylistFromMessages();

    return Consumer<PlaybackProvider>(
      builder: (context, playback, child) {
        final items = playback.playlist.isNotEmpty ? playback.playlist : playlist;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0 * scale),
              child: Text(
                (AppLocalizations.of(context)?.muzykalnyeTrekiOtsutstvuyut_3301 ?? 'Fallback'),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14 * scale,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isCurrent = playback.currentAudioUrl == item.url;
            final isPlaying = isCurrent && playback.isPlaying;

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
                          ? (isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play)
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
        );
      },
    );
  }
}
