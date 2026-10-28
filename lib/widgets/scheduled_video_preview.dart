import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class ScheduledVideoPreview extends StatefulWidget {
  final File? file;
  final String? url;
  const ScheduledVideoPreview({super.key, this.file, this.url});
  @override
  State<ScheduledVideoPreview> createState() => _ScheduledVideoPreviewState();
}

class _ScheduledVideoPreviewState extends State<ScheduledVideoPreview> {
  Player? _player;
  VideoController? _video;
  bool _loading = false;
  bool _failed = false;
  Future<void> _play() async {
    if (_loading || _player != null) return;
    setState(() => _loading = true);
    try {
      final player = Player();
      _player = player;
      _video = VideoController(player);
      await player.open(Media(widget.file?.path ?? widget.url!));
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: _failed
        ? const Icon(Icons.broken_image_outlined)
        : _video != null && !_loading
        ? Video(controller: _video!)
        : ColoredBox(
            color: Colors.black,
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      onPressed: _play,
                      color: Colors.white,
                      iconSize: 40,
                      icon: const Icon(Icons.play_circle_outline),
                    ),
            ),
          ),
  );
}
