import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'vm.dart';
import 'social.dart';
import 'ui/responsive.dart';

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading radio content.',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Force a rebuild by using a workaround: pop and re-open the sheet
                      if (context.mounted) {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => const RadioSheet(),
                            );
                          }
                        });
                      }
                    },
                  )
                ],
              ),
            ),
          );
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
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.shortestSide >= 600;
    final isSmallPhone = ResponsiveScale.isSmallPhone(mq);
    final gridCols = isTablet ? 3 : 2;
    final aspect = isTablet ? 2.6 : 3.0;

    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height - topPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // KPFT logo centered
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.asset('assets/kpft.png', width: ResponsiveScale.sSmallAware(context, 80)),
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
                height: MediaQuery.of(context).size.width * (isSmallPhone ? 0.33 : 0.4),
                fit: BoxFit.cover,
              ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: ResponsiveScale.sSmallAware(context, 24.0),
                  mainAxisSpacing: ResponsiveScale.sSmallAware(context, 18.0),
                  childAspectRatio: aspect,
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
                      padding: EdgeInsets.all(ResponsiveScale.sSmallAware(context, 6.0)),
                      minimumSize: Size(
                        ResponsiveScale.sSmallAware(context, 50),
                        ResponsiveScale.sSmallAware(context, 20),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: ResponsiveScale.sSmallAware(context, 26),
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
              height: 4,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 4.0,
                  // Add extra space above the social icons on tablets,
                  // modest space on larger phones, and keep small phones tight.
                  top: isTablet ? 14.0 : (isSmallPhone ? 6.0 : 10.0),
                ),
                child: const SocialIcons(),
              ),
            ),
            const SizedBox(height: 2),
            const PrivacyPolicyButton(),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      logger.w('launchUrl returned false for $urlString');
    }
  }
}

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.white24),
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse('https://docs.pacifica.org/kpft-privacy.html');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (context.mounted) {
              Navigator.pop(context); // dismiss sheet after launching
            }
          }
        },
        child: const Text(
          'Privacy policy',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
