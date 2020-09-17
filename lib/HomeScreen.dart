import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:animated_background/animated_background.dart';

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
        //appBar: AppBar(
         // title: Text('Welcome to Flutter'),
        //),
        body: ParticleBackground(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: SingleChildScrollView(
                    child: SoundRecorderWidget(
                  onToggleRecordingBrowser: () => _toggleRecordingBrowser(),
                )),
              ),
              ExpandedSection(
                  expand: showRecordingBrowser,
                  child: Container(
                    child: AudioPlayerWidget(),
                  )),
            ],
          ),
        ));

  }
}

class ParticleBackground extends StatefulWidget{
  final Widget child;

  ParticleBackground({this.child});

  @override
  _ParticleBackgroundState createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with TickerProviderStateMixin {

  var particleOptions = ParticleOptions(
    baseColor: Colors.cyan,
    spawnOpacity: 0.0,
    opacityChangeRate: 0.4,
    minOpacity: 0.2,
    maxOpacity: 0.6,
    spawnMinSpeed: 30.0,
    spawnMaxSpeed: 70.0,
    spawnMinRadius: 7.0,
    spawnMaxRadius: 15.0,
    particleCount: 30,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      behaviour: RandomParticleBehaviour(options: particleOptions),
      vsync: this,
      child: widget.child,
    );
  }
}

