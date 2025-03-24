import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApi {
  static const String GEMINI_API_KEY = "AIzaSyCsE-myi0ey2sBLi_4X39M418pWIuKdQK0";

  static const String endpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY";

  /// Requests a detailed baking recipe with both ingredients and instructions.
  /// The response must be a JSON object with two keys: "ingredients" and "instructions".
  /// "ingredients" is a JSON array of objects (each with quantity, unit, name, skipConversion)
  /// and "instructions" is a JSON array of strings (each representing a step).
  static Future<Map<String, dynamic>> getRecipe(String dishName) async {
    final prompt =
        "Provide a detailed baking recipe for '$dishName' with structured ingredients and instructions. The response must be a JSON object with two keys: 'ingredients' and 'instructions'. The 'ingredients' value must be a JSON array of objects, where each object has the following keys: quantity (numeric), unit, name, and skipConversion (true if the ingredient should not undergo unit conversion). The 'instructions' value must be a JSON array of strings, each representing a step in the recipe. Provide ONLY the JSON object without any explanations or markdown formatting.";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "topK": 1,
          "topP": 1,
          "maxOutputTokens": 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'];
        if (parts != null && parts.isNotEmpty) {
          String jsonText = parts[0]['text'].trim();
          jsonText = _cleanMarkdown(jsonText); // Clean Markdown if exists
          try {
            final result = jsonDecode(jsonText);
            if (result is Map<String, dynamic>) {
              return result;
            } else {
              throw Exception("Expected JSON object but got a different structure.");
            }
          } catch (e) {
            throw Exception("JSON Parsing Error: $e\n\nRaw text was:\n$jsonText");
          }
        }
      }
      throw Exception("Invalid Gemini response structure.");
    } else {
      throw Exception("Gemini API Error: ${response.body}");
    }
  }

  // Helper function to remove Markdown code block formatting
  static String _cleanMarkdown(String response) {
    response = response.trim();
    if (response.startsWith('```json')) {
      response = response.substring(7).trim(); // Remove starting ```json
    }
    if (response.startsWith('```')) {
      response = response.substring(3).trim(); // Remove starting ```
    }
    if (response.endsWith('```')) {
      response = response.substring(0, response.length - 3).trim(); // Remove ending ```
    }
    return response;
  }
}
