import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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
                  child: AudioPlayerWidget(),
                )),
              ],
            )));
  }
}

class AudioPlayerWidget extends StatefulWidget {
  Future<String> getDurationFromPath(String path) async {
    var track =
        Track.fromFile(path, mediaFormat: WellKnownMediaFormats.adtsAac);
    return getDuration(track);
  }

  Future<String> getDuration(Track track) async {
    if (track == null) {
      return '00:00';
    }
    String duration;
    await track.duration
        .then((value) => duration = value.toString().substring(2, 7));
    return duration;
  }

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  double _currentSliderValue = 0;
  var _track; //Track.fromAsset('assets/sample1.aac');
  var _player = SoundPlayer.noUI(playInBackground: true);
  var _isPlaying = false;

  @override
  void initState() {
    // For some reason state doesn't get updated when _player.isPlaying() is
    // used. This workaround fixes this issue.
    _player.onStopped = ({wasUser}) => setState(() {
          _isPlaying = false;
        });
    _player.onResumed = ({wasUser}) => setState(() {
          _isPlaying = true;
        });
    _player.onPaused = ({wasUser}) => setState(() {
          _isPlaying = false;
        });
    _player.onStarted = ({wasUser}) => setState(() {
          _isPlaying = true;
        });
    super.initState();
  }

  void loadTrack(String path) {
    _stop();
    _track = Track.fromFile(path, mediaFormat: WellKnownMediaFormats.adtsAac);
    _play();
  }

  Future<void> _play() async {
    if (_player.isPaused) {
      await _player.resume();
    } else {
      await _player.play(_track);
    }
  }

  Future<void> _pause() async {
    if (_player.isPlaying) {
      await _player.pause();
    }
  }

  Future<void> _stop() async {
    if (_player.isPlaying) {
      _player.stop();
    }
  }

  @override
  void dispose() {
    _player.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildAudioPlayer(),
      RecordingBrowser(
        onLoadTrack: (String path) => loadTrack(path),
      )
    ]);
  }

  Widget _buildAudioPlayer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Colors.cyan, //Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
            // bottomLeft: Radius.circular(36),
            // bottomRight: Radius.circular(36),
          )),
      child: Container(
        padding: EdgeInsets.only(right: 20, left: 5),
        child: Row(
          children: [
            _isPlaying
                ? IconButton(
                    icon: new Icon(Icons.pause, color: Colors.white),
                    splashRadius: 20.0,
                    onPressed: _pause)
                : IconButton(
                    icon: new Icon(Icons.play_arrow, color: Colors.white),
                    splashRadius: 20.0,
                    onPressed: _play),
            StreamBuilder<PlaybackDisposition>(
                stream: _player.dispositionStream(),
                builder: (BuildContext context,
                    AsyncSnapshot<PlaybackDisposition> snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data.position.toString().substring(2, 7),
                    );
                  } else {
                    return Text('00:00');
                  }
                }),
            Expanded(child: _seekBarWidget()),
            FutureBuilder(
                future: widget.getDuration(_track),
                initialData: "00:00",
                builder: (BuildContext context, AsyncSnapshot<String> text) {
                  return text == null ? Text('00:00') : Text(text.data);
                }),
          ],
        ),
      ),
    );
  }

  Widget _seekBarWidget() {
    return StreamBuilder<PlaybackDisposition>(
        stream: _player.dispositionStream(),
        builder: (BuildContext context,
            AsyncSnapshot<PlaybackDisposition> snapshot) {
          if (snapshot.hasData) {
            return Slider(
                value: snapshot.data.position.inSeconds.toDouble(),
                min: 0,
                max: snapshot.data.duration.inSeconds.toDouble(),
                );
          } else {
            return Slider(value: 0);
            ;
          }
        });
  }
}

class RecordingBrowser extends StatefulWidget {
  final Function(String) onLoadTrack;

  RecordingBrowser({@required this.onLoadTrack});

  @override
  _RecordingBrowserState createState() => _RecordingBrowserState();
}

class _RecordingBrowserState extends State<RecordingBrowser> {
  final _biggerFont = TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return _buildRecordings();
  }

  Future<List<FileSystemEntity>> _recordingDirContents() async {
    var dir;
    await SoundManager().getRecordingDirectory().then((value) => dir = value);
    var files = Directory.fromUri(Uri.parse(dir)).listSync();
    return files;
  }

  Widget _buildRecordings() {
    return FutureBuilder(
        future: _recordingDirContents(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return _createListView(context, snapshot);
        });
  }

  Widget _createListView(BuildContext context, AsyncSnapshot snapshot) {
    List<FileSystemEntity> files = snapshot.data;
    return Expanded(
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).accentColor,
              //borderRadius: BorderRadius.only(
              //  topLeft: Radius.circular(36),
              // topRight: Radius.circular(36))
            ),
            child: new ListView.builder(
              itemCount: files.length,
              itemBuilder: (BuildContext context, int index) {
                var file = files[index];
                return new Column(
                  children: <Widget>[
                    new ListTile(
                      title: new Text(basename(file.path)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: new Icon(Icons.play_arrow, color: Colors.black),
                          onPressed: () {
                            widget.onLoadTrack(file.path);
                          },
                        ),
                        SizedBox(width: 10),
                        FutureBuilder(
                            future: AudioPlayerWidget()
                                .getDurationFromPath(file.path),
                            initialData: "0:00:00",
                            builder: (BuildContext context,
                                AsyncSnapshot<String> text) {
                              return Text(text.data);
                            }),
                      ]),
                    ),
                    new Divider(
                      height: 2.0,
                    ),
                  ],
                );
              },
            )));
  }
}
