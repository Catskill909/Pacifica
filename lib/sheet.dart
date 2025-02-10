import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'vm.dart'; // Replace with your correct path to vm.dart
import 'social.dart';

class RadioSheet extends StatelessWidget {
  // Updated constructor with key parameter
  const RadioSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RadioContent>>(
      future: fetchRadioContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Center widget with a black background
          return Container(
            color: Colors.black, // Set the background color to black
            child: const Center(
              child: SizedBox(
                width: 50, // Adjust width as needed
                height: 50, // Adjust height as needed
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // Display the error
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.data?.isEmpty ?? true) {
          // Handle the case when there is no data
          return const Text('No data available');
        } else {
          // Data is fetched successfully, build the sheet
          return buildSheet(
              context,
              snapshot
                  .data!); // Ensure that buildSheet is correctly implemented
        }
      },
    );
  }

  Widget buildSheet(BuildContext context, List<RadioContent> content) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black, // Set the background color to black
      height:
          MediaQuery.of(context).size.height - topPadding, // Adjust the height
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Make the column use minimum vertical space
          children: [
            Stack(
              children: [
                // KPFT logo centered
                Align(
                  alignment:
                      Alignment.topCenter, // Align KPFT logo to top center
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 10.0), // Adjust top padding to position the logo
                    child: Image.asset('assets/kpft.png',
                        width: 80), // Adjust width as needed
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
                    0.4, // Set image height to half of its width
                fit:
                    BoxFit.cover, // Ensure the image covers the available width
              ),
            const SizedBox(
              height: 10, // Add some spacing between the image and buttons
            ),
            Padding(
              // Wrap GridView.builder with Padding
              padding: const EdgeInsets.fromLTRB(
                  16.0, 8.0, 16.0, 0), // Apply horizontal and top padding
              child: GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 24.0, // Spacing between columns
                  mainAxisSpacing: 18.0, // Spacing between rows
                  childAspectRatio: 3.0, // Aspect ratio for each button
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
                          6.0), // Adjust the button padding as needed
                      minimumSize: const Size(
                          50, 20), // Set the fixed button width and height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the border radius as needed
                      ),
                    ),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      ), // Adjust the text size as needed
                    ),
                    onPressed: () => _launchURL(item.url),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 0, // Add some spacing between the grid and social icons
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
