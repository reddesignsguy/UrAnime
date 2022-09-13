/// This file manages the home page of the app
/// Authors: Albany Patriawan
/// Author Emails: albanypatriawan@gmail.com
/// Last Modified: September 13, 2022
/// Creation Date: June 6, 2022
///
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:my_anime/entities/anime.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

// A widget for the home page of the app
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// The state of the home page widget
class _HomePageState extends State<HomePage> {
  static int page = 0; // Current page of the list of animes on the home page

  late Future<List<Anime>>
      animesFuture; // The Future object of list of liked animes

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildPage([
      Consumer<ListViewModel>(
        builder: (context, viewModel, child) {
          // For refreshing the page on pulldown
          return RefreshIndicator(
            onRefresh: updateMyAnimeFuture,
            child: Column(
              children: [
                SizedBox(height: 60),
                MyListOfAnime(
                    animesFuture: getLikedAnime(),
                    page: page,
                    animePerPage: MyAnimeConstants.animePerPage),
              ],
            ),
          );
        },
      )
    ]);
  }

  // Refreshes the liked anime
  Future updateMyAnimeFuture() async {
    setState(() {
      animesFuture = getLikedAnime();
    });
  }
}
