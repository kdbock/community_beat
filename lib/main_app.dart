import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/index.dart';
import 'screens/news_events_screen.dart';
import 'screens/business_directory_screen.dart';
import 'screens/bulletin_board_screen.dart';
import 'screens/polls/polls_screen.dart';
import 'screens/public_services_screen.dart';
import 'screens/map_screen.dart';
import 'screens/firestore_test_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/app_state_provider.dart' show AppStateProvider;
import 'providers/news_events_provider.dart' as news;
import 'providers/business_directory_provider.dart' as business;
import 'providers/bulletin_board_provider.dart' as bulletin;
import 'providers/notification_provider.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => news.NewsEventsProvider()),
        ChangeNotifierProvider(
          create: (_) => business.BusinessDirectoryProvider(),
        ),
        ChangeNotifierProvider(create: (_) => bulletin.BulletinBoardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Community Beat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AppContent(),
      ),
    );
  }
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const NewsEventsScreen(),
    const BusinessDirectoryScreen(),
    const BulletinBoardScreen(),
    const PollsScreen(),
    const PublicServicesScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[AppContent] initState called');
    // Auth is already initialized in AppInitializer
    NotificationHandler.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return ScaffoldWrapper(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              appState.setBottomNavIndex(index);
            },
          ),
          drawer: const CustomDrawer(),
        );
      },
    );
  }
}

/// Root app widget with theme and providers
class CommunityBeatApp extends StatelessWidget {
  const CommunityBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => news.NewsEventsProvider()),
        ChangeNotifierProvider(
          create: (_) => business.BusinessDirectoryProvider(),
        ),
        ChangeNotifierProvider(create: (_) => bulletin.BulletinBoardProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Community Beat',
        debugShowCheckedModeBanner: false,
        routes: {'/firestore-test': (context) => const FirestoreTestScreen()},
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue[700],
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[700]!,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue[100],
            labelStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
