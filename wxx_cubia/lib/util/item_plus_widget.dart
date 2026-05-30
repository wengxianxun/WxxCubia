import 'package:flutter/material.dart';

class ItemPlusWidget extends StatefulWidget {
  final String title;
  final String imgPath;

  const ItemPlusWidget({super.key, required this.title, required this.imgPath});

  @override
  State<ItemPlusWidget> createState() => _ItemPlusWidget();
}

class _ItemPlusWidget extends State<ItemPlusWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/btn/btn_bg.png',
                  width: 35,
                  height: 35,
                ),
                Image.asset(widget.imgPath, width: 30, height: 30),
              ],
            ),
          ),

          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
