import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyCRT0n2r5LaAMQOGMUAen1X53WEwhVdBDQ';
  try {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    // Since there's no direct listModels in the SDK easily accessible without additional imports,
    // we try a very simple generateContent with a known model to see the error or success.
    final response = await model.generateContent([Content.text('hi')]);
    print('Success: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}
