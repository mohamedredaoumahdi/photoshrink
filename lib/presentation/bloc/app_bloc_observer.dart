import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/utils/logger_util.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    
    final blocName = bloc.runtimeType.toString();
    final eventName = event.toString();
    
    LoggerUtil.blocEvent(blocName, _formatEventName(eventName));
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    LoggerUtil.e(bloc.runtimeType.toString(), 'Error: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    
    final blocName = bloc.runtimeType.toString();
    final currentState = _formatStateName(change.currentState.toString());
    final nextState = _formatStateName(change.nextState.toString());
    
    LoggerUtil.blocState(blocName, currentState, nextState);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    
    // We already log state changes in onChange, so we can omit duplicate logging here
    // This helps reduce console clutter
  }
  
  // Helper to format file paths in state objects to make logs more readable
  String _formatStateName(String stateName) {
    // For complex states containing file paths (like in HomeLoadSuccess),
    // we truncate the paths to improve log readability
    final regex = RegExp(r'(/[^\s,\[\]]+)');
    return stateName.replaceAllMapped(regex, (match) {
      return LoggerUtil.truncatePath(match.group(0) ?? '');
    });
  }
  
  // Helper to format event names for better readability
  String _formatEventName(String eventName) {
    // Format image paths in events
    if (eventName.contains('ImageSelectionRequestedEvent') || 
        eventName.contains('ImagesSelectedEvent') ||
        eventName.contains('StartCompressionProcess')) {
      
      // If event has image paths, simplify by showing just the count
      if (eventName.contains('[') && eventName.contains(']')) {
        final pathsStart = eventName.indexOf('[');
        final pathsEnd = eventName.lastIndexOf(']');
        if (pathsStart > 0 && pathsEnd > pathsStart) {
          final paths = eventName.substring(pathsStart + 1, pathsEnd).split(',');
          final count = paths.length;
          final eventType = eventName.substring(0, pathsStart).trim();
          return '$eventType [${count} images]';
        }
      }
    }
    
    return eventName;
  }
}