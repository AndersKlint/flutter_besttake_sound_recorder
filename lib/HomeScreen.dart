import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'SoundRecorderWidget.dart';
import 'recordingBrowser.dart';
import 'expansion_section.dart';

class HomeScreenWidget extends StatefulWidget {
  @override
  _HomeScreenWidgetState createState() => _HomeScreenWidgetState();
}

class _HomeScreenWidgetState extends State<HomeScreenWidget> {
  var showRecordingBrowser = false;

  void _toggleRecordingBrowser() {
    setState(() {
      showRecordingBrowser = !showRecordingBrowser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: SoundRecorderWidget(onToggleRecordingBrowser: () => _toggleRecordingBrowser(),),
            ),
            ExpandedSection( expand: showRecordingBrowser,
                child: Container(
                  child: AudioPlayerWidget(),
                )),
          ],
        ));
  }
}

