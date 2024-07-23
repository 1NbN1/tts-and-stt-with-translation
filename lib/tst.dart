import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Add this line

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  stt.SpeechToText? _speech;
  bool _isListening = false;
  double _confidence = 1.0;
  TextEditingController _controller = TextEditingController();
  TextEditingController _translationController = TextEditingController();
  String _selectedSpeechLanguage = 'en_US';
  String _selectedTranslationLanguage = 'es_ES';
  List<LocaleName> _localeNames = [];
  FlutterTts _flutterTts = FlutterTts(); // Add this line

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadLanguages();
  }

  void _loadLanguages() async {
    bool available = await _speech!.initialize();
    if (available) {
      var locales = await _speech!.locales();
      setState(() {
        _localeNames = locales;
      });
    }
  }

  void _speak(String text, String language) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                value: _selectedSpeechLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpeechLanguage = newValue!;
                  });
                },
                items: _localeNames
                    .map<DropdownMenuItem<String>>((LocaleName locale) {
                  return DropdownMenuItem<String>(
                    value: locale.localeId,
                    child: Text(locale.name),
                  );
                }).toList(),
              ),
              TextField(
                minLines: 5,
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide()),
                  hintText: 'Press the mic and start speaking',
                  suffixIcon: GestureDetector(
                    onTap: _listen,
                    child: _isListening
                        ? AvatarGlow(
                            animate: true,
                            glowColor: Theme.of(context).primaryColor,
                            duration: const Duration(milliseconds: 2000),
                            repeat: true,
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: Colors.blue,
                            ),
                          )
                        : Icon(_isListening ? Icons.stop : Icons.mic),
                  ),
                ),
                style: const TextStyle(fontSize: 24.0),
              ),
              DropdownButton<String>(
                value: _selectedTranslationLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTranslationLanguage = newValue!;
                    // Re-translate the text whenever the translation language is changed
                    if (_controller.text.isNotEmpty) {
                      _translateText(_controller.text);
                    }
                  });
                },
                items: _localeNames
                    .map<DropdownMenuItem<String>>((LocaleName locale) {
                  return DropdownMenuItem<String>(
                    value: locale.localeId,
                    child: Text(locale.name),
                  );
                }).toList(),
              ),
              TextField(
                minLines: 5,
                controller: _translationController,
                readOnly: true,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide()),
                  hintText: 'Translation will appear here',
                ),
                style: const TextStyle(fontSize: 24.0),
              ),
              ElevatedButton(
                onPressed: () {
                  _speak(_translationController.text,
                      _selectedTranslationLanguage);
                },
                child: Text('Speak'),
              ),
              if (_isListening)
                AvatarGlow(
                  animate: true,
                  glowColor: Theme.of(context).primaryColor,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: _listen,
                    child: Icon(_isListening ? Icons.stop : Icons.mic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech!.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech!.listen(
          localeId: _selectedSpeechLanguage,
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
            _translateText(val.recognizedWords);
          }),
        );
      } else {
        setState(() => _isListening = false);
        _speech!.stop();
      }
    } else {
      setState(() => _isListening = false);
      _speech!.stop();
    }
  }

  void _translateText(String text) async {
    final translator = GoogleTranslator();
    Translation translation = await translator.translate(
      text,
      from: _selectedSpeechLanguage.split('_')[0],
      to: _selectedTranslationLanguage.split('_')[0],
    );
    setState(() {
      _translationController.text = translation.text;
    });
  }
}
