import 'package:flutter/material.dart';

/// Screen size categorization for Eva Bits
enum DeviceScreenType {
  smallMobile, // < 360 width (e.g. iPhone SE 1st gen, small Androids)
  mobile,      // 360 .. < 600 width (standard smartphones)
  tablet,      // 600 .. < 1024 width (iPad Mini, iPad 10th gen, iPad Air, 10-11" tablets)
  desktop,     // >= 1024 width (iPad Pro 12.9" landscape, desktop web)
}

/// Central responsive helper for Eva Bits.
/// Works with both [BuildContext] and optional [BoxConstraints].
class Responsive {
  final BuildContext context;
  final BoxConstraints? constraints;

  Responsive(this.context, [this.constraints]);

  double get width =>
      constraints?.maxWidth ?? MediaQuery.sizeOf(context).width;
  double get height =>
      constraints?.maxHeight ?? MediaQuery.sizeOf(context).height;

  bool get isSmallMobile => width < 360;
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
  bool get isTabletOrDesktop => width >= 600;

  bool get isShort => height < 680;
  bool get isVeryShort => height < 520;
  bool get isTall => height >= 900;
  bool get isLandscape => width > height;

  DeviceScreenType get deviceType {
    if (width < 360) return DeviceScreenType.smallMobile;
    if (width < 600) return DeviceScreenType.mobile;
    if (width < 1024) return DeviceScreenType.tablet;
    return DeviceScreenType.desktop;
  }

  /// Returns a responsive value based on device type
  T value<T>({
    required T mobile,
    T? smallMobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTabletOrDesktop && tablet != null) return tablet;
    if (isSmallMobile && smallMobile != null) return smallMobile;
    return mobile;
  }

  /// Max width constraint for content containers
  double get maxContentWidth {
    if (isDesktop) return 1080;
    if (isTablet) return 960;
    return double.infinity;
  }

  /// Max width for cards / dialogs / sheets
  double get maxCardWidth {
    if (isDesktop) return 960;
    if (isTablet) return 860;
    return double.infinity;
  }
}

/// Extension on BuildContext for quick responsive checks
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
  bool get isTablet => Responsive(this).isTabletOrDesktop;
  bool get isMobile => Responsive(this).isMobile;
  bool get isSmallMobile => Responsive(this).isSmallMobile;
  bool get isShort => Responsive(this).isShort;
  bool get isLandscape => Responsive(this).isLandscape;
}
