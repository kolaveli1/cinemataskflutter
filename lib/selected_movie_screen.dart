import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "seat_selection.dart"; 

class SelectedMovieScreen extends StatefulWidget {
  final Map<String, String> movie;

  SelectedMovieScreen({required this.movie});

  @override
  _SelectedMovieScreenState createState() => _SelectedMovieScreenState();
}

class _SelectedMovieScreenState extends State<SelectedMovieScreen> {
  List<Map<String, dynamic>> showtimes = [];
  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchShowtimes();
  }

  Future<void> fetchShowtimes() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.237:3000/reservations/showtimes/${widget.movie['title']}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final now = DateTime.now();

        setState(() {
          showtimes = data.map((showtime) {
            final dateParts = showtime["date"].split(" ");
            final month = _monthToNumber(dateParts[1]);
            final day = dateParts[0].padLeft(2, "0");
            final year = now.year.toString();
            final time = showtime["showtime"];
            final fullDateStr = "$year-$month-$day $time";
            final showtimeDate = DateTime.parse(fullDateStr);
            return {
              "hallName": showtime["hallName"],
              "date": showtime["date"],
              "showtime": showtime["showtime"],
              "showtimeID": showtime["_id"],
              "showtimeDate": showtimeDate,
            };
          }).where((showtime) {
            return showtime["showtimeDate"].isAfter(now);
          }).toList();
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = "Failed to load showtimes";
        });
        throw Exception("Failed to load showtimes");
      }
    } catch (error) {
      setState(() {
        hasError = true;
        errorMessage = "Error: $error";
      });
    }
  }

  String _monthToNumber(String month) {
    switch (month.toLowerCase()) {
      case "january":
        return "01";
      case "february":
        return "02";
      case "march":
        return "03";
      case "april":
        return "04";
      case "may":
        return "05";
      case "june":
        return "06";
      case "july":
        return "07";
      case "august":
        return "08";
      case "september":
        return "09";
      case "october":
        return "10";
      case "november":
        return "11";
      case "december":
        return "12";
      default:
        throw ArgumentError("Invalid month: $month");
    }
  }

  void navigateToSeatSelection(String hallName, String date, String showtime, String showtimeID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          movieTitle: widget.movie["title"]!,
          hallName: hallName,
          date: date,
          showtime: showtime,
          showtimeID: showtimeID,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie["title"]!),
      ),
      body: hasError
          ? Center(child: Text("Failed to load showtimes. $errorMessage"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(  
                    child: Image.network(
                      widget.movie["imageURL"]!,
                      width: 200,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  "Current showtimes for ${widget.movie["title"]}",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: showtimes.isEmpty
                      ? Text("No showtimes available.")
                      : ListView.builder(
                          itemCount: showtimes.length,
                          itemBuilder: (context, index) {
                            final showtime = showtimes[index];
                            return ListTile(
                              title: Text(showtime["hallName"]),
                              subtitle: Text("Date: ${showtime["date"]}, Time: ${showtime["showtime"]}"),
                              onTap: () {
                                navigateToSeatSelection(
                                  showtime["hallName"],
                                  showtime["date"],
                                  showtime["showtime"],
                                  showtime["showtimeID"],
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
