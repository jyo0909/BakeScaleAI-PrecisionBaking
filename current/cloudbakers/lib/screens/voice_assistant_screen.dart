import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {

  bool _shouldAutoListen = false;

  final List<Map<String, String>> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isLoading = false;
  String? _awaitingCountryFor;
  Map<String, dynamic>? _incompleteQuery;

  @override
void initState() {
  super.initState();
  _tts.setCompletionHandler(() {
    if (_shouldAutoListen) {
      _listen(); // resume listening after speaking
    }
  });
}


  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            if (val.finalResult) {
              String userInput = val.recognizedWords;
              _speech.stop();
              setState(() => _isListening = false);

              setState(() {
                _messages.add({"sender": "user", "text": userInput});
                _isLoading = true;
              });

              String response;

              if (_awaitingCountryFor != null && _incompleteQuery != null) {
                _incompleteQuery!["country"] = _parseCountryFromText(userInput);
                response = await _callApi(_incompleteQuery!);
                _awaitingCountryFor = null;
                _incompleteQuery = null;
              } else {
                final parsed = _parseUserQuery(userInput);
                if (parsed == null) {
                  response = "Sorry, I didn't understand. You can say things like 'Convert 1 cup of sugar to grams in India' or 'substitute for butter'.";
                } else if (parsed["type"] == "convert" && (parsed["country"] == null || parsed["country"].isEmpty)) {
                  _awaitingCountryFor = parsed["ingredient"];
                  _incompleteQuery = parsed;
                  response = "Which country's measurements would you like to convert for? You can say: US, UK, or Metric.";
                } else {
                  response = await _callApi(parsed);
                }
              }

              setState(() {
                _messages.add({"sender": "assistant", "text": response});
                _isLoading = false;
              });

              await _speakAndListenAfter(
                response,
                autoListen: _awaitingCountryFor != null, // only auto listen if follow-up needed
              );


            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speakAndListenAfter(String text, {bool autoListen = false}) async {
  _shouldAutoListen = autoListen;
  await _tts.speak(text);
}


  String _parseCountryFromText(String input) {
    input = input.toLowerCase();
    if (input.contains("us") || input.contains("america") || input.contains("united states")) {
      return "US";
    } else if (input.contains("uk") || input.contains("britain") || input.contains("england")) {
      return "UK";
    } else if (input.contains("india") || input.contains("australia") || input.contains("metric") || input.contains("europe")) {
      return "Metric";
    }
    return "US";
  }

  Future<String> _callApi(Map<String, dynamic> parsed) async {
    const baseUrl = "https://baking-api-665092274723.us-central1.run.app";
    try {
      if (parsed['type'] == 'convert') {
        final response = await http.post(
          Uri.parse("$baseUrl/convert"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(parsed),
        );
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          return "${result["quantity"]} ${result["from"]} of ${result["ingredient"]} equals ${result["grams"]} ${result["to"]} in ${parsed["country"]}";
        } else {
          return "Conversion failed. Please try again.";
        }
      } else {
        final response = await http.post(
          Uri.parse("$baseUrl/substitute"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"ingredient": parsed["ingredient"]}),
        );
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          return "You can substitute ${result["ingredient"]} with: ${result["substitutes"].join(', ')}.";
        } else {
          return "Could not find a substitute.";
        }
      }
    } catch (e) {
      return "Oops! Something went wrong: ${e.toString()}";
    }
  }

  Map<String, dynamic>? _parseUserQuery(String query) {
    query = query.toLowerCase();
    if (query.contains("convert")) {
      final regex = RegExp(r'convert\s+([\d.]+|\w+)\s+(\w+)\s+of\s+(\w+)(?:\s+to\s+\w+)?(?:\s+in\s+(\w+))?');
      final match = regex.firstMatch(query);
      if (match != null) {
        final quantity = _parseNumber(match.group(1)!);
        final unit = _mapUnit(match.group(2)!);
        final ingredient = match.group(3)!;
        final country = match.group(4);
        return {
          "type": "convert",
          "quantity": quantity,
          "unit": unit,
          "ingredient": ingredient,
          "country": country,
        };
      }
    } else if (query.contains("substitute") || query.contains("replace") || query.contains("alternative")) {
      final regex = RegExp(r'(?:substitute|replace|alternative)\s+(?:for\s+)?(\w+)');
      final match = regex.firstMatch(query);
      if (match != null) {
        return {"type": "substitute", "ingredient": match.group(1)!};
      }
    }
    return null;
  }

  double? _parseNumber(String input) {
    final words = {
      "one": 1, "two": 2, "three": 3, "four": 4,
      "five": 5, "six": 6, "seven": 7, "eight": 8,
      "nine": 9, "ten": 10
    };
    return double.tryParse(input) ?? words[input]?.toDouble();
  }

  String _mapUnit(String unit) {
    final mapping = {
      "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp",
      "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp",
      "cup": "cup", "cups": "cup", "gram": "g", "grams": "g",
      "kilogram": "kg", "kilograms": "kg",
    };
    return mapping[unit] ?? unit;
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2))
          ],
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f9),
      appBar: AppBar(
        title: const Text("Baking Assistant"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16, top: 8),
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg["text"]!, msg["sender"] == "user");
              },
            ),
          ),
          if (_isLoading)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 120),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isListening ? Colors.red : Colors.green,
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
