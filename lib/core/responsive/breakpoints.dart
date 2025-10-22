class Breakpoints {
  // Breakpoints baseados no Material Design
  static const double mobile = 600; // telas menores que 600px
  static const double tablet = 900; // telas entre 600px e 900px
  static const double desktop = 1200; // telas maiores que 900px

  // Breakpoints específicos para layouts complexos
  static const double smallMobile = 360;
  static const double largeTablet = 1024;
  static const double largeDesktop = 1440;

  // Métodos auxiliares para verificar breakpoints
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isSmallMobile(double width) => width < smallMobile;
  static bool isLargeTablet(double width) => width >= tablet && width < desktop;
  static bool isLargeDesktop(double width) => width >= largeDesktop;
}
