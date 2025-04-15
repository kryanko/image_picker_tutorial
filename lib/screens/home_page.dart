import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:image_picker_tutorial/utils/dialog_helper.dart';
import 'package:image_picker_tutorial/widgets/aspect_ratio_video.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final String? title;
  const HomePage({super.key, this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<XFile>? _mediaFileList;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController limitController = TextEditingController();

  Future<void> _playVideo(XFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;

      const double volume = kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    }
  }

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
    bool isMultiImage = false,
    bool isMedia = false,
  }) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    if (context.mounted) {
      if (isVideo) {
        final XFile? file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 10),
        );
        await _playVideo(file);
      } else if (isMultiImage || isMedia) {
        await displayPickImageDialog(
          context: context,
          isMulti: isMultiImage,
          maxWidthController: maxWidthController,
          maxHeightController: maxHeightController,
          qualitycontoller: qualityController,
          limitController: limitController,
          onPick: (
            double? maxWidth,
            double? maxHeight,
            int? quality,
            int? limit,
          ) async {
            try {
              final List<XFile> pickedFileList =
                  isMedia
                      ? await _picker.pickMultipleMedia(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                        imageQuality: quality,
                        limit: limit,
                      )
                      : await _picker.pickMultiImage(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                        imageQuality: quality,
                        limit: limit,
                      );
              setState(() {
                _mediaFileList = pickedFileList;
              });
            } catch (e) {
              setState(() {
                _pickImageError = e;
              });
            }
          },
        );
      } else {
        await displayPickImageDialog(
          context: context,
          isMulti: false,
          maxWidthController: maxWidthController,
          maxHeightController: maxHeightController,
          qualitycontoller: qualityController,
          limitController: limitController,
          onPick: (
            double? maxWidth,
            double? maxHeight,
            int? quality,
            int? limit,
          ) async {
            try {
              final XFile? pickedFile = await _picker.pickImage(
                source: source,
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: quality,
              );
              setState(() {
                _setImageFileListFromFile(pickedFile);
              });
            } catch (e) {
              setState(() {
                _pickImageError = e;
              });
            }
          },
        );
      }
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.video) {
        isVideo = true;
        await _playVideo(response.file);
      } else {
        isVideo = false;
        setState(() {
          if (response.files == null) {
            _setImageFileListFromFile(response.file);
          } else {
            _mediaFileList = response.files;
          }
        });
      }
    } else {
      _retrieveDataError = response.exception?.code;
    }
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Text? _getRetrieveErrorWidget() {
    if (_toBeDisposed != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return ListView.builder(
        key: UniqueKey(),
        itemCount: _mediaFileList!.length,
        itemBuilder: (BuildContext context, int index) {
          final String? mime = lookupMimeType(_mediaFileList![index].path);
          return kIsWeb
              ? Image.network(_mediaFileList![index].path)
              : (mime == null || mime.startsWith('image/')
                  ? Image.file(
                    File(_mediaFileList![index].path),
                    errorBuilder:
                        (_, __, ___) =>
                            const Center(child: Text('Unsupported image type')),
                  )
                  : _buildInlineVideoPlayer(index));
        },
      );
    } else if (_pickImageError != null) {
      return Text('Pick image error: $_pickImageError');
    } else {
      return const Text('You have not yet picked an image.');
    }
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return const Text('You have not yet picked a video.');
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AspectRatioVideo(_controller),
    );
  }

  Widget _handlePreview() {
    return isVideo ? _previewVideo() : _previewImages();
  }

  Widget _buildInlineVideoPlayer(int index) {
    final controller = VideoPlayerController.file(
      File(_mediaFileList![index].path),
    );
    controller.setVolume(kIsWeb ? 0.0 : 1.0);
    controller.initialize();
    controller.setLooping(true);
    controller.play();
    return Center(child: AspectRatioVideo(controller));
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        FloatingActionButton(
          onPressed: () {
            isVideo = false;
            _onImageButtonPressed(ImageSource.gallery, context: context);
          },
          tooltip: 'Pick Image from gallery',
          heroTag: 'image0',
          child: const Icon(Icons.photo),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            isVideo = false;
            _onImageButtonPressed(
              ImageSource.gallery,
              context: context,
              isMultiImage: true,
              isMedia: true,
            );
          },
          tooltip: 'Pick Multiple Media',
          heroTag: 'mediaMulti',
          child: const Icon(Icons.photo_library),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            isVideo = true;
            _onImageButtonPressed(ImageSource.gallery, context: context);
          },
          tooltip: 'Pick Video',
          heroTag: 'video',
          backgroundColor: Colors.red,
          child: const Icon(Icons.video_library),
        ),
        const SizedBox(height: 16),
        if (_picker.supportsImageSource(ImageSource.camera))
          FloatingActionButton(
            onPressed: () {
              isVideo = false;
              _onImageButtonPressed(ImageSource.camera, context: context);
            },
            tooltip: 'Take a Photo',
            heroTag: 'cameraImage',
            child: const Icon(Icons.camera_alt),
          ),
      ],
    );
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: Center(
        child:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? FutureBuilder<void>(
                  future: retrieveLostData(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<void> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return _handlePreview();
                    }
                    return const Text(
                      'You have not yet picked an image.',
                      textAlign: TextAlign.center,
                    );
                  },
                )
                : _handlePreview(),
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }
}
