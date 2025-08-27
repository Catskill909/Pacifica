// Import the necessary packages
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ui/responsive.dart';

// Define the SocialIcons widget
class SocialIcons extends StatelessWidget {
  // Constructor for the SocialIcons widget
  const SocialIcons({super.key});

  // Override the build method for the SocialIcons widget
  @override
  Widget build(BuildContext context) {
    // Compute responsive diameter so 5 icons fit on any phone.
    final mq = MediaQuery.of(context);
    final double screenWidth = mq.size.width;
    final bool isSmall = ResponsiveScale.isSmallPhone(mq);
    const int count = 5;
    const double gap = 10.0; // slightly tighter gap between icons
    final double available = screenWidth - 32; // approximate content width
    // Choose diameter so that (count * d) + (gaps) fits available width.
    // Cap growth on very wide screens, and cap smaller on small phones only.
    final double baseDiameter = (available - gap * (count - 1)) / count;
    final double diameter = math.min(isSmall ? 40.0 : 52.0, baseDiameter);
    final double iconSize = diameter * 0.65; // visual balance inside circle
    final double radius = diameter / 2;

    // Return a Row widget containing a list of SocialIcon widgets
    return Padding(
      padding: EdgeInsets.only(top: isSmall ? 6.0 : 0.0, bottom: isSmall ? 6.0 : 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Create a SocialIcon widget for Twitter
          SocialIcon(
            icon: FontAwesomeIcons.twitter,
            url: 'https://twitter.com/KpftHouston',
            iconSize: iconSize,
            circleRadius: radius,
            padding: 4,
            context: context, // Pass the context to the SocialIcon widget
          ),
          const SizedBox(width: gap),
          // Create a SocialIcon widget for Facebook
          SocialIcon(
            icon: FontAwesomeIcons.facebook,
            url: 'https://www.facebook.com/kpfthouston/',
            iconSize: iconSize,
            circleRadius: radius,
            padding: 4,
            context: context, // Pass the context to the SocialIcon widget
          ),
          const SizedBox(width: gap),
          // Create a SocialIcon widget for Instagram
          SocialIcon(
            icon: FontAwesomeIcons.instagram,
            url: 'https://www.instagram.com/kpfthouston/?hl=en',
            iconSize: iconSize,
            circleRadius: radius,
            padding: 4,
            context: context, // Pass the context to the SocialIcon widget
          ),
          const SizedBox(width: gap),
          // Create a SocialIcon widget for YouTube
          SocialIcon(
            icon: FontAwesomeIcons.youtube,
            url: 'https://www.youtube.com/channel/UCxf2097DYBA96ffsMwoV4hw',
            iconSize: iconSize,
            circleRadius: radius,
            padding: 4,
            context: context, // Pass the context to the SocialIcon widget
          ),
          const SizedBox(width: gap),
          // Create a SocialIcon widget for Email
          SocialIcon(
            icon: FontAwesomeIcons.envelope,
            url: 'mailto:gm@kpft.org',
            iconSize: iconSize,
            circleRadius: radius,
            padding: 4,
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
    super.key,
    required this.icon,
    required this.url,
    this.iconSize = 44,
    this.padding = 8,
    this.circleRadius = 28,
    required this.context, // Pass the context to the SocialIcon widget
  });

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
