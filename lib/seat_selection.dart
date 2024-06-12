import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;
  final String hallName;
  final String date;
  final String showtime;
  final String showtimeID;

  SeatSelectionScreen({
    required this.movieTitle,
    required this.hallName,
    required this.date,
    required this.showtime,
    required this.showtimeID,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<int> reservedSeats = [];
  List<int> selectedSeats = [];
  int capacity = 0;
  bool addButtonEnabled = false;
  bool deleteButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchReservedSeats();
    fetchHallCapacity();
  }

  Future<void> fetchReservedSeats() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.237:3000/reservations/showtimereservation/${widget.showtimeID}"));
      final data = json.decode(response.body);

      if (data is! List) {
        setState(() {
          reservedSeats = [];
        });
        return;
      }

      final newReservedSeats = data.fold<List<int>>([], (acc, reservation) {
        final seatsFromReservation = reservation["seats"].map<int>((seat) => int.parse(seat.split(" ")[1])).toList();
        return acc..addAll(seatsFromReservation);
      });

      setState(() {
        reservedSeats = newReservedSeats;
      });
    } catch (error) {
    }
  }

  Future<void> fetchHallCapacity() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.0.237:3000/reservations/${widget.hallName}"));
      final data = json.decode(response.body);
      setState(() {
        capacity = data;
      });
    } catch (error) {
    }
  }

  void toggleSeatSelection(int seatNumber) {
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        selectedSeats.add(seatNumber);
      }

      bool areAllSelectedSeatsReserved = selectedSeats.every((seat) => reservedSeats.contains(seat));
      bool areAllSelectedSeatsAvailable = selectedSeats.every((seat) => !reservedSeats.contains(seat));

      if (!(areAllSelectedSeatsReserved || areAllSelectedSeatsAvailable)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("You can only choose seats from the same reservation."),
        ));
        selectedSeats.remove(seatNumber);
      }

      addButtonEnabled = selectedSeats.any((seat) => !reservedSeats.contains(seat));
      deleteButtonEnabled = selectedSeats.every((seat) => reservedSeats.contains(seat)) && selectedSeats.isNotEmpty;

      if (selectedSeats.isEmpty) {
        addButtonEnabled = false;
        deleteButtonEnabled = false;
      }
    });
  }

Future<void> addReservation() async {
  try {
    final response = await http.post(
      Uri.parse("http://192.168.0.237:3000/reservations"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "showtimeID": widget.showtimeID,
        "seats": selectedSeats.map((seatNumber) => "Seat $seatNumber").toList(),
      }),
    );

    await fetchReservedSeats();
    
    setState(() {
      selectedSeats = [];
      addButtonEnabled = false;
      deleteButtonEnabled = false;
    });
  } catch (error) {
    print('Error during reservation: $error');
  }
}



  Future<void> deleteReservation() async {
    try {
      final seatNumbers = selectedSeats.join(",");
      final response = await http.delete(
        Uri.parse("http://192.168.0.237:3000/reservations/deletereservation/${widget.showtimeID}?selectedSeats=$seatNumbers"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to delete reservation");
      }

      await fetchReservedSeats(); 
      setState(() {
        selectedSeats = [];
        deleteButtonEnabled = false;
      });
    } catch (error) {
    }
  }

  Widget renderSeats() {
    int rows = 0;
    int seatsPerRow = 0;

    if (capacity == 100) {
      rows = 14;
      seatsPerRow = (capacity / rows).ceil();
    } else if (capacity == 50) {
      rows = 8;
      seatsPerRow = (capacity / rows).ceil();
    } else if (capacity < 20) {
      rows = (capacity / 5).ceil();
      seatsPerRow = 5;
    } else {
      rows = (capacity / 10).ceil(); 
      seatsPerRow = 10;
    }

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(seatsPerRow, (colIndex) {
            int seatNumber = rowIndex * seatsPerRow + colIndex + 1;
            if (seatNumber > capacity) return Container();
            bool isReserved = reservedSeats.contains(seatNumber);
            bool isSelected = selectedSeats.contains(seatNumber);
            return GestureDetector(
              onTap: () => toggleSeatSelection(seatNumber),
              child: Container(
                margin: EdgeInsets.all(4),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : isReserved ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    "$seatNumber",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Seats"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Movie: ${widget.movieTitle}", style: TextStyle(fontSize: 18)),
            Text("Hall: ${widget.hallName}", style: TextStyle(fontSize: 18)),
            Text("Date: ${widget.date}", style: TextStyle(fontSize: 18)),
            Text("Showtime: ${widget.showtime}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Expanded(
              child: renderSeats(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: addButtonEnabled ? addReservation : null,
                  child: Text("Reserve seats"),
                ),
                ElevatedButton(
                  onPressed: deleteButtonEnabled ? deleteReservation : null,
                  child: Text("Delete seats"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
