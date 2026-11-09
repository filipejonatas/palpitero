// Placeholder: este projeto ainda nao esta ligado a um projeto Firebase.
//
// Gere o arquivo real com o FlutterFire CLI (substitui este arquivo):
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<SEU_PROJETO_FIREBASE>
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase nao configurado. Rode `flutterfire configure` para gerar '
      'lib/firebase_options.dart.',
    );
  }
}
