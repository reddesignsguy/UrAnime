/// This file holds many reusable widgets/functions to be used by multiple classes across the app
/// Authors: Albany Patriwan
/// Author Emails: albanypatriawan@gmail.com
/// Last Modified: September 13, 2022
/// Creation Date: June 6, 2022

import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import "dart:io";
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
part "anime.g.dart";

/// This class holds each individual anime and its respective data.
/// Input parameters: title (String), image URL (String), description (String)
@HiveType(typeId: 1)
class Anime {
  @HiveField(0)
  String canonicalTitle;

  @HiveField(1)
  String coverImage;

  @HiveField(2)
  String description;

  Anime(this.canonicalTitle, this.coverImage, this.description);
}

// This holds static data to be used across the app
class MyAnimeConstants {
  static const animePerPage = 20;
}

/// A widget that displays a singular anime and its respective data
/// Parameters:
/// index (A number that represents its "position" within the list of displayed animes)
/// anime (Anime object)
class MyAnimeCard extends StatefulWidget {
  final int index;
  final Anime anime;

  const MyAnimeCard({required this.index, required this.anime});

  @override
  State<MyAnimeCard> createState() => _MyAnimeCardState();
}

class _MyAnimeCardState extends State<MyAnimeCard> {
  // initialize HiveBox of user's locally saved liked animes
  static late Box _likedAnimes;

  late bool liked; // card is blue is true, dark grey if false
  late Duration likedDuration = Duration(
      milliseconds: 1000); // length of duration based on what is liked or not

  late Curve curve = Curves.easeOut; // currently chosen curve

  @override
  void initState() {
    super.initState();

    // check if anime is liked
    liked = animeIsLiked(widget.anime);

    // set default duration
    likedDuration = Duration(milliseconds: 1000);

    // initialize likeAnimes hive box
    _likedAnimes = Hive.box<Anime>("likedAnimes");
  }

  // Build function of AnimeCard widget
  @override
  Widget build(BuildContext context) {
    // change state of card if anime is liked/not liked
    animeIsLiked(widget.anime) ? liked = true : liked = false;
    return GestureDetector(
      // Detect double tap on anime cards
      onDoubleTap: () {
        if (animeIsLiked(widget.anime)) {
          _likedAnimes.delete(widget.anime.canonicalTitle);
          setState(() => {
                likedDuration = Duration(milliseconds: 600),
                liked = false,
                curve = Curves.easeOut
              });
        } else {
          _likedAnimes.put(widget.anime.canonicalTitle, widget.anime);
          setState(() => {
                likedDuration = Duration(milliseconds: 150),
                liked = true,
                curve = Curves.easeIn
              });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: likedDuration,
          curve: curve,
          color: liked == false
              ? Color.fromARGB(255, 37, 37, 37)
              : Color.fromARGB(255, 6, 129, 194),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Text(widget.index.toString(),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: liked == false
                          ? Color.fromARGB(255, 98, 98, 98)
                          : Color.fromARGB(255, 37, 37, 37),
                    )),
                Container(
                  height: 50,
                  child: Text(widget.anime.canonicalTitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: liked == false
                              ? Colors.grey
                              : Color.fromARGB(255, 37, 37, 37))),
                ),
                SizedBox(height: 5),
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.anime.coverImage,
                      scale: 1.0,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a list of Anime card widgets
/// Input parameters:
/// animesFuture (A Future object wrapping a list of animes)
/// page (int)
/// animePerPage(int)
class MyListOfAnime extends StatefulWidget {
  Future<List<Anime>> animesFuture;
  final int page; // The current page number of the list of animes
  final int animePerPage; // number of animes to be displayed on the page

  MyListOfAnime(
      {required this.animesFuture,
      required this.page,
      required this.animePerPage});

  @override
  State<MyListOfAnime> createState() => _MyListOfAnimeState();
}

/// The state of MyListOfAnime
class _MyListOfAnimeState extends State<MyListOfAnime> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: widget.animesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Anime> animes = snapshot.data!;
          return GridView.count(
            childAspectRatio: 0.52,
            crossAxisCount: 2,
            // Create a list given the snapshot data of the anime list
            children: List.generate(animes.length, (index) {
              final anime = animes[index];
              return MyAnimeCard(
                index: widget.page * widget.animePerPage + index + 1,
                anime: anime,
              );
            }),
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          );
        } else {
          return const Text("Loading");
        }
      },
    );
  }
}

// checks if inputted anime has been liked
bool animeIsLiked(Anime a) {
  // initialize anime box
  Box _likedAnimes = Hive.box<Anime>("likedAnimes");

  // check if anime has been liked
  return _likedAnimes.get(a.canonicalTitle) != null;
}

/// A function that fetches anime data from an API of a anime database
/// Parameters:
/// - param (String: The filter that allows users to look up specific animes/features)
/// - page (int: A specified page of the queried results). Due to limitations of KitsuAPI, we can only
/// - retrieve results of 20 items per page. Therefore, a certain page number must be given to navigate
/// through all the results from the data fetch (which is most likely above 20 items)
/// - animePerPage (int: Specificies number of anime per page from the API [Range: 0-20])
/// Returns: A list of animes wrapped in a Future object
///
Future<List<Anime>> getAnimeData([param, page, animePerPage]) async {
  List<Anime> animes = []; // animes list to be returned
  String query =
      "https://kitsu.io/api/edge/anime?page[limit]=${animePerPage}"; // API url

  // If filter is given, specify filter in the query
  if (param != "") {
    query = "${query}&filter[text]${param}";
  }

  // If page is given, specify page in the query
  if (page != null) {
    query = "${query}&page[offset]=${page}";
  }

  // Wait asynchronously for Response object
  final response = await http.get(Uri.parse(query));

  // Successful API fetch
  if (response.statusCode == 200) {
    // Get JSON body
    var body = jsonDecode(response.body);

    // Convert JSON body to map
    final Map map = jsonDecode(response.body);

    // Obtain data from API (Specific to kitsu.io formatting(JSON:API))
    var animeData = map["data"];

    // Iterate through queried data and convert to Anime objects
    for (var anime in animeData) {
      var attributes = anime['attributes']; // Extract attributes from map
      animes.add(Anime(
          attributes['canonicalTitle'],
          attributes['posterImage']['large'],
          attributes['description'])); // Create Anime object
    }

    // Failed API fetch
  } else {
    throw Exception("Failed to load anime");
  }

  return animes;
}

/// A function that gets the user's locally saved anime data
/// Returns: A list of liked animes wrapped in a Future object
Future<List<Anime>> getLikedAnime() {
  // Initialize likedAnimes box
  Box _likedAnimes = Hive.box<Anime>("likedAnimes");

  // Convert _likedAnimes box to map
  Map map = _likedAnimes.toMap();

  // Convert map into a list
  List<Anime> likedAnimes = [];
  for (var key in map.keys) {
    likedAnimes.add(map[key]);
  }

  // Create a future for animes list (asynchronous)
  return Future.value(likedAnimes);
}

/// Builds a generic page
/// Parameters:
/// - widgets (List<Widget>: A list of widget objects)
Widget buildPage(List<Widget> widgets) {
  return ListView(children: [
    Container(
      color: Color.fromARGB(255, 0, 0, 0),
      padding: const EdgeInsets.all(15.0),
      child: Container(
        child: Column(
          children: widgets,
        ),
      ),
    ),
  ]);
}

// Used to update liked anime list (in home page) whenever user likes an anime from the search page
class ListViewModel extends ChangeNotifier {
  void updateCurrentPage() {
    notifyListeners();
  }
}
