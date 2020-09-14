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
  SoundManagerState createState() => SoundManagerState();

  Future<String> getDurationFromPath(String path) async {
    var track =
        Track.fromFile(path, mediaFormat: WellKnownMediaFormats.adtsAac);
    String duration;
    await track.duration
        .then((value) => duration = value.toString().substring(0, 7));
    return duration;
  }

  Future<String> getRecordingDirectory() async {
    requestPermission(Permission.storage);

    if (await Permission.storage.request().isGranted) {
      String rootDir;
      if (Platform.isIOS) {
        rootDir = (await getApplicationDocumentsDirectory()).path;
      } else {
        rootDir = (await getExternalStorageDirectory()).path;
      }
      String dir = rootDir + '/BestTakeRecordings';

      if (!(await Directory(dir).exists())) {
        await Directory(dir).create();
      }
      return Future.value(dir);
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

class SoundManagerState extends State<SoundManager> {
  var _recorder = SoundRecorder();
  var _isRecording = false;
  var _recordingInitialized = false;

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

  Future<void> _startRecording() async {
    if (_recorder.isPaused) {
      await _recorder.resume();
      setState(() {
        _isRecording = true;
      });
    } else {
      _recorder = SoundRecorder();
      if (await Permission.microphone.request().isGranted) {
        var recording = Track.tempFile(WellKnownMediaFormats.adtsAac);
        var recTrack = Track.fromFile(recording,
            mediaFormat: WellKnownMediaFormats.adtsAac);
        _recorder.onStopped = ({wasUser}) {
          _saveRecordingAlert(recording);
          _recorder.release();
          _recordingInitialized = false;
        };
        await _recorder.record(recTrack);
        _recordingInitialized = true;
        setState(() {
          _isRecording = true;
        });
      } else {
        await SoundManager().requestPermission(Permission.microphone);
        Fluttertoast.showToast(
            msg:
                "Failed to start recording: permission to access microphone denied.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
  }

  Future<void> _pauseRecording() async {
    if (_recorder.isRecording) {
      await _recorder.pause();
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder.isPaused) {
      // Can't stop recorder while paused
      await _recorder.resume();
    }
    await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Widget buildTimeStamp() {
    return Container(
        padding: const EdgeInsets.only(top: 80, bottom: 80),
        child: Center(
          child: Text(
            (_recorder.duration.toString().length > 6)
                ? _recorder.duration.toString().substring(0, 7)
                : '0:00:00',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
            ),
          ),
        ));
  }

  Widget _recordingIcon() {
    if (_isRecording) {
      return Icon(Icons.pause, color: Colors.black);
    } else if (_recordingInitialized) {
      return Icon(Icons.play_arrow, color: Colors.black);
    }
    return Icon(Icons.fiber_manual_record, color: Colors.red);
  }

  Widget playerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleButton(_recordingIcon(), () {
          _isRecording ? _pauseRecording() : _startRecording();
        }),
        _buildCircleButton(
            Icon(Icons.stop,
                color: _recordingInitialized
                    ? Colors.red
                    : Colors.red.withOpacity(0.5)),
            _recordingInitialized ? _stopRecording : null),
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
        backgroundColor: (onPressedAction == null)
            ? Theme.of(context).accentColor.withOpacity(0.5)
            : Theme.of(context).accentColor,
        child: IconButton(
            splashColor: Theme.of(context).accentColor,
            highlightColor: Theme.of(context).accentColor,
            icon: icon,
            onPressed: onPressedAction));
  }
}
