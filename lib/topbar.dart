import 'package:flutter/material.dart';
import './smiley_sunglass_icons.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final Function toggleFlagMode;
  final Function resetBoard;
  final bool wonGame;
  final bool alive;
  final int flagLeft;
  final int timeElapsed;
  final bool flagMode;
  final Function appSettingsPressed;
  @override
  Size get preferredSize {
    return new Size.fromHeight(48.0);
  }

  TopBar(this.toggleFlagMode,this.resetBoard, this.wonGame, this.alive, this.flagLeft,
      this.timeElapsed,this.flagMode,this.appSettingsPressed);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey[400],
        bottom: PreferredSize(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                buildSettingsButton(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildDigital(flagLeft),
                    buildFace(),
                    buildDigital(timeElapsed),
                  ]
                ),
               buildFlagButton(),
              ]),
        ));
  }

  Widget buildFace() {
    return Container(
      color: Colors.grey[400],
      child: InkWell(
        onTap: () {
          resetBoard();
        },
        child: CircleAvatar(
          child: Icon(
            wonGame ? SmileySunglass.smiling_face_with_sunglasses :
            (alive
                ? Icons.tag_faces
                : Icons.sentiment_very_dissatisfied),
            color: Colors.black,
            size: 40.0,
          ),
          backgroundColor: Colors.yellowAccent,
        ),
      ),
    );
  }

  Widget buildDigital(int val){
    return Container(
      height: 40.0,
      width: 72.0,
      alignment: Alignment.center,
      color: Colors.black,
      child: RichText(
        text: TextSpan(
            style: new TextStyle(
              fontFamily: 'Digital7',
              fontSize: 50,
              color: Colors.red,
            ),
            text: val.toString().padLeft(3,'0'))
      ),
    );
  }

  Widget buildSettingsButton() {
    return IconButton(
      padding: EdgeInsets.only(left: 10),
      icon: Icon(Icons.settings),
      onPressed: appSettingsPressed,
    );
  }

  Widget buildFlagButton() {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: ButtonTheme(
      minWidth: 1.0,
      height: 35.0,
      child: RaisedButton(
        onPressed: toggleFlagMode,
        child: Icon(Icons.flag, color: Colors.red[600]),
        color: flagMode ? Colors.grey[500] : Colors.grey[300],
      ),
      ),
    );
  }
}
