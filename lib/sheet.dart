import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart'; 
import 'vm.dart'; 
import 'social.dart';

final logger = Logger(); 

class RadioSheet extends StatelessWidget {
  const RadioSheet({super.key});

  @override
  Widget build(BuildContext context) {
    logger.d('Building RadioSheet'); 
    return FutureBuilder<List<RadioContent>>(
      future: fetchRadioContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          logger.d('Fetching radio content'); 
          return Container(
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          logger.e('Error fetching radio content: ${snapshot.error}'); 
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.data?.isEmpty ?? true) {
          logger.d('No radio content available'); 
          return const Text('No data available');
        } else {
          logger.d('Radio content fetched successfully'); 
          return buildSheet(context, snapshot.data!);
        }
      },
    );
  }

  Widget buildSheet(BuildContext context, List<RadioContent> content) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black,
      height:
          MediaQuery.of(context).size.height - topPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Stack(
              children: [
                // KPFT logo centered
                Align(
                  alignment:
                      Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 10.0),
                    child: Image.asset('assets/kpft.png',
                        width: 80),
                  ),
                ),
                // Close icon aligned to the top right
                Positioned(
                  right: 4.0,
                  top: 20.0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      size: 36,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty)
              Image.network(
                content[0].topImage,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width *
                    0.4,
                fit:
                    BoxFit.cover,
              ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 8.0, 16.0, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24.0,
                  mainAxisSpacing: 18.0,
                  childAspectRatio: 3.0,
                ),
                itemCount: content.length,
                itemBuilder: (context, index) {
                  final item = content[index];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(
                          int.parse('0xff${item.color.replaceFirst('#', '')}')),
                      backgroundColor: Color(int.parse(
                          '0xff${item.color2.replaceFirst('#', '')}')),
                      padding: const EdgeInsets.all(
                          6.0),
                      minimumSize: const Size(
                          50, 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10.0),
                      ),
                    ),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    onPressed: () => _launchURL(item.url),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 0,
            ),
            const SocialIcons(),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }
}
