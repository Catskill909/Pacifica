import 'package:flutter/widgets.dart';

class ResponsiveScale {
  // Breakpoints tuned for phones vs tablets
  static double scaleForMediaQuery(MediaQueryData mq) {
    final shortest = mq.size.shortestSide;
    if (shortest < 600) return 1.0; // phones (e.g., iPhone XR)
    if (shortest < 840) return 1.25; // small tablets
    return 1.45; // large tablets (e.g., iPad Pro)
  }

  static double s(BuildContext context, double base) {
    return base * scaleForMediaQuery(MediaQuery.of(context));
  }

  static double sFromMq(MediaQueryData mq, double base) {
    return base * scaleForMediaQuery(mq);
  }
}
