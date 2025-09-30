# Integração Firebase (passo a passo)

Este guia descreve, em passos concretos, como integrar o Firebase ao projeto `ponto_digital_app` (Android / iOS / Web). Inclui comandos PowerShell, onde colocar os arquivos gerados e trechos de código a aplicar no projeto.

IMPORTANTE: você precisa acesso ao Firebase Console e permissões para criar/editar um projeto.

---

## 1) Pré-requisitos

- Flutter SDK instalado e funcionando.
- Ter o projeto aberto na pasta raiz (onde está `pubspec.yaml`).
- Dart SDK (vem com Flutter) — necessário para instalar FlutterFire CLI.
- Conta no Firebase e permissão para criar apps no projeto.
- (Windows) PowerShell disponível.

## 2) Instalar FlutterFire CLI

Abra PowerShell e execute:

```powershell
# Instalar FlutterFire CLI via dart pub global
dart pub global activate flutterfire_cli

# Adicionar o diretório de bin do pub-cache ao PATH (sessão atual)
$env:PATH += ";" + "$env:USERPROFILE\AppData\Local\Pub\Cache\bin"

# Verificar instalação
flutterfire --version
```

Se `flutterfire` não for encontrado depois, reinicie o terminal ou adicione permanentemente o caminho ao PATH do Windows.

## 3) Criar/usar projeto no Firebase Console

1. Acesse https://console.firebase.google.com
2. Crie um novo projeto (ou use um existente).
3. Anote o `Project ID` (ex.: `ponto-digital-prod`).

## 4) Registrar aplicativos no Firebase (Android / iOS / Web)

### Android

- Abra `android/app/build.gradle.kts` e copie o `applicationId` (ou abra `AndroidManifest.xml`).
- No Firebase Console > Project Overview > Add app > Android, cole o package name (applicationId) e finalize.
- Baixe o arquivo `google-services.json` e coloque em `android/app/google-services.json`.

Kotlin DSL (build.gradle.kts): se você tiver `build.gradle.kts`, adicione o plugin do Google Services conforme instruções do Firebase (veja seção 6).

### iOS

- Abra `ios/Runner.xcodeproj` / `Info.plist` e copie o `CFBundleIdentifier` (bundle id).
- No Firebase Console > Add app > iOS, registre com esse bundle id.
- Baixe `GoogleService-Info.plist` e coloque em `ios/Runner/GoogleService-Info.plist`.
- No Xcode: abra `ios/Runner.xcworkspace`, arraste o `GoogleService-Info.plist` para o target `Runner` (certifique-se que está incluído no target).

### Web (opcional)

- Se precisar de target Web, registre app Web no console e copie as configurações geradas.

## 5) Configurar Android Gradle (Google Services)

No `android/build.gradle` (ou `build.gradle.kts`) adicione o classpath do Google Services (na seção de buildscript / dependencies):

Groovy (exemplo):
```groovy
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

Kotlin DSL (exemplo mínimo, editar conforme seu `build.gradle.kts`):
```kotlin
// settings.gradle.kts ou build.gradle.kts (proj-level)
plugins {
  // ...
}

dependencies {
  // adicionar se estiver usando buildscript block
  // classpath("com.google.gms:google-services:4.3.15")
}
```

No `android/app/build.gradle` (ou `build.gradle.kts` de app) aplique o plugin Google Services ao final do arquivo (Groovy):

```groovy
apply plugin: 'com.google.gms.google-services'
```

Para Kotlin DSL, aplicar plugin conforme o padrão do seu `build.gradle.kts` (procure exemplos oficiais do Google Services para Kotlin DSL).

> Observação: após adicionar `google-services.json`, execute `flutter clean` e `flutter pub get` antes de compilar.

## 6) Gerar `firebase_options.dart` com FlutterFire CLI

Na raiz do projeto execute:

```powershell
# Faz login (abre browser)
flutterfire login

# Configura o projeto e gera lib/firebase_options.dart
flutterfire configure --project <PROJECT_ID>
```

A CLI tentará detectar os apps Android/iOS/Web já registrados no projeto. Ao final, você terá `lib/firebase_options.dart` com `DefaultFirebaseOptions`.

Se quiser especificar saída manualmente:

```powershell
flutterfire configure --project <PROJECT_ID> --out=lib/firebase_options.dart
```
## 6) Gerar `firebase_options.dart` com FlutterFire CLI

A partir de versões mais recentes, a FlutterFire CLI não expõe mais o comando `flutterfire login`. Além disso, a FlutterFire CLI depende da ferramenta oficial do Firebase (firebase-tools) para algumas operações. Antes de executar `flutterfire configure`, instale e autentique o Firebase CLI.

Opções de instalação (PowerShell):

```powershell
# instalar via npm (recomendado quando você tem Node.js)
npm install -g firebase-tools

# alternativo: Chocolatey (se você usa choco)
choco install firebase-cli

# verifique a instalação
firebase --version
```

Autenticação (escolha um dos fluxos):

- Fluxo interativo (abre o browser):

```powershell
firebase login
```

- Fluxo CI / token (útil se preferir gerar um token e usar em CI ou script):

```powershell
# gere um token (abre browser e retorna um token de CI)
firebase login:ci

