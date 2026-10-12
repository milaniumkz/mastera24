import 'package:flutter/material.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  static Future<T?> push<T>(Route<T> route) {
    return key.currentState!.push(route);
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    key.currentState?.popUntil(predicate);
  }

  static Future<T?> pushReplacement<T, TO>(Route<T> newRoute, {TO? result}) {
    return key.currentState!.pushReplacement(newRoute, result: result);
  }
}
