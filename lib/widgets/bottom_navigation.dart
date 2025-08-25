import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/responsive.dart';

class StreamBottomNavigation extends StatelessWidget {
  final Function(String streamId) onTabChanged;
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
    onTabChanged(streamId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleTabTap(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: ResponsiveScale.sSmallAware(context, 16, factor: 0.80),
        unselectedFontSize: ResponsiveScale.sSmallAware(context, 16, factor: 0.80),
        showUnselectedLabels: true,
        enableFeedback: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        iconSize: ResponsiveScale.sSmallAware(context, 32, factor: 0.80),
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
