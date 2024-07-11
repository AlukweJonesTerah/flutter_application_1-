import 'package:english_words/english_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'auth_guard.dart';
import 'firebase_options.dart';
import 'patient_page.dart';
import 'patient_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(
    ChangeNotifierProvider(create: (context) => MyAppState(),
    child: MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Hospital Management App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/signup': (context) => SignupPage(),
          '/home': (context) => AuthGuard(child: MyHomePage()),
          '/patient_page': (context) => AuthGuard(child: PatientPage()),
          '/patient_dashboard': (context) => AuthGuard(child: PatientDashboard()),
        },
        navigatorObservers: [RouteObserver()],
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  String? _role;
  String? _username;
  String? _email;
  String? _password;

  bool _isAuthenticated = false;
  final _storage = FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  MyAppState() {
    _loadAuthState();
  }

  Future<bool> verifyRole(String role, String verificationCode) async {
    if (role == 'patient') return true;
    if (role == 'doctor' && verificationCode == 'VALID_DOCTOR_CODE') return true;
    if (role == 'admin' && verificationCode == 'VALID_ADMIN_CODE') return true;
    return false;
  }

  void _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    final isAuthenticatedStr = await _storage.read(key: 'isAuthenticated');
    _isAuthenticated = isAuthenticatedStr == 'true';
    notifyListeners();
  }

  void _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isAuthenticated', _isAuthenticated);

    await _storage.write(key: 'isAuthenticated', value: _isAuthenticated.toString());
  }

  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      _saveAuthState();
      notifyListeners();
    } catch (e) {
      print('Login error: $e');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String role, String username, String email, String password, String verificationCode) async {
    if (await verifyRole(role, verificationCode)) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _role = role;
        _username = username;
        _email = email;
        _password = password;
        _isAuthenticated = true;
        _saveAuthState();
        notifyListeners();
        return true;
      } catch (e) {
        print('Signup error: $e');
        return false;
      }
    }
    return false;
  }

  void logout() {
    _auth.signOut();
    _isAuthenticated = false;
    _email = null;
    _password = null;
    _role = null;
    _saveAuthState();
    notifyListeners();
  }
}



class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        page = GeneratorPage();
        break;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.logout),
                    label: Text('Logout'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  if (value == 2) {
                    var appState = context.read<MyAppState>();
                    appState.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    setState(() {
                      selectedIndex = value;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }

  //  void _showLogoutMessage() {
  //   _scaffoldKey.currentState?.showSnackBar(
  //     SnackBar(
  //       content: Text('You have been logged out.'),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            key: ValueKey(pair),
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}
