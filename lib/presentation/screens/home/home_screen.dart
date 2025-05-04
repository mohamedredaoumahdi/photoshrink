import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photoshrink/core/constants/app_constants.dart';
import 'package:photoshrink/core/constants/route_constants.dart';
import 'package:photoshrink/di/dependency_injection.dart';
import 'package:photoshrink/presentation/bloc/home/home_bloc.dart';
import 'package:photoshrink/presentation/bloc/home/home_event.dart';
import 'package:photoshrink/presentation/bloc/home/home_state.dart';
import 'package:photoshrink/presentation/common_widgets/empty_state.dart';
import 'package:photoshrink/presentation/common_widgets/loading_indicator.dart';
import 'package:photoshrink/presentation/screens/home/widgets/image_thumbnail_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeBloc _homeBloc = getIt<HomeBloc>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _homeBloc.add(LoadSettingsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is NavigateToCompressionScreen) {
            Navigator.of(context).pushNamed(
              RouteConstants.compression,
              arguments: {
                'imagePaths': state.imagePaths,
                'quality': state.quality,
              },
            ).then((value) {
              // Refresh state when returning from compression screen
              if (value == true) {
                _homeBloc.add(LoadSettingsEvent());
              }
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppConstants.appName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_open),
                  tooltip: 'Open Archive',
                  onPressed: () {
                    _showOpenArchiveDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteConstants.settings);
                  },
                ),
              ],
            ),
            body: _buildBody(context, state),
            floatingActionButton: _buildFloatingActionButton(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is HomeInitial || state is HomeLoading) {
      return const LoadingIndicator();
    } else if (state is HomeLoadSuccess) {
      return Column(
        children: [
          // App description
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Share High-Quality Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select images to bundle into a single file without losing quality. Perfect for sharing through messaging apps like WhatsApp.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (state.selectedImagePaths.isNotEmpty)
                      Text(
                        '${state.selectedImagePaths.length} images selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: state.selectedImagePaths.isEmpty
                ? EmptyState(
                    icon: Icons.image,
                    title: 'No Images Selected',
                    message: 'Tap the button below to select images to archive with original quality.',
                    buttonLabel: 'Select Images',
                    onButtonPressed: () {
                      context.read<HomeBloc>().add(
                            const ImageSelectionRequestedEvent(),
                          );
                    },
                  )
                : ImageThumbnailGrid(
                    imagePaths: state.selectedImagePaths,
                    onRemove: (index) {
                      // Remove an image from the grid
                      final updatedImagePaths = List<String>.from(state.selectedImagePaths);
                      updatedImagePaths.removeAt(index);
                      context.read<HomeBloc>().add(
                            ImagesSelectedEvent(updatedImagePaths),
                          );
                    },
                  ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Text('Something went wrong. Please try again.'),
      );
    }
  }

  Widget _buildFloatingActionButton(BuildContext context, HomeState state) {
    if (state is HomeLoadSuccess) {
      return state.selectedImagePaths.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                context.read<HomeBloc>().add(
                      const ImageSelectionRequestedEvent(),
                    );
              },
              child: const Icon(Icons.add_photo_alternate),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_more',
                  onPressed: () {
                    context.read<HomeBloc>().add(
                          const ImageSelectionRequestedEvent(),
                        );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'archive',
                  onPressed: () {
                    context.read<HomeBloc>().add(StartCompressionEvent());
                  },
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Archive Images'),
                ),
              ],
            );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _showOpenArchiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Archive'),
        content: const Text(
          'To open an archive file (.phsrk), you need to select it from your file manager or receive it through a messaging app like WhatsApp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}