import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' show parse;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPFT News',
      theme: ThemeData.dark(),
      home: const WordPressIntegrationScreen(),
    );
  }
}

class WordPressIntegrationScreen extends StatefulWidget {
  const WordPressIntegrationScreen({super.key});

  @override
  WordPressIntegrationScreenState createState() =>
      WordPressIntegrationScreenState();
}

class WordPressIntegrationScreenState
    extends State<WordPressIntegrationScreen> {
  late Future<List<Post>> posts;

  @override
  void initState() {
    super.initState();
    posts = fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    final response = await http
        .get(Uri.parse('https://kpft.org/wp-json/wp/v2/posts?per_page=20'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KPFT News',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // Close icon
            onPressed: () {
              Navigator.pop(context); // Close the view
            },
          ),
        ],
        automaticallyImplyLeading: false, // Prevents the back arrow
      ),
      body: FutureBuilder<List<Post>>(
        future: posts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            return ListView.separated(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  trailing:
                      const Icon(Icons.arrow_forward_ios), // Adds ">" icon
                  tileColor: Colors.grey[850], // Dark tile background color
                  title: Text(
                    snapshot.data![index].title,
                    style: const TextStyle(
                      fontFamily:
                          'Oswald', // The font family name you used in pubspec.yaml
                      fontWeight: FontWeight.w400,
                      fontSize: 16.0, // Adjust the font size as needed
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostDetailScreen(post: snapshot.data![index]),
                      ),
                    );
                  },
                );
              },
              // Divider widget as a separator
              separatorBuilder: (context, index) {
                return const Divider(color: Colors.grey, height: 1);
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  PostDetailScreenState createState() => PostDetailScreenState();
}

class PostDetailScreenState extends State<PostDetailScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('http')) {
              _launchURL(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(
      Uri.dataFromString(
        '<html>'
        '<head>'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        '<style>'
        'body { font-size: 16px; font-family: Helvetica, Sans-Serif;}'
        'img, video, iframe { max-width: 100%; height: auto; }'
        '</style>'
        '</head>'
        '<body>'
        '<h1>${widget.post.title}</h1>'
        '${widget.post.content}'
        '</body>'
        '</html>',
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ),
    );
  }

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KPFT News',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}

class Post {
  final String title;
  final String content;

  Post({required this.title, required this.content});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: _decodeHtmlString(json['title']['rendered']),
      content: json['content']['rendered'],
    );
  }

  static String _decodeHtmlString(String htmlString) {
    var document = parse(htmlString);
    return document.body?.innerHtml ?? "";
  }
}
