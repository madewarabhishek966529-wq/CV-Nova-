class AppConstants {
  AppConstants._();

  static const appName = 'CVNova';

  // Local dev backend. Notes:
  // - Android emulator: 'localhost' does NOT reach the host machine — use
  //   10.0.2.2 instead (Android's alias for the host loopback).
  // - iOS simulator / web / desktop: 'localhost' works as-is.
  // - Physical device: use the host machine's LAN IP.
  // Swap this for a real environment-based config once there's a staging/
  // prod backend to point at.
  static const apiBaseUrl = 'http://localhost:8000/api/v1';

  static const minPasswordLength = 8;
}
