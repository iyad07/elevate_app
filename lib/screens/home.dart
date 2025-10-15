import 'package:flutter/material.dart';

import '../widgets/stock_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: StockListWidget(
          stockSymbols: ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN'],
        ));
  }
}
