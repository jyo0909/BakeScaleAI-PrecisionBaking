import 'dart:convert';
import 'package:http/http.dart' as http;

class BakingApi {
  static const String baseUrl = "https://baking-api-665092274723.us-central1.run.app";

  /// Convert Ingredient API Call
  static Future<Map<String, dynamic>> convertIngredient({
    required String ingredient,
    required double quantity,
    required String unit,
    required String country,
  }) async {
    final Uri url = Uri.parse("$baseUrl/convert");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ingredient": ingredient,
        "quantity": quantity,
        "unit": unit,
        "country": country,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Conversion Failed: ${response.body}");
    }
  }

  /// Get Ingredient Substitutes API Call
  static Future<Map<String, dynamic>> getSubstitutes({required String ingredient}) async {
    final Uri url = Uri.parse("$baseUrl/substitute");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ingredient": ingredient}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Substitution Failed: ${response.body}");
    }
  }
}
