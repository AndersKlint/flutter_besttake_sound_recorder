import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sounds/sounds.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:path/path.dart';

import 'SoundManager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Color(0xFF37474F),
          accentColor: Color(0xFFb3e5fc),
          scaffoldBackgroundColor: Color(0xFFF3F5F7),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: Text('Welcome to Flutter'),
            ),
            body: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: SoundManager(),
                ),
                Expanded(
                    child: Container(
                  child: RecordingBrowser(),
                )),
              ],
            )));
  }
}

class RecordingBrowser extends StatefulWidget {
  @override
  _RecordingBrowserState createState() => _RecordingBrowserState();
}

class _RecordingBrowserState extends State<RecordingBrowser> {
  final _biggerFont = TextStyle(fontSize: 18.0);
  var _track = Track.fromAsset('assets/sample1.aac');
  var _player = SoundPlayer.noUI();
  var _isPlaying =
  false; // player.isPlaying is async, so this workaround will update widget state properly


  @override
  Widget build(BuildContext context) {
    return _buildRecordings();
  }

  void loadTrack(String path) {
    _track = Track.fromFile(path, mediaFormat: WellKnownMediaFormats.adtsAac);
  }

  Future<List<FileSystemEntity>> _recordingDirContents() async {
    var dir;
    await SoundManager().getRecordingDirectory().then((value) => dir = value);
    var files = Directory.fromUri(Uri.parse(dir)).listSync();
    return files;
  }

  void _play() {
    if (_player.isStopped) {
      _player = SoundPlayer.noUI();
    }
    if (_player.isPaused) {
      _player.resume();
    } else {
      _player.play(_track);
      print(_track.path);
    }
    _isPlaying = true;
  }

  void _pause() {
    if (_isPlaying) {
      _player.pause();
      _isPlaying = false;
    }
  }

  void _stop() {
    _pause();
    _player.stop();
    _player.release();
    setState(() {
      // TODO
    });
  }

  Widget _buildRecordings() {
    return FutureBuilder(
        future: _recordingDirContents(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return new Text('loading...');
            default:
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              else
                return _createListView(context, snapshot);
          }
        });
  }

  Widget _createListView(BuildContext context, AsyncSnapshot snapshot) {
    List<FileSystemEntity> files = snapshot.data;
    return new ListView.builder(
      itemCount: files.length,
      itemBuilder: (BuildContext context, int index) {
        var file = files[index];
        return new Column(
          children: <Widget>[
            new ListTile(
                title: new Text(basename(file.path)),
                trailing: FutureBuilder(
                    future: SoundManager().getDurationFromPath(file.path),
                    initialData: "0:00:00",
                    builder:
                        (BuildContext context, AsyncSnapshot<String> text) {
                      return Text(text.data);
                    }),
             // onTap: () =>  SoundManagerState().loadTrack(file.path),
            ),
            new Divider(
              height: 2.0,
            ),
          ],
        );
      },
    );
  }
}
