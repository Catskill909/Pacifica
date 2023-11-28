import 'dart:convert';
import 'package:http/http.dart' as http;

// Define a class to represent each item in the JSON data
class RadioContent {
  String name;
  String url;
  String color;
  String color2;
  String color3;
  String stream1;
  String stream2;
  String topImage;
  String facebook;
  String instagram;

  // Update the constructor to provide default values for optional fields
  RadioContent({
    required this.name,
    required this.url,
    this.color = '',
    this.color2 = '',
    this.color3 = '',
    this.stream1 = '',
    this.stream2 = '',
    this.topImage = '',
    this.facebook = '',
    this.instagram = '',
  });

  // A factory constructor to create an instance of RadioContent from a map
  factory RadioContent.fromJson(Map<String, dynamic> json) {
    return RadioContent(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      color: json['color'] ?? '',
      color2: json['color2'] ?? '',
      color3: json['color3'] ?? '',
      stream1: json['stream1'] ?? '',
      stream2: json['stream2'] ?? '',
      topImage: json['top_image'] ?? '',
      facebook: json['facebook'] ?? '',
      instagram: json['instagram'] ?? '',
    );
  }
}

// A function to deserialize the JSON data
List<RadioContent> parseRadioContent(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<RadioContent>((json) => RadioContent.fromJson(json)).toList();
}

Future<List<RadioContent>> fetchRadioContent() async {
  var url = Uri.parse('https://script.googleusercontent.com/macros/echo?user_content_key=ZusfaB9Df3_8bGcNzboDRfcXLjvxtpuM-r6S4Fey6r6u5oMId4uPf9h3OGW1TvFRJGwdy3EBeF2esDMX8zE2yCj53VJEn1oGm5_BxDlH2jW0nuo2oDemN9CCS2h10ox_1xSncGQajx_ryfhECjZEnAESNsSTKoRwanpsIaJVjj1R__YhvJOGfwe5LvrW6RTIWAaMvLFGNcev4oUjp5VTl6CzOUYfTNzW2nYfzm4fdJ28mzDTCqnGIg&lib=MB2OKmrqza3mkfX8OeELxciAVIva_cr95');
  var response = await http.get(url);

  if (response.statusCode == 200) {
    return parseRadioContent(response.body);
  } else {
    throw Exception('Failed to load radio content');
  }
}
