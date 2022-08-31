import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "dart:io";
import 'package:my_anime/entities/anime.dart';
import "package:my_anime/pages/search_page.dart";
import "package:my_anime/pages/home_page.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:hive/hive.dart";
import 'package:provider/provider.dart';

void main() async {
  // initialize hive
  await Hive.initFlutter();

  // register adapter

  Hive.registerAdapter(AnimeAdapter());
  // open hive box
  var likedAnimes = await Hive.openBox<Anime>("likedAnimes");

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  final Color barColor = Color.fromARGB(255, 37, 37, 37);
  final Color textColor = Color.fromARGB(255, 98, 98, 98);

  final pages = [
    HomePage(),
    SearchPage()
  ]; // list containing home page and search page

  static final int animePerPage =
      20; // number of animes displayed for both pages

  int currentPageIndex =
      0; // indicates whether home page or search page is selected

  final inputController = TextEditingController();

  // Retrieves data from anime API
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ListViewModel>(
        create: (BuildContext context) => ListViewModel(),
        child: Consumer<ListViewModel>(builder: ((context, viewModel, child) {
          return MaterialApp(
              theme: new ThemeData(scaffoldBackgroundColor: Colors.black),
              home: Scaffold(
                appBar: AppBar(
                  title: Text("UrAnime",
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          shadows: <Shadow>[
                            Shadow(
                                color: Color.fromARGB(255, 67, 67, 67),
                                offset: Offset(0, 6),
                                blurRadius: 2),
                            Shadow(
                                color: Color.fromARGB(255, 24, 24, 24),
                                offset: Offset(0, 4),
                                blurRadius: 2)
                          ])),
                  backgroundColor: Color.fromARGB(255, 6, 129, 194),
                ),
                body: IndexedStack(
                    alignment: Alignment.center,
                    index: currentPageIndex,
                    children: pages),
                bottomNavigationBar: BottomNavigationBar(
                  unselectedFontSize: 20,
                  showUnselectedLabels: false,
                  iconSize: 30,
                  unselectedItemColor: textColor,
                  selectedItemColor: Color.fromARGB(255, 214, 214, 214),
                  backgroundColor: barColor,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: currentPageIndex,
                  onTap: (index) => {
                    // update home page to check if new animes have been liked in search page
                    if (true) {viewModel.updateCurrentPage(index)},
                    setState(() => currentPageIndex = index)
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: "My Anime",
                      backgroundColor: Colors.grey,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: "Discover",
                      backgroundColor: Colors.grey,
                    )
                  ],
                ),
              ));
        })));
  }
}

// Notes
// // Entry point of application
// // Special type of function (when you call it main)
// void main() {
//   for (int i = 0; i < 5; i++) {
//     print("hi");
//   }

//   var p1 = Person("test", 5);  // "new" keyword is not required + positional arguments
//   var p2 = Person(age: 5, name: "test");  // named arguments used (order does not matter)

//   p1.name = "Bob"
//   print(p1.name)
// }

// // Naming convention: Camelcase
// int addNumbers(int num1, int num2) {
//   return num1 + num2;
// }

// class Person {
//   // We call these "properties" (belongs to class), as opposed to "variables" (belongs to function)
//   String name;
//   int age;

// We have to create a constructor
// Person(String n, int a = 30) { // default value
//   name = n;
//   age = a;
// }
// }

// SHORTCUT CLASS

class AdvancedPerson {
  String name;
  int age;

  AdvancedPerson(this.name, this.age);
}
