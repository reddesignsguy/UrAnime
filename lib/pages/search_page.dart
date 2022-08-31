import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "dart:io";
import 'package:my_anime/entities/anime.dart';
import "package:hive/hive.dart";
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage();

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
  }

  // settings
  static const animePerPage = 20;
  static String input = "";
  static int page = 0;
  static bool showResults = false;

  // List<Anime> likedAnimes = [];
  int currentPageIndex = 1;

  // fetch anime data from kitsu API
  Future<List<Anime>> animesFuture = getAnimeData(input, page, animePerPage);

  // handles gestures
  final inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildPage([
      Card(
        color: Color.fromARGB(255, 37, 37, 37),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  onSubmitted: ((value) => setState(() {
                        animesFuture = getAnimeData(value, page, animePerPage);
                        showResults = true;
                      })),
                  onTap: () => {print("tapped")},
                  textInputAction: TextInputAction.send,
                  controller: inputController,
                  decoration: new InputDecoration.collapsed(
                      fillColor: Colors.grey, hintText: 'Search')),
            ),
          ],
        ),
      ),
      showResults
          ? Column(
              children: [
                SizedBox(height: 20),
                Text("Showing results for.. '${input}'",
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.grey)),
                // List animes
                SizedBox(height: 20),
                Consumer<ListViewModel>(builder: (context, viewModel, child) {
                  return MyListOfAnime(
                      animesFuture: animesFuture,
                      page: page,
                      animePerPage: MyAnimeConstants.animePerPage,
                      isMyLikedAnimeList: false);
                })
              ],
            )
          : Container(),
    ]);
  }
}
