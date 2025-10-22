import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveUtils {
  static double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isSmallMobile(width)) return 12.0;
    if (Breakpoints.isMobile(width)) return 16.0;
    if (Breakpoints.isTablet(width)) return 24.0;
    return 32.0;
  }

  static double getResponsiveCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isSmallMobile(width)) return 80.0;
    if (Breakpoints.isMobile(width)) return 100.0;
    if (Breakpoints.isTablet(width)) return 120.0;
    return 140.0;
  }

  static int getResponsiveGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isSmallMobile(width)) return 1;
    if (Breakpoints.isMobile(width)) return 1;
    if (Breakpoints.isTablet(width)) return 2;
    if (width < Breakpoints.largeDesktop) return 3;
    return 4;
  }

  static double getResponsiveAvatarSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isSmallMobile(width)) return 40.0;
    if (Breakpoints.isMobile(width)) return 56.0;
    if (Breakpoints.isTablet(width)) return 64.0;
    return 72.0;
  }

  static EdgeInsets getResponsivePaddingAll(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isSmallMobile(width)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    if (Breakpoints.isMobile(width)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
    if (Breakpoints.isTablet(width)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  }
}
