import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Compression',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VideoCompressionScreen(),
    );
  }
}

class VideoCompressionScreen extends StatefulWidget {
  @override
  _VideoCompressionScreenState createState() => _VideoCompressionScreenState();
}

class _VideoCompressionScreenState extends State<VideoCompressionScreen> {
  final ImagePicker picker = ImagePicker();
  File? _videoFile;
  bool _isCompressing = false;
  int? originalFileSize;
  int? compressedFileSize;
  String? compressedFilePath;

  @override
  Widget build(BuildContext context) {

    var mq = MediaQuery.of(context).size;
    void _showBottomSheet() {
      showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          builder: (_) {
            return ListView(
              shrinkWrap: true,
              padding:
              EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Pick Video"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: CircleBorder(),
                            fixedSize: Size(mq.width * .3, mq.height * .15)),
                        onPressed: () async {
                          _selectVideoFromCamera();
                        },
                        child: Image.asset("assets/images/camera.png")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: CircleBorder(),
                            fixedSize: Size(mq.width * .3, mq.height * .15)),
                        onPressed: () async {
                          _selectVideoFromGallery();
                        },
                        child: Image.asset("assets/images/gallery.png"))
                  ],
                )
              ],
            );
          });
    }
    Widget showDilaoge() {
      return AlertDialog(
        title: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Compression'),
        actions: [
          IconButton(onPressed: (){
            _showBottomSheet();

          }, icon: Icon(Icons.upload))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            SizedBox(height: 20),
            if (_videoFile != null) Text('Selected Video: ${_videoFile!.path}'),
            SizedBox(height: 20),
            if (originalFileSize != null)
              Text('Original File Size: ${originalFileSize!} bytes'),
            SizedBox(height: 20),
            _videoFile != null ?     ElevatedButton(
              onPressed:  compressVideo,
              child: _isCompressing ? showDilaoge() : Text('Compress Video'),
            ): Text("No Video Found"),
            SizedBox(height: 20),
            if (compressedFileSize != null)
              Text('Compressed File Size: ${compressedFileSize!} bytes'),
            SizedBox(height: 20),
            if (compressedFilePath != null)
              ElevatedButton(
                onPressed: downloadCompressedVideo,
                child: Text('Download Compressed Video'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectVideoFromGallery() async {
    final XFile? image =
    await picker.pickVideo(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _videoFile = File(image.path);
        originalFileSize = _videoFile!.lengthSync();
        compressedFileSize = null;
        compressedFilePath = null;
        _isCompressing = false;
      });
    }
  }

  Future<void> _selectVideoFromCamera() async {
    final XFile? image =
    await picker.pickVideo(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _videoFile = File(image.path);
        originalFileSize = _videoFile!.lengthSync();
        compressedFileSize = null;
        compressedFilePath = null;
        _isCompressing = false;
      });
    }
  }

  void compressVideo() async {
    if (_videoFile == null) {
      return; // No video selected, exit function
    }

    setState(() {
      _isCompressing = true;
    });

    Directory tempDir = await getTemporaryDirectory();
    String currentTime = DateTime.now().millisecondsSinceEpoch.toString();

    String outputPath = '${tempDir.path}/${currentTime}.mp4';
    String inputPath = _videoFile!.path;

    double maxTargetSizeInMB = 3.0;
    int originalSizeInBytes = originalFileSize!;
    int maxTargetSizeInBytes = (maxTargetSizeInMB * 1024 * 1024).toInt();
    print("This is maxTargetSizeInBytes $maxTargetSizeInBytes");
    double compressionRatio = maxTargetSizeInBytes / originalSizeInBytes;
    print("This is compressionRatio $compressionRatio");
    String ffmpegCommand =
        '-i $inputPath -vf "scale=iw/2:ih/2" -b:v ${compressionRatio.ceil()} -c:v mpeg4 -b:a 128k -c:a aac $outputPath';
    print("This is ffmpegCommand $ffmpegCommand");
    FFmpegKit.executeAsync(
      ffmpegCommand,
          (session) async {
        if (ReturnCode.isSuccess(await session.getReturnCode())) {
          print('Video compression successful');
          setState(() {
            File compressedVideo = File(outputPath);
            compressedFileSize = compressedVideo.lengthSync();
            compressedFilePath = outputPath;
            _isCompressing = false;
          });

          _videoFile
              ?.delete(); // Delete the original video file after compression
        } else {
          print('Video compression failed');
          setState(() {
            _isCompressing = false;
          });
        }
      },
    );
  }

  void downloadCompressedVideo() async {
    if (compressedFilePath != null) {
      String path = compressedFilePath!;
      if (await File(path).exists()) {
        OpenFile.open(path);
      } else {
        print('File does not exist');
      }
    }
  }
}
