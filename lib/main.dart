import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sounds/sounds.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: AudioPlayer(),
            )));
  }
}

class AudioPlayer extends StatefulWidget {
  @override
  _AudioPlayerState createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  var _track = Track.fromAsset('assets/sample1.aac');
  var _player = SoundPlayer.noUI();
  var _recorder = SoundRecorder();
  var _isPlaying =
      false; // player.isPlaying is async, so this workaround will update widget state properly


  Future<void> _requestPermission(Permission permission) async {
    await permission.request();
  }

  Future<void> _saveRecording(String tempRecordingPath, String filename) async {
    await _requestPermission(Permission.storage);
    String dir = (await getExternalStorageDirectory()).path;
    String subDir = 'BestTakeRecordings';
    print('$dir');
    print('$dir/$subDir/$filename');
    await Directory('$dir/$subDir').create();
    await File(tempRecordingPath).copy('$dir/$subDir/$filename');
    await File(tempRecordingPath).delete();
  }


  void _play() {
    if (_player.isStopped) {
      _player = SoundPlayer.noUI();
    }
    if (_player.isPaused) {
      _player.resume();
    } else {
      _player.play(_track);
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

  void _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      var recording = Track.tempFile(WellKnownMediaFormats.adtsAac);
      var recTrack =
          Track.fromFile(recording, mediaFormat: WellKnownMediaFormats.adtsAac);

      _recorder.onStopped = ({wasUser}) {
        _recorder.release();
        _saveRecording(recording, 'test_recording.aac');

      };
      _recorder.record(recTrack);
    }
    else {
      await _requestPermission(Permission.microphone);
      _startRecording();
    }
  }

  void _stopRecording() {
    _recorder.stop();
  }

  Widget buildTimeStamp() {
    return Container(
        padding: const EdgeInsets.only(top: 80, bottom: 80),
        child: Center(
          child: Text(
            _player.currentPosition.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
            ),
          ),
        ));
  }

  Widget playerControls() {
    return Expanded(
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    _startRecording),
                _buildCircleButton(
                    Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black), () {
                  setState(() {
                    _isPlaying ? _pause() : _play();
                  });
                }),
                _buildCircleButton(
                    Icon(Icons.stop, color: Colors.black), _stop),
                _buildCircleButton(
                    Icon(Icons.stop, color: Colors.red), _stopRecording),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [buildTimeStamp(), playerControls()]);
  }

  Widget _buildCircleButton(Icon icon, Function onPressedAction) {
    return CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).accentColor,
        child: IconButton(
            splashColor: Theme.of(context).accentColor,
            highlightColor: Theme.of(context).accentColor,
            icon: icon,
            onPressed: onPressedAction));
  }
}

/*
class RecordingBrowser extends StatefulWidget {
  @override
  _RecordingBrowserState createState() => _RecordingBrowserState();
}

class _RecordingBrowserState extends State<RecordingBrowser> {

  Widget _buildRecordings() {
    return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemBuilder:  (context, i) {
          if (i.isOdd) return Divider();

          final index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
*/
