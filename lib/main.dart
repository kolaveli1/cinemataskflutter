import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "selected_movie_screen.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Cinema Reservation App"),
        ),
        body: MoviesScreen(),
      ),
    );
  }
}

class MoviesScreen extends StatefulWidget {
  @override
  _MoviesScreenState createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<Map<String, String>> movies = [];

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.237:3000/reservations/movies"));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List) {
          setState(() {
            movies = List<Map<String, String>>.from(data.map((movie) => {
              "title": movie["title"] as String,
              "imageURL": movie["imageURL"] as String,
            }));
          });
        } else {
          throw Exception("Data format is incorrect");
        }
      } else {
        throw Exception("Failed to load movies");
      }
    } catch (error) {
    }
  }

  void navigateToSelectedMovie(Map<String, String> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedMovieScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Upcoming Movies",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: movies.isEmpty
                ? Text("No movies available.", style: TextStyle(color: Colors.black))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return GestureDetector(
                        onTap: () => navigateToSelectedMovie(movie),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              movie["imageURL"]!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
