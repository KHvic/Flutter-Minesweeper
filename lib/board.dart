import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import './tiles.dart';
import './topbar.dart';
import './settings-menu.dart';
import './bidirectional-scrollview.dart';
import './smiley_sunglass_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<List<int>> dirs = [[0,1],[1,0],[-1,0],[0,-1],[1,1],[-1,-1],[1,-1],[-1,1]];

class Board extends StatefulWidget {
  @override
  BoardState createState() => BoardState();
}

class BoardState extends State<Board> {
  // scrolling behaviors
  bool reset = false;
  void resetDone(){
    reset = false;
  }
  // persistence
  int easyTime = 0;
  int mediumTime = 0;
  int hardTime = 0;

  Difficulty diff = Difficulty.easy;
  int rows = 15;
  int cols = 10;
  int numOfMines = 30;
  int uncoveredCells = 0;

  List<List<TileState>> uiState = [];
  List<List<bool>> tiles = []; // hasBomb?

  bool alive = false;
  bool wonGame = false;
  int flagUsed = 0;
  bool flagMode = false;
  Timer timer;
  Stopwatch stopwatch = Stopwatch();
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void resetBoard() {
    reset = true;
    alive = true;
    wonGame = false;
    flagMode = false;
    flagUsed = 0;
    uncoveredCells = rows*cols;
    stopwatch.reset();

    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });

    uiState = new List<List<TileState>>.generate(rows, (row) {
      return new List<TileState>.filled(cols, TileState.covered);
    });

    tiles = new List<List<bool>>.generate(rows, (row) {
      return new List<bool>.filled(cols, false);
    });


    // bomb assignment
    Random random = Random();
    int remainingMines = numOfMines;
    int remainingCells = rows*cols;
    for(int i=0;i<rows && remainingMines > 0;i++){
      for(int j=0;j<cols && remainingMines > 0;j++, remainingCells--){
        double threshold = remainingMines.toDouble()/remainingCells;
        if(random.nextDouble() <= threshold){
          tiles[i][j] = true;
          remainingMines--;
        }
      }
    }
    stopwatch.stop();
  }

  @override
  void initState() {
    resetBoard();
    loadPreferences();
    super.initState();
  }

  Widget buildBoard() {
    List<Row> boardRow = <Row>[];
    for (int y = 0; y < rows; y++) {
      List<Widget> rowChildren = <Widget>[];
      for (int x = 0; x < cols; x++) {
        TileState state = uiState[y][x];
        int count = mineCount(x, y);

        // reveal all bombs when dead
        if (!alive) {
          if (state != TileState.blown && state != TileState.blownclick)
            state = tiles[y][x] ? TileState.revealed : state;
        } else if(wonGame && tiles[y][x]) {
          state = TileState.flagged;
        }

        if (state == TileState.covered || state == TileState.flagged) {
          rowChildren.add(InkWell(
            onTap: () {
                flagMode ? flag(x, y) : probe(x, y);
            },
            child: Listener(
                child: CoveredMineTile(
                  flagged: state == TileState.flagged,
                  posX: x,
                  posY: y,
                )),
          ));
        } else {
          rowChildren.add(OpenMineTile(
            state: state,
            count: count,
          ));
        }
      }
      boardRow.add(Row(
        children: rowChildren,
        mainAxisAlignment: MainAxisAlignment.center,
        key: ValueKey<int>(y),
      ));
    }

    return
    Container(
      color: Colors.grey[700],
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: boardRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int timeElapsed = stopwatch.elapsedMilliseconds ~/ 1000;
    if(timeElapsed == 999) alive = false;
    return Scaffold(
      appBar: TopBar(toggleFlagMode,resetBoard,wonGame,alive,numOfMines-flagUsed,timeElapsed,flagMode,appSettingsPressed),
      body: Center(child:BidirectionalScrollViewPlugin(child: buildBoard(),reset: this.reset,resetDone: this.resetDone)),
    );
  }

  void toggleFlagMode(){
    flagMode = !flagMode;
  }

  // click event on cell
  void probe(int x, int y) {
    if (!alive) return;
    if (uiState[y][x] == TileState.flagged) return;
    setState(() {
      if (tiles[y][x]) {
        uiState[y][x] = TileState.blownclick;
        alive = false;
        timer.cancel();
        stopwatch.stop(); // force the stopwatch to stop.
      } else {
        open(x, y);
        if (!stopwatch.isRunning) stopwatch.start();
      }
      if ((uncoveredCells == numOfMines) && alive) {
        wonGame = true;
        _showWinDialog();
        stopwatch.stop();
      }
    });
  }

  void open(int x, int y) {
    if (!inBoard(x, y)) return;
    if (uiState[y][x] == TileState.open) return;
    uiState[y][x] = TileState.open;
    uncoveredCells--;

    if (mineCount(x, y) > 0) return;

    // propagate and open cells with 0 mines
    for(List<int> dir in dirs){
      int nextX = x + dir[0];
      int nextY = y + dir[1];
      open(nextX, nextY);
    }
  }

  void flag(int x, int y) {
    if (!alive) return;
    setState(() {
      // unflag
      if (uiState[y][x] == TileState.flagged) {
        uiState[y][x] = TileState.covered;
        --flagUsed;
      } else {
        // flag
        if(flagUsed >= numOfMines) return;
        uiState[y][x] = TileState.flagged;
        ++flagUsed;
      }
    });
  }

  int mineCount(int x, int y) {
    int count = 0;
    for(List<int> dir in dirs){
      int nextX = x + dir[0];
      int nextY = y + dir[1];
      count += bombs(nextX, nextY);
    }
    return count;
  }

  int bombs(int x, int y) => inBoard(x, y) && tiles[y][x] ? 1 : 0;
  bool inBoard(int x, int y) => x >= 0 && x < cols && y >= 0 && y < rows;

  void appSettingsPressed() {
    int bestTime = diff.index == 0 ? easyTime : diff.index == 1 ? mediumTime : hardTime;
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Color(0xFF737373),
            height: 250,
            child: Container(
              child: SettingsMenu(selectDifficulty,diff,bestTime),
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                ),
              ),
            ),
          );
        });
  }


  void selectDifficulty(Difficulty selected) {
    Navigator.pop(context);
    updateDifficulty(selected);
  }

  void updateDifficulty(Difficulty selected) {
    setState(() {
      if(selected == Difficulty.easy) {
        numOfMines = 10;
        rows = cols = 9;
      } else if(selected == Difficulty.medium){
        numOfMines = 40;
        rows = cols = 16;
      } else if(selected == Difficulty.hard){
        numOfMines = 99;
        rows = 30;
        cols = 16;
      }
      diff = selected;
      savePreferences();
      resetBoard();
    });
  }

  void _showWinDialog() {
    int bestTime = 999;
    int curTime = stopwatch.elapsedMilliseconds ~/ 1000;
    if(diff == Difficulty.easy) {
      if(curTime < easyTime) easyTime = curTime;
      bestTime = easyTime;
    } else if(diff == Difficulty.medium) {
      if(curTime < mediumTime) mediumTime = curTime;
      bestTime = mediumTime;
    } else if(diff == Difficulty.hard) {
      if(curTime < hardTime) hardTime = curTime;
      bestTime = hardTime;
    }
    // save new best time
    if(curTime < bestTime) {
      bestTime = curTime;
      savePreferences();
    }
    showDialog(context: context,
        builder: (context){
      return AlertDialog(
        title: Row(children:[
          Text("You Won! "),
          CircleAvatar(
            child: Icon(SmileySunglass.smiling_face_with_sunglasses,
              color: Colors.black,
              size: 15.0,
            ),
            radius: 10.0,
            backgroundColor: Colors.yellowAccent,
          ),
        ]),
        content: Text("Best Time: ${bestTime}s" + "\n\nTime Taken: ${curTime}s",
        ),
        actions: <Widget>[
          FlatButton(
            child: Text("Close"),
            onPressed:(){
              Navigator.of(context).pop();
              resetBoard();
            },
          ),
        ],
      );
    });
  }

  Future<bool> savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("EasyTime", easyTime);
    prefs.setInt("MediumTime", mediumTime);
    prefs.setInt("HardTime", hardTime);
    prefs.setInt("Difficulty", diff.index);
    return prefs.commit();
  }

  Future<bool> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int diffIndex = prefs.getInt("Difficulty") ?? 1;
    setState(() {
      switch (diffIndex) {
        case 0 :
          diff = Difficulty.easy;
          break;
        case 1 :
          diff = Difficulty.medium;
          break;
        case 2 :
          diff = Difficulty.hard;
          break;
      }
      easyTime = prefs.getInt("EasyTime") ?? 999;
      mediumTime = prefs.getInt("MediumTime") ?? 999;
      hardTime = prefs.getInt("HardTime") ?? 999;
    });
    updateDifficulty(diff);
    return true;
  }
}