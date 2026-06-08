// GENERATED FILE — remplacer les valeurs YOUR_* par celles de votre projet Firebase.
//
// Pour générer ce fichier automatiquement avec vos vraies clés :
//   1. Créez un projet sur https://console.firebase.google.com
//   2. Installez la CLI : npm install -g firebase-tools && dart pub global activate flutterfire_cli
//   3. Connectez-vous : firebase login
//   4. Depuis le dossier mobile/ : flutterfire configure
//
// En attendant, l'initialisation Firebase échoue silencieusement (try/catch dans main.dart)
// et les push notifications sont désactivées.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions : plateforme non configurée. '
          'Exécutez flutterfire configure.',
        );
    }
  }

  // ── Web ─────────────────────────────────────────────────────────────────────
  // Remplacer avec vos vraies valeurs depuis Firebase Console > Paramètres du projet
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );

  // ── Android ──────────────────────────────────────────────────────────────────
  // Remplacer avec les valeurs de l'app Android enregistrée dans Firebase
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );

  // ── iOS ──────────────────────────────────────────────────────────────────────
  // Remplacer avec les valeurs de l'app iOS enregistrée dans Firebase
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.leoni.motivup',
  );
}
