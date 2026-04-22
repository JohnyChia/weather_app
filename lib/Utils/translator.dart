import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

/// 全局语言状态
ValueNotifier<String> appLang = ValueNotifier("en");

final GoogleTranslator _translator = GoogleTranslator();

class TranslatorHelper {
  static final Map<String, Future<String>> _futureCache = {};
  static final Map<String, String> _resultCache = {};

  static void clearCache() {
    _futureCache.clear();
    _resultCache.clear();
  }

  static Future<String> translate(String text) {
    final lang = appLang.value;

    if (lang == "en") return Future.value(text);

    final key = "${lang}_$text";

    if (_resultCache.containsKey(key)) {
      return Future.value(_resultCache[key]!);
    }

    if (_futureCache.containsKey(key)) {
      return _futureCache[key]!;
    }

    final targetLang = (lang == "zh") ? "zh-cn" : "en";

    final future = _translator.translate(text, to: targetLang).then((result) {
      _resultCache[key] = result.text;
      _futureCache.remove(key);
      return result.text;
    }).catchError((_) => text);

    _futureCache[key] = future;
    return future;
  }
}

class AutoText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const AutoText(
      this.text, {
        super.key,
        this.style,
        this.maxLines,
        this.overflow,
      });

  @override
  State<AutoText> createState() => _AutoTextState();
}

class _AutoTextState extends State<AutoText> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();

    _future = TranslatorHelper.translate(widget.text);

    appLang.addListener(_onLangChanged);
  }

  void _onLangChanged() {
    setState(() {
      _future = TranslatorHelper.translate(widget.text);
    });
  }

  @override
  void didUpdateWidget(covariant AutoText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _future = TranslatorHelper.translate(widget.text);
    }
  }

  @override
  void dispose() {
    appLang.removeListener(_onLangChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? widget.text,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}