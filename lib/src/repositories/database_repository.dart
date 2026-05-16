import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';

import '../constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/inventory_item.dart';
import '../models/player.dart';
import '../models/sale.dart';
import '../models/session.dart';
import '../models/station.dart';

class DatabaseRepository {
  DatabaseRepository({
    FirebaseDatabase? database,
    firebase_auth.FirebaseAuth? auth,
  }) : _databaseOverride = database,
       _authOverride = auth;

  static const _databaseUrl =
      'https://gamezone-108f6-default-rtdb.europe-west1.firebasedatabase.app';

  final FirebaseDatabase? _databaseOverride;
  final firebase_auth.FirebaseAuth? _authOverride;

  FirebaseDatabase get _database =>
      _databaseOverride ?? FirebaseDatabase.instance;
  firebase_auth.FirebaseAuth get _auth =>
      _authOverride ?? firebase_auth.FirebaseAuth.instance;

  DatabaseReference get _root =>
      _database.databaseURL == null || _database.databaseURL!.isEmpty
      ? FirebaseDatabase.instanceFor(
          app: _database.app,
          databaseURL: _databaseUrl,
        ).ref()
      : _database.ref();

  DatabaseReference _ref(String path) => _root.child(path);

  Future<int> createStation(Station station) async {
    final id = await _nextId('stations');
    await _ref('stations/$id').set(_clean(station.copyWith(id: id).toMap()));
    return id;
  }

  Future<Station?> getStation(int id) async {
    final map = await _getMap('stations/$id');
    return map == null ? null : Station.fromMap(map);
  }

  Future<List<Station>> getStations() async {
    final stations = await _getList('stations', Station.fromMap);
    stations.sort((a, b) => a.name.compareTo(b.name));
    return stations;
  }

  Future<int> updateStation(Station station) async {
    if (station.id == null) return 0;
    await _ref('stations/${station.id}').set(_clean(station.toMap()));
    return 1;
  }

  Future<int> deleteStation(int id) async {
    await _ref('stations/$id').remove();
    return 1;
  }

  Future<void> seedDemoDataIfNeeded() async {
    await _ensureFirebaseAuth();
    await _seedUsersIfNeeded();
    await _seedSettingsIfNeeded();
    await _seedEsp32NodesIfNeeded();

    final stations = await getStations();
    if (stations.isEmpty) {
      for (final station in [
        Station(id: 1, name: 'Poste 1', reference: 'A', consoleType: 'PS5'),
        Station(id: 2, name: 'Poste 2', reference: 'B', consoleType: 'PS5'),
        Station(
          id: 3,
          name: 'Poste 3',
          reference: 'C',
          consoleType: 'Xbox Series X',
        ),
        Station(
          id: 4,
          name: 'Poste 4',
          reference: 'D',
          consoleType: 'PC Gaming',
        ),
        Station(id: 5, name: 'Poste VR', reference: 'VR', consoleType: 'PS5'),
        Station(
          id: 6,
          name: 'Switch Lounge',
          reference: 'SW',
          consoleType: 'Nintendo Switch',
        ),
      ]) {
        await _ref('stations/${station.id}').set(_clean(station.toMap()));
      }
      await _setCounterAtLeast('stations', 6);
    }

    final inventory = await getInventoryItems();
    if (inventory.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final items = [
        InventoryItem(
          id: 1,
          name: 'Manette PS5 A',
          type: 'Manette',
          status: 'attribue',
          reference: 'A1',
          assignedStationId: 1,
          assignedStationName: 'Poste 1',
          hoursUsed: 312,
          wearLevel: 'inspection',
          serialNumber: 'PS5-$now-A',
        ),
        InventoryItem(
          id: 2,
          name: 'Manette PS5 B',
          type: 'Manette',
          status: 'attribue',
          reference: 'A2',
          assignedStationId: 1,
          assignedStationName: 'Poste 1',
          hoursUsed: 386,
          wearLevel: 'critique',
          serialNumber: 'PS5-$now-B',
        ),
        InventoryItem(
          id: 3,
          name: 'Casque VR',
          type: 'VR',
          status: 'attribue',
          reference: 'VR1',
          assignedStationId: 5,
          assignedStationName: 'Poste VR',
          hoursUsed: 146,
          maxHoursBeforeWear: 300,
          serialNumber: 'VR-$now',
        ),
        InventoryItem(
          id: 4,
          name: 'Manette Xbox stock',
          type: 'Manette',
          status: 'en_stock',
          reference: '',
          assignedStationId: 0,
          purchasePrice: 22000,
          salePrice: 30000,
          serialNumber: 'XB-$now',
        ),
      ];
      for (final item in items) {
        await _ref('inventory_items/${item.id}').set(_clean(item.toMap()));
      }
      await _setCounterAtLeast('inventory_items', 4);
    }

    final sessions = await getSessions();
    if (sessions.isEmpty) {
      final now = DateTime.now();
      await _ref('sessions/1').set(
        _clean(
          Session(
            id: 1,
            stationId: 1,
            stationName: 'Poste 1',
            playerName: 'most',
            amountPaid: 250,
            totalMinutes: 40,
            minutesUsed: 36,
            minutesRemaining: 4,
            status: 'paused',
            startedAt: now
                .subtract(const Duration(minutes: 36))
                .toIso8601String(),
            pausedAt: now.toIso8601String(),
            expiresAt: now.add(const Duration(hours: 72)).toIso8601String(),
          ).toMap(),
        ),
      );
      await updateStation(
        Station(
          id: 1,
          name: 'Poste 1',
          reference: 'A',
          consoleType: 'PS5',
          status: AppConstants.statusEnPause,
        ),
      );

      var id = 2;
      for (final data in [
        ('lm', 500.0, now.subtract(const Duration(days: 1, hours: 2))),
        ('Kouassi', 750.0, now.subtract(const Duration(days: 2, hours: 4))),
      ]) {
        final minutes = priceToMinutes(data.$2).toInt();
        await _ref('sessions/$id').set(
          _clean(
            Session(
              id: id,
              stationId: 4,
              stationName: 'Poste 4',
              playerName: data.$1,
              amountPaid: data.$2,
              totalMinutes: minutes,
              minutesUsed: minutes,
              minutesRemaining: 0,
              status: 'completed',
              startedAt: data.$3.toIso8601String(),
              completedAt: data.$3
                  .add(Duration(minutes: minutes))
                  .toIso8601String(),
            ).toMap(),
          ),
        );
        id++;
      }
      await _setCounterAtLeast('sessions', 3);
    }

    final sales = await getSales();
    if (sales.isEmpty) {
      final now = DateTime.now();
      final seededSales = [
        Sale(
          id: 1,
          type: 'session',
          description: 'Session Poste 1 - Wilfried',
          amount: 500,
          clientName: 'Wilfried',
          createdAt: now.toIso8601String(),
        ),
        Sale(
          id: 2,
          type: 'vente_directe',
          description: "Vente: Manette PS4 d'occasion",
          amount: 15000,
          clientName: 'Client boutique',
          createdAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        ),
        Sale(
          id: 3,
          type: 'session',
          description: 'Session PC Gaming - lm',
          amount: 2500,
          clientName: 'lm',
          createdAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        ),
      ];
      for (final sale in seededSales) {
        await _ref('sales/${sale.id}').set(_clean(sale.toMap()));
      }
      await _setCounterAtLeast('sales', 3);
    }

    final players = await getPlayers();
    if (players.isEmpty) {
      final seededPlayers = [
        Player(
          id: 1,
          name: 'Wilfried',
          totalSessions: 52,
          totalSpent: 18500,
          totalMinutesPlayed: 1880,
          bonusMinutes: 40,
        ),
        Player(
          id: 2,
          name: 'most',
          totalSessions: 12,
          totalSpent: 6000,
          totalMinutesPlayed: 960,
        ),
        Player(
          id: 3,
          name: 'Kouassi',
          totalSessions: 23,
          totalSpent: 14500,
          totalMinutesPlayed: 1640,
        ),
        Player(
          id: 4,
          name: 'lm',
          totalSessions: 7,
          totalSpent: 3500,
          totalMinutesPlayed: 560,
        ),
      ];
      for (final player in seededPlayers) {
        await _ref('players/${player.id}').set(_clean(player.toMap()));
      }
      await _setCounterAtLeast('players', 4);
    }
  }

  double priceToMinutes(double price) {
    if (price <= 0) return 0;
    return (price / AppConstants.basePrice) * AppConstants.baseMinutes;
  }

  Future<AppUser?> authenticateUser(String login, String password) async {
    final normalized = login.trim().toLowerCase();
    final email = normalized.contains('@')
        ? normalized
        : '$normalized@gmail.com';
    final authPassword = email == 'admin@gmail.com' && password == 'admin'
        ? 'admin123'
        : password;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: authPassword,
      );
    } on firebase_auth.FirebaseAuthException {
      return null;
    }

    final users = await getUsers();
    for (final user in users) {
      final matchesLogin =
          user.email.toLowerCase() == normalized ||
          user.email.toLowerCase() == email ||
          user.name.toLowerCase() == normalized;
      if (!matchesLogin || !user.isActive) continue;
      return user;
    }
    return AppUser(
      id: null,
      name: email.split('@').first,
      email: email,
      passwordHash: '',
      role: email == 'admin@gmail.com' ? 'admin' : 'manager',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppSettings> getAppSettings() async {
    final map = await _getMap('app_settings/1');
    if (map != null) {
      final settings = AppSettings.fromMap(map);
      final flag = await _getMap('metadata/flags/bonus_gift_default_v2');
      if ((flag == null || flag.isEmpty) && settings.bonusGiftMinutes == 10) {
        final updated = settings.copyWith(bonusGiftMinutes: 40);
        await updateAppSettings(updated);
        await _ref(
          'metadata/flags/bonus_gift_default_v2',
        ).set({'done': true, 'updated_at': DateTime.now().toIso8601String()});
        return updated;
      }
      return settings;
    }

    const settings = AppSettings(
      id: 1,
      basePrice: AppConstants.basePrice,
      baseMinutes: AppConstants.baseMinutes,
      ttsEnabled: true,
      voiceGender: 'female',
      bonusGiftMinutes: 40,
    );
    await updateAppSettings(settings);
    return settings;
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    await _ref('app_settings/${settings.id}').set(_clean(settings.toMap()));
  }

  Future<List<AppUser>> getUsers() async {
    final users = await _getList('app_users', AppUser.fromMap);
    users.sort((a, b) {
      final roleCompare = a.role.compareTo(b.role);
      return roleCompare == 0 ? a.name.compareTo(b.name) : roleCompare;
    });
    return users;
  }

  Future<int> createUser(AppUser user) async {
    final id = await _nextId('app_users');
    final userToSave = user.copyWith(
      id: id,
      passwordHash: _hashPasswordIfNeeded(user.passwordHash),
    );
    await _ref('app_users/$id').set(_clean(userToSave.toMap()));
    return id;
  }

  Future<int> updateUser(AppUser user) async {
    if (user.id == null) return 0;
    final existing = await getUser(user.id!);
    final shouldHashPassword =
        existing == null || user.passwordHash != existing.passwordHash;
    final userToSave = shouldHashPassword
        ? user.copyWith(passwordHash: _hashPasswordIfNeeded(user.passwordHash))
        : user;
    await _ref('app_users/${user.id}').set(_clean(userToSave.toMap()));
    return 1;
  }

  Future<AppUser?> getUser(int id) async {
    final map = await _getMap('app_users/$id');
    return map == null ? null : AppUser.fromMap(map);
  }

  Future<int> createSession(Session session) async {
    final id = await _nextId('sessions');
    await _ref('sessions/$id').set(_clean(session.copyWith(id: id).toMap()));
    return id;
  }

  Future<int> startSession({
    required Station station,
    required String playerName,
    required double amountPaid,
    required int totalMinutes,
    required AppUser operator,
  }) async {
    final now = DateTime.now().toIso8601String();
    final sessionId = await createSession(
      Session(
        stationId: station.id!,
        stationName: station.name,
        playerName: playerName,
        amountPaid: amountPaid,
        totalMinutes: totalMinutes,
        minutesUsed: 0,
        minutesRemaining: totalMinutes,
        status: 'active',
        startedAt: now,
        startedByName: operator.name,
        startedByRole: operator.role,
      ),
    );

    await Future.wait([
      updateStation(station.copyWith(status: AppConstants.statusOccupe)),
      createSale(
        Sale(
          type: 'session',
          description: 'Session ${station.name} - $playerName',
          amount: amountPaid,
          sessionId: sessionId,
          clientName: playerName,
          createdAt: now,
        ),
      ),
      _syncEsp32StationState(station.id!, AppConstants.statusOccupe),
    ]);
    return sessionId;
  }

  Future<Session?> getSession(int id) async {
    final map = await _getMap('sessions/$id');
    return map == null ? null : Session.fromMap(map);
  }

  Future<List<Session>> getSessions({String? status}) async {
    final sessions = await _getList('sessions', Session.fromMap);
    final filtered = status == null
        ? sessions
        : sessions.where((session) => session.status == status).toList();
    filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return filtered;
  }

  Future<List<Session>> getOpenSessions() async {
    final sessions = await getSessions();
    return sessions
        .where(
          (session) => session.status == 'active' || session.status == 'paused',
        )
        .toList();
  }

  Future<Session?> getOpenSessionForStation(int stationId) async {
    final sessions = await getOpenSessions();
    final matches = sessions
        .where((session) => session.stationId == stationId)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return matches.first;
  }

  Future<void> pauseSession(Session session) async {
    final now = DateTime.now();
    final usage = _calculateUsage(session, now);
    final remaining = (session.totalMinutes - usage)
        .clamp(0, session.totalMinutes)
        .toInt();

    await Future.wait([
      updateSession(
        session.copyWith(
          status: 'paused',
          minutesUsed: usage,
          minutesRemaining: remaining,
          pausedAt: now.toIso8601String(),
          expiresAt: now.add(const Duration(hours: 72)).toIso8601String(),
        ),
      ),
      _ref(
        'stations/${session.stationId}/status',
      ).set(AppConstants.statusEnPause),
      _syncEsp32StationState(session.stationId, AppConstants.statusEnPause),
    ]);
  }

  Future<void> resumeSession(Session session) async {
    final now = DateTime.now().toIso8601String();
    await Future.wait([
      updateSession(
        Session(
          id: session.id,
          stationId: session.stationId,
          stationName: session.stationName,
          playerName: session.playerName,
          amountPaid: session.amountPaid,
          totalMinutes: session.minutesRemaining,
          minutesUsed: 0,
          minutesRemaining: session.minutesRemaining,
          status: 'active',
          startedAt: now,
          startedByName: session.startedByName,
          startedByRole: session.startedByRole,
          completedByName: session.completedByName,
          completedByRole: session.completedByRole,
        ),
      ),
      _ref(
        'stations/${session.stationId}/status',
      ).set(AppConstants.statusOccupe),
      _syncEsp32StationState(session.stationId, AppConstants.statusOccupe),
    ]);
  }

  Future<void> extendSession(
    Session session, {
    required int addedMinutes,
    required double addedAmount,
  }) async {
    await Future.wait([
      updateSession(
        session.copyWith(
          totalMinutes: session.totalMinutes + addedMinutes,
          minutesRemaining: session.minutesRemaining + addedMinutes,
          amountPaid: session.amountPaid + addedAmount,
        ),
      ),
      createSale(
        Sale(
          type: 'session',
          description:
              'Prolongation ${session.stationName} - ${session.playerName}',
          amount: addedAmount,
          sessionId: session.id ?? 0,
          clientName: session.playerName,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ),
    ]);
  }

  Future<void> completeSession(Session session, {AppUser? operator}) async {
    if (session.id != null) {
      final current = await getSession(session.id!);
      if (current == null ||
          current.status == 'completed' ||
          current.status == 'expired') {
        return;
      }
      session = current;
    }

    final now = DateTime.now();
    final usedMinutes = session.status == 'active'
        ? _calculateUsage(session, now)
        : session.minutesUsed;
    final addedHours = usedMinutes / 60;

    final station = await getStation(session.stationId);
    final writes = <Future<Object?>>[
      updateSession(
        session.copyWith(
          status: 'completed',
          minutesUsed: usedMinutes.clamp(0, session.totalMinutes).toInt(),
          minutesRemaining: 0,
          completedAt: now.toIso8601String(),
          completedByName:
              operator?.name ?? session.completedByName ?? 'Système',
          completedByRole:
              operator?.role ?? session.completedByRole ?? 'system',
        ),
      ),
      if (station != null)
        updateStation(
          station.copyWith(
            status: AppConstants.statusLibre,
            totalHoursUsed: station.totalHoursUsed + addedHours,
          ),
        )
      else
        _ref(
          'stations/${session.stationId}/status',
        ).set(AppConstants.statusLibre),
      _syncEsp32StationState(session.stationId, AppConstants.statusLibre),
    ];
    await Future.wait(writes);

    final items = await getInventoryItems(status: 'attribue');
    for (final item in items.where(
      (item) => item.assignedStationId == session.stationId,
    )) {
      final hoursUsed = item.hoursUsed + addedHours;
      await updateInventoryItem(
        item.copyWith(
          hoursUsed: hoursUsed,
          wearLevel: _wearLevelFor(hoursUsed, item.maxHoursBeforeWear),
        ),
      );
    }
  }

  Future<void> expirePausedSessions() async {
    final now = DateTime.now();
    final sessions = await getSessions(status: 'paused');
    for (final session in sessions) {
      final expiresAt = session.expiresAt == null
          ? null
          : DateTime.tryParse(session.expiresAt!);
      if (expiresAt == null || expiresAt.isAfter(now)) continue;
      await updateSession(
        session.copyWith(
          status: 'expired',
          minutesRemaining: 0,
          completedAt: now.toIso8601String(),
        ),
      );
      await _ref(
        'stations/${session.stationId}/status',
      ).set(AppConstants.statusLibre);
      await _syncEsp32StationState(session.stationId, AppConstants.statusLibre);
    }
  }

  Future<int> updateSession(Session session) async {
    if (session.id == null) return 0;
    await _ref('sessions/${session.id}').set(_clean(session.toMap()));
    return 1;
  }

  Future<int> deleteSession(int id) async {
    await _ref('sessions/$id').remove();
    return 1;
  }

  Future<int> createInventoryItem(InventoryItem item) async {
    final id = await _nextId('inventory_items');
    await _ref(
      'inventory_items/$id',
    ).set(_clean(item.copyWith(id: id).toMap()));
    return id;
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    final map = await _getMap('inventory_items/$id');
    return map == null ? null : InventoryItem.fromMap(map);
  }

  Future<List<InventoryItem>> getInventoryItems({String? status}) async {
    final items = await _getList('inventory_items', InventoryItem.fromMap);
    final filtered = status == null
        ? items
        : items.where((item) => item.status == status).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) return 0;
    await _ref('inventory_items/${item.id}').set(_clean(item.toMap()));
    return 1;
  }

  Future<int> deleteInventoryItem(int id) async {
    await _ref('inventory_items/$id').remove();
    return 1;
  }

  Future<int> countInventoryItemsForStation(int stationId) async {
    final items = await getInventoryItems(status: 'attribue');
    return items.where((item) => item.assignedStationId == stationId).length;
  }

  Future<int> createSale(Sale sale) async {
    final id = await _nextId('sales');
    await _ref('sales/$id').set(_clean(sale.copyWithId(id).toMap()));
    return id;
  }

  Future<List<Sale>> getSales() async {
    final sales = await _getList('sales', Sale.fromMap);
    sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sales;
  }

  Future<double> getRevenueTotal() async {
    final sales = await getSales();
    return sales.fold<double>(0, (total, sale) => total + sale.amount);
  }

  Future<int> getCompletedSessionCount() async {
    final sessions = await getSessions();
    return sessions
        .where(
          (session) =>
              session.status == 'completed' || session.status == 'expired',
        )
        .length;
  }

  Future<int> completeExpiredActiveSessions() async {
    final sessions = await getSessions(status: 'active');
    var completed = 0;
    final now = DateTime.now();
    for (final session in sessions) {
      if (!_isActiveSessionExpired(session, now)) continue;
      await completeSession(session);
      completed++;
    }
    return completed;
  }

  Future<int> createPlayer(Player player) async {
    final id = await _nextId('players');
    await _ref('players/$id').set(_clean(player.copyWith(id: id).toMap()));
    return id;
  }

  Future<Player?> getPlayer(int id) async {
    final map = await _getMap('players/$id');
    return map == null ? null : Player.fromMap(map);
  }

  Future<List<Player>> getPlayers() async {
    final players = await _buildPlayersFromHistory();
    players.sort((a, b) => b.totalSessions.compareTo(a.totalSessions));
    return players;
  }

  Future<int> updatePlayer(Player player) async {
    if (player.id == null) return 0;
    await _ref('players/${player.id}').set(_clean(player.toMap()));
    return 1;
  }

  Future<int> deletePlayer(int id) async {
    await _ref('players/$id').remove();
    return 1;
  }

  Future<bool> givePlayerBonusToOpenSession(Player player) async {
    if (player.id == null || player.bonusMinutes <= 0) return false;
    final sessions = await getOpenSessions();
    final playerKey = _playerKey(player.name);
    final matches = sessions
        .where((session) => _playerKey(session.playerName) == playerKey)
        .toList();
    if (matches.isEmpty) return false;

    matches.sort((a, b) {
      if (a.status == b.status) return b.startedAt.compareTo(a.startedAt);
      return a.status == 'active' ? -1 : 1;
    });
    final session = matches.first;
    await Future.wait([
      updateSession(
        session.copyWith(
          totalMinutes: session.totalMinutes + player.bonusMinutes,
          minutesRemaining: session.minutesRemaining + player.bonusMinutes,
        ),
      ),
      updatePlayer(player.copyWith(bonusMinutes: 0)),
    ]);
    return true;
  }

  Future<List<Player>> _buildPlayersFromHistory() async {
    final settings = await getAppSettings();
    final existingPlayers = await _getList('players', Player.fromMap);
    final existingByName = {
      for (final player in existingPlayers) _playerKey(player.name): player,
    };
    final sessions = await getSessions();
    final sales = await getSales();
    final sessionsById = {
      for (final session in sessions)
        if (session.id != null) session.id!: session,
    };
    final statsByName = <String, _PlayerHistoryStats>{};

    for (final session in sessions) {
      final key = _playerKey(session.playerName);
      if (key.isEmpty) continue;
      statsByName.putIfAbsent(
          key,
          () => _PlayerHistoryStats(session.playerName.trim()),
        )
        ..totalSessions += 1
        ..totalMinutesPlayed += _playedMinutesFor(session);
    }

    final saleSessionIds = <int>{};
    for (final sale in sales.where((sale) => sale.type == 'session')) {
      final playerName = (sale.clientName?.trim().isNotEmpty ?? false)
          ? sale.clientName!.trim()
          : sessionsById[sale.sessionId]?.playerName.trim() ?? '';
      final key = _playerKey(playerName);
      if (key.isEmpty) continue;
      if (sale.sessionId > 0) saleSessionIds.add(sale.sessionId);
      final stats = statsByName.putIfAbsent(
        key,
        () => _PlayerHistoryStats(playerName),
      );
      stats.totalSpent += sale.amount;
    }

    for (final session in sessions) {
      final sessionId = session.id;
      if (sessionId != null && saleSessionIds.contains(sessionId)) continue;
      final key = _playerKey(session.playerName);
      if (key.isEmpty) continue;
      statsByName
              .putIfAbsent(
                key,
                () => _PlayerHistoryStats(session.playerName.trim()),
              )
              .totalSpent +=
          session.amountPaid;
    }

    final players = <Player>[];
    var createdNewPlayer = false;
    for (final entry in statsByName.entries) {
      final existing = existingByName[entry.key];
      final stats = entry.value;
      final currentCheckpoint = (stats.totalSessions ~/ 10) * 10;
      final previousCheckpoint =
          existing?.bonusCheckpointSessions ??
          (stats.totalSessions < 10 ? 0 : currentCheckpoint);
      final unlockedBonusCount =
          ((currentCheckpoint - previousCheckpoint) ~/ 10).clamp(0, 9999);
      final bonusMinutes =
          (existing?.bonusMinutes ?? 0) +
          (unlockedBonusCount * settings.bonusGiftMinutes);
      final id = existing?.id ?? await _nextId('players');
      createdNewPlayer = createdNewPlayer || existing == null;
      final player = Player(
        id: id,
        name: existing?.name ?? stats.name,
        totalSessions: stats.totalSessions,
        totalSpent: stats.totalSpent,
        totalMinutesPlayed: stats.totalMinutesPlayed,
        bonusMinutes: bonusMinutes,
        bonusCheckpointSessions: unlockedBonusCount > 0
            ? currentCheckpoint
            : previousCheckpoint,
      );
      players.add(player);
      if (existing == null || !_samePlayerStats(existing, player)) {
        await _ref('players/${player.id}').set(_clean(player.toMap()));
      }
    }

    await _resetPlayerBonusesIfNeeded(players);

    if (createdNewPlayer && players.isNotEmpty) {
      final maxId = players
          .map((player) => player.id ?? 0)
          .reduce((value, element) => value > element ? value : element);
      await _setCounterAtLeast('players', maxId);
    }

    return players;
  }

  Future<void> _resetPlayerBonusesIfNeeded(List<Player> players) async {
    if (players.isEmpty) return;
    final flag = await _getMap('metadata/flags/player_bonus_reset_v1');
    if (flag != null && flag.isNotEmpty) return;

    final ranked = [...players]
      ..sort((a, b) {
        final sessionCompare = b.totalSessions.compareTo(a.totalSessions);
        return sessionCompare == 0
            ? b.totalSpent.compareTo(a.totalSpent)
            : sessionCompare;
      });
    final firstId = ranked.first.id;
    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final targetBonus = player.id == firstId ? 40 : 0;
      final targetCheckpoint = (player.totalSessions ~/ 10) * 10;
      if (player.bonusMinutes == targetBonus &&
          player.bonusCheckpointSessions == targetCheckpoint) {
        continue;
      }
      final updated = player.copyWith(
        bonusMinutes: targetBonus,
        bonusCheckpointSessions: targetCheckpoint,
      );
      players[i] = updated;
      await _ref('players/${updated.id}').set(_clean(updated.toMap()));
    }
    await _ref(
      'metadata/flags/player_bonus_reset_v1',
    ).set({'done': true, 'updated_at': DateTime.now().toIso8601String()});
  }

  String _playerKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _samePlayerStats(Player a, Player b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.totalSessions == b.totalSessions &&
        a.totalSpent == b.totalSpent &&
        a.totalMinutesPlayed == b.totalMinutesPlayed &&
        a.bonusMinutes == b.bonusMinutes &&
        a.bonusCheckpointSessions == b.bonusCheckpointSessions;
  }

  int _playedMinutesFor(Session session) {
    if (session.status == 'active') {
      return _calculateUsage(session, DateTime.now());
    }
    if (session.minutesUsed > 0) return session.minutesUsed;
    if (session.status == 'completed' || session.status == 'expired') {
      return session.totalMinutes;
    }
    return (session.totalMinutes - session.minutesRemaining)
        .clamp(0, session.totalMinutes)
        .toInt();
  }

  Future<void> _ensureFirebaseAuth() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInWithEmailAndPassword(
        email: 'admin@gmail.com',
        password: 'admin123',
      );
    } on firebase_auth.FirebaseAuthException {
      try {
        await _auth.createUserWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
      } on firebase_auth.FirebaseAuthException {
        // Enable Email/Password Authentication in Firebase Console if this
        // fails; public development database rules may still allow bootstraps.
      }
    }
  }

  Future<void> _seedSettingsIfNeeded() async {
    if (await _getMap('app_settings/1') != null) return;
    await updateAppSettings(
      const AppSettings(
        id: 1,
        basePrice: AppConstants.basePrice,
        baseMinutes: AppConstants.baseMinutes,
        ttsEnabled: true,
        voiceGender: 'female',
        bonusGiftMinutes: 40,
      ),
    );
  }

  Future<void> _seedUsersIfNeeded() async {
    final users = await getUsers();
    final now = DateTime.now().toIso8601String();
    final admin = users.where((user) => user.role == 'admin').firstOrNull;
    final manager = users.where((user) => user.role == 'manager').firstOrNull;

    if (admin == null) {
      await _ref('app_users/1').set(
        _clean(
          AppUser(
            id: 1,
            name: 'admin',
            email: 'admin@gmail.com',
            passwordHash: _hashPassword('admin'),
            role: 'admin',
            createdAt: now,
          ).toMap(),
        ),
      );
      await _setCounterAtLeast('app_users', 1);
    } else if (admin.email != 'admin@gmail.com' ||
        admin.passwordHash == 'admin') {
      await updateUser(
        admin.copyWith(
          email: 'admin@gmail.com',
          passwordHash: _hashPassword('admin'),
        ),
      );
    }

    if (manager == null) {
      await _ref('app_users/2').set(
        _clean(
          AppUser(
            id: 2,
            name: 'gestionnaire',
            email: 'manager',
            passwordHash: _hashPassword('manager123'),
            role: 'manager',
            createdAt: now,
          ).toMap(),
        ),
      );
      await _setCounterAtLeast('app_users', 2);
    }
  }

  Future<void> _seedEsp32NodesIfNeeded() async {
    final existing = await _getMap('esp32_devices');
    final now = DateTime.now().toIso8601String();
    const relayPins = [25, 26, 27, 32];
    for (var i = 0; i < relayPins.length; i++) {
      final stationId = i + 1;
      final key = 'station_$stationId';
      if (existing != null && existing.containsKey(key)) continue;
      await _ref('esp32_devices/$key').set({
        'station_id': stationId,
        'station_name': 'Poste $stationId',
        'relay_pin': relayPins[i],
        'led_pin': 2,
        'state': AppConstants.statusLibre,
        'command': 'idle',
        'last_seen_at': null,
        'updated_at': now,
      });
    }
  }

  Future<void> _syncEsp32StationState(int stationId, String status) async {
    final key = 'station_$stationId';
    await _ref('esp32_devices/$key').update({
      'station_id': stationId,
      'state': status,
      'command': status == AppConstants.statusOccupe ? 'power_on' : 'power_off',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _nextId(String collection) async {
    final counterRef = _ref('metadata/counters/$collection');
    final result = await counterRef.runTransaction((value) {
      final current = (value as num?)?.toInt() ?? 0;
      return Transaction.success(current + 1);
    });
    if (!result.committed) {
      throw StateError('Impossible de générer un identifiant pour $collection');
    }
    return (result.snapshot.value as num).toInt();
  }

  Future<void> _setCounterAtLeast(String collection, int value) async {
    final counterRef = _ref('metadata/counters/$collection');
    await counterRef.runTransaction((currentValue) {
      final current = (currentValue as num?)?.toInt() ?? 0;
      return Transaction.success(current < value ? value : current);
    });
  }

  Future<Map<String, Object?>?> _getMap(String path) async {
    final snapshot = await _ref(path).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return _normalizeMap(snapshot.value);
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, Object?> map) fromMap,
  ) async {
    final snapshot = await _ref(path).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final value = snapshot.value;
    if (value is Map) {
      return value.values
          .where((entry) => entry != null)
          .map(_normalizeMap)
          .map(fromMap)
          .toList();
    }
    if (value is List) {
      return value
          .where((entry) => entry != null)
          .map(_normalizeMap)
          .map(fromMap)
          .toList();
    }
    return [];
  }

  Map<String, Object?> _normalizeMap(Object? value) {
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), _normalizeValue(entry)),
      );
    }
    return <String, Object?>{};
  }

  Object? _normalizeValue(Object? value) {
    if (value is Map) return _normalizeMap(value);
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  Map<String, Object?> _clean(Map<String, Object?> map) {
    return {
      for (final entry in map.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }

  String _hashPasswordIfNeeded(String passwordOrHash) {
    if (passwordOrHash.startsWith('sha256:')) return passwordOrHash;
    return _hashPassword(passwordOrHash);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('gamezone:$password');
    return 'sha256:${sha256.convert(bytes)}';
  }

  int _calculateUsage(Session session, DateTime now) {
    final startedAt = DateTime.parse(session.startedAt);
    final elapsed = now.difference(startedAt).inMinutes + session.minutesUsed;
    return elapsed.clamp(0, session.totalMinutes).toInt();
  }

  bool _isActiveSessionExpired(Session session, DateTime now) {
    final startedAt = DateTime.tryParse(session.startedAt);
    if (startedAt == null) return false;
    final elapsedSeconds =
        now.difference(startedAt).inSeconds + (session.minutesUsed * 60);
    return elapsedSeconds >= session.totalMinutes * 60;
  }

  String _wearLevelFor(double hoursUsed, double maxHours) {
    if (maxHours <= 0) return 'bon';
    final ratio = hoursUsed / maxHours;
    if (ratio >= 0.95) return 'critique';
    if (ratio >= 0.75) return 'inspection';
    return 'bon';
  }
}

class _PlayerHistoryStats {
  _PlayerHistoryStats(this.name);

  final String name;
  int totalSessions = 0;
  double totalSpent = 0;
  int totalMinutesPlayed = 0;
}

extension on Sale {
  Sale copyWithId(int id) {
    return Sale(
      id: id,
      type: type,
      description: description,
      amount: amount,
      sessionId: sessionId,
      inventoryItemId: inventoryItemId,
      clientName: clientName,
      createdAt: createdAt,
    );
  }
}
