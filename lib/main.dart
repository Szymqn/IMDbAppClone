import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Movie App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.dark,
            primaryContainer: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var favorites = <Movie>[];
  List<Movie>? _cachedMovies;
  bool _isInitialized = false;

  MyAppState() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_movie_ids') ?? [];
    
    await _loadCachedMovies();

    if (_cachedMovies != null) {
      favorites = _cachedMovies!
          .where((movie) => favoriteIds.contains(movie.id.toString()))
          .toList();
    }

    _isInitialized = true;
    notifyListeners();
  }

    Future<void> _loadCachedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_movies');
    
    if (cachedData != null) {
      final json = jsonDecode(cachedData);
      _cachedMovies = (json['movies'] as List)
          .map((movie) => Movie.fromJson(movie))
          .toList();
    }
  }

  Future<void> cacheMovies(List<Movie> movies) async {
    _cachedMovies = movies;
    final prefs = await SharedPreferences.getInstance();
    final moviesJson = {
      'movies': movies.map((m) => m.toJson()).toList(),
    };
    await prefs.setString('cached_movies', jsonEncode(moviesJson));
  }

  List<Movie>? getCachedMovies() => _cachedMovies;

  Future<void> toggleFavorite(Movie movie) async {
    if (favorites.contains(movie)) {
      favorites.remove(movie);
    } else {
      favorites.add(movie);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = favorites.map((m) => m.id.toString()).toList();
    await prefs.setStringList('favorite_movie_ids', favoriteIds);
    
    notifyListeners();
  }

  bool get isInitialized => _isInitialized;
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MovieListPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Movies'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MovieListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    // Show cached movies immediately if available
    final cachedMovies = appState.getCachedMovies();
    
    if (cachedMovies != null) {
      return _buildMovieList(context, cachedMovies);
    }

    return FutureBuilder<List<Movie>>(
      future: fetchMovies(appState),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final movies = snapshot.data!;
          return _buildMovieList(context, movies);
        }
      },
    );
  }

  Widget _buildMovieList(BuildContext context, List<Movie> movies) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: movies[index].poster.isNotEmpty
              ? Image.network(
                  movies[index].poster,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.movie, size: 50);
                  },
                )
              : Icon(Icons.movie, size: 50),
          title: Text(movies[index].title),
          subtitle: Text('${movies[index].year} • ${movies[index].genre.join(', ')}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailPage(movie: movies[index]),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Movie>> fetchMovies(MyAppState appState) async {
    final String response = await rootBundle.loadString('assets/movies.json');
    final json = jsonDecode(response);
    final movies = (json['movies'] as List).map((movie) => Movie.fromJson(movie)).toList();
    
    // Cache the movies
    await appState.cacheMovies(movies);
    
    return movies;
  }
}

class MovieDetailPage extends StatelessWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text('Year'),
              trailing: Text('${movie.year}'),
            ),
            ListTile(
              title: Text('Genre'),
              subtitle: Text(movie.genre.join(', ')),
            ),
            ListTile(
              title: Text('Duration'),
              trailing: Text('${movie.durationMinutes} min'),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              leading: Icon(Icons.movie_creation_outlined),
              title: Text('Director'),
              children: [
                ListTile(
                  title: Text(movie.director.name),
                  subtitle: movie.director.nationality.isNotEmpty
                      ? Text(movie.director.nationality)
                      : null,
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.people_alt_outlined),
              title: Text('Cast'),
              children: [
                for (final actor in movie.cast)
                  ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text(actor),
                  ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.star_border),
              title: Text('Ratings'),
              children: [
                ListTile(
                  title: Text('IMDb'),
                  trailing: Text('${movie.ratings.imdb}'),
                ),
                ListTile(
                  title: Text('Rotten Tomatoes'),
                  trailing: Text(movie.ratings.rottenTomatoes),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => appState.toggleFavorite(movie),
              child: Text(appState.favorites.contains(movie)
                  ? 'Remove from Favorites'
                  : 'Add to Favorites'),
            ),
          ],
        ),
      ),
    );
  }
}

class Movie {
  final int id;
  final String title;
  final int year;
  final List<String> genre;
  final int durationMinutes;
  final Director director;
  final List<String> cast;
  final Ratings ratings;
  final String poster;

  Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.durationMinutes,
    required this.director,
    required this.cast,
    required this.ratings,
    required this.poster,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      year: json['year'],
      genre: List<String>.from(json['genre']),
      durationMinutes: json['duration_minutes'],
      director: Director.fromJson(json['director']),
      cast: List<String>.from(json['cast']),
      ratings: Ratings.fromJson(json['ratings']),
      poster: json['poster'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'genre': genre,
      'duration_minutes': durationMinutes,
      'director': director.toJson(),
      'cast': cast,
      'ratings': ratings.toJson(),
      'poster': poster,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Movie && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class Director {
  final String name;
  final String nationality;

  Director({required this.name, required this.nationality});

  factory Director.fromJson(Map<String, dynamic> json) {
    return Director(
      name: json['name'],
      nationality: (json['nationality'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nationality': nationality,
    };
  }
}

class Ratings {
  final double imdb;
  final String rottenTomatoes;

  Ratings({required this.imdb, required this.rottenTomatoes});

  factory Ratings.fromJson(Map<String, dynamic> json) {
    final imdbVal = (json['IMDb'] as num).toDouble();
    final rt = (json['RottenTomatoes'] ?? 'N/A').toString();
    return Ratings(imdb: imdbVal, rottenTomatoes: rt);
  }

  Map<String, dynamic> toJson() {
    return {
      'IMDb': imdb,
      'RottenTomatoes': rottenTomatoes,
    };
  }
}
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have '
            '${appState.favorites.length} favorites:',
          ),
        ),
        for (var movie in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(movie.title), // Display movie title
          ),
      ],
    );
  }
}