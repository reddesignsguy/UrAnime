import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:my_anime/entities/anime.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static int page = 0;
  late Box _likedAnimes;

  late Future<List<Anime>> animesFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return buildPage([
      Consumer<ListViewModel>(
        builder: (context, viewModel, child) {
          print('building home page');
          return RefreshIndicator(
            onRefresh: updateMyAnimeFuture,
            child: Column(
              children: [
                Text(
                    style: TextStyle(color: Colors.white, fontSize: 40),
                    "Liked Anime"),
                SizedBox(height: 60),
                MyListOfAnime(
                    animesFuture: getLikedAnime(),
                    page: page,
                    animePerPage: MyAnimeConstants.animePerPage,
                    isMyLikedAnimeList: true),
              ],
            ),
          );
        },
      )
    ]);
  }

  Future updateMyAnimeFuture() async {
    setState(() {
      animesFuture = getLikedAnime();
    });
  }
}
