import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'myappbar.dart';
import 'dart:math';

class ProjectInput extends StatefulWidget {
  @override
  _ProjectInputState createState() => _ProjectInputState();
}

class _ProjectInputState extends State<ProjectInput> {
  /// Creates a [Page1Screen].
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller2 = TextEditingController();
  final FocusNode _focusNode2 = FocusNode();
  final TextEditingController _controller3 = TextEditingController();
  final FocusNode _focusNode3 = FocusNode();
  late Project myData;

  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);
  //stateful piece of information set to the output of the datepicker that i used.
  // ignore: avoid_init_to_null
  var dateInput = null;
  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _focusNode2.requestFocus();
      _focusNode3.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: MyAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: () async {
                      print(dateInput);
                      //dont submit or go to the next screen if the user hasnt entered anything.
                      if (_nameController.text == "" ||
                          _controller2.text == "" ||
                          dateInput == null ||
                          _controller3.text == "") {
                        return;
                      }
                      myData = await createProject(
                          _nameController.text,
                          pickerColor.value,
                          dateInput,
                          _controller2.text,
                          _controller3.text);
                      var plannedIndex = myData.projectIndex;
                      //go to the screen with the project that was just planned.
                      context.go('/generateSchedules/$plannedIndex');
                    },
                    child: Container(
                      width: (double.infinity),
                      height: 50,
                      color: Colors.amber,
                      child: const Center(
                          child: Text("Plan my Project",
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.center)),
                    ),
                  ),
                ),
                TextFormField(
                  focusNode: _focusNode,
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter project name',
                  ),
                ),
                DateTimePicker(
                  type: DateTimePickerType.date,
                  dateMask: 'd MMM, yyyy',
                  initialValue: DateTime.now().toString(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  icon: Icon(Icons.event),
                  dateLabelText: 'Date',
                  onChanged: (val) {
                    dateInput = val;
                  },
                  onSaved: (val) {
                    dateInput = val;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  focusNode: _focusNode2,
                  controller: _controller2,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Number of sessions to complete',
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  focusNode: _focusNode3,
                  controller: _controller3,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Approximate the number of hours to complete',
                  ),
                ),
                //scrollable box with random colors generated.
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: FractionallySizedBox(
                    widthFactor: .9,
                    child: Column(
                      children: [
                        Text("Set Project Color"),
                        MaterialPicker(
                          pickerColor: pickerColor,
                          onColorChanged: changeColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    _focusNode2.dispose();
    _controller2.dispose();
    _focusNode3.dispose();
    _controller3.dispose();
    super.dispose();
  }
}

Container colorCircle(Color c) {
  return Container(
    margin: const EdgeInsets.only(left: 20),
    width: 30,
    height: 30,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

ListView nCircles(n) {
  List<Widget> circleList = <Widget>[];
  for (int i = 0; i < n; i++) {
    // circleList.add(NCircles(numCircles: 100));
  }
  var list = ListView(
    scrollDirection: Axis.horizontal,
    children: circleList,
  );
  return list;
}

class Project {
  final String projectName;
  final int projectColor;
  final int numSessions;
  final int numHours;
  final String projectNotes;
  final String startDate;
  final String endDate;
  final int projectIndex;
  final List<dynamic> projectDays;

  const Project(
      {required this.projectName,
      required this.projectColor,
      required this.numSessions,
      required this.numHours,
      required this.projectNotes,
      required this.startDate,
      required this.endDate,
      required this.projectIndex,
      required this.projectDays});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectName: json['projectName'],
      projectColor: json['projectColor'],
      numSessions: json['numSessions'],
      numHours: json['numHours'],
      projectNotes: json['projectNotes'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      projectIndex: json['projectIndex'],
      projectDays: json['projectDays'],
    );
  }
}

class ProjectDay {
  final String eventName;
  final String timeDelta;
  final String date;

  const ProjectDay(
      {required this.eventName, required this.timeDelta, required this.date});

  factory ProjectDay.fromJson(Map<String, dynamic> json) {
    return ProjectDay(
      eventName: json['eventName'],
      timeDelta: json['timeDelta'],
      date: json['date'],
    );
  }
}

Future<Project> createProject(
    projectName, currentColor, projectDeadline, numSessions, numHours) async {
  final response = await http.post(
    Uri.parse('http://71.182.194.216:8080/planProject'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "projectName": "$projectName",
      "projectColor": "$currentColor",
      "projectDeadline": "$projectDeadline",
      "numSessions": "$numSessions",
      "numHours": "$numHours"
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
    return Project.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    print("wrong values or the algorithm on the backend is broken.");
    throw Exception('Failed to create project.');
  }
}
// // main list with data in it.
// //TODO this code is weird ill look at it later.
// FractionallySizedBox projectList(myData) {
//   List<Widget> projListItemList = <Widget>[];
//   return FractionallySizedBox(
//     widthFactor: 1,
//     child: Column(
//       children: [
//         projectFuture(myData, projListItemList),
//       ],
//     ),
//   );
// }

// //build the list at the bottom of the home screen and set the routes to be able to go into the per project view.
// FutureBuilder<String> projectFuture(myData, List<Widget> projListItemList) {
//   return FutureBuilder<String>(
//     future: myData,
//     builder: (context, snapshot) {
//       if (snapshot.hasData) {
//         String data = snapshot.data!;
//         final List<dynamic> projectNameList = jsonDecode(data);
//         for (var i = 0; i < projectNameList.length; i++) {
//           projListItemList.add(ProjListItem(
//             name: (projectNameList[i])['$i'].toString() + "$i",
//             route: "/showProject/$i", //NOTE2
//           ));

//           // print(projectNameList[i]);
//         }
//         return projectButtons(projListItemList);
//       } else if (snapshot.hasError) {
//         return Text('${snapshot.error}');
//       }

//       // By default, show a loading spinner.
//       return const CircularProgressIndicator();
//     },
//   );
// }

//a function to take an array of 7 ints and return a widget with horizontally sized boxes like this.
