import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? smallMobile;
  final Widget? largeTablet;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.smallMobile,
    this.largeTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Ordem de prioridade: smallMobile -> mobile -> tablet -> largeTablet -> desktop
        if (Breakpoints.isSmallMobile(width) && smallMobile != null) {
          return smallMobile!;
        } else if (Breakpoints.isMobile(width)) {
          return mobile;
        } else if (Breakpoints.isLargeTablet(width) && largeTablet != null) {
          return largeTablet!;
        } else if (Breakpoints.isTablet(width) && tablet != null) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

// Widget para valores responsivos
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? smallMobile;
  final Widget Function(T value) builder;

  const ResponsiveValue({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.smallMobile,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        T value;

        if (Breakpoints.isSmallMobile(width) && smallMobile != null) {
          value = smallMobile!;
        } else if (Breakpoints.isMobile(width)) {
          value = mobile;
        } else if (Breakpoints.isTablet(width)) {
          value = tablet ?? mobile;
        } else {
          value = desktop ?? tablet ?? mobile;
        }

        return builder(value);
      },
    );
  }
}
