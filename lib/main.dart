import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/constants/app_constants.dart';
import 'src/models/app_settings.dart';
import 'src/models/app_user.dart';
import 'src/models/inventory_item.dart';
import 'src/models/player.dart';
import 'src/models/sale.dart';
import 'src/models/session.dart';
import 'src/models/station.dart';
import 'src/services/app_database.dart';
import 'src/services/alert_audio_service.dart';
import 'src/services/report_export_service.dart';
import 'src/widgets/add_station_dialog.dart';
import 'src/widgets/extend_session_dialog.dart';
import 'src/widgets/start_session_dialog.dart';
import 'src/widgets/station_card.dart';

const _bg = Color(0xFF0A0C0B);
const _surface = Color(0xFF121514);
const _border = Color(0xFF1E2120);
const _green = Color(0xFF00E676);
const _orange = Color(0xFFFFAB00);
const _purple = Color(0xFF7E57C2);
const _mutedText = Color(0xFFB0B0B0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GameZoneApp());
}

class GameZoneApp extends StatelessWidget {
  const GameZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameZone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          brightness: Brightness.dark,
          surface: _surface,
        ),
        scaffoldBackgroundColor: _bg,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _bootstrapFuture;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = databaseRepository.seedDemoDataIfNeeded();
  }

  void _setUser(AppUser user) {
    setState(() => _currentUser = user);
  }

  Future<void> _logout() async {
    await databaseRepository.signOut();
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Erreur de démarrage',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _mutedText),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _bootstrapFuture = databaseRepository
                                    .seedDemoDataIfNeeded();
                              });
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (_currentUser == null) {
          return LoginPage(onAuthenticated: _setUser);
        }
        return GameZoneDashboard(
          user: _currentUser!,
          onLogout: () => _logout(),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onAuthenticated});

  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'admin@gmail.com');
  final _passwordController = TextEditingController(text: 'admin');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = await databaseRepository.authenticateUser(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      setState(() => _error = 'Adresse email ou mot de passe incorrect.');
      return;
    }

    widget.onAuthenticated(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sports_esports,
                    size: 44,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GameZone',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connexion Firebase',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameZoneDashboard extends StatefulWidget {
  const GameZoneDashboard({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<GameZoneDashboard> createState() => _GameZoneDashboardState();
}

class _GameZoneDashboardState extends State<GameZoneDashboard> {
  late Future<_DashboardData> _dataFuture;
  _DashboardData? _lastData;
  int _selectedIndex = 0;
  Timer? _alertTimer;
  bool _checkingAlerts = false;
  final Set<int> _fiveMinuteAlerted = <int>{};
  final Set<int> _threeMinuteAlerted = <int>{};

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
    _alertTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkSessionAlerts(),
    );
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<_DashboardData> _loadData() async {
    await databaseRepository.completeExpiredActiveSessions();
    await databaseRepository.expirePausedSessions();

    final results = await Future.wait<Object>([
      databaseRepository.getStations(),
      databaseRepository.getSessions(),
      databaseRepository.getInventoryItems(),
      databaseRepository.getSales(),
      databaseRepository.getPlayers(),
      databaseRepository.getUsers(),
      databaseRepository.getAppSettings(),
    ]);

    final stations = results[0] as List<Station>;
    final sessions = results[1] as List<Session>;
    final inventory = results[2] as List<InventoryItem>;
    final sales = results[3] as List<Sale>;
    final players = results[4] as List<Player>;
    final users = results[5] as List<AppUser>;
    final settings = results[6] as AppSettings;
    final openSessions = sessions
        .where(
          (session) => session.status == 'active' || session.status == 'paused',
        )
        .toList();
    final revenue = sales.fold<double>(0, (total, sale) => total + sale.amount);
    final completedSessions = sessions
        .where(
          (session) =>
              session.status == 'completed' || session.status == 'expired',
        )
        .length;

    final assetCounts = <int, int>{};
    final stationAssets = <int, List<String>>{};
    for (final station in stations) {
      if (station.id != null) {
        final assignedItems = inventory
            .where(
              (item) =>
                  item.assignedStationId == station.id &&
                  item.status == 'attribue',
            )
            .toList();
        assetCounts[station.id!] = assignedItems.length;
        stationAssets[station.id!] = assignedItems
            .map(
              (item) => item.reference.isEmpty
                  ? item.name
                  : '${item.reference} · ${item.name}',
            )
            .toList();
      }
    }

    final data = _DashboardData(
      stations: stations,
      sessions: sessions,
      openSessions: openSessions,
      inventory: inventory,
      sales: sales,
      players: players,
      users: users,
      settings: settings,
      revenue: revenue,
      completedSessions: completedSessions,
      assetCounts: assetCounts,
      stationAssets: stationAssets,
    );
    _lastData = data;
    return data;
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  void _setLocalData(_DashboardData data) {
    _lastData = data;
    setState(() {
      _dataFuture = Future.value(data);
    });
  }

  void _refreshInBackground() {
    final future = _loadData();
    _dataFuture = future;
    unawaited(
      future
          .then((data) {
            if (!mounted) return;
            setState(() => _dataFuture = Future.value(data));
          })
          .catchError((Object _) {
            if (_lastData != null && mounted) {
              setState(() => _dataFuture = Future.value(_lastData));
            }
          }),
    );
  }

  void _showSyncError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _applyStartedSession(Station station, Session session) {
    final data = _lastData;
    final stationId = station.id;
    if (data == null || stationId == null) return;

    final updatedStations = data.stations
        .map(
          (item) => item.id == stationId
              ? item.copyWith(status: AppConstants.statusOccupe)
              : item,
        )
        .toList();
    final updatedSessions = [
      session,
      ...data.sessions.where((item) => item.stationId != stationId),
    ];
    final updatedOpenSessions = [
      session,
      ...data.openSessions.where((item) => item.stationId != stationId),
    ];
    final updatedSales = [
      Sale(
        type: 'session',
        description: 'Session ${station.name} - ${session.playerName}',
        amount: session.amountPaid,
        clientName: session.playerName,
        createdAt: session.startedAt,
      ),
      ...data.sales,
    ];

    _setLocalData(
      data.copyWith(
        stations: updatedStations,
        sessions: updatedSessions,
        openSessions: updatedOpenSessions,
        sales: updatedSales,
        revenue: data.revenue + session.amountPaid,
      ),
    );
  }

  void _applySessionStatus(Session session, String stationStatus) {
    final data = _lastData;
    if (data == null) return;

    final now = DateTime.now();
    final sessionStatus = stationStatus == AppConstants.statusOccupe
        ? 'active'
        : 'paused';
    final updatedSession = stationStatus == AppConstants.statusOccupe
        ? Session(
            id: session.id,
            stationId: session.stationId,
            stationName: session.stationName,
            playerName: session.playerName,
            amountPaid: session.amountPaid,
            totalMinutes: session.minutesRemaining,
            minutesUsed: 0,
            minutesRemaining: session.minutesRemaining,
            status: sessionStatus,
            startedAt: now.toIso8601String(),
            startedByName: session.startedByName,
            startedByRole: session.startedByRole,
            completedByName: session.completedByName,
            completedByRole: session.completedByRole,
          )
        : session.copyWith(
            status: sessionStatus,
            pausedAt: now.toIso8601String(),
            expiresAt: now.add(const Duration(hours: 72)).toIso8601String(),
          );

    _setLocalData(
      data.copyWith(
        stations: data.stations
            .map(
              (station) => station.id == session.stationId
                  ? station.copyWith(status: stationStatus)
                  : station,
            )
            .toList(),
        sessions: data.sessions
            .map((item) => item.id == session.id ? updatedSession : item)
            .toList(),
        openSessions: [
          updatedSession,
          ...data.openSessions.where(
            (item) => item.stationId != session.stationId,
          ),
        ],
      ),
    );
  }

  void _applyEndedSession(Session session) {
    final data = _lastData;
    if (data == null) return;

    final now = DateTime.now();
    final usedMinutes = session.status == 'active'
        ? _calculateCurrentUsage(session, now)
        : session.minutesUsed;
    final completedSession = session.copyWith(
      status: 'completed',
      minutesUsed: usedMinutes.clamp(0, session.totalMinutes).toInt(),
      minutesRemaining: 0,
      completedAt: now.toIso8601String(),
      completedByName: widget.user.name,
      completedByRole: widget.user.role,
    );

    _setLocalData(
      data.copyWith(
        stations: data.stations
            .map(
              (station) => station.id == session.stationId
                  ? station.copyWith(
                      status: AppConstants.statusLibre,
                      totalHoursUsed: station.totalHoursUsed + usedMinutes / 60,
                    )
                  : station,
            )
            .toList(),
        sessions: data.sessions
            .map((item) => item.id == session.id ? completedSession : item)
            .toList(),
        openSessions: data.openSessions
            .where((item) => item.stationId != session.stationId)
            .toList(),
        completedSessions: data.completedSessions + 1,
      ),
    );
  }

  int _calculateCurrentUsage(Session session, DateTime now) {
    final startedAt = DateTime.tryParse(session.startedAt);
    if (startedAt == null) return session.minutesUsed;
    final elapsed = now.difference(startedAt).inMinutes + session.minutesUsed;
    return elapsed.clamp(0, session.totalMinutes).toInt();
  }

  Future<void> _toggleSound(AppSettings settings) async {
    await databaseRepository.updateAppSettings(
      settings.copyWith(ttsEnabled: !settings.ttsEnabled),
    );
    _refresh();
  }

  Future<void> _startSession(Station station) async {
    final results = await Future.wait<Object>([
      databaseRepository.getSessions(),
      databaseRepository.getAppSettings(),
    ]);
    final recentPlayers = results[0] as List<Session>;
    final settings = results[1] as AppSettings;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StartSessionDialog(
          stationName: station.name,
          settings: settings,
          recentPlayers: recentPlayers
              .map((session) => session.playerName)
              .toSet()
              .take(5)
              .toList(),
          onConfirm: (playerName, amount, minutes) {
            final startedAt = DateTime.now().toIso8601String();
            final optimisticSession = Session(
              stationId: station.id!,
              stationName: station.name,
              playerName: playerName,
              amountPaid: amount,
              totalMinutes: minutes,
              minutesUsed: 0,
              minutesRemaining: minutes,
              status: 'active',
              startedAt: startedAt,
              startedByName: widget.user.name,
              startedByRole: widget.user.role,
            );
            _applyStartedSession(station, optimisticSession);
            unawaited(
              databaseRepository
                  .startSession(
                    station: station,
                    playerName: playerName,
                    amountPaid: amount,
                    totalMinutes: minutes,
                    operator: widget.user,
                  )
                  .then((_) => _refreshInBackground())
                  .catchError((Object _) {
                    _showSyncError(
                      "La session n'a pas pu etre synchronisee avec Firebase.",
                    );
                    _refresh();
                  }),
            );
          },
        );
      },
    );
  }

  Future<void> _pauseSession(Session? session) async {
    if (session == null) return;
    _applySessionStatus(session, AppConstants.statusEnPause);
    unawaited(
      databaseRepository
          .pauseSession(session)
          .then((_) => _refreshInBackground())
          .catchError((Object _) {
            _showSyncError("La mise en pause n'a pas pu etre synchronisee.");
            _refresh();
          }),
    );
  }

  Future<void> _resumeSession(Session? session) async {
    if (session == null) return;
    _applySessionStatus(session, AppConstants.statusOccupe);
    unawaited(
      databaseRepository
          .resumeSession(session)
          .then((_) => _refreshInBackground())
          .catchError((Object _) {
            _showSyncError("La reprise n'a pas pu etre synchronisee.");
            _refresh();
          }),
    );
  }

  Future<void> _extendSession(Session? session) async {
    if (session == null) return;
    final settings = await databaseRepository.getAppSettings();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return ExtendSessionDialog(
          session: session,
          settings: settings,
          onConfirm: (amount, minutes) async {
            await databaseRepository.extendSession(
              session,
              addedMinutes: minutes,
              addedAmount: amount,
            );
            _refresh();
          },
        );
      },
    );
  }

  Future<void> _endSession(Session? session) async {
    if (session == null) return;
    final settings = await databaseRepository.getAppSettings();
    if (settings.ttsEnabled) {
      await AlertAudioService.instance.playBell();
      await AlertAudioService.instance.announceSessionFinished(
        stationName: session.stationName,
        voiceGender: settings.voiceGender,
      );
    }
    _applyEndedSession(session);
    unawaited(
      databaseRepository
          .completeSession(session, operator: widget.user)
          .then((_) => _refreshInBackground())
          .catchError((Object _) {
            _showSyncError("La fin de session n'a pas pu etre synchronisee.");
            _refresh();
          }),
    );
  }

  Future<void> _checkSessionAlerts() async {
    if (_checkingAlerts) return;
    _checkingAlerts = true;
    try {
      final completed = await databaseRepository
          .completeExpiredActiveSessions();
      if (completed > 0) {
        _fiveMinuteAlerted.clear();
        _threeMinuteAlerted.clear();
        _refreshInBackground();
      }

      final settings = await databaseRepository.getAppSettings();
      if (!settings.ttsEnabled) {
        _fiveMinuteAlerted.clear();
        _threeMinuteAlerted.clear();
        return;
      }

      final activeSessions = await databaseRepository.getSessions(
        status: 'active',
      );
      final activeIds = activeSessions
          .map((session) => session.id)
          .whereType<int>()
          .toSet();
      _fiveMinuteAlerted.removeWhere((id) => !activeIds.contains(id));
      _threeMinuteAlerted.removeWhere((id) => !activeIds.contains(id));

      for (final session in activeSessions) {
        final sessionId = session.id;
        if (sessionId == null) continue;
        final startedAt = DateTime.tryParse(session.startedAt);
        if (startedAt == null) continue;
        final elapsedMinutes =
            DateTime.now().difference(startedAt).inMinutes +
            session.minutesUsed;
        final remainingMinutes = (session.totalMinutes - elapsedMinutes)
            .clamp(0, session.totalMinutes)
            .toInt();

        if (remainingMinutes <= 5 &&
            remainingMinutes > 3 &&
            !_fiveMinuteAlerted.contains(sessionId)) {
          _fiveMinuteAlerted.add(sessionId);
          await AlertAudioService.instance.playBell();
        }

        if (remainingMinutes <= 3 &&
            remainingMinutes > 0 &&
            !_threeMinuteAlerted.contains(sessionId)) {
          _threeMinuteAlerted.add(sessionId);
          await AlertAudioService.instance.playBell();
          await AlertAudioService.instance.announceRemainingTime(
            stationName: session.stationName,
            minutesLeft: remainingMinutes,
            voiceGender: settings.voiceGender,
          );
        }
      }
    } finally {
      _checkingAlerts = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final data = snapshot.data ?? _lastData;

        return Scaffold(
          body: isLoading && data == null
              ? const Center(child: CircularProgressIndicator())
              : _Shell(
                  selectedIndex: _selectedIndex,
                  user: widget.user,
                  settings: data!.settings,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  onToggleSound: () => _toggleSound(data.settings),
                  onLogout: widget.onLogout,
                  child: _buildSelectedView(data),
                ),
        );
      },
    );
  }

  Widget _buildSelectedView(_DashboardData data) {
    switch (_selectedIndex) {
      case 1:
        return _SessionsView(data: data);
      case 2:
        return _SalesView(data: data);
      case 3:
        return _PlayersView(data: data, onChanged: _refresh);
      case 4:
        return _MaintenanceView(data: data, onChanged: _refresh);
      case 5:
        return _InventoryView(data: data, onChanged: _refresh);
      case 6:
        return _ReportsView(data: data, user: widget.user);
      case 7:
        return _SettingsView(
          data: data,
          user: widget.user,
          onChanged: _refresh,
        );
      case 8:
        if (widget.user.isAdmin) {
          return _UsersView(data: data, onChanged: _refresh);
        }
        return _AccessDeniedView(user: widget.user);
      default:
        return _DashboardView(
          data: data,
          user: widget.user,
          onRefresh: _refresh,
          onOpenSettings: () => setState(() => _selectedIndex = 7),
          onToggleSound: () => _toggleSound(data.settings),
          onLogout: widget.onLogout,
          onStartSession: _startSession,
          onPauseSession: _pauseSession,
          onResumeSession: _resumeSession,
          onExtendSession: _extendSession,
          onEndSession: _endSession,
        );
    }
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.selectedIndex,
    required this.user,
    required this.settings,
    required this.onDestinationSelected,
    required this.onToggleSound,
    required this.onLogout,
    required this.child,
  });

  final int selectedIndex;
  final AppUser user;
  final AppSettings settings;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleSound;
  final VoidCallback onLogout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final destinations = _destinationsFor(user);

    if (compact) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            destinations[selectedIndex].label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Aide de cette page',
              onPressed: () => _showPageHelp(context, selectedIndex, user),
              icon: const Icon(Icons.help_outline),
            ),
            IconButton(
              tooltip: settings.ttsEnabled ? 'Couper le son' : 'Activer le son',
              onPressed: onToggleSound,
              icon: Icon(
                settings.ttsEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _RolePill(user: user),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: _surface,
          child: SafeArea(
            child: _SidebarContent(
              user: user,
              settings: settings,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                Navigator.pop(context);
                onDestinationSelected(index);
              },
              onLogout: onLogout,
              onHelp: () => _showPageHelp(context, selectedIndex, user),
            ),
          ),
        ),
        body: ColoredBox(color: _bg, child: child),
      );
    }

    return Row(
      children: [
        Container(
          width: 250,
          color: _surface,
          child: SafeArea(
            child: _SidebarContent(
              user: user,
              settings: settings,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              onLogout: onLogout,
              onHelp: () => _showPageHelp(context, selectedIndex, user),
            ),
          ),
        ),
        Container(width: 1, color: _border),
        Expanded(
          child: ColoredBox(color: _bg, child: child),
        ),
      ],
    );
  }

  List<_DestinationItem> _destinationsFor(AppUser user) {
    return [
      const _DestinationItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      const _DestinationItem(
        label: 'Sessions',
        icon: Icons.timer_outlined,
        selectedIcon: Icons.timer,
      ),
      const _DestinationItem(
        label: 'Ventes',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
      ),
      const _DestinationItem(
        label: 'Joueurs',
        icon: Icons.stars_outlined,
        selectedIcon: Icons.stars,
      ),
      const _DestinationItem(
        label: 'Maintenance IA',
        icon: Icons.auto_fix_high_outlined,
        selectedIcon: Icons.auto_fix_high,
      ),
      const _DestinationItem(
        label: 'Stock maître',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
      const _DestinationItem(
        label: 'Rapports',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
      ),
      const _DestinationItem(
        label: 'Paramètres',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
      if (user.isAdmin)
        const _DestinationItem(
          label: 'Utilisateurs',
          icon: Icons.group_outlined,
          selectedIcon: Icons.group,
          adminSection: true,
        ),
    ];
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.user,
    required this.settings,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.onHelp,
  });

  final AppUser user;
  final AppSettings settings;
  final List<_DestinationItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports, color: _green, size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'GameZone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Aide de cette page',
                onPressed: onHelp,
                icon: const Icon(Icons.help_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              children: [
                const _SidebarSectionLabel('OPÉRATIONS'),
                for (var i = 0; i < destinations.length; i++)
                  if (!destinations[i].adminSection)
                    _SidebarTile(
                      item: destinations[i],
                      selected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                const SizedBox(height: 18),
                if (user.isAdmin) ...[
                  const _SidebarSectionLabel('ADMINISTRATION'),
                  for (var i = 0; i < destinations.length; i++)
                    if (destinations[i].adminSection)
                      _SidebarTile(
                        item: destinations[i],
                        selected: selectedIndex == i,
                        onTap: () => onDestinationSelected(i),
                      ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SidebarProfile(user: user, settings: settings, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DestinationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? _green.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _green.withValues(alpha: 0.32)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? _green : _mutedText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? Colors.white : _mutedText,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarProfile extends StatelessWidget {
  const _SidebarProfile({
    required this.user,
    required this.settings,
    required this.onLogout,
  });

  final AppUser user;
  final AppSettings settings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _purple.withValues(alpha: 0.35),
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.isAdmin ? 'Administrateur' : 'Gestionnaire',
                      style: const TextStyle(color: _mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.ratioLabel,
            style: TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Déconnexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationItem {
  const _DestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.adminSection = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool adminSection;
}

class _HelpTopic {
  const _HelpTopic({
    required this.title,
    required this.intro,
    required this.steps,
    this.notes = const [],
  });

  final String title;
  final String intro;
  final List<String> steps;
  final List<String> notes;
}

void _showPageHelp(BuildContext context, int selectedIndex, AppUser user) {
  final topic = _helpTopicFor(selectedIndex, user);
  showDialog<void>(
    context: context,
    builder: (context) => _HelpDialog(topic: topic),
  );
}

_HelpTopic _helpTopicFor(int index, AppUser user) {
  switch (index) {
    case 1:
      return const _HelpTopic(
        title: 'Aide - Sessions',
        intro:
            'Cette page sert à suivre toutes les sessions actives, en pause et terminées.',
        steps: [
          'Démarrez une session depuis le Dashboard en choisissant un poste libre.',
          'Entrez le nom du joueur, le montant payé et vérifiez la durée calculée.',
          'Une session active peut être mise en pause, prolongée ou terminée.',
          'Les sessions terminées alimentent l’historique joueurs, le chiffre d’affaires et la maintenance.',
        ],
        notes: [
          'Une session arrivée à zéro est arrêtée automatiquement, même si vous n’êtes pas sur le Dashboard.',
          'Une session en pause garde son temps restant pendant la durée prévue.',
        ],
      );
    case 2:
      return const _HelpTopic(
        title: 'Aide - Ventes',
        intro:
            'Cette page regroupe les revenus de sessions et les ventes boutique.',
        steps: [
          'Les ventes de session sont créées automatiquement au démarrage ou à la prolongation d’une session.',
          'Les ventes boutique concernent les accessoires ou articles vendus directement.',
          'Le chiffre d’affaires total du tableau de bord vient de ces ventes enregistrées.',
        ],
        notes: [
          'Pour que l’historique joueur soit juste, utilisez le nom réel du joueur au démarrage de la session.',
        ],
      );
    case 3:
      return const _HelpTopic(
        title: 'Aide - Joueurs & Fidélité',
        intro:
            'Cette page construit le club fidélité à partir des vraies sessions jouées.',
        steps: [
          'Chaque nom entré au lancement d’une session devient un joueur suivi.',
          'Le total dépensé vient des ventes de session liées au joueur.',
          'Le temps joué vient des sessions actives, en pause, terminées ou expirées.',
          'Le rang dépend du nombre de sessions: Bronze, Argent, Or ou Légendaire.',
          'Le bonus cadeau utilise la valeur définie par l’administrateur dans les paramètres.',
        ],
        notes: [
          'Le bouton cadeau ajoute directement ces minutes au joueur sélectionné.',
          'Évitez les fautes dans les noms pour ne pas créer deux profils pour le même client.',
        ],
      );
    case 4:
      return const _HelpTopic(
        title: 'Aide - Maintenance',
        intro:
            'La maintenance actuelle est prédictive par seuil d’heures, pas une IA complexe.',
        steps: [
          'Ajoutez les équipements dans le stock avec un seuil d’usure en heures.',
          'Attribuez ces équipements à un poste au moment de créer le poste.',
          'Quand une session se termine, ses heures sont ajoutées aux équipements du poste.',
          'Le matériel passe en inspection ou critique selon son niveau d’usure.',
          'Après réparation ou remplacement, marquez l’équipement comme réparé pour remettre son compteur à zéro.',
        ],
        notes: [
          'La prévision fonctionne seulement si les équipements sont bien attribués aux postes.',
        ],
      );
    case 5:
      return const _HelpTopic(
        title: 'Aide - Stock maître',
        intro:
            'Le stock maître est la base de tout le matériel utilisé par les postes.',
        steps: [
          'Ajoutez d’abord une console ou un équipement dans le stock.',
          'Choisissez le type: Console, Manette, Casque, Écran, Câble ou autre.',
          'Choisissez ensuite le modèle précis, par exemple PS5 Slim, Xbox Series S ou DualSense.',
          'Renseignez la marque, la référence, le numéro de série et le seuil d’usure si nécessaire.',
          'Un poste ne peut utiliser que du matériel disponible en stock.',
        ],
        notes: [
          'Pour créer un poste PS5 Slim, ajoutez d’abord une console PS5 Slim au stock.',
          'Les équipements attribués sortent du stock disponible.',
        ],
      );
    case 6:
      return const _HelpTopic(
        title: 'Aide - Rapports',
        intro:
            'Les rapports servent à analyser la salle sur une période donnée.',
        steps: [
          'Choisissez la période à analyser.',
          'Consultez les revenus sessions, ventes boutique, temps joué et postes les plus utilisés.',
          'Exportez le rapport pour garder une trace ou le partager.',
        ],
        notes: [
          'Les rapports dépendent des sessions, ventes et équipements correctement enregistrés.',
        ],
      );
    case 7:
      return const _HelpTopic(
        title: 'Aide - Paramètres',
        intro:
            'Les paramètres contrôlent les règles générales de fonctionnement.',
        steps: [
          'Définissez le tarif de base, par exemple 250 FCFA pour 40 minutes.',
          'Activez ou désactivez les annonces sonores.',
          'Choisissez la voix utilisée pour les alertes.',
          'Sauvegardez pour appliquer les changements aux prochaines sessions.',
        ],
        notes: [
          'Modifier le tarif ne change pas les anciennes sessions déjà enregistrées.',
        ],
      );
    case 8:
      return _HelpTopic(
        title: user.isAdmin ? 'Aide - Utilisateurs' : 'Accès administrateur',
        intro: user.isAdmin
            ? 'Cette page est réservée à l’administrateur pour gérer les comptes.'
            : 'Cette section est réservée aux administrateurs.',
        steps: user.isAdmin
            ? const [
                'Créez un utilisateur avec un nom, un identifiant et un mot de passe.',
                'Choisissez le rôle: administrateur ou gestionnaire.',
                'Un administrateur peut gérer les utilisateurs et voir les zones sensibles.',
                'Un gestionnaire travaille surtout sur les opérations quotidiennes.',
              ]
            : const [
                'Connectez-vous avec un compte administrateur pour accéder à cette page.',
              ],
        notes: const [
          'Gardez au moins un compte administrateur actif pour éviter de bloquer la gestion.',
        ],
      );
    default:
      return const _HelpTopic(
        title: 'Aide - Dashboard',
        intro:
            'Le Dashboard est la page principale pour piloter les postes de jeu.',
        steps: [
          'Pour ajouter un poste, ajoutez d’abord la console et ses équipements dans le Stock maître.',
          'Cliquez sur Poste, donnez un nom et une référence, puis choisissez le modèle de console.',
          'Sélectionnez la console en stock et les accessoires nécessaires, comme les manettes.',
          'Pour lancer une session, cliquez sur Démarrer sur un poste libre.',
          'Entrez le joueur et le montant payé: la durée est calculée avec le tarif configuré.',
          'Quand la session démarre, le poste passe occupé, l’ESP32 reçoit l’ordre et le relais s’active.',
        ],
        notes: [
          'Les sessions terminées mettent à jour les joueurs, les revenus et la maintenance.',
          'Les alertes sonores peuvent être activées ou coupées depuis le bouton son.',
        ],
      );
  }
}

class _HelpDialog extends StatelessWidget {
  const _HelpDialog({required this.topic});

  final _HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.help_outline, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topic.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(topic.intro, style: const TextStyle(color: _mutedText)),
              const SizedBox(height: 16),
              for (var i = 0; i < topic.steps.length; i++)
                _HelpStep(number: i + 1, text: topic.steps[i]),
              if (topic.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'À retenir',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                for (final note in topic.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: _orange,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(color: _mutedText),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.black,
          ),
          child: const Text('Compris'),
        ),
      ],
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: _green.withValues(alpha: 0.32)),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final color = user.isAdmin
        ? const Color(0xFF7C3AED)
        : const Color(0xFF059669);
    final label = user.isAdmin ? 'Admin' : 'Gestionnaire';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: Icon(
          user.isAdmin ? Icons.admin_panel_settings : Icons.storefront,
          color: color,
          size: 18,
        ),
        label: Text(label),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        backgroundColor: color.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.user,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onToggleSound,
    required this.onLogout,
    required this.onStartSession,
    required this.onPauseSession,
    required this.onResumeSession,
    required this.onExtendSession,
    required this.onEndSession,
  });

  final _DashboardData data;
  final AppUser user;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleSound;
  final VoidCallback onLogout;
  final ValueChanged<Station> onStartSession;
  final ValueChanged<Session?> onPauseSession;
  final ValueChanged<Session?> onResumeSession;
  final ValueChanged<Session?> onExtendSession;
  final ValueChanged<Session?> onEndSession;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final horizontalPadding = compact ? 16.0 : 28.0;
    final sessionsByStation = {
      for (final session in data.openSessions) session.stationId: session,
    };
    final occupied = data.stations
        .where((station) => station.status == AppConstants.statusOccupe)
        .length;
    final paused = data.stations
        .where((station) => station.status == AppConstants.statusEnPause)
        .length;
    final maintenanceAlerts = data.inventory
        .where(
          (item) =>
              item.wearLevel == 'critique' || item.wearLevel == 'inspection',
        )
        .length;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            8,
          ),
          sliver: SliverToBoxAdapter(
            child: _DashboardHeader(
              user: user,
              settings: data.settings,
              onRefresh: onRefresh,
              onOpenSettings: onOpenSettings,
              onToggleSound: onToggleSound,
              onLogout: onLogout,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            8,
          ),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  icon: Icons.sports_esports,
                  label: 'Postes actifs',
                  value: '$occupied/${data.stations.length}',
                  color: AppConstants.statusColors[AppConstants.statusOccupe]!,
                ),
                _MetricTile(
                  icon: Icons.pause_circle,
                  label: 'Sessions en pause',
                  value: paused.toString(),
                  color: AppConstants.statusColors[AppConstants.statusEnPause]!,
                ),
                _MetricTile(
                  icon: Icons.build_circle,
                  label: 'Alertes IA',
                  value: maintenanceAlerts.toString(),
                  color: const Color(0xFF64748B),
                ),
                _MetricTile(
                  icon: Icons.payments,
                  label: user.isAdmin ? 'CA total' : 'CA masqué',
                  value: user.isAdmin
                      ? AppConstants.formatPrice(data.revenue)
                      : '—',
                  color: const Color(0xFF059669),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            28,
          ),
          sliver: SliverGrid.builder(
            itemCount: data.stations.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: compact ? 520 : 390,
              mainAxisExtent: compact ? 420 : 410,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final station = data.stations[index];
              final session = sessionsByStation[station.id];
              return StationCard(
                station: station,
                session: session,
                assetCount: data.assetCounts[station.id] ?? 0,
                accessories: data.stationAssets[station.id] ?? const [],
                onStartSession: () => onStartSession(station),
                onPauseSession: () => onPauseSession(session),
                onResumeSession: () => onResumeSession(session),
                onExtendSession: () => onExtendSession(session),
                onEndSession: () => onEndSession(session),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.user,
    required this.settings,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onToggleSound,
    required this.onLogout,
  });

  final AppUser user;
  final AppSettings settings;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleSound;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Vue opérationnelle de la salle de jeux',
              style: TextStyle(color: _mutedText),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RoundActionButton(
              tooltip: settings.ttsEnabled ? 'Couper le son' : 'Activer le son',
              icon: settings.ttsEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              onPressed: onToggleSound,
            ),
            _RoundActionButton(
              tooltip: 'Actualiser',
              icon: Icons.refresh,
              onPressed: onRefresh,
            ),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Poste'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (!compact) _RolePill(user: user),
            if (!compact)
              _RoundActionButton(
                tooltip: 'Déconnexion',
                icon: Icons.logout,
                onPressed: onLogout,
              ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SessionsView extends StatefulWidget {
  const _SessionsView({required this.data});

  final _DashboardData data;

  @override
  State<_SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<_SessionsView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final all = _sessionRows();
    final active = all.where((session) => session.status == 'active').toList();
    final paused = all.where((session) => session.status == 'paused').toList();
    final completed = all
        .where(
          (session) =>
              session.status == 'completed' || session.status == 'expired',
        )
        .toList();
    final lists = [active, paused, completed];
    final labels = [
      'Actives (${active.length})',
      'En pause (${paused.length})',
      'Terminées (${completed.length})',
    ];

    return _PageFrame(
      title: 'Sessions',
      subtitle: 'Suivi des sessions actives, suspendues et terminées',
      child: Column(
        children: [
          _CapsuleTabs(
            labels: labels,
            selectedIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _DarkPanel(
              padding: EdgeInsets.zero,
              child: lists[_tab].isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune session',
                        style: TextStyle(color: _mutedText, fontSize: 16),
                      ),
                    )
                  : _WideTable(
                      minWidth: 1220,
                      child: _SessionTable(sessions: lists[_tab]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Session> _sessionRows() {
    final rows = [...widget.data.openSessions];
    final knownIds = rows.map((session) => session.id).toSet();
    for (final session in widget.data.sessions) {
      if (!knownIds.contains(session.id)) rows.add(session);
    }
    return rows;
  }
}

class _SessionTable extends StatelessWidget {
  const _SessionTable({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _TableHeader(
          columns: [
            'Joueur',
            'Poste',
            'Montant',
            'Temps',
            'Statut',
            'Activée par',
            'Terminée par',
            'Date',
          ],
          flexes: [2, 2, 1, 2, 1, 2, 2, 2],
        ),
        for (final session in sessions)
          _TableRowBox(
            flexes: const [2, 2, 1, 2, 1, 2, 2, 2],
            children: [
              _IconText(icon: Icons.person_outline, text: session.playerName),
              _IconText(icon: Icons.devices_other, text: session.stationName),
              Text(
                AppConstants.formatPrice(session.amountPaid),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _IconText(
                icon: Icons.schedule,
                text: session.status == 'paused'
                    ? '${session.minutesRemaining}min restantes'
                    : AppConstants.formatDuration(session.totalMinutes),
                color: session.status == 'paused' ? _orange : Colors.white,
              ),
              _StatusBadge(status: session.status),
              Text(
                _formatSessionOperator(
                  session.startedByName,
                  session.startedByRole,
                ),
                style: const TextStyle(color: _mutedText),
              ),
              Text(
                _formatSessionOperator(
                  session.completedByName,
                  session.completedByRole,
                  fallback:
                      session.status == 'completed' ||
                          session.status == 'expired'
                      ? 'Système'
                      : '—',
                ),
                style: const TextStyle(color: _mutedText),
              ),
              Text(
                _formatIsoDate(
                  session.completedAt ?? session.pausedAt ?? session.startedAt,
                ),
                style: const TextStyle(color: _mutedText),
              ),
            ],
          ),
      ],
    );
  }
}

class _SalesView extends StatelessWidget {
  const _SalesView({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final sessionRevenue = data.sales
        .where((sale) => sale.type == 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);
    final directRevenue = data.sales
        .where((sale) => sale.type != 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);

    return _PageFrame(
      title: 'Ventes',
      subtitle: 'Suivi des revenus sessions et boutique',
      child: Column(
        children: [
          _ResponsiveCards(
            children: [
              _FinanceCard(
                icon: Icons.attach_money,
                color: _green,
                amount: data.revenue,
                label: 'CA Total',
              ),
              _FinanceCard(
                icon: Icons.sports_esports,
                color: _purple,
                amount: sessionRevenue,
                label: 'Sessions de jeu',
              ),
              _FinanceCard(
                icon: Icons.shopping_cart_outlined,
                color: _orange,
                amount: directRevenue,
                label: 'Ventes directes',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _DarkPanel(
              padding: EdgeInsets.zero,
              child: _WideTable(
                minWidth: 900,
                child: ListView(
                  children: [
                    const _TableHeader(
                      columns: [
                        'Description',
                        'Type',
                        'Montant',
                        'Client',
                        'Date',
                      ],
                      flexes: [3, 1, 1, 2, 2],
                    ),
                    for (final sale in data.sales)
                      _TableRowBox(
                        flexes: const [3, 1, 1, 2, 2],
                        children: [
                          Text(
                            sale.description,
                            style: const TextStyle(color: Colors.white),
                          ),
                          _SaleBadge(type: sale.type),
                          Text(
                            AppConstants.formatPrice(sale.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            sale.clientName ?? '—',
                            style: const TextStyle(color: _mutedText),
                          ),
                          Text(
                            _formatIsoDate(sale.createdAt),
                            style: const TextStyle(color: _mutedText),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayersView extends StatefulWidget {
  const _PlayersView({required this.data, required this.onChanged});

  final _DashboardData data;
  final VoidCallback onChanged;

  @override
  State<_PlayersView> createState() => _PlayersViewState();
}

class _PlayersViewState extends State<_PlayersView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final players = widget.data.players
        .where(
          (player) => player.name.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
    final loyal = widget.data.players
        .where((player) => player.totalSessions >= 10)
        .length;
    final totalRevenue = widget.data.players.fold<double>(
      0,
      (sum, player) => sum + player.totalSpent,
    );
    final bonus = widget.data.players.fold<int>(
      0,
      (sum, player) => sum + player.bonusMinutes,
    );

    return _PageFrame(
      title: 'Joueurs & Fidélité',
      subtitle: 'Classement, bonus et programme de fidélité',
      child: ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                icon: Icons.people,
                label: 'Joueurs enregistrés',
                value: '${widget.data.players.length}',
                color: _green,
              ),
              _MetricTile(
                icon: Icons.local_fire_department,
                label: 'Clients fidèles 10+',
                value: '$loyal',
                color: _orange,
              ),
              _MetricTile(
                icon: Icons.payments,
                label: 'CA total joueurs',
                value: AppConstants.formatPrice(totalRevenue),
                color: const Color(0xFF22D3EE),
              ),
              _MetricTile(
                icon: Icons.card_giftcard,
                label: 'Minutes bonus',
                value: '$bonus',
                color: _purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher un joueur...',
              hintStyle: const TextStyle(color: _mutedText),
              prefixIcon: const Icon(Icons.search, color: _mutedText),
              filled: true,
              fillColor: _surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DarkPanel(
            padding: EdgeInsets.zero,
            child: _WideTable(
              minWidth: 1050,
              child: Column(
                children: [
                  const _TableHeader(
                    columns: [
                      'Joueur',
                      'Rang',
                      'Sessions',
                      'Total dépensé',
                      'Temps joué',
                      'Bonus',
                      'Actions',
                    ],
                    flexes: [2, 2, 1, 2, 2, 1, 1],
                  ),
                  for (final player in players)
                    _TableRowBox(
                      flexes: const [2, 2, 1, 2, 2, 1, 1],
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _RankBadge(player: player),
                        Text(
                          '${player.totalSessions}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          AppConstants.formatPrice(player.totalSpent),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          AppConstants.formatDuration(
                            player.totalMinutesPlayed,
                          ),
                          style: const TextStyle(color: _mutedText),
                        ),
                        Text(
                          '+${player.bonusMinutes}',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          tooltip: player.bonusMinutes > 0
                              ? 'Ajouter ${player.bonusMinutes} min à sa session'
                              : 'Aucun bonus disponible',
                          onPressed: player.bonusMinutes <= 0
                              ? null
                              : () async {
                                  final givenMinutes = player.bonusMinutes;
                                  final applied = await databaseRepository
                                      .givePlayerBonusToOpenSession(player);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        applied
                                            ? '$givenMinutes min ajoutées à la session de ${player.name}.'
                                            : 'Aucune session en cours trouvée pour ${player.name}.',
                                      ),
                                    ),
                                  );
                                  if (applied) widget.onChanged();
                                },
                          icon: Icon(
                            Icons.card_giftcard,
                            color: player.bonusMinutes > 0
                                ? _green
                                : _mutedText,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DarkPanel(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _TierCard(
                  icon: Icons.workspace_premium_outlined,
                  color: Colors.pinkAccent,
                  title: 'Bronze',
                  desc: '0-9 sessions',
                  reward: 'Aucun bonus',
                ),
                _TierCard(
                  icon: Icons.military_tech_outlined,
                  color: Colors.blueGrey,
                  title: 'Argent',
                  desc: '10-19 sessions',
                  reward: '+40 min au palier',
                ),
                _TierCard(
                  icon: Icons.military_tech,
                  color: _orange,
                  title: 'Or',
                  desc: '20-49 sessions',
                  reward: '+40 min à chaque palier de 10',
                ),
                _TierCard(
                  icon: Icons.verified,
                  color: Color(0xFFFFD54F),
                  title: 'Légendaire',
                  desc: '50+ sessions',
                  reward: '+40 min + priorité',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceView extends StatelessWidget {
  const _MaintenanceView({required this.data, required this.onChanged});

  final _DashboardData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final critical = data.inventory
        .where((item) => item.wearLevel == 'critique')
        .toList();
    final attention = data.inventory
        .where(
          (item) =>
              item.wearLevel == 'inspection' || item.wearLevel == 'attention',
        )
        .toList();
    final good = data.inventory
        .where((item) => item.wearLevel == 'bon')
        .toList();

    return _PageFrame(
      title: 'Maintenance IA',
      subtitle: 'Suivi prédictif de l’usure du matériel',
      child: ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                icon: Icons.error,
                label: 'Critique',
                value: '${critical.length}',
                color: Colors.redAccent,
              ),
              _MetricTile(
                icon: Icons.warning,
                label: 'Attention',
                value: '${attention.length}',
                color: _orange,
              ),
              _MetricTile(
                icon: Icons.check_circle,
                label: 'Bon état',
                value: '${good.length}',
                color: _green,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MaintenanceSection(
            title: 'Remplacement requis',
            items: critical,
            color: Colors.redAccent,
            onChanged: onChanged,
          ),
          _MaintenanceSection(
            title: 'À surveiller',
            items: attention,
            color: _orange,
            onChanged: onChanged,
          ),
          _MaintenanceSection(
            title: 'En bon état',
            items: good,
            color: _green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InventoryView extends StatefulWidget {
  const _InventoryView({required this.data, required this.onChanged});

  final _DashboardData data;
  final VoidCallback onChanged;

  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final stock = widget.data.inventory
        .where((item) => item.status == 'en_stock')
        .toList();
    final assigned = widget.data.inventory
        .where((item) => item.status == 'attribue')
        .toList();
    final sold = widget.data.inventory
        .where((item) => item.status == 'vendu')
        .toList();
    final lists = [stock, assigned, sold];

    return _PageFrame(
      title: 'Inventaire',
      subtitle: 'Gestion des stocks et équipements',
      action: FilledButton.icon(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Column(
        children: [
          _CapsuleTabs(
            labels: [
              'En stock (${stock.length})',
              'Attribués (${assigned.length})',
              'Vendus (${sold.length})',
            ],
            selectedIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _DarkPanel(
              padding: EdgeInsets.zero,
              child: _WideTable(
                minWidth: 980,
                child: ListView(
                  children: [
                    const _TableHeader(
                      columns: [
                        'Article',
                        'Type',
                        'État',
                        'Usure',
                        'Poste',
                        'Actions',
                      ],
                      flexes: [3, 1, 1, 2, 2, 2],
                    ),
                    for (final item in lists[_tab])
                      _TableRowBox(
                        flexes: const [3, 1, 1, 2, 2, 2],
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.type,
                            style: const TextStyle(color: _mutedText),
                          ),
                          _InventoryStatusBadge(item: item),
                          Text(
                            '${item.hoursUsed.toStringAsFixed(0)}h / ${item.maxHoursBeforeWear.toStringAsFixed(0)}h',
                            style: const TextStyle(color: _mutedText),
                          ),
                          Text(
                            item.assignedStationName ?? '—',
                            style: const TextStyle(color: _mutedText),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.link,
                                  color: Colors.lightBlueAccent,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart,
                                  color: _orange,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  if (item.id != null) {
                                    await databaseRepository
                                        .deleteInventoryItem(item.id!);
                                    widget.onChanged();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final purchase = TextEditingController(text: '0');
    final wear = TextEditingController(text: '400');
    final serial = TextEditingController();
    final reference = TextEditingController();
    var type = 'Console';
    var model = AppConstants.inventoryModelsFor(type).first;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: _surface,
            title: const Text(
              'Ajouter un article',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DarkTextField(controller: name, label: 'Nom'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    dropdownColor: _surface,
                    decoration: _darkInput('Type d’équipement'),
                    items: AppConstants.inventoryTypes
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          type = value;
                          model = AppConstants.inventoryModelsFor(type).first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: model,
                    dropdownColor: _surface,
                    decoration: _darkInput('Modèle'),
                    items: AppConstants.inventoryModelsFor(type)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => model = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _DarkTextField(
                    controller: brand,
                    label: 'Marque (optionnel)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkTextField(
                          controller: purchase,
                          label: 'Prix achat (FCFA)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkTextField(
                          controller: wear,
                          label: 'Seuil usure (h)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DarkTextField(
                    controller: reference,
                    label: 'Référence équipement',
                  ),
                  const SizedBox(height: 12),
                  _DarkTextField(
                    controller: serial,
                    label: 'N° série (optionnel)',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );

    if (created == true) {
      final displayName = name.text.trim().isNotEmpty
          ? name.text.trim()
          : '${brand.text.trim()} $model'.trim();
      if (displayName.isEmpty) {
        brand.dispose();
        name.dispose();
        purchase.dispose();
        wear.dispose();
        serial.dispose();
        reference.dispose();
        return;
      }
      await databaseRepository.createInventoryItem(
        InventoryItem(
          name: displayName,
          type: type,
          reference: reference.text.trim().toUpperCase(),
          purchasePrice: double.tryParse(purchase.text) ?? 0,
          maxHoursBeforeWear: double.tryParse(wear.text) ?? 400,
          serialNumber: serial.text.trim().isEmpty ? null : serial.text.trim(),
          notes: model,
        ),
      );
      widget.onChanged();
    }

    brand.dispose();
    name.dispose();
    purchase.dispose();
    wear.dispose();
    serial.dispose();
    reference.dispose();
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 26 : 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: _mutedText)),
                ],
              );

              if (action == null) return titleBlock;

              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleBlock),
                  action!,
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WideTable extends StatelessWidget {
  const _WideTable({required this.child, required this.minWidth});

  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < minWidth
                ? minWidth
                : constraints.maxWidth,
            child: child,
          ),
        );
      },
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const spacing = 14.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                SizedBox(width: double.infinity, child: children[i]),
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _CapsuleTabs extends StatelessWidget {
  const _CapsuleTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1110),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == i ? _border : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: selectedIndex == i ? Colors.white : _mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, required this.flexes});

  final List<String> columns;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(
                columns[i],
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRowBox extends StatelessWidget {
  const _TableRowBox({required this.children, required this.flexes});

  final List<Widget> children;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++)
            Expanded(flex: flexes[i], child: children[i]),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? _mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paused' => _orange,
      'completed' => _green,
      'expired' => Colors.redAccent,
      _ => Colors.lightBlueAccent,
    };
    final label = switch (status) {
      'paused' => 'En pause',
      'completed' => 'Terminée',
      'expired' => 'Expirée',
      _ => 'Active',
    };
    return _MiniBadge(label: label, color: color, filled: status == 'paused');
  }
}

class _SaleBadge extends StatelessWidget {
  const _SaleBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isSession = type == 'session';
    return _MiniBadge(
      label: isSession ? 'Session' : 'Vente',
      color: isSession ? _purple : _orange,
      textColor: isSession ? Colors.white : Colors.black,
      filled: true,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    this.textColor,
    this.filled = false,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.icon,
    required this.color,
    required this.amount,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final double amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _DarkPanel(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 18),
              ],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.formatPrice(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label, style: const TextStyle(color: _mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final sessions = player.totalSessions;
    final data = sessions >= 50
        ? ('Légendaire', const Color(0xFFFFD54F))
        : sessions >= 20
        ? ('Or', _orange)
        : sessions >= 10
        ? ('Argent', Colors.blueGrey.shade200)
        : ('Bronze', Colors.pinkAccent);
    return _MiniBadge(label: data.$1, color: data.$2);
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.reward,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F1D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(desc, style: const TextStyle(color: _mutedText)),
            const SizedBox(height: 4),
            Text(reward, style: const TextStyle(color: _green, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InventoryStatusBadge extends StatelessWidget {
  const _InventoryStatusBadge({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.status == 'attribue'
        ? _orange
        : item.status == 'vendu'
        ? Colors.redAccent
        : Colors.lightBlueAccent;
    final label = item.status == 'attribue'
        ? 'Attribué'
        : item.status == 'vendu'
        ? 'Vendu'
        : 'En stock';
    return _MiniBadge(label: label, color: color);
  }
}

class _MaintenanceSection extends StatelessWidget {
  const _MaintenanceSection({
    required this.title,
    required this.items,
    required this.color,
    required this.onChanged,
  });

  final String title;
  final List<InventoryItem> items;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                _MaintenanceCard(
                  item: item,
                  color: color,
                  onChanged: onChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.item,
    required this.color,
    required this.onChanged,
  });

  final InventoryItem item;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ratio = item.maxHoursBeforeWear <= 0
        ? 0.0
        : (item.hoursUsed / item.maxHoursBeforeWear).clamp(0.0, 1.0).toDouble();
    final remaining = (item.maxHoursBeforeWear - item.hoursUsed)
        .clamp(0, item.maxHoursBeforeWear)
        .toInt();
    return SizedBox(
      width: 330,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 18),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _MiniBadge(label: item.wearLevel, color: color),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
            const SizedBox(height: 10),
            Text(
              '$remaining h restantes avant maintenance',
              style: const TextStyle(color: _mutedText),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await databaseRepository.updateInventoryItem(
                  item.copyWith(hoursUsed: 0, wearLevel: 'bon'),
                );
                onChanged();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: color.withValues(alpha: 0.45)),
              ),
              child: const Text('Marquer comme remplacé / réparé'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _darkInput(label),
    );
  }
}

InputDecoration _darkInput(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _mutedText),
    filled: true,
    fillColor: const Color(0xFF1B1F1D),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green),
    ),
  );
}

String _formatIsoDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _formatSessionOperator(
  String? name,
  String? role, {
  String fallback = '—',
}) {
  final cleanName = name?.trim();
  if (cleanName == null || cleanName.isEmpty) return fallback;
  final cleanRole = role?.trim();
  if (cleanRole == null || cleanRole.isEmpty) return cleanName;
  final label = cleanRole == 'admin'
      ? 'Admin'
      : cleanRole == 'manager'
      ? 'Gestionnaire'
      : cleanRole == 'system'
      ? 'Système'
      : cleanRole;
  return '$cleanName · $label';
}

class _ReportsView extends StatefulWidget {
  const _ReportsView({required this.data, required this.user});

  final _DashboardData data;
  final AppUser user;

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  String _selectedPeriod = 'hebdomadaire';

  DateTime get _now => DateTime.now();

  DateTime _periodStart(String period) {
    switch (period) {
      case 'journalier':
        return DateTime(_now.year, _now.month, _now.day);
      case 'trimestriel':
        return _now.subtract(const Duration(days: 90));
      case 'semestriel':
        return _now.subtract(const Duration(days: 180));
      case 'hebdomadaire':
      default:
        return _now.subtract(const Duration(days: 7));
    }
  }

  bool _isWithin(DateTime? date, DateTime from, DateTime to) {
    if (date == null) return false;
    return !date.isBefore(from) && !date.isAfter(to);
  }

  Future<void> _exportCurrentReport() async {
    final from = _periodStart(_selectedPeriod);
    final sales = _filteredSales(from);
    final sessions = _filteredSessions(from);
    try {
      await ReportExportService().exportReport(
        periodLabel: _selectedPeriod,
        from: from,
        to: _now,
        user: widget.user,
        sessions: sessions,
        sales: sales,
        stations: widget.data.stations,
        inventory: widget.data.inventory,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le rapport $_selectedPeriod a été généré avec succès.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export impossible : $error')));
    }
  }

  List<Sale> _filteredSales(DateTime from) {
    return widget.data.sales.where((sale) {
      final createdAt = DateTime.tryParse(sale.createdAt);
      return _isWithin(createdAt, from, _now);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Session> _filteredSessions(DateTime from) {
    return widget.data.sessions.where((session) {
      final sessionDate = DateTime.tryParse(
        session.completedAt ?? session.startedAt,
      );
      return _isWithin(sessionDate, from, _now);
    }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Map<String, double> _stationRevenue(List<Sale> sales) {
    final sessionsById = {
      for (final session in widget.data.sessions)
        if (session.id != null) session.id!: session,
    };
    final revenueByStation = <String, double>{};
    for (final sale in sales.where((sale) => sale.type == 'session')) {
      final session = sessionsById[sale.sessionId];
      final stationName =
          session?.stationName ??
          _extractStationNameFromDescription(sale.description);
      revenueByStation.update(
        stationName,
        (value) => value + sale.amount,
        ifAbsent: () => sale.amount,
      );
    }
    return Map.fromEntries(
      revenueByStation.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, double> _productRevenue(List<Sale> sales) {
    final map = <String, double>{};
    for (final sale in sales.where((sale) => sale.type != 'session')) {
      final label = sale.description.replaceFirst('Vente: ', '').trim();
      map.update(
        label,
        (value) => value + sale.amount,
        ifAbsent: () => sale.amount,
      );
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, int> _playsPerDay(List<Session> sessions) {
    final from = _periodStart(_selectedPeriod);
    final buckets = <String, int>{};
    final totalDays = _now.difference(from).inDays + 1;
    for (var i = totalDays - 1; i >= 0; i--) {
      final day = DateTime(
        _now.year,
        _now.month,
        _now.day,
      ).subtract(Duration(days: i));
      buckets[_dayLabel(day)] = 0;
    }
    for (final session in sessions) {
      final date = DateTime.tryParse(session.startedAt);
      if (!_isWithin(date, from, _now) || date == null) continue;
      final key = _dayLabel(date);
      if (buckets.containsKey(key)) {
        buckets.update(key, (value) => value + 1);
      }
    }
    return buckets;
  }

  String _extractStationNameFromDescription(String description) {
    final parts = description.split(' - ');
    if (parts.isEmpty) return 'Autre';
    final left = parts.first
        .replaceFirst('Session ', '')
        .replaceFirst('Prolongation ', '')
        .trim();
    return left.isEmpty ? 'Autre' : left;
  }

  String _dayLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stockCount = widget.data.inventory
        .where((item) => item.status == 'en_stock')
        .length;
    final assignedCount = widget.data.inventory
        .where((item) => item.status == 'attribue')
        .length;
    final from = _periodStart(_selectedPeriod);
    final sales = _filteredSales(from);
    final sessions = _filteredSessions(from);
    final stationRevenue = _stationRevenue(sales);
    final productRevenue = _productRevenue(sales);
    final dailyPlays = _playsPerDay(sessions);
    final sessionsRevenue = sales
        .where((sale) => sale.type == 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);
    final productSalesRevenue = sales
        .where((sale) => sale.type != 'session')
        .fold<double>(0, (sum, sale) => sum + sale.amount);
    final periodRevenue = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.amount,
    );
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.totalMinutes,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Suivi des performances par poste, ventes et fréquentation',
                  style: TextStyle(color: _mutedText),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final period in const [
                  ('Journalier', 'journalier'),
                  ('Hebdomadaire', 'hebdomadaire'),
                  ('Trimestriel', 'trimestriel'),
                  ('Semestriel', 'semestriel'),
                ])
                  _PeriodChip(
                    label: period.$1,
                    selected: _selectedPeriod == period.$2,
                    onTap: () => setState(() => _selectedPeriod = period.$2),
                  ),
                FilledButton.icon(
                  onPressed: widget.user.isAdmin ? _exportCurrentReport : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exporter PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 14), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: title),
                Flexible(child: actions),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              icon: Icons.payments,
              label: 'CA période',
              value: AppConstants.formatPrice(periodRevenue),
              color: const Color(0xFF059669),
            ),
            _MetricTile(
              icon: Icons.timer,
              label: 'Sessions comptées',
              value: sessions.length.toString(),
              color: const Color(0xFF2563EB),
            ),
            _MetricTile(
              icon: Icons.warehouse,
              label: 'Stock magasin',
              value: stockCount.toString(),
              color: const Color(0xFF7C3AED),
            ),
            _MetricTile(
              icon: Icons.link,
              label: 'Actifs attribués',
              value: assignedCount.toString(),
              color: const Color(0xFFEA580C),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (!widget.user.isAdmin) ...[
          const _PermissionNotice(
            title: 'Vue gestionnaire',
            message:
                'Les exports PDF restent réservés à l’administrateur, mais les indicateurs et graphiques opérationnels restent visibles.',
          ),
          const SizedBox(height: 18),
        ],
        _DarkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rapport par poste',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Combien chaque poste a rapporté sur la période',
                style: TextStyle(color: _mutedText),
              ),
              const SizedBox(height: 14),
              _HorizontalRevenueChart(
                values: stationRevenue,
                formatter: AppConstants.formatPrice,
                color: _green,
                emptyMessage: 'Aucun revenu par poste sur cette période.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DarkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rapport des ventes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sessions de jeu vs produits vendus',
                style: TextStyle(color: _mutedText),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    icon: Icons.sports_esports,
                    label: 'Jeux',
                    value: AppConstants.formatPrice(sessionsRevenue),
                    color: _purple,
                  ),
                  _MetricTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Produits',
                    value: AppConstants.formatPrice(productSalesRevenue),
                    color: _orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HorizontalRevenueChart(
                values: productRevenue,
                formatter: AppConstants.formatPrice,
                color: _orange,
                emptyMessage: 'Aucune vente produit sur cette période.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DarkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fréquentation par jour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nombre de sessions démarrées chaque jour sur la période',
                style: const TextStyle(color: _mutedText),
              ),
              const SizedBox(height: 16),
              _DailyPlaysChart(values: dailyPlays),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DarkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tableau récapitulatif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _SummaryTable(
                rows: [
                  ('Période', _selectedPeriod),
                  ('CA total', AppConstants.formatPrice(periodRevenue)),
                  ('CA jeux', AppConstants.formatPrice(sessionsRevenue)),
                  (
                    'CA produits',
                    AppConstants.formatPrice(productSalesRevenue),
                  ),
                  ('Temps joué', '${(totalMinutes / 60).toStringAsFixed(1)} h'),
                  ('Sessions', sessions.length.toString()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DarkPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dernières transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (sales.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aucune transaction sur cette période.',
                    style: TextStyle(color: _mutedText),
                  ),
                )
              else
                ...sales
                    .take(8)
                    .map(
                      (sale) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          sale.type == 'session'
                              ? Icons.timer_outlined
                              : Icons.shopping_bag_outlined,
                          color: sale.type == 'session' ? _purple : _orange,
                        ),
                        title: Text(
                          sale.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          _formatIsoDate(sale.createdAt),
                          style: const TextStyle(color: _mutedText),
                        ),
                        trailing: Text(
                          AppConstants.formatPrice(sale.amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEEF2FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.shield_outlined, color: Color(0xFF4F46E5)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(message),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E2120) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _green : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HorizontalRevenueChart extends StatelessWidget {
  const _HorizontalRevenueChart({
    required this.values,
    required this.formatter,
    required this.color,
    required this.emptyMessage,
  });

  final Map<String, double> values;
  final String Function(double) formatter;
  final Color color;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(emptyMessage, style: const TextStyle(color: _mutedText)),
      );
    }

    final maxValue = values.values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });

    return Column(
      children: [
        for (final entry in values.entries.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : entry.value / maxValue,
                      minHeight: 12,
                      backgroundColor: color.withValues(alpha: 0.14),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Text(
                    formatter(entry.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DailyPlaysChart extends StatelessWidget {
  const _DailyPlaysChart({required this.values});

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Aucune session sur cette période.',
          style: TextStyle(color: _mutedText),
        ),
      );
    }

    final maxValue = values.values.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });

    final chartWidth = values.length <= 7
        ? double.infinity
        : values.length * 54.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final entry in values.entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: maxValue == 0
                                ? 0.02
                                : entry.value / maxValue,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _green),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.key,
                        style: const TextStyle(color: _mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  rows[i].$1,
                  style: const TextStyle(color: _mutedText),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                rows[i].$2,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (i != rows.length - 1) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: _border),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Accès réservé',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.name}, cette section est disponible uniquement pour les administrateurs.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView({
    required this.data,
    required this.user,
    required this.onChanged,
  });

  final _DashboardData data;
  final AppUser user;
  final VoidCallback onChanged;

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late bool _ttsEnabled;
  late String _voice;
  late final TextEditingController _basePriceController;
  late final TextEditingController _baseMinutesController;
  late final TextEditingController _bonusGiftMinutesController;

  @override
  void initState() {
    super.initState();
    _ttsEnabled = widget.data.settings.ttsEnabled;
    _voice = widget.data.settings.voiceGender;
    _basePriceController = TextEditingController(
      text: widget.data.settings.basePrice.toStringAsFixed(0),
    );
    _baseMinutesController = TextEditingController(
      text: widget.data.settings.baseMinutes.toString(),
    );
    _bonusGiftMinutesController = TextEditingController(
      text: widget.data.settings.bonusGiftMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _baseMinutesController.dispose();
    _bonusGiftMinutesController.dispose();
    super.dispose();
  }

  Future<void> _openAddStationWizard() async {
    final created = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Assistant ajout poste',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: AddStationDialog(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (created == true && mounted) {
      widget.onChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Poste créé avec succès.')));
    }
  }

  Future<void> _toggleMaintenance(Station station) async {
    final nextStatus = station.status == AppConstants.statusMaintenance
        ? AppConstants.statusLibre
        : AppConstants.statusMaintenance;
    await databaseRepository.updateStation(
      station.copyWith(status: nextStatus),
    );
    widget.onChanged();
  }

  Future<void> _deleteStation(Station station) async {
    if (station.id == null) return;
    final assignedItems = await databaseRepository.getInventoryItems();
    for (final item in assignedItems.where(
      (item) => item.assignedStationId == station.id,
    )) {
      await databaseRepository.updateInventoryItem(
        item.copyWith(
          status: 'en_stock',
          assignedStationId: 0,
          assignedStationName: null,
        ),
      );
    }
    await databaseRepository.deleteStation(station.id!);
    widget.onChanged();
  }

  Future<void> _savePricingSettings() async {
    final basePrice = double.tryParse(_basePriceController.text.trim());
    final baseMinutes = int.tryParse(_baseMinutesController.text.trim());
    final bonusGiftMinutes = int.tryParse(
      _bonusGiftMinutesController.text.trim(),
    );

    if (basePrice == null ||
        basePrice <= 0 ||
        baseMinutes == null ||
        baseMinutes <= 0 ||
        bonusGiftMinutes == null ||
        bonusGiftMinutes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrez un tarif, une durée et un bonus cadeau valides.',
          ),
        ),
      );
      return;
    }

    if (!widget.user.isAdmin &&
        bonusGiftMinutes != widget.data.settings.bonusGiftMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seul un administrateur peut modifier le bonus cadeau.',
          ),
        ),
      );
      return;
    }

    await databaseRepository.updateAppSettings(
      widget.data.settings.copyWith(
        basePrice: basePrice,
        baseMinutes: baseMinutes,
        bonusGiftMinutes: widget.user.isAdmin
            ? bonusGiftMinutes
            : widget.data.settings.bonusGiftMinutes,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres tarifaires enregistrés.')),
    );
    widget.onChanged();
  }

  Future<void> _saveVoiceSettings({bool? enabled, String? voice}) async {
    final nextEnabled = enabled ?? _ttsEnabled;
    final nextVoice = voice ?? _voice;
    await databaseRepository.updateAppSettings(
      widget.data.settings.copyWith(
        ttsEnabled: nextEnabled,
        voiceGender: nextVoice,
      ),
    );
    if (!mounted) return;
    widget.onChanged();
  }

  Future<void> _testVoice() async {
    if (!_ttsEnabled) return;
    await AlertAudioService.instance.playBell();
    await AlertAudioService.instance.announceRemainingTime(
      stationName: 'Poste 1',
      minutesLeft: 3,
      voiceGender: _voice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 26 : 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configuration des postes, alertes vocales et stock',
                    style: TextStyle(color: _mutedText),
                  ),
                ],
              );
              final action = FilledButton.icon(
                onPressed: _openAddStationWizard,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau poste'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), action],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Expanded(child: compact ? _mobileLayout() : _desktopLayout()),
        ],
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _stationsSection(shrinkWrap: false)),
        const SizedBox(width: 18),
        Expanded(flex: 3, child: _settingsPanels()),
      ],
    );
  }

  Widget _mobileLayout() {
    return ListView(
      children: [
        _stationsSection(shrinkWrap: true),
        const SizedBox(height: 18),
        _VoiceSettingsPanel(
          enabled: _ttsEnabled,
          voice: _voice,
          onEnabledChanged: (value) {
            setState(() => _ttsEnabled = value);
            _saveVoiceSettings(enabled: value);
          },
          onVoiceChanged: (value) {
            setState(() => _voice = value);
            _saveVoiceSettings(voice: value);
          },
          onTest: _testVoice,
        ),
        const SizedBox(height: 16),
        _PricingSettingsPanel(
          basePriceController: _basePriceController,
          baseMinutesController: _baseMinutesController,
          bonusGiftMinutesController: _bonusGiftMinutesController,
          canEditBonusGift: widget.user.isAdmin,
          onSave: _savePricingSettings,
        ),
        const SizedBox(height: 16),
        _StockPanel(items: widget.data.inventory),
      ],
    );
  }

  Widget _settingsPanels() {
    return ListView(
      children: [
        _VoiceSettingsPanel(
          enabled: _ttsEnabled,
          voice: _voice,
          onEnabledChanged: (value) {
            setState(() => _ttsEnabled = value);
            _saveVoiceSettings(enabled: value);
          },
          onVoiceChanged: (value) {
            setState(() => _voice = value);
            _saveVoiceSettings(voice: value);
          },
          onTest: _testVoice,
        ),
        const SizedBox(height: 16),
        _PricingSettingsPanel(
          basePriceController: _basePriceController,
          baseMinutesController: _baseMinutesController,
          bonusGiftMinutesController: _bonusGiftMinutesController,
          canEditBonusGift: widget.user.isAdmin,
          onSave: _savePricingSettings,
        ),
        const SizedBox(height: 16),
        _StockPanel(items: widget.data.inventory),
      ],
    );
  }

  Widget _stationsSection({required bool shrinkWrap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Postes (${widget.data.stations.length})',
          style: const TextStyle(
            color: _mutedText,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        if (shrinkWrap)
          _stationsGrid(shrinkWrap: true)
        else
          Expanded(child: _stationsGrid(shrinkWrap: false)),
      ],
    );
  }

  Widget _stationsGrid({required bool shrinkWrap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: widget.data.stations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 240,
          ),
          itemBuilder: (context, index) {
            final station = widget.data.stations[index];
            final assigned = widget.data.stationAssets[station.id] ?? const [];
            return _SettingsStationCard(
              station: station,
              assignedCount: assigned.length,
              onMaintenance: () => _toggleMaintenance(station),
              onDelete: () => _deleteStation(station),
            );
          },
        );
      },
    );
  }
}

class _SettingsStationCard extends StatelessWidget {
  const _SettingsStationCard({
    required this.station,
    required this.assignedCount,
    required this.onMaintenance,
    required this.onDelete,
  });

  final Station station;
  final int assignedCount;
  final VoidCallback onMaintenance;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppConstants.statusColors[station.status] ?? _green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F1D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  AppConstants.consoleEmojis[station.consoleType] ?? 'GM',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      station.consoleType,
                      style: const TextStyle(color: _mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$assignedCount équipements attribués',
            style: const TextStyle(color: _mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            '${station.totalHoursUsed.toStringAsFixed(0)}h d’utilisation',
            style: const TextStyle(color: _mutedText),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMaintenance,
                  icon: const Icon(Icons.build, size: 16),
                  label: Text(
                    station.status == AppConstants.statusMaintenance
                        ? 'Remettre'
                        : 'Maintenance',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple.withValues(alpha: 0.26),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceSettingsPanel extends StatelessWidget {
  const _VoiceSettingsPanel({
    required this.enabled,
    required this.voice,
    required this.onEnabledChanged,
    required this.onVoiceChanged,
    required this.onTest,
  });

  final bool enabled;
  final String voice;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onVoiceChanged;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return _DarkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.volume_up, color: _green),
              SizedBox(width: 10),
              Text(
                'Alertes vocales TTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F1D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annonces vocales',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '5 min cloche + 3 min voix',
                        style: TextStyle(color: _mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: _green,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'VOIX',
            style: TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _VoiceChoice(
                  label: 'Voix féminine',
                  selected: voice == 'female',
                  onTap: () => onVoiceChanged('female'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VoiceChoice(
                  label: 'Voix masculine',
                  selected: voice == 'male',
                  onTap: () => onVoiceChanged('male'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'DÉCLENCHEURS',
            style: TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          const _TriggerRow(
            label: '5 minutes restantes',
            badge: 'Cloche',
            color: _orange,
          ),
          SizedBox(height: 8),
          const _TriggerRow(
            label: '3 minutes restantes',
            badge: 'Voix',
            color: Colors.redAccent,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: enabled ? onTest : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tester la voix'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _border),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingSettingsPanel extends StatelessWidget {
  const _PricingSettingsPanel({
    required this.basePriceController,
    required this.baseMinutesController,
    required this.bonusGiftMinutesController,
    required this.canEditBonusGift,
    required this.onSave,
  });

  final TextEditingController basePriceController;
  final TextEditingController baseMinutesController;
  final TextEditingController bonusGiftMinutesController;
  final bool canEditBonusGift;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _DarkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: _green),
              SizedBox(width: 10),
              Text(
                'Tarification',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: basePriceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Montant de base (FCFA)',
              labelStyle: const TextStyle(color: _mutedText),
              filled: true,
              fillColor: const Color(0xFF1B1F1D),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: baseMinutesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Durée de base (minutes)',
              labelStyle: const TextStyle(color: _mutedText),
              filled: true,
              fillColor: const Color(0xFF1B1F1D),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bonusGiftMinutesController,
            enabled: canEditBonusGift,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Bonus cadeau par clic (minutes)',
              helperText: canEditBonusGift
                  ? 'Valeur utilisée par le bouton cadeau des joueurs'
                  : 'Réservé à l’administrateur',
              helperStyle: const TextStyle(color: _mutedText),
              labelStyle: const TextStyle(color: _mutedText),
              filled: true,
              fillColor: const Color(0xFF1B1F1D),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _green),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceChoice extends StatelessWidget {
  const _VoiceChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _green.withValues(alpha: 0.08)
              : const Color(0xFF1B1F1D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _green : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _green : _mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({
    required this.label,
    required this.badge,
    required this.color,
  });

  final String label;
  final String badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockPanel extends StatelessWidget {
  const _StockPanel({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final available = items.where((item) => item.status == 'en_stock').length;
    return _DarkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock disponible',
            style: TextStyle(
              color: _mutedText,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            available.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'articles en stock prêts à attribuer',
            style: TextStyle(color: _mutedText),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: _border),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Gérer l’inventaire'),
          ),
        ],
      ),
    );
  }
}

class _DarkPanel extends StatelessWidget {
  const _DarkPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView({required this.data, required this.onChanged});

  final _DashboardData data;
  final VoidCallback onChanged;

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  Future<void> _createUser() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: '123456');
    var role = 'manager';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvel utilisateur'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: const [
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text('Gestionnaire'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrateur'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => role = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      return;
    }

    await databaseRepository.createUser(
      AppUser(
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        passwordHash: passwordController.text,
        role: role,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    widget.onChanged();
  }

  Future<void> _toggleUser(AppUser user) async {
    await databaseRepository.updateUser(
      user.copyWith(isActive: !user.isActive),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Gestion des utilisateurs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.icon(
              onPressed: _createUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Créer'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.data.users.map((user) {
          final color = user.isAdmin
              ? const Color(0xFF7C3AED)
              : const Color(0xFF059669);
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.storefront,
                  color: color,
                ),
              ),
              title: Text(user.name),
              subtitle: Text(
                '${user.email} • ${user.isAdmin ? 'Administrateur' : 'Gestionnaire'}',
              ),
              trailing: Switch(
                value: user.isActive,
                onChanged: (_) => _toggleUser(user),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.stations,
    required this.sessions,
    required this.openSessions,
    required this.inventory,
    required this.sales,
    required this.players,
    required this.users,
    required this.settings,
    required this.revenue,
    required this.completedSessions,
    required this.assetCounts,
    required this.stationAssets,
  });

  final List<Station> stations;
  final List<Session> sessions;
  final List<Session> openSessions;
  final List<InventoryItem> inventory;
  final List<Sale> sales;
  final List<Player> players;
  final List<AppUser> users;
  final AppSettings settings;
  final double revenue;
  final int completedSessions;
  final Map<int, int> assetCounts;
  final Map<int, List<String>> stationAssets;

  _DashboardData copyWith({
    List<Station>? stations,
    List<Session>? sessions,
    List<Session>? openSessions,
    List<InventoryItem>? inventory,
    List<Sale>? sales,
    List<Player>? players,
    List<AppUser>? users,
    AppSettings? settings,
    double? revenue,
    int? completedSessions,
    Map<int, int>? assetCounts,
    Map<int, List<String>>? stationAssets,
  }) {
    return _DashboardData(
      stations: stations ?? this.stations,
      sessions: sessions ?? this.sessions,
      openSessions: openSessions ?? this.openSessions,
      inventory: inventory ?? this.inventory,
      sales: sales ?? this.sales,
      players: players ?? this.players,
      users: users ?? this.users,
      settings: settings ?? this.settings,
      revenue: revenue ?? this.revenue,
      completedSessions: completedSessions ?? this.completedSessions,
      assetCounts: assetCounts ?? this.assetCounts,
      stationAssets: stationAssets ?? this.stationAssets,
    );
  }
}
