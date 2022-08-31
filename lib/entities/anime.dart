import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import "dart:io";
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
part "anime.g.dart";

/*
This dart file contains reusable classes/widget-returning functions for the sake of
DRY principle. 

*/

/* Anime class:

*/
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

class MyAnimeConstants {
  static const animePerPage = 20;
}

class MyAnimeCard extends StatefulWidget {
  final int index;
  final Anime anime;

  const MyAnimeCard({required this.index, required this.anime});

  @override
  State<MyAnimeCard> createState() => _MyAnimeCardState();
}

class _MyAnimeCardState extends State<MyAnimeCard> {
  // initialize anime box
  static late Box _likedAnimes;

  late bool liked; // card is blue is true, dark grey if false
  late Duration likedDuration = Duration(
      milliseconds: 1000); // length of duration based on what is liked or not

  late Curve curve = Curves.easeOut; // currently chosen curve
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // check if anime is liked
    liked = animeIsLiked(widget.anime);

    // set default duration
    likedDuration = Duration(milliseconds: 1000);

    // initialize likeAnimes hive box
    _likedAnimes = Hive.box<Anime>("likedAnimes");
  }

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

class MyListOfAnime extends StatefulWidget {
  Future<List<Anime>> animesFuture;
  final int page;
  final int animePerPage;
  final bool
      isMyLikedAnimeList; // true if this list is a list of your liked anime, and not a general catalog of animes
  MyListOfAnime(
      {required this.animesFuture,
      required this.page,
      required this.animePerPage,
      required this.isMyLikedAnimeList});

  @override
  State<MyListOfAnime> createState() => _MyListOfAnimeState();
}

class _MyListOfAnimeState extends State<MyListOfAnime> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: widget.animesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Anime> animes = snapshot.data!;
          // animes =
          // Gesture
          return GridView.count(
            childAspectRatio: 0.52,
            crossAxisCount: 2,
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

Future<List<Anime>> getAnimeData([param, page, animePerPage]) async {
  List<Anime> animes = []; // animes list to be returned
  String query =
      "https://kitsu.io/api/edge/anime?page[limit]=${animePerPage}"; // API url

  // Use inputted parameteres for filtering results
  if (param != "") {
    query = "${query}&filter[text]${param}";
  }
  if (page != null) {
    print(page);
    query = "${query}&page[offset]=${page}";
  }
  final response = await http.get(Uri.parse(query));

  // Successful API fetch
  if (response.statusCode == 200) {
    // JSON body
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

Future<List<Anime>> getLikedAnime() {
  // initialize likedAnimes box
  Box _likedAnimes = Hive.box<Anime>("likedAnimes");

  // convert _likedAnimes box to map
  Map map = _likedAnimes.toMap();

  // convert map into a list
  List<Anime> likedAnimes = [];
  for (var key in map.keys) {
    likedAnimes.add(map[key]);
  }

  // create a future for animes list (asynchronous)
  return Future.value(likedAnimes);
}

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

// used to update liked anime list (in home page) whenever user likes an anime from the search page
class ListViewModel extends ChangeNotifier {
  int _current_page = 0;

  int get current_page => _current_page;

  Future<List<Anime>> _futuresMyLikedAnime = getLikedAnime();

  Future<List<Anime>> get futuresMyLikedAnime => _futuresMyLikedAnime;

  // called whenver
  void updateLikedAnimeList() {
    _futuresMyLikedAnime = getLikedAnime();
    notifyListeners();
  }

  void updatePages() {
    notifyListeners();
  }

  void updateCurrentPage(int index) {
    _current_page = index;
    notifyListeners();
  }
}
