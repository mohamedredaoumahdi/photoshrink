import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_event.dart';
import 'package:photoshrink/presentation/bloc/auth/auth_state.dart';
import 'package:photoshrink/services/auth/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
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

    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmail(event.email, event.password);
      // The authenticated state will be emitted by the stream listener
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signUpWithEmail(event.email, event.password);
      // The authenticated state will be emitted by the stream listener
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      //await _authService.signInWithGoogle();
      // The authenticated state will be emitted by the stream listener
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      // The unauthenticated state will be emitted by the stream listener
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(event.email);
      emit(PasswordResetSent());
    } catch (e) {
      emit(AuthError(_getErrorMessage(e)));
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

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}