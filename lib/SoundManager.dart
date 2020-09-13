import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sounds/sounds.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SoundManager extends StatefulWidget {
  @override
  _SoundManagerState createState() => _SoundManagerState();

  Future<String> getDurationFromPath(String path) async {
      var track = Track.fromFile(path, mediaFormat: WellKnownMediaFormats.adtsAac);
      String duration;
      await track.duration.then((value) => duration = value.toString().substring(0,7));
      return duration;
  }

  Future<String> getRecordingDirectory() async {
    requestPermission(Permission.storage);
    String rootDir;
    if (Platform.isIOS) {
      rootDir = (await getApplicationDocumentsDirectory()).path;
    } else {
      rootDir = (await getExternalStorageDirectory()).path;
    }
    String dir = rootDir + '/BestTakeRecordings';

    if (await Permission.storage.request().isGranted) {
      if (await Directory(dir).exists()) {
        await Directory(dir).create();
        return Future.value(dir);
      }
    } else {
      Fluttertoast.showToast(
          msg:
              "Failed to save recording, permission denied to write to storage.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    return Future.value(null);
  }

  Future<void> requestPermission(Permission permission) async {
    await permission.request();
  }
}

class _SoundManagerState extends State<SoundManager> {
  var _track = Track.fromAsset('assets/sample1.aac');
  var _player = SoundPlayer.noUI();
  var _isPlaying =
      false; // player.isPlaying is async, so this workaround will update widget state properly

  var _recorder = SoundRecorder();

  Future<bool> _saveRecording(String tempRecordingPath, String filename) async {
    filename += '.aac';
    String dir;
    await SoundManager().getRecordingDirectory().then((value) => dir = value);
    if (dir != null) {
      String filepath = '$dir/$filename';
      await File(tempRecordingPath).copy(filepath);
      await File(tempRecordingPath).delete();
      print('Recording saved to: $filepath');
      return Future.value(true);
    }
    return Future.value(false);
  }

  String _saveRecordingAlert(String tempRecordingPath) {
    String _fieldRes = '';
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    final myController = TextEditingController();

    Alert(
        context: context,
        title: 'Save recording',
        content: Form(
          key: _formKey,
          child: TextFormField(
            validator: (value) {
              if (value.isEmpty) {
                return "please enter a filename";
              }
              return null;
            },
            onSaved: (value) {
              _fieldRes = value;
            },
            decoration:
                InputDecoration(icon: Icon(Icons.save), hintText: 'filename'),
            controller: myController,
          ),
        ),
        buttons: [
          DialogButton(
            onPressed: () => {Navigator.pop(context)},
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontSize: 20),
            ),
          ),
          DialogButton(
            onPressed: () async {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();

                var _response;
                await _saveRecording(tempRecordingPath, myController.text)
                    .then((value) => _response = value);
                if (_response) {
                  Navigator.pop(context, false);
                }
              }
            },
            child: Text(
              "Save",
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          )
        ]).show();

    // myController.dispose();
    return _fieldRes;
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
    _recorder = SoundRecorder();
    if (await Permission.microphone.request().isGranted) {
      var recording = Track.tempFile(WellKnownMediaFormats.adtsAac);
      var recTrack =
          Track.fromFile(recording, mediaFormat: WellKnownMediaFormats.adtsAac);

      _recorder.onStopped = ({wasUser}) {
        _saveRecordingAlert(recording);
        _recorder.release();
      };

      _recorder.record(recTrack);
    } else {
      await SoundManager().requestPermission(Permission.microphone);
      Fluttertoast.showToast(
          msg:
              "Failed to start recording: permission to access microphone denied.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleButton(Icon(Icons.fiber_manual_record, color: Colors.red),
            _startRecording),
        _buildCircleButton(
            Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black), () {
          setState(() {
            _isPlaying ? _pause() : _play();
          });
        }),
        _buildCircleButton(Icon(Icons.stop, color: Colors.black), _stop),
        _buildCircleButton(Icon(Icons.stop, color: Colors.red), _stopRecording),
      ],
    );
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
