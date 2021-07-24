import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }

class SettingsMenu extends StatelessWidget implements PreferredSizeWidget {
  final Function selectDifficulty;
  Difficulty currentDiff;
  final int bestTime;
  SettingsMenu(this.selectDifficulty,this.currentDiff,this.bestTime);

  @override
  Size get preferredSize {
    return new Size.fromHeight(48.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: Icon(Icons.star_border),
          title: Text('Beginner'),
          onTap: () => selectDifficulty(Difficulty.easy),
          selected: currentDiff == Difficulty.easy,
        ),
        ListTile(
          leading: Icon(Icons.star_half),
          title: Text('Intermediate'),
          onTap: () => selectDifficulty(Difficulty.medium),
          selected: currentDiff == Difficulty.medium,
        ),
        ListTile(
          leading: Icon(Icons.star),
          title: Text('Expert'),
          onTap: () => selectDifficulty(Difficulty.hard),
          selected: currentDiff == Difficulty.hard,
        ),
        Text("Best Time: ${bestTime}s"),
      ],
    );
  }
}
