import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_event.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_state.dart';
import 'package:photoshrink/services/auth/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String TAG = 'AuthBloc';
  
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    
    LoggerUtil.i(TAG, 'AuthBloc initialized');

    // Listen for auth state changes from Firebase
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        LoggerUtil.i(TAG, 'Auth state changed: User authenticated (${_maskEmail(user.email)})');
        add(AuthCheckRequested()); // Check auth state to properly update UI
      } else {
        LoggerUtil.i(TAG, 'Auth state changed: User unauthenticated');
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Auth check requested');
    final user = _authService.currentUser;
    if (user != null) {
      LoggerUtil.i(TAG, 'Auth check: User is authenticated (${_maskEmail(user.email)})');
      emit(Authenticated(user));
    } else {
      LoggerUtil.i(TAG, 'Auth check: User is not authenticated');
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Sign in with email requested for ${_maskEmail(event.email)}');
    emit(AuthLoading());
    try {
      await _authService.signInWithEmail(event.email, event.password);
      // Don't emit Authenticated here - let the authStateChanges listener handle it
      LoggerUtil.i(TAG, 'Sign in with email successful for ${_maskEmail(event.email)}');
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      LoggerUtil.e(TAG, 'Sign in with email failed: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Sign up with email requested for ${_maskEmail(event.email)}');
    emit(AuthLoading());
    try {
      await _authService.signUpWithEmail(event.email, event.password);
      // Don't emit Authenticated here - let the authStateChanges listener handle it
      LoggerUtil.i(TAG, 'Sign up with email successful for ${_maskEmail(event.email)}');
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      LoggerUtil.e(TAG, 'Sign up with email failed: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Sign in with Google requested');
    emit(AuthLoading());
    try {
      // Comment or uncomment this based on whether you have Google Sign-In implemented
      //await _authService.signInWithGoogle();
      LoggerUtil.i(TAG, 'Google sign-in is not implemented yet');
      emit(AuthError('Google sign-in is not implemented yet'));
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      LoggerUtil.e(TAG, 'Sign in with Google failed: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Sign out requested');
    try {
      await _authService.signOut();
      LoggerUtil.i(TAG, 'Sign out successful');
      // The unauthenticated state will be emitted by the stream listener
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      LoggerUtil.e(TAG, 'Sign out failed: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    LoggerUtil.d(TAG, 'Password reset requested for ${_maskEmail(event.email)}');
    emit(AuthLoading());
    try {
      await _authService.resetPassword(event.email);
      LoggerUtil.i(TAG, 'Password reset email sent to ${_maskEmail(event.email)}');
      emit(PasswordResetSent());
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      LoggerUtil.e(TAG, 'Password reset failed: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'user-disabled':
          return 'This user has been disabled.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return 'An unknown error occurred.';
  }
  
  // Helper method to mask email addresses in logs for privacy
  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) {
      return '[email not provided]';
    }
    
    final parts = email.split('@');
    if (parts.length != 2) {
      return '[invalid email format]';
    }
    
    String username = parts[0];
    String domain = parts[1];
    
    // Show only first and last character of username
    if (username.length > 2) {
      username = '${username[0]}***${username[username.length - 1]}';
    } else {
      username = '***';
    }
    
    return '$username@$domain';
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    LoggerUtil.i(TAG, 'AuthBloc closed');
    return super.close();
  }
}