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

  // Identify smaller/older phones (e.g., 360dp width class or short height)
  static bool isSmallPhone(MediaQueryData mq) {
    final shortest = mq.size.shortestSide;
    return shortest <= 360 || mq.size.height <= 640;
  }

  // Apply normal scaling, then reduce slightly on small phones only
  static double sSmallAware(BuildContext context, double base, {double factor = 0.85}) {
    final mq = MediaQuery.of(context);
    final scaled = base * scaleForMediaQuery(mq);
    return isSmallPhone(mq) ? scaled * factor : scaled;
  }

  static double sFromMqSmallAware(MediaQueryData mq, double base, {double factor = 0.85}) {
    final scaled = base * scaleForMediaQuery(mq);
    return isSmallPhone(mq) ? scaled * factor : scaled;
  }
}
