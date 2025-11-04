import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress Flutter framework debug prints (including GestureDetector logs)
  debugPrint = (String? message, {int? wrapWidth}) {
    // Only print Firebase logs, main logs, local notification logs, and login logs
    if (message != null &&
        (message.startsWith('[main]') ||
            message.startsWith('🔥') ||
            message.startsWith('📱') ||
            message.startsWith('📅'))) {
      print(message);
    }
  };

  print('[main] Starting Trabacco Mobile App');
  print('[main] App initialization started');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[main] ✅ Firebase initialized');

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(
    FirebaseMessagingService.firebaseMessagingBackgroundHandler,
  );

  // Initialize Firebase messaging
  try {
    print('[main] 🔥 Starting Firebase messaging initialization...');
    await FirebaseMessagingService.initialize();
    print('[main] ✅ Firebase messaging initialized');
  } catch (e) {
    print(
        '[main] ❌ Firebase messaging initialization failed (device may not have Google Play Services)');
    print('[main] Error: $e');
    print('[main] Error type: ${e.runtimeType}');
    print('[main] Stack trace: ${StackTrace.current}');
    print('[main] ℹ️ App will continue with local notifications only');
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
    try {
      print('[main] 🔍 Checking authentication status...');

      final authService = AuthService();
      final user = await authService.getCurrentUser();
      final token = await authService.getToken();
      final roleType = await authService.getUserRoleType();

      print('[main] 📊 Auth Check Results:');
      print('[main]   - User exists: ${user != null}');
      print('[main]   - Token exists: ${token != null}');
      print('[main]   - Role type: $roleType');

      if (user != null && token != null && roleType != null) {
        print('[main] 🔐 All auth data found, validating token...');

        // Validate token is still valid
        final isValid = await authService.isTokenValid();
        print('[main] 🎯 Token validation result: $isValid');

        if (isValid) {
          print('[main] ✅ Token is valid, auto-login successful');
        } else {
          print(
              '[main] ⚠️ Token validation failed, but attempting auto-login anyway...');
          print(
              '[main] 💡 This might be due to network issues or server temporarily down');

          // For now, let's be more lenient and allow auto-login if we have
          // stored user data, even if token validation fails
          // This prevents users from being logged out due to temporary network issues
        }

        // Proceed with auto-login if we have all the required data
        print('[main] ✅ Auto-login proceeding, redirecting to dashboard...');

        // Refresh FCM token when auto-login happens
        try {
          await FirebaseMessagingService.initialize();
          print('[main] ✅ FCM token refreshed for auto-login');
        } catch (e) {
          print('[main] ⚠️ FCM refresh failed during auto-login: $e');
        }

        // Navigate to appropriate dashboard
        setState(() {
          _targetWidget = _getLandingScreen(roleType, token, user);
          _isLoading = false;
        });
        return;
      } else {
        print('[main] ❌ Missing auth data:');
        print('[main]   - User: ${user != null}');
        print('[main]   - Token: ${token != null}');
        print('[main]   - Role: ${roleType != null}');
      }
    } catch (e) {
      print('[main] ❌ Auth check error: $e');
    }

    // If we get here, user needs to login
    print('[main] 🚪 Redirecting to login screen...');
    setState(() {
      _targetWidget = const LoginScreen();
      _isLoading = false;
    });
  }

  Widget _getLandingScreen(String roleType, String token, User user) {
    print('[main] 🎯 Getting landing screen for role: $roleType');

    if (roleType == 'technician') {
      print('[main] ➡️ Routing to TechnicianLandingScreen');
      return TechnicianLandingScreen(
        token: token,
        technicianId: user.id,
      );
    } else if (roleType == 'area_coordinator') {
      print('[main] ➡️ Routing to CoordinatorLandingScreen');
      return CoordinatorLandingScreen(
        token: token,
        coordinatorId: user.id,
      );
    } else {
      print('[main] ➡️ Routing to FarmWorkerLandingScreen (default)');
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
