import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:convert';



class currRoom extends StatefulWidget {
  var currRoomId;
  var currRoomName;
  currRoom({Key key, @required this.currRoomId, @required this.currRoomName}) : super(key: key);

  @override
  _currRoomState createState() => _currRoomState();
}

Future<String> sendRequest(bodyInp, destination) async {
  var userName = "";
  var req = await http.post(destination,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(bodyInp)
  );
  return req.body;
}

List<String> handleParticipants(value){
  var decodedValue = jsonDecode(value);
  return List<String>.from(decodedValue["activeUsers"]);
}

void leaveCall(userName, roomId, context) async {
  await AgoraRtcEngine.leaveChannel();
  print("left agora");
  var bodyInp = {"userName":userName, "roomUUID":roomId};
  var leaveResponse = sendRequest(bodyInp, "https://6mq03o1xyc.execute-api.us-east-1.amazonaws.com/main/leaveCall");
  print("left response");
  leaveResponse.then((value) =>  {
  Navigator.pop(context)
  });
}

class _currRoomState extends State<currRoom> {
  var userName = "Rohan";
  var participantList = [];
  var volume = 25.0;
  bool muted = false;
  bool deafen = false;

  bool _isInChannel = false;
  final _infoStrings = <String>[];
  bool speakerEnabled = true;

  String dropdownValue = 'Off';

  /// remote user list
  final _remoteUsers = List<int>();


  @override
  void initState() {
    // TODO: implement initState
    _initAgoraRtcEngine();
    _addAgoraEventHandlers();

    var bodyInp = {"userName":userName, "roomUUID":widget.currRoomId};
    var callResponse = sendRequest(bodyInp, "https://6mq03o1xyc.execute-api.us-east-1.amazonaws.com/main/joinCall");
    callResponse.then((value) =>  setState(() {
      participantList = handleParticipants(value);
      _joinChannel(widget.currRoomId);
    }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var muteString = "Mute";
    if (muted == true){
      muteString = "Unmute";
    }
    var deafenString = "Deafen";
    if (deafen == true){
      deafenString = "Undeafen";
    }
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text("teahouse"),
            ),
            body: new ListView(
                children: [
                  new Center(
                    child: new Text(
                      widget.currRoomName,
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  new Center(
                    child: new Text(
                      "Active Participants",
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  new Container(
                    height: 300,
                      child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                    semanticChildCount: 4,
                    shrinkWrap: true,
                    itemCount: participantList.length,
                      itemBuilder: (context, index) {
                    return new Container(
                      width: 10,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      child: new Text(participantList[index]),
                      color: Colors.teal[100]
                    );
                  })),
                  new Slider(
                      value:volume,
                      min: 0.0,
                      max: 100.0,
                      onChanged:(newVal){setState(() {
                    volume = newVal;
                    AgoraRtcEngine.adjustPlaybackSignalVolume(volume.round());
                  });}),
                  new Center(child: RaisedButton(child: new Text(muteString),onPressed: () => setState(() {
                    muted = !muted;
                    AgoraRtcEngine.muteLocalAudioStream(muted);
                  }))),
                  new Center(child: RaisedButton(child: new Text(deafenString),onPressed: () => setState(() {
                    deafen = !deafen;
                    AgoraRtcEngine.muteAllRemoteAudioStreams(deafen);
                  }))),
                  new Center(child: RaisedButton(child: new Text("Leave"),onPressed: () => leaveCall(userName, widget.currRoomId, context)),),

                ])));
  }

  Future<void> _initAgoraRtcEngine() async {
    AgoraRtcEngine.create('ba4192246d73493fa287c5c948b43f84');

    AgoraRtcEngine.enableAudio();
    AgoraRtcEngine.setEnableSpeakerphone(true);
    // AgoraRtcEngine.setParameters('{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}');
    AgoraRtcEngine.setChannelProfile(ChannelProfile.Communication);
    AgoraRtcEngine.setAudioProfile(AudioProfile.SpeechStandard, AudioScenario.ChatRoomGaming);
    AgoraRtcEngine.adjustRecordingSignalVolume(50);

  }
  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onJoinChannelSuccess =
        (String channel, int uid, int elapsed) {
      setState(() {
        String info = 'onJoinChannel: ' + channel + ', uid: ' + uid.toString();
        _infoStrings.add(info);
        print(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _remoteUsers.clear();
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        String info = 'userJoined: ' + uid.toString();
        _infoStrings.add(info);
        _remoteUsers.add(uid);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        String info = 'userOffline: ' + uid.toString();
        _infoStrings.add(info);
        _remoteUsers.remove(uid);
      });
    };
  }
  void _joinChannel(roomUIUD) async {
    await AgoraRtcEngine.joinChannel(null, roomUIUD, null, 0);
  }


}
