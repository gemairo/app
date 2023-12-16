#!/bin/bash
flutter clean
rm -Rf ios/Pods
rm -Rf ios/.symlinks
rm -Rf ios/Flutter/Flutter.framework
rm -Rf ios/Flutter/Flutter.podspec
rm -Rf ios/Podfile.lock
flutter pub get
flutter packages get
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter pub get
cd ios/
# arch -x86_64 pod repo update
# arch -x86_64 pod install
pod repo update
pod install
cd ../
# flutter packages pub run flutter_launcher_name:main
# flutter pub pub run flutter_native_splash:create
# flutter build ios --release