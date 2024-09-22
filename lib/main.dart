import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()` can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera, create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  Future<void> takeAPicture() async {
    // Take the Picture in a try / catch block. If anything goes wrong, catch the error.
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      await _controller.setFlashMode(FlashMode.off);

      // Attempt to take a picture and get the file `image` where it was saved.
      final image = await _controller.takePicture();

      if (!context.mounted) return;

      // If the picture was taken, display it on a new screen.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            // Pass the automatically generated path to the DisplayPictureScreen widget.
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tirar Foto')),
      // You must wait until the controller is initialized before displaying the camera preview. Use a FutureBuilder to display a loading spinner until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: takeAPicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  const DisplayPictureScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreen(imagePath: imagePath);
}

// A widget that displays the picture taken by the user.
class _DisplayPictureScreen extends State<DisplayPictureScreen> {
  final String imagePath;

  _DisplayPictureScreen({required this.imagePath});

  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String questionAudioPath = '';
  String answerAudioPath = '';

  @override
  void initState() {
    audioRecord = Record();
    audioPlayer = AudioPlayer();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start(encoder: AudioEncoder.wav, numChannels: 1);
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error Start Recording : $e');
      }
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        questionAudioPath = path!;
      });
      await askAboutImage(XFile(imagePath), XFile(questionAudioPath));
    } catch (e) {
      if (kDebugMode) {
        print('Error Stopping Record : $e');
      }
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlScource = UrlSource(answerAudioPath);
      await audioPlayer.play(urlScource);
    } catch (e) {
      if (kDebugMode) {
        print('Error Playing Recording : $e');
      }
    }
  }

  Future<void> askAboutImage(XFile imageFile, XFile audioFile) async {
    String base64Image = await getBase64Image();
    String base64Audio = await getBase64QuestionAudio();
    // String endpoint = "http://192.168.3.27:9000/violet/ask";
    String endpoint = "https://tcc-violet-reactive.onrender.com/violet/ask";
    await askViolet(endpoint, base64Image, base64Audio: base64Audio);
  }

  Future<void> describeImage() async {
    String base64Image = await getBase64Image();
    // String endpoint = "http://192.168.3.27:9000/violet/describe";
    String endpoint = "https://tcc-violet-reactive.onrender.com/violet/describe";
    await askViolet(endpoint, base64Image);
  }

  Future<void> askViolet(String endpoint, String base64Image, {String base64Audio = ''}) async {
    showAlertDialog();
    try {
      http.Response response = await requestViolet(endpoint, base64Image, base64Audio: base64Audio);
      await playVioletResponse(response);
    } catch (e) {
      await playRecording();
    }
  }

  Future<String> getBase64Image() async {
    XFile imageFile = XFile(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<String> getBase64QuestionAudio() async {
    XFile audioFile = XFile(questionAudioPath);
    List<int> audioBytes = await audioFile.readAsBytes();
    String base64Audio = base64Encode(audioBytes);
    return base64Audio;
  }

  Future<http.Response> requestViolet(String endpoint, String base64Image, {String base64Audio = ''}) async {
    http.Response response = await http.post(
      Uri.parse(endpoint),
      body: jsonEncode({
        "image": base64Image,
        "audio": base64Audio,
      }),
      headers: { 'Content-type': 'application/json' },
    );
    return response;
  }

  Future<void> playVioletResponse(http.Response response) async {
    Navigator.pop(context);
    
    Uint8List bytes = base64Decode(response.body);
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    
    setState(() {
      answerAudioPath = '$appDocPath/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    });
    
    await File(answerAudioPath).writeAsBytes(bytes);
    await playRecording();
  }

  void showAlertDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // impedir fechar o diálogo clicando fora dele
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Aguarde...'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imagem Em Análise')),
      // The image is stored as a file on the device. Use the `Image.file` constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      floatingActionButton: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    if (isRecording)
                    const Text('Gravando...', style: TextStyle(fontSize: 20),),
                    ElevatedButton(
                      onPressed: isRecording ? stopRecording : startRecording,
                      child: isRecording ? const Text('Parar Gravação e Enviar Pergunta', style: TextStyle(fontSize: 13),) : answerAudioPath == '' ? const Text('Perguntar', style: TextStyle(fontSize: 13),) : const Text('Perguntar Novamente Para A Imagem Em Análise', style: TextStyle(fontSize: 13),),
                    ),
                  ]
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            if (!isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: describeImage,
                  child: const Text('Descrever Imagem', style: TextStyle(fontSize: 13),),
                ),
                if (answerAudioPath != '')
                const SizedBox(
                  width: 10,
                ),
                if (answerAudioPath != '')
                ElevatedButton(
                  onPressed: playRecording,
                  child: const Text('Ouvir Resposta Novamente', style: TextStyle(fontSize: 13),),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}