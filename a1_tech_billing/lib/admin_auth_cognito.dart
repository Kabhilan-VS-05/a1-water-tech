part of 'main.dart';

class AdminCognitoStorage extends CognitoStorage {
  AdminCognitoStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<dynamic> getItem(String key) async {
    final String? raw = _prefs.getString(key);
    if (raw == null) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> setItem(String key, dynamic value) async {
    await _prefs.setString(key, jsonEncode(value));
    return getItem(key);
  }

  @override
  Future<dynamic> removeItem(String key) async {
    final dynamic existing = await getItem(key);
    await _prefs.remove(key);
    return existing;
  }

  @override
  Future<void> clear() async {
    final List<String> keys = _prefs
        .getKeys()
        .where((String key) => key.contains(kAdminCognitoClientId))
        .toList();
    for (final String key in keys) {
      await _prefs.remove(key);
    }
  }
}

class AdminIdentity {
  const AdminIdentity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.idToken,
  });

  final String uid;
  final String email;
  final String displayName;
  final String idToken;
}

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  late final CognitoUserPool _userPool = CognitoUserPool(
    kAdminCognitoUserPoolId,
    kAdminCognitoClientId,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userPool.storage = AdminCognitoStorage(prefs);
    _initialized = true;
  }

  Future<AdminIdentity?> restoreSession() async {
    await initialize();

    final CognitoUser? cognitoUser = await _userPool.getCurrentUser();
    if (cognitoUser == null) {
      return null;
    }

    final CognitoUserSession? session = await cognitoUser.getSession();
    if (session == null || !session.isValid()) {
      return null;
    }

    return _identityFromSession(cognitoUser, session);
  }

  Future<AdminIdentity> signIn({
    required String email,
    required String password,
  }) async {
    await initialize();

    final CognitoUser cognitoUser = CognitoUser(
      email.trim().toLowerCase(),
      _userPool,
      storage: _userPool.storage,
    );

    final AuthenticationDetails authDetails = AuthenticationDetails(
      username: email.trim().toLowerCase(),
      password: password,
    );

    final CognitoUserSession? session = await cognitoUser.authenticateUser(
      authDetails,
    );

    if (session == null || !session.isValid()) {
      throw Exception('Authentication failed. Please try again.');
    }

    return _identityFromSession(cognitoUser, session);
  }

  Future<void> signOut() async {
    await initialize();

    final CognitoUser? currentUser = await _userPool.getCurrentUser();
    if (currentUser != null) {
      await currentUser.signOut();
    }

    await _userPool.storage.clear();
  }

  AdminIdentity _identityFromSession(
    CognitoUser cognitoUser,
    CognitoUserSession session,
  ) {
    final Map<dynamic, dynamic> payload =
        session.getIdToken().payload as Map<dynamic, dynamic>? ??
        <dynamic, dynamic>{};
    final String email = _str(
      payload['email'],
      fallback: cognitoUser.username ?? '',
    ).toLowerCase();

    return AdminIdentity(
      uid: _str(payload['sub']),
      email: email,
      displayName: _str(
        payload['email'],
        fallback: cognitoUser.username ?? email,
      ),
      idToken: _str(session.getIdToken().getJwtToken()),
    );
  }
}

class AdminAccessRecord {
  const AdminAccessRecord({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory AdminAccessRecord.fromMap(Map<String, dynamic> data) {
    return AdminAccessRecord(
      id: _str(data['id']),
      email: _str(data['email']).toLowerCase(),
      displayName: _str(
        data['displayName'],
        fallback: _str(data['email'], fallback: 'Admin'),
      ),
    );
  }
}
