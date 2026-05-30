import 'package:flutter/material.dart';

class SettingCell extends StatefulWidget {
  final String title;
  final Widget childWidget;
  const SettingCell({Key? key, required this.title, required this.childWidget})
    : super(key: key);

  @override
  _AdCellState createState() => _AdCellState();
}

class _AdCellState extends State<SettingCell> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white54,
        border: Border(
          bottom: BorderSide(color: Colors.black54, width: 0.67),
          top: BorderSide(color: Colors.black54, width: 0.67),
        ),
      ),
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          widget.childWidget,
        ],
      ),
    );
  }
}
