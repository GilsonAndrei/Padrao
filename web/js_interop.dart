@JS()
library notification_interop;

import 'package:js/js.dart';

// ✅ Interface para Notification do JavaScript
@JS('Notification')
class Notification {
  external factory Notification(String title, [NotificationOptions options]);
  external static String get permission;
  external static Future<String> requestPermission();

  external void close();

  // Event handlers
  external set onclick(void Function(Event) callback);
}

@JS()
@anonymous
class NotificationOptions {
  external factory NotificationOptions({
    String? body,
    String? icon,
    String? badge,
    String? tag,
    bool? requireInteraction,
    dynamic data,
  });

  external String get body;
  external String get icon;
  external String get badge;
  external String get tag;
  external bool get requireInteraction;
  external dynamic get data;
}

@JS()
class Event {
  external dynamic get target;
}

// ✅ Interface para Window
@JS('window')
external Window get window;

@JS()
class Window {
  external void focus();
  external bool get closed;
}

// ✅ Funções globais JavaScript
@JS('eval')
external dynamic eval(String code);

@JS('console.log')
external void consoleLog(dynamic message);

@JS('document.hasFocus')
external bool documentHasFocus();

@JS('document.dispatchEvent')
external void documentDispatchEvent(Event event);

@JS('window.dispatchEvent')
external void windowDispatchEvent(Event event);

@JS('Event')
class EventConstructor {
  external factory EventConstructor(String type);
}
