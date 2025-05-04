import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoshrink/core/utils/logger_util.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class for picking directories on the device
class DirectoryPicker {
  static const String TAG = 'DirectoryPicker';

  /// Show a directory picker dialog and return the selected directory path
  static Future<String?> showDirectoryPicker(BuildContext context) async {
    LoggerUtil.d(TAG, 'Showing directory picker');
    
    // Check storage permission based on Android API level
    bool hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      LoggerUtil.w(TAG, 'Storage permission denied');
      _showPermissionDeniedDialog(context);
      return null;
    }
    
    try {
      // Get available directories
      final List<Directory> directories = await _getAvailableDirectories();
      LoggerUtil.d(TAG, 'Found ${directories.length} available directories');
      
      // Show directory selection dialog
      return await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return _DirectorySelectionDialog(directories: directories);
        },
      );
    } catch (e) {
      LoggerUtil.e(TAG, 'Error showing directory picker: $e');
      return null;
    }
  }
  
  /// Check appropriate storage permissions based on platform and Android API level
  static Future<bool> _checkStoragePermission() async {
    if (Platform.isIOS) {
      // iOS doesn't need explicit permissions for the directories we're using
      return true;
    }
    
    // For Android, check the API level
    if (Platform.isAndroid) {
      // Get Android SDK version
      final sdkInt = await _getAndroidSdkVersion();
      LoggerUtil.d(TAG, 'Android SDK Version: $sdkInt');
      
      if (sdkInt >= 33) {
        // Android 13+ uses Photos & Media permission
        final status = await Permission.photos.status;
        if (status.isGranted) return true;
        
        LoggerUtil.d(TAG, 'Requesting photos permission for Android 13+');
        final result = await Permission.photos.request();
        return result.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11-12 uses Manage External Storage permission
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;
        
        LoggerUtil.d(TAG, 'Requesting manage external storage permission for Android 11+');
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else {
        // Android 10 and below use Storage permission
        final status = await Permission.storage.status;
        if (status.isGranted) return true;
        
        LoggerUtil.d(TAG, 'Requesting storage permission for Android 10 and below');
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    }
    
    return false;
  }
  
  /// Get the Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    try {
      if (!Platform.isAndroid) return 0;
      
      // Default to a reasonably recent Android version if we can't determine
      return 30; // Android 11
    } catch (e) {
      LoggerUtil.e(TAG, 'Error getting Android SDK version: $e');
      return 30; // Default to Android 11
    }
  }
  
  /// Get available directories for storage
  static Future<List<Directory>> _getAvailableDirectories() async {
    final List<Directory> directories = [];
    
    try {
      // App documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      directories.add(appDocDir);
      LoggerUtil.d(TAG, 'Added app documents directory: ${appDocDir.path}');
      
      // External storage directory (Android only)
      if (Platform.isAndroid) {
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null) {
          directories.addAll(externalDirs);
          for (final dir in externalDirs) {
            LoggerUtil.d(TAG, 'Added external directory: ${dir.path}');
          }
        }
      }
      
      // Downloads directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        directories.add(downloadsDir);
        LoggerUtil.d(TAG, 'Added downloads directory: ${downloadsDir.path}');
      }
      
      // Temporary directory
      final tempDir = await getTemporaryDirectory();
      directories.add(tempDir);
      LoggerUtil.d(TAG, 'Added temporary directory: ${tempDir.path}');
      
      // Application support directory
      if (Platform.isIOS) {
        final appSupportDir = await getApplicationSupportDirectory();
        directories.add(appSupportDir);
        LoggerUtil.d(TAG, 'Added application support directory: ${appSupportDir.path}');
      }
      
    } catch (e) {
      LoggerUtil.e(TAG, 'Error getting available directories: $e');
    }
    
    return directories;
  }
  
  /// Show a dialog when permission is denied
  static void _showPermissionDeniedDialog(BuildContext context) {
    String permissionName = Platform.isAndroid 
        ? (Platform.version.contains('Android 13') ? 'Photos & Media' : 'Storage') 
        : 'Photos';
        
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName Permission Required'),
          content: Text(
            'PhotoShrink needs $permissionName permission to save compressed images. '
            'Please grant this permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}

/// A dialog for selecting a directory
class _DirectorySelectionDialog extends StatelessWidget {
  final List<Directory> directories;
  
  const _DirectorySelectionDialog({
    Key? key,
    required this.directories,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Storage Location'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: directories.length + 1, // +1 for default option
          itemBuilder: (context, index) {
            if (index == 0) {
              // Default option
              return ListTile(
                leading: const Icon(Icons.folder_special),
                title: const Text('Default Location'),
                subtitle: const Text('App\'s default storage location'),
                onTap: () {
                  LoggerUtil.d('DirectoryPicker', 'Selected default location');
                  Navigator.of(context).pop('');
                },
              );
            } else {
              // Directory options
              final directory = directories[index - 1];
              final dirName = _getDirectoryName(directory.path);
              
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(dirName),
                subtitle: Text(
                  directory.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  LoggerUtil.d('DirectoryPicker', 'Selected directory: ${directory.path}');
                  Navigator.of(context).pop(directory.path);
                },
              );
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
  
  /// Get a user-friendly directory name from a path
  String _getDirectoryName(String path) {
    final segments = path.split('/');
    final lastSegment = segments.last;
    
    // If last segment is empty, use the one before
    if (lastSegment.isEmpty && segments.length > 1) {
      return segments[segments.length - 2];
    }
    
    // Decode special directories
    switch (lastSegment) {
      case 'Documents':
        return 'Documents';
      case 'Downloads':
        return 'Downloads';
      case 'Pictures':
        return 'Pictures';
      case 'DCIM':
        return 'Camera';
      case 'tmp':
        return 'Temporary';
      default:
        return lastSegment;
    }
  }
}