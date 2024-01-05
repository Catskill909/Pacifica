// Import the necessary packages
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Define the SocialIcons widget
class SocialIcons extends StatelessWidget {
  // Constructor for the SocialIcons widget
  const SocialIcons({Key? key}) : super(key: key);

  // Override the build method for the SocialIcons widget
  @override
  Widget build(BuildContext context) {
    // Return a Row widget containing a list of SocialIcon widgets
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 2.0), // Add different padding on top and bottom
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Create a SocialIcon widget for Twitter
          SocialIcon(
            icon: FontAwesomeIcons.twitter,
            url: 'https://twitter.com/KpftHouston',
            iconSize: 38,
            padding: 0,
            context: context, // Pass the context to the SocialIcon widget
          ),
          // Add a SizedBox for spacing
          const SizedBox(width: 10),
          // Create a SocialIcon widget for Facebook
          SocialIcon(
            icon: FontAwesomeIcons.facebook,
            url: 'https://www.facebook.com/kpfthouston/',
            iconSize: 38,
            padding: 0,
            context: context, // Pass the context to the SocialIcon widget
          ),
          // Add a SizedBox for spacing
          const SizedBox(width: 10),
          // Create a SocialIcon widget for Instagram
          SocialIcon(
            icon: FontAwesomeIcons.instagram,
            url: 'https://www.instagram.com/kpfthouston/?hl=en',
            iconSize: 38,
            padding: 0,
            context: context, // Pass the context to the SocialIcon widget
          ),
          // Add a SizedBox for spacing
          const SizedBox(width: 10),
          // Create a SocialIcon widget for YouTube
          SocialIcon(
            icon: FontAwesomeIcons.youtube,
            url: 'https://www.youtube.com/channel/UCxf2097DYBA96ffsMwoV4hw',
            iconSize: 38,
            padding: 0,
            context: context, // Pass the context to the SocialIcon widget
          ),
          // Add a SizedBox for spacing
          const SizedBox(width: 10),
          // Create a SocialIcon widget for Email
          SocialIcon(
            icon: FontAwesomeIcons.envelope,
            url: 'mailto:gm@kpft.org',
            iconSize: 38,
            padding: 0,
            context: context, // Pass the context to the SocialIcon widget
          ),
        ],
      ),
    );
  }
}

// Define the SocialIcon widget
class SocialIcon extends StatelessWidget {
  // Define the necessary variables for the SocialIcon widget
  final IconData icon;
  final String url;
  final double iconSize;
  final double padding;
  final double circleRadius;
  final BuildContext context; // Add a variable for the context

  // Constructor for the SocialIcon widget
  const SocialIcon({
    Key? key,
    required this.icon,
    required this.url,
    this.iconSize = 44,
    this.padding = 8,
    this.circleRadius = 28,
    required this.context, // Pass the context to the SocialIcon widget
  }) : super(key: key);

  // Override the build method for the SocialIcon widget
  @override
  Widget build(BuildContext context) {
    // Return a GestureDetector widget that launches a URL when tapped
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: circleRadius,
          child: FaIcon(
            icon,
            color: Colors.black,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  // Define the _launchURL method for the SocialIcon widget
  void _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}