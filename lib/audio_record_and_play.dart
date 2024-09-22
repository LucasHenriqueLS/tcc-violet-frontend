// // import 'package:flutter/material.dart';
// // import 'package:camera/camera.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// // class MinhaTela extends StatefulWidget {
// //   @override
// //   _MinhaTelaState createState() => _MinhaTelaState();
// // }

// // class _MinhaTelaState extends State<MinhaTela> {
// //   late CameraController _controller;
// //   late Future<void> _initializeControllerFuture;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Inicializando a câmera
// //     _controller = CameraController(cameras[0], ResolutionPreset.medium);
// //     _initializeControllerFuture = _controller.initialize();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Tirar Foto'),
// //       ),
// //       body: FutureBuilder<void>(
// //         future: _initializeControllerFuture,
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.done) {
// //             return CameraPreview(_controller);
// //           } else {
// //             return Center(child: CircularProgressIndicator());
// //           }
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         child: Icon(Icons.camera_alt),
// //         onPressed: () async {
// //           try {
// //             await _initializeControllerFuture;
// //             // Tirar a foto
// //             XFile imageFile = await _controller.takePicture();
// //             // Enviar a foto para o endpoint
// //             enviarFotoParaEndpoint(imageFile);
// //           } catch (e) {
// //             print("Erro ao tirar foto: $e");
// //           }
// //         },
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }
// // }




// // Future<void> enviarFotoParaEndpoint(XFile imageFile) async {
// //   // Lendo o arquivo da foto
// //   List<int> imageBytes = await imageFile.readAsBytes();

// //   // Codificando a foto em base64
// //   String base64Image = base64Encode(imageBytes);

// //   // Defina o seu endpoint
// //   String endpoint = "http://seu_endpoint.com";

// //   // Enviando a foto para o endpoint
// //   try {
// //     http.Response response = await http.post(
// //       Uri.parse(endpoint),
// //       body: {
// //         "image": base64Image,
// //       },
// //     );
    
// //     // Aqui você pode lidar com a resposta da requisição
// //     print("Resposta do servidor: ${response.statusCode}");
// //   } catch (e) {
// //     print("Erro ao enviar a foto para o servidor: $e");
// //   }
// // }



// Future<http.Response> fetchAlbum() {
//   return http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
// }

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';

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
        await audioRecord.start();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('Error Start Recording : $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print('Error Stopping Record : $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlScource = UrlSource(audioPath);
      await audioPlayer.play(urlScource);
    } catch (e) {
      print('Error Playing Recording : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isRecording)
            const Text('Recording in Progress', style: TextStyle(fontSize: 20),),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: isRecording ? const Text('Stop Recording') : const Text('Start Recording'),
            ),
            const SizedBox(
              height: 25,
            ),
            if (!isRecording)
            ElevatedButton(
              onPressed: playRecording,
              child: const Text('Play Recording'),
            ),
          ],
        ),
      ),
    );
  }
}