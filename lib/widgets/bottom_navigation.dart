import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamBottomNavigation extends StatelessWidget {
  final Function(String streamId, String webViewUrl) onTabChanged;
  final int currentIndex;

  const StreamBottomNavigation({
    super.key,
    required this.onTabChanged,
    required this.currentIndex,
  });

  void _handleTabTap(int index, BuildContext context) async {
    if (index == 3) {
      // DONATE tab - open in external browser
      final Uri url = Uri.parse('https://kpft.org/support-kpft/');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final String streamId = ['HD1', 'HD2', 'HD3'][index];
    final String webViewUrl = [
      'https://starkey.digital/app/',
      'https://starkey.digital/app2/',
      'https://starkey.digital/app3/',
    ][index];

    onTabChanged(streamId, webViewUrl);
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding for safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleTabTap(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'HD1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'HD2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'HD3',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'DONATE',
          ),
        ],
      ),
    );
  }
}
