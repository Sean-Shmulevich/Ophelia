import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'inputProject.dart';
import 'weekView.dart';
import 'settings.dart';
import "generateSchedules.dart";
import 'myappbar.dart';
import 'showProject.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:collection';

void main() {
  runApp(const MyApp());
}

//RPC routing instead of REST
//REST: is resource oriented routes
// Returning data is in JSON format and requests we are using are PUT, DELETE, POST, and GET
//RPC: is functional routes very data-centric
//it consists of allowing client code to call a piece of server code as if it was local.
//I chose this because it will make the routing less nested.

//How to routes get resources? from the user object reference
//make it accessible to all paths somehow?
//the issue with this is that all the data is in the app at once some of it should be on the server.
//all paths have the user ID
//they send fetch requests to the server with their current path
final GoRouter _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          MyHomePage(title: 'Flutter Demo Page', refresh: false),
      routes: <GoRoute>[
        GoRoute(
          path: 'projectInput',
          builder: (BuildContext context, GoRouterState state) =>
              ProjectInput(),
        ),
        GoRoute(
          path: 'refresh',
          builder: (BuildContext context, GoRouterState state) => MyHomePage(
            title: 'Flutter Demo Page',
            refresh: true,
          ),
        ),
        GoRoute(
          path: 'generateSchedules/:id',
          builder: (BuildContext context, GoRouterState state) =>
              GenerateSchedules(
            id: state.params['id']!,
          ),
        ),
        GoRoute(
          path: 'weekView',
          builder: (BuildContext context, GoRouterState state) =>
              const WeekView(),
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) =>
              const Settings(title: "hello world"),
        ),
        GoRoute(
          path: 'showProject/:id',
          builder: (BuildContext context, GoRouterState state) => ShowProject(
            id: state.params['id']!,
          ),
        ),
      ],
    ),
  ],
);

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
)..addAll(_kEventSource);

final _kEventSource = Map.fromIterable(List.generate(50, (index) => index),
    key: (item) => DateTime.utc(kFirstDay.year, kFirstDay.month, item * 5),
    value: (item) => List.generate(
        item % 4 + 1, (index) => Event('Event $item | ${index + 1}')))
  ..addAll({
    kToday: [
      Event('Today\'s Event 1'),
      Event('Today\'s Event 2'),
    ],
  });

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Page'),
    );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title, required this.refresh});

  final String title;
  final bool refresh;
  // final myData = fetchNames();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late Future<String> myData = fetchNames();

  @override
  void initState() {
    myData = fetchNames(); //NOTE4
    // projectList = projectList(myData, true);
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    if (widget.refresh) {}
  }

  List<Event> _getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

  @override
  void dispose() {
    print("FirstRoute: dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    myData = fetchNames();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.blue[600],
      resizeToAvoidBottomInset: false,
      appBar: MyAppBar(),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              Container(
                color: Colors.blue[200],
                padding: const EdgeInsets.all(10),
                child: const Text(
                  textAlign: TextAlign.center,
                  "Welcome user you have 5 projects scheduled for this week",
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 0),
                color: Colors.blue[100],
                child: TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  selectedDayPredicate: (day) {
                    // Use `selectedDayPredicate` to determine which day is currently selected.
                    // If this returns true, then `day` will be marked as selected.

                    // Using `isSameDay` is recommended to disregard
                    // the time-part of compared DateTime objects.
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      // Call `setState()` when updating the selected day
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _selectedEvents.value = _getEventsForDay(selectedDay);
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      // Call `setState()` when updating calendar format
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    // No need to call `setState()` here
                    _focusedDay = focusedDay;
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/weekview');
                },
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft),
                child: Container(
                  //this makes the width expand.
                  height: 33,
                  margin: const EdgeInsets.only(bottom: 70, top: 0),

                  alignment: Alignment.center,
                  color: Colors.blue[300],

                  // we can set width here with conditions
                  // var height = MediaQuery.of(context).viewPadding.top;
                  child: const Text(
                    'Week View',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              //optional makes the calender more to the top of the screen Spacer(),
              Container(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: projectList(myData, true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
    projectList() - Project Container positioned to bottom of the screen
    Container with a list view of list items inside of it.
  */
  Future<String> fetchNames() async {
    print("here");
    final response = await http
        .get(Uri.parse('http://71.182.194.216:8080/getProjectNames')); //NOTE3

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return ((response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      // throw Exception('Failed to load album');
      return '{API not connected probably}';
    }
  }

  // main list with data in it.
  //TODO this code is weird ill look at it later.
  FractionallySizedBox projectList(myData, refresh) {
    List<Widget> projListItemList = <Widget>[];
    if (refresh) {
      projListItemList = <Widget>[];
    }
    return FractionallySizedBox(
      widthFactor: 1,
      child: Column(
        children: [
          projectFuture(myData, projListItemList),
        ],
      ),
    );
  }

  //build the list at the bottom of the home screen and set the routes to be able to go into the per project view.
  FutureBuilder<String> projectFuture(myData, List<Widget> projListItemList) {
    return FutureBuilder<String>(
      future: myData,
      builder: (context, snapshot) {
        //empty the previos stuff in the list
        projListItemList = <Widget>[];
        if (snapshot.hasData) {
          String data = snapshot.data!;
          print(data);
          if (data == "[\"noProjects\"]") {
            return Text('No Projects Scheduled Yet');
          }
          final List<dynamic> projectNameList = jsonDecode(data);
          for (var i = 0; i < projectNameList.length; i++) {
            projListItemList.add(ProjListItem(
              name: (projectNameList[i])['$i'].toString() + "$i",
              route: "/showProject/$i", //NOTE2
              color: Color(int.parse(projectNameList[i]['projectColor'])),
            ));

            print(projectNameList[i]['projectColor']);
          }
          return projectButtons(projListItemList);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      },
    );
  }

  //represents buttons scrollable list
  Container projectButtons(List<Widget> projListItemList) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.blue[600],
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: projListItemList,
      ),
    );
  }
}

//this needs to be a class because i dont know how to give the current context to a function.
//The actual button that routes to the specific project
class ProjListItem extends StatelessWidget {
  final name;
  final route;
  final color;
  const ProjListItem(
      {super.key,
      required this.name,
      required this.route,
      required this.color});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: .9,
      child: TextButton(
        onPressed: () => context.go(route), //NOTE1
        child: Container(
          decoration: Shadows(color),
          margin: const EdgeInsets.only(bottom: 10),
          height: 38,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              name,
            ),
          ),
        ),
      ),
    );
  }
}

// BOX shadows styles
BoxDecoration Shadows(color) {
  return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(50),
      boxShadow: const [
        // Shadow for top-left corner
        BoxShadow(
          color: Color.fromARGB(255, 0, 65, 162),
          offset: Offset(10, 10),
          blurRadius: 6,
          spreadRadius: 1,
        ),
        // Shadow for bottom-right corner
        BoxShadow(
          color: Colors.white12,
          offset: Offset(-10, -10),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ]);
}
