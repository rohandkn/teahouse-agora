import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:teahouse/currRoom.dart';
import 'package:permission_handler/permission_handler.dart';



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

Map<String, List<String>> handleResponse(value){
  var decodedValue = jsonDecode(value);
  return {"roomNames":List<String>.from(decodedValue["roomLst"]),
    "roomIds":List<String>.from(decodedValue["roomUUIDLst"])};
}

Future<void> _handleMicPermission() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.microphone
  ].request();
}


roomClicked(roomId,roomName, context) async {
  await _handleMicPermission();
  if(await Permission.microphone.isGranted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>
          currRoom(currRoomId: roomId, currRoomName: roomName)),
    );
    print(roomId);
    print(roomName);
  }
}

class myRooms extends StatefulWidget {
  @override
  _myRoomsState createState() => _myRoomsState();
}

class _myRoomsState extends State<myRooms> {
  var roomResponse;
  var roomMap = [];
  var idMap = [];
  var userName = "Rohan";

  @override
  void initState() {
    // TODO: implement initState
    var bodyInp = {"userName":userName};
    roomResponse = sendRequest(bodyInp, "https://6mq03o1xyc.execute-api.us-east-1.amazonaws.com/main/getMyRooms");
    roomResponse.then((value) =>  setState(() {
      var res = handleResponse(value);
      roomMap = res["roomNames"];
      idMap = res["roomIds"];
    }));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text("teahouse"),
            ),
            body: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Center(
                  child: new Text(
                    "My Rooms",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                new GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3),
                    itemCount: roomMap.length,
                    itemBuilder: (context, index) {
                      return new InkWell(
                      onTap: () => roomClicked(idMap[index],roomMap[index],context),
                         child: new Container(
                        width: 10,
                        margin: const EdgeInsets.all(15),
                        padding: const EdgeInsets.all(8),
                        child: new Text(roomMap[index]),
                        color: Colors.teal[100],
                      ));
                    }),
                new Center(
                    child: new RaisedButton(
                        child: const Text('Create Room',
                            style:
                                TextStyle(fontSize: 20, color: Colors.black)),
                        onPressed: null))
              ],
            )));
  }
}