# defina a variável de ambiente na sessão do PowerShell e rode o configure
#$env:FIREBASE_TOKEN = 'SEU_TOKEN_AQUI'
```

Depois de instalar `firebase-tools` e autenticar (com `firebase login` ou definindo `FIREBASE_TOKEN`), execute a FlutterFire CLI para gerar `lib/firebase_options.dart`.

Exemplo (fluxo interativo) — rodar da raiz do projeto:

```powershell
flutterfire configure --project pontocerto-83e68 --out=lib/firebase_options.dart
```

Exemplo (fluxo com token) — se você usou `firebase login:ci` e exportou o token:

```powershell
#$env:FIREBASE_TOKEN = 'SEU_TOKEN_AQUI' ; flutterfire configure --project pontocerto-83e68 --out=lib/firebase_options.dart
```

Observações:

- Se `flutterfire configure` ainda reclamar que não encontra o comando `firebase`, confirme que o diretório com os executáveis (`npm` global bin ou a instalação do Chocolatey) está no seu PATH e reinicie o terminal.
- A CLI tentará detectar os apps Android/iOS/Web já registrados no projeto. Ao final, você terá `lib/firebase_options.dart` com `DefaultFirebaseOptions`.

## 7) Adicionar dependências Flutter

No `pubspec.yaml` (ou via comandos abaixo) adicione:

- `firebase_core`
- `firebase_messaging` (se for usar FCM)
- `flutter_local_notifications` (para exibir notificações locais em foreground)

Comandos PowerShell:

```powershell
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
flutter pub get
```

Escolha versões compatíveis com seu Flutter SDK (o `pub add` já fará fetch das versões compatíveis).

## 8) Inicializar Firebase no `main.dart`

Atualize `lib/main.dart` para usar as opções geradas:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await ThemeService.init();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushService.init(); // se você tiver implementado
  } catch (e) {
    // continuar sem Firebase (opcional)
  }

  runApp(const PontoDigitalApp());
}
```

> Se `firebase_options.dart` não estiver no `lib/`, ajuste o import path.

## 9) Implementação mínima de `PushService` (FCM + notificações locais)

Se você não tiver `lib/services/push_service.dart` implemente um serviço mínimo. O exemplo abaixo é um resumo — ajuste conforme seu projeto.

> Atenção: handlers de background devem ser funções de nível superior.

```dart
// lib/services/push_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // lidar com mensagem em background
}

class PushService {
  static Future<void> init() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS permissions
    await FirebaseMessaging.instance.requestPermission();

    // inicializar plugin de notificações locais
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Mostrar notificação local
      final notification = message.notification;
      if (notification?.title != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification!.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails('default_channel', 'Default', importance: Importance.max),
          ),
        );
      }
    });
  }

  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
```

Adapte `AndroidNotificationDetails` e canais conforme necessidade.

## 10) Android: Permissões e configuração adicional

- Verifique `android/app/src/main/AndroidManifest.xml` para permissões (normalmente FCM não exige permissões extras além de internet).
- Se usar `flutter_local_notifications`, garanta ícones adequados em `mipmap`.
- Se target SDK >= 33, trate permissões de POST_NOTIFICATIONS no Android 13.

Exemplo de permissão (AndroidManifest.xml) para notificações em Android 13:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## 11) iOS: Capabilities e permissions

- No Xcode, abra `ios/Runner.xcworkspace`.
- Ative `Push Notifications` e `Background Modes` → `Remote notifications` nas capabilities do target Runner.
- Certifique-se de usar um provisioning profile que tenha Push habilitado.

## 12) Testar envio de push

- No Firebase Console → Cloud Messaging, envie uma mensagem de teste para o token do dispositivo (pegar via `PushService.getToken()` ou logs).
- Teste com o app em foreground/background/terminated (verifique handlers equivalentes para cada estado).

## 13) Troubleshooting rápido

- `flutterfire configure` falha: verifique se registrou corretamente os package names/bundle ids no Firebase Console.
- Erros Android build (google-services): confirme `google-services.json` em `android/app/` e plugin aplicado.
- iOS: problemas de provisioning → abrir Xcode e revisar Signing & Capabilities.
- Background handler não é chamado: handler precisa ser top-level (não dentro de classes/closures).

## 14) Validar e CI

- Após configurar, rode localmente:

```powershell
flutter clean; flutter pub get; flutter analyze; flutter run -d <device>
```

- Para CI (GitHub Actions) adicione passos para `flutter analyze` e `flutter test`.

---

Se quiser que eu:
- gere um `lib/services/push_service.dart` mais completo e pronto para usar com seu código existente (eu edito o repo), escolha "B";
- ou, se preferir que eu gere os comandos exatos para você rodar `flutterfire configure` com o `<PROJECT_ID>` já preenchido e revisar os arquivos resultantes, escolha "A".

Quer que eu crie também um snippet pronto e testado de `PushService` dentro do repositório? (sim / não)
