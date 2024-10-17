import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures the binding is initialized
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(SnakeGame()); // Runs the app
}

class SnakeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      home: const GamePage(),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends State<GamePage> {
  static const int rows = 20;
  static const int columns = 20;

  List<int> snakePositions = [];
  int foodPosition = Random().nextInt(rows * columns);
  String currentDirection = 'right';
  bool isPlaying = false;

  int currentScore = 0;
  int highScore = 0;
  String playerName = '';

  late Timer timer;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref(); // Initialize database reference

  @override
  void initState() {
    super.initState();
    loadHighScore();
    resetGame();
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('highScore', highScore);
  }

  Future<void> saveScoreToLeaderboard() async {
    if (playerName.isNotEmpty) {
      try {
        // Debugging print statements
        print("Saving score: $currentScore for player: $playerName");

        await databaseReference.child("leaderboard").push().set({
          'name': playerName,
          'score': currentScore,
        });

        print("Score saved successfully: $currentScore for player: $playerName");
      } catch (error) {
        print("Failed to save score: $error"); // Error handling
      }
    } else {
      print("Player name is empty. Score not saved.");
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    DatabaseEvent event = await databaseReference.child("leaderboard").once();
    DataSnapshot snapshot = event.snapshot;

    List<Map<String, dynamic>> scoreList = [];
    if (snapshot.value != null) {
      Map<dynamic, dynamic> scores = Map<dynamic, dynamic>.from(snapshot.value as Map);

      scores.forEach((key, value) {
        scoreList.add({'name': value['name'], 'score': value['score']});
      });

      scoreList.sort((a, b) => b['score'].compareTo(a['score']));

      // Print scores for debugging
      print("Leaderboard scores: $scoreList");
    }
    return scoreList;
  }

  void resetGame() {
    setState(() {
      snakePositions = [0, 1, 2];
      foodPosition = Random().nextInt(rows * columns);
      currentDirection = 'right';
      isPlaying = false;
      currentScore = 0;
    });
  }

  void startGame() {
    if (!isPlaying) {
      isPlaying = true;
      const duration = Duration(milliseconds: 200);
      timer = Timer.periodic(duration, (Timer timer) {
        updateSnake();
        if (gameOver()) {
          timer.cancel();
          showGameOverDialog();
        }
      });
    }
  }

void updateSnake() {
  setState(() {
    int newHeadPosition;
    switch (currentDirection) {
      case 'up':
        newHeadPosition = snakePositions.last - columns;
        break;
      case 'down':
        newHeadPosition = snakePositions.last + columns;
        break;
      case 'left':
        newHeadPosition = (snakePositions.last % columns == 0)
            ? snakePositions.last + (columns - 1)
            : snakePositions.last - 1;
        break;
      case 'right':
        newHeadPosition = (snakePositions.last % columns == columns - 1)
            ? snakePositions.last - (columns - 1)
            : snakePositions.last + 1;
        break;
      default:
        newHeadPosition = snakePositions.last;
    }

    snakePositions.add(newHeadPosition);

    if (snakePositions.last == foodPosition) {
      // Generate a new food position that does not overlap with the snake
      do {
        foodPosition = Random().nextInt(rows * columns);
      } while (snakePositions.contains(foodPosition)); // Repeat if food overlaps

      currentScore += 10; // Increase score by 10 when food is eaten
      if (currentScore > highScore) {
        highScore = currentScore; // Update high score if current score exceeds it
        saveHighScore(); // Save the new high score
      }
    } else {
      snakePositions.removeAt(0);
    }
  });
}

  bool gameOver() {
    if (snakePositions.sublist(0, snakePositions.length - 1).contains(snakePositions.last)) {
      return true;
    }
    int row = (snakePositions.last / columns).floor();
    int column = snakePositions.last % columns;
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return true;
    }
    return false;
  }

void showGameOverDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Score: $currentScore\nHigh Score: $highScore'),
            TextField(
              onChanged: (value) {
                playerName = value; // Update player name from input
              },
              decoration: const InputDecoration(hintText: "Enter your name"),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Submit Score'),
            onPressed: () async {
              await saveScoreToLeaderboard(); // Save score to leaderboard
              await getLeaderboard(); // Fetch leaderboard after submission
              Navigator.of(context).pop(); // Close the dialog
              resetGame(); // Reset the game
            },
          ),
          TextButton(
            child: const Text('Try Again'),
            onPressed: () {
              Navigator.of(context).pop();
              resetGame(); // Reset the game
            },
          ),
        ],
      );
    },
  );
}

  void changeDirection(String newDirection) {
    if ((newDirection == 'up' && currentDirection != 'down') ||
        (newDirection == 'down' && currentDirection != 'up') ||
        (newDirection == 'left' && currentDirection != 'right') ||
        (newDirection == 'right' && currentDirection != 'left')) {
      currentDirection = newDirection;
    }
  }

void showLeaderboard() async {
  List<Map<String, dynamic>> scoreList = await getLeaderboard();
  if (scoreList.isEmpty) {
    print("No scores found.");
    // You can show a dialog saying there are no scores if needed
  } else {
    showScoresDialog(scoreList);
  }
}

  void showScoresDialog(List<Map<String, dynamic>> scoreList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: scoreList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${scoreList[index]['name']}', style: const TextStyle(color: Colors.white)),
                  trailing: Text('${scoreList[index]['score']}', style: const TextStyle(color: Colors.white)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showNameInputDialog() async {
    TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  playerName = nameController.text;
                });
                Navigator.of(context).pop();
                startGame(); // Start the game after entering name
              },
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  final double gridSize = MediaQuery.of(context).size.width; // Grid size based on screen width

  return Scaffold(
    appBar: AppBar(
      title: const Text('Snake Game'),
      backgroundColor: Colors.black,
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $currentScore', style: const TextStyle(fontSize: 20)),
                Text('High Score: $highScore', style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          SizedBox(
            width: gridSize,
            height: gridSize,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  changeDirection('down');
                } else if (details.delta.dy < 0) {
                  changeDirection('up');
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) {
                  changeDirection('right');
                } else if (details.delta.dx < 0) {
                  changeDirection('left');
                }
              },
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 1, // Ensures each cell is square
                ),
                itemCount: rows * columns,
                itemBuilder: (BuildContext context, int index) {
                  if (snakePositions.contains(index)) {
                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  } else if (index == foodPosition) {
                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: isPlaying ? null : showNameInputDialog,
                  child: const Text('Start Game'),
                ),
                ElevatedButton(
                  onPressed: showLeaderboard,
                  child: const Text('Show Leaderboard'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_up, size: 40),
                      onPressed: () => changeDirection('up'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, size: 40),
                      onPressed: () => changeDirection('left'),
                    ),
                    const SizedBox(width: 40), // Adjust spacing between left and right buttons
                    IconButton(
                      icon: const Icon(Icons.arrow_right, size: 40),
                      onPressed: () => changeDirection('right'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down, size: 40),
                      onPressed: () => changeDirection('down'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}