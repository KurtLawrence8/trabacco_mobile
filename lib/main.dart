import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'screens/technician_landing_screen.dart';
import 'screens/farm_worker_landing_screen.dart';
import 'screens/coordinator_landing_screen.dart';
import 'services/firebase_messaging_service.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        // Preserve explicit tagged messages during development for troubleshooting
      }
    };
  }

  if (!kReleaseMode) {
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kReleaseMode) {
  }

  FirebaseMessaging.onBackgroundMessage(
    FirebaseMessagingService.firebaseMessagingBackgroundHandler,
  );

  if (!kReleaseMode) {
  }

  try {
    await FirebaseMessagingService.initialize();
    if (!kReleaseMode) {
    }
  } catch (e) {
    if (!kReleaseMode) {
          }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmWorkerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> main() async {
  if (kReleaseMode) {
    await runZonedGuarded(
      () async {
        await _bootstrapApp();
      },
      (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          // Silence print output in production builds
        },
      ),
    );
  } else {
    await _bootstrapApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Trabacco Mobile',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
          secondary: Colors.orange,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget _targetWidget = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Always show login screen first on app start
    // Clear any stored auth data to ensure fresh login

    try {
      final authService = AuthService();

      // Clear any stored auth data on app start
      try {
        await authService.logout();
      } catch (e) {
        // Continue anyway - we'll show login screen
      }
    } catch (e) {
      // Continue anyway - we'll show login screen
    }

    // Always redirect to login screen on app start
    setState(() {
      _targetWidget = const LoginScreen();
      _isLoading = false;
    });
  }

  // ignore: unused_element
  Widget _getLandingScreen(String roleType, String token, User user) {

    if (roleType == 'technician') {
      return TechnicianLandingScreen(
        token: token,
        technicianId: user.id,
      );
    } else if (roleType == 'area_coordinator') {
      return CoordinatorLandingScreen(
        token: token,
        coordinatorId: user.id,
      );
    } else {
      return FarmWorkerLandingScreen(
        token: token,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _targetWidget;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

