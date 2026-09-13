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
/// listening.
///
/// Unlike the website (which offers a full voice picker), this always
/// narrates in Hindi (India) — a fixed choice per request, not a
/// per-article default the reader can change. Play/pause/resume/stop
/// and speed are still adjustable; there's no voice dropdown.
class ArticleNarrationPlayer extends StatefulWidget {
  final String plainText;

  const ArticleNarrationPlayer({super.key, required this.plainText});

  @override
  State<ArticleNarrationPlayer> createState() => _ArticleNarrationPlayerState();
}

enum _PlayState { idle, playing, paused }

const _hindiIndiaLocale = 'hi-IN';

/// The speed dropdown's options, expressed as real perceived multipliers
/// (what "1x" actually sounds like) mapped to the `_rate` value flutter_tts
/// itself needs to reach that speed. `flutter_tts.setSpeechRate()` takes a
/// platform-agnostic 0.0 (slowest) – 1.0 (fastest) value, NOT "1.0 = normal
/// speed" — this package previously passed the real multiplier straight
/// through (e.g. 1.0 for "normal"), which on Android reached the native
/// engine as `rate * 2.0` (see flutter_tts's own Android plugin code),
/// i.e. literally double speed — exactly the "too fast" narration reported.
/// iOS's native default (`AVSpeechUtteranceDefaultSpeechRate`) is ~0.5, so
/// 0.5 is "normal" on both platforms; scaling every option by 0.5 here
/// converts each real multiplier into the value flutter_tts actually wants.
final _speedOptions = <double, String>{
  0.375: '0.75x',
  0.5: '1x',
  0.625: '1.25x',
  0.75: '1.5x',
  1.0: '2x',
};

class _ArticleNarrationPlayerState extends State<ArticleNarrationPlayer> {
  final FlutterTts _tts = FlutterTts();
  _PlayState _state = _PlayState.idle;
  double _rate = 0.5;
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
    await _setHindiVoice();
  }

  /// Always narrates in Hindi (India), regardless of the article's own
  /// language field. Tries to pick an exact hi-IN *voice* first (more
  /// natural-sounding on devices that ship more than one Hindi voice);
  /// setLanguage('hi-IN') alone is a safe fallback every Android TTS
  /// engine understands even without a distinct voice for it.
  Future<void> _setHindiVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is List) {
        for (final v in raw) {
          if (v is Map) {
            final locale = v['locale']?.toString().toLowerCase();
            if (locale == _hindiIndiaLocale.toLowerCase()) {
              await _tts.setVoice({'name': v['name'].toString(), 'locale': v['locale'].toString()});
              return;
            }
          }
        }
      }
    } catch (_) {
      // Fall through to setLanguage below.
    }
    try {
      await _tts.setLanguage(_hindiIndiaLocale);
    } catch (_) {
      // No Hindi language pack on this device — TTS still speaks in
      // whatever the platform default is rather than not working at all.
    }
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
      child: Row(
        children: [
          _PlayButton(state: _state, onPlay: _play, onPause: _pause, onResume: _resume, onStop: _stop),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('इस खबर को सुनें', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          SizedBox(
            width: 92,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _rate,
                isDense: true,
                isExpanded: true,
                items: _speedOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
          if (_state != _PlayState.idle)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, size: 22),
              tooltip: 'रोकें',
              onPressed: _stop,
              visualDensity: VisualDensity.compact,
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
