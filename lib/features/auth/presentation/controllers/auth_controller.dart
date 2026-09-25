import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/user_model.dart';
import '../../../../repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isOfflineSimulated;
  final bool rememberMe;
  final String? savedEmail;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isOfflineSimulated = false,
    this.rememberMe = true,
    this.savedEmail,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isOfflineSimulated,
    bool? rememberMe,
    String? savedEmail,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOfflineSimulated: isOfflineSimulated ?? this.isOfflineSimulated,
      rememberMe: rememberMe ?? this.rememberMe,
      savedEmail: savedEmail ?? this.savedEmail,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState()) {
    initSession();
  }

  Future<void> initSession() async {
    try {
      final savedUser = await _authRepository.getSavedSession();
      final savedEmail = await _authRepository.getSavedEmail();
      state = state.copyWith(
        user: savedUser,
        savedEmail: savedEmail,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  Future<bool> login(String email, String password, {bool? rememberMe}) async {
    final shouldRemember = rememberMe ?? state.rememberMe;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.login(
        email,
        password,
        rememberMe: shouldRemember,
      );
      state = state.copyWith(
        isLoading: false,
        user: user,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> loginWithDemo(UserRole role, {bool isFreshOwner = false}) async {
    String email;
    if (role == UserRole.owner && isFreshOwner) {
      email = 'newowner@test.com';
    } else {
      switch (role) {
        case UserRole.owner:
          email = AppConstants.ownerEmail;
          break;
        case UserRole.officer:
          email = AppConstants.officerEmail;
          break;
        case UserRole.gatc:
          email = AppConstants.gatcEmail;
          break;
        case UserRole.admin:
          email = AppConstants.adminEmail;
          break;
        case UserRole.public:
          return true;
      }
    }
    return login(email, AppConstants.demoPassword);
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = state.copyWith(clearUser: true, clearError: true);
  }

  void toggleSimulateOffline() {
    final next = !state.isOfflineSimulated;
    _authRepository.toggleSimulateOffline(next);
    state = state.copyWith(isOfflineSimulated: next);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});
