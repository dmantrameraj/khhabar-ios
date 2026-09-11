import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/theme/app_theme.dart';

/// "Listen to this article" — the app-side equivalent of the website's
/// Web Speech API narration player (public/assets/js/narration.js).
/// Deliberately skips that version's live word-by-word highlighting/
/// scroll-sync: retrofitting that onto flutter_html's rendered widget
/// tree would need a full custom text renderer instead, for a feature
/// that mainly matters to someone actively looking at the screen —
/// exactly the case where they'd just read the article instead of
/// listening. Play/pause/resume/stop, speed, and voice (Indian voices
/// preferred, matching the website) carry the actual value: listening
/// while doing something else.
class ArticleNarrationPlayer extends StatefulWidget {
  final String plainText;

  const ArticleNarrationPlayer({super.key, required this.plainText});

  @override
  State<ArticleNarrationPlayer> createState() => _ArticleNarrationPlayerState();
}

enum _PlayState { idle, playing, paused }

/// Major Indian language codes, most-relevant-for-Hindi-news-first —
/// matches ArticleNarrator.INDIAN_LANG_PREFIXES on the website exactly,
/// so the voice picker sorts the same way in both places.
const _indianLocalePrefixes = [
  'hi-IN',
  'en-IN',
  'bn-IN',
  'ta-IN',
  'te-IN',
  'mr-IN',
  'gu-IN',
  'kn-IN',
  'ml-IN',
  'pa-IN',
  'ur-IN',
];

class _ArticleNarrationPlayerState extends State<ArticleNarrationPlayer> {
  final FlutterTts _tts = FlutterTts();
  _PlayState _state = _PlayState.idle;
  double _rate = 1.0;
  List<Map<String, String>> _voices = [];
  Map<String, String>? _voice;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _tts.setStartHandler(() {
      if (mounted) setState(() => _state = _PlayState.playing);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _state = _PlayState.idle);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _state = _PlayState.idle);
    });
    _tts.setPauseHandler(() {
      if (mounted) setState(() => _state = _PlayState.paused);
    });
    _tts.setContinueHandler(() {
      if (mounted) setState(() => _state = _PlayState.playing);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _state = _PlayState.idle);
    });
    await _tts.awaitSpeakCompletion(true);

    try {
      final raw = await _tts.getVoices;
      final voices = <Map<String, String>>[];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map) {
            final name = v['name']?.toString();
            final locale = v['locale']?.toString();
            if (name != null && locale != null) {
              voices.add({'name': name, 'locale': locale});
            }
          }
        }
      }

      final indian = voices.where(_isIndianVoice).toList();
      final others = voices.where((v) => !_isIndianVoice(v)).toList();
      final sorted = [...indian, ...others];

      final preferredPrefix = _isPrimarilyHindi(widget.plainText) ? 'hi-IN' : 'en-IN';
      var defaultVoice = sorted.firstWhere(
        (v) => v['locale']!.toLowerCase().startsWith(preferredPrefix.toLowerCase()),
        orElse: () => sorted.firstWhere(_isIndianVoice, orElse: () => <String, String>{}),
      );
      if (defaultVoice.isEmpty) {
        defaultVoice = sorted.isNotEmpty ? sorted.first : <String, String>{};
      }

      if (mounted) {
        setState(() {
          _voices = sorted;
          _voice = defaultVoice.isEmpty ? null : defaultVoice;
        });
      }
      if (defaultVoice.isNotEmpty) {
        await _tts.setVoice(defaultVoice);
      }
    } catch (_) {
      // No voices available on this device — narration still works with
      // whatever the platform default is, just no picker to show.
    }
  }

  bool _isIndianVoice(Map<String, String> v) {
    final locale = v['locale']?.toLowerCase() ?? '';
    return _indianLocalePrefixes.any((p) => locale.startsWith(p.toLowerCase()));
  }

  bool _isPrimarilyHindi(String text) {
    final devanagari = RegExp(r'[ऀ-ॿ]').allMatches(text).length;
    return text.isNotEmpty && devanagari > text.length * 0.15;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    if (widget.plainText.trim().isEmpty) return;
    try {
      await _tts.setSpeechRate(_rate);
      if (_voice != null) {
        await _tts.setVoice(_voice!);
      }
      await _tts.speak(widget.plainText);
    } catch (_) {
      if (mounted) {
        setState(() => _supported = false);
      }
    }
  }

  Future<void> _pause() => _tts.pause();

  Future<void> _resume() => _play();

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _state = _PlayState.idle);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.navy.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlayButton(state: _state, onPlay: _play, onPause: _pause, onResume: _resume, onStop: _stop),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('इस खबर को सुनें', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              if (_state != _PlayState.idle)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 22),
                  tooltip: 'रोकें',
                  onPressed: _stop,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _rate,
                    isDense: true,
                    isExpanded: true,
                    items: const [0.75, 1.0, 1.25, 1.5, 2.0]
                        .map((r) => DropdownMenuItem(value: r, child: Text('${r}x गति')))
                        .toList(),
                    onChanged: (r) async {
                      if (r == null) return;
                      setState(() => _rate = r);
                      if (_state != _PlayState.idle) {
                        await _tts.setSpeechRate(r);
                        await _play();
                      }
                    },
                  ),
                ),
              ),
              if (_voices.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, String>>(
                      value: _voice,
                      isDense: true,
                      isExpanded: true,
                      items: _voices
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text('${v['name']} (${v['locale']})', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _voice = v);
                        await _tts.setVoice(v);
                        if (_state != _PlayState.idle) {
                          await _play();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final _PlayState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _PlayButton({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, onTap) = switch (state) {
      _PlayState.idle => (Icons.play_circle_fill, onPlay),
      _PlayState.playing => (Icons.pause_circle_filled, onPause),
      _PlayState.paused => (Icons.play_circle_fill, onResume),
    };

    return IconButton(
      icon: Icon(icon, color: AppTheme.accent, size: 34),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
