import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'env.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ArtLine',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoaderOverlay(
          useDefaultLoading: true,
          child: MyHomePage(title: 'ArtLine'),
        ));
  }
}

enum Stage {
  Picking,
  Picked,
  Transforming,
  Transformed,
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Stage _stage = Stage.Picking;
  File _sourceImage;
  File _transformedImage;
  final picker = ImagePicker();

  Future getImage(ImageSource source) async {
    if (_stage != Stage.Picking && _stage != Stage.Transformed) {
      print('Previous process is not completed');
      return;
    }
    setState(() => _stage = Stage.Picking);
    final pickedFile = await picker.getImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _sourceImage = File(pickedFile.path);
        _stage = Stage.Picked;

        transform();
      } else {
        print('No image selected.');
      }
    });
  }

  Future transform() async {
    if (_stage != Stage.Picked) {
      print('Pick an image first');
      return;
    }
    setState(() => _stage = Stage.Transforming);
    // Optimize image and upload to server.
    try {
      context.showLoaderOverlay();

      final outputFile = await compressAndUploadImage(_sourceImage);
      if (_transformedImage != null) {
        await _transformedImage.delete();
      }
      setState(() {
        _transformedImage = outputFile;
        _stage = Stage.Transformed;
      });
    } catch (error) {
      print('Cannot transform due to $error');
      setState(() => _stage = Stage.Picking);
    } finally {
      context.hideLoaderOverlay();
    }
  }

  Future<File> compressAndUploadImage(File sourceImage) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      sourceImage.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 90,
    );
    final payload = base64.encode(compressed);
    final response = await http.post(transformApiUrl,
        headers: {}, body: payload, encoding: Encoding.getByName('utf-8'));
    if (response.statusCode != 200) {
      throw new Exception('Server error ${response.statusCode}');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final serial = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final outputFile = File('${appDir.path}/$serial.jpg');
    final decoded =
        base64.decode(base64.normalize(response.body.replaceAll('\n', '')));
    await outputFile.writeAsBytes(decoded);
    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _stage == Stage.Transformed
                ? Image.file(_transformedImage)
                : _sourceImage != null
                    ? Image.file(_sourceImage)
                    : Text("Please pick an image :)")
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                getImage(ImageSource.gallery);
              },
              tooltip: 'Gallery',
              child: Icon(Icons.photo_album),
            ),
            FloatingActionButton(
              onPressed: () {
                getImage(ImageSource.camera);
              },
              tooltip: 'Camera',
              child: Icon(Icons.photo_camera),
            ),
          ],
        ),
      ),
    );
  }
}
