import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(SnakeGame());
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

  late Timer timer;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    setState(() {
      snakePositions = [0, 1, 2];
      foodPosition = Random().nextInt(rows * columns);
      currentDirection = 'right';
      isPlaying = false;
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
      switch (currentDirection) {
        case 'up':
          snakePositions.add(snakePositions.last - columns);
          break;
        case 'down':
          snakePositions.add(snakePositions.last + columns);
          break;
        case 'left':
          snakePositions.add(snakePositions.last - 1);
          break;
        case 'right':
          snakePositions.add(snakePositions.last + 1);
          break;
      }
      if (snakePositions.last == foodPosition) {
        foodPosition = Random().nextInt(rows * columns);
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
          backgroundColor: Colors.grey[900],
          title: const Text('Game Over', style: TextStyle(color: Colors.white)),
          content: const Text('You hit the wall or yourself! Try again?', style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
            ),
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Game'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: rows * columns,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                ),
                itemBuilder: (BuildContext context, int index) {
                  if (snakePositions.contains(index)) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin: const EdgeInsets.all(2),
                    );
                  } else if (index == foodPosition) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin: const EdgeInsets.all(2),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin: const EdgeInsets.all(2),
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                      onPressed: () => changeDirection('up'),
                      child: const Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                      onPressed: () => changeDirection('left'),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                      onPressed: () => changeDirection('right'),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
                      onPressed: () => changeDirection('down'),
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: startGame,
                  child: const Text('Start', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: resetGame,
                  child: const Text('Reset', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Created by Rasheed Zxr',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
