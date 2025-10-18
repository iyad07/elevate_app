import 'package:flutter/material.dart';
import '../widgets/stock_list.dart';
import 'home.dart';
import 'investment_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _selectedIndex = 1; // Search icon is selected by default
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // All available stocks for exploration (expanded list)
  final List<String> _allStockSymbols = [
    'GOOGL', // Google/Alphabet Inc
    'AAPL',  // Apple Inc
    'META',  // Meta Platforms Inc
    'NVDA',  // NVIDIA Corp
    'TSLA',  // Tesla Inc
    'AMZN',  // Amazon.com Inc
    'NFLX',  // Netflix Inc
    'IBM',   // International Business Machines Corp
    'ORCL',  // Oracle Corp
    'INTC',  // Intel Corp
    'MSFT',  // Microsoft Corp
    'BABA',  // Alibaba Group
    'V',     // Visa Inc
    'JPM',   // JPMorgan Chase & Co
    'JNJ',   // Johnson & Johnson
    'WMT',   // Walmart Inc
    'PG',    // Procter & Gamble Co
    'UNH',   // UnitedHealth Group Inc
    'HD',    // Home Depot Inc
    'MA',    // Mastercard Inc
    'DIS',   // Walt Disney Co
    'PYPL',  // PayPal Holdings Inc
    'BAC',   // Bank of America Corp
    'ADBE',  // Adobe Inc
    'CRM',   // Salesforce Inc
    'XOM',   // Exxon Mobil Corp
    'KO',    // Coca-Cola Co
    'PFE',   // Pfizer Inc
    'CSCO',  // Cisco Systems Inc
    'ABT',   // Abbott Laboratories
  ];

  // Currently displayed stocks (starts with first batch)
  List<String> _displayedStocks = [];
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialStocks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialStocks() {
    setState(() {
      _displayedStocks = _allStockSymbols.take(_itemsPerPage).toList();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStocks();
    }
  }

  Future<void> _loadMoreStocks() async {
    if (_isLoadingMore || _displayedStocks.length >= _allStockSymbols.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      final currentLength = _displayedStocks.length;
      final remainingItems = _allStockSymbols.length - currentLength;
      final itemsToAdd = remainingItems > _itemsPerPage ? _itemsPerPage : remainingItems;
      
      _displayedStocks.addAll(
        _allStockSymbols.skip(currentLength).take(itemsToAdd)
      );
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1F), // Home page background color
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3A2E), // Home page card color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Explore',
                    style: TextStyle(
                      color: Color(0xFFCDFF00), // Home page accent color
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3A2E), // Home page card color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.fromARGB(67, 204, 255, 0), // Home page border color
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search stocks...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Popular Stocks Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D1F), // Home page background
                  border: Border.all(
                    color: Color.fromARGB(67, 204, 255, 0), // Home page border
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Text(
                        'Popular Stocks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _displayedStocks.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _displayedStocks.length) {
                                  // Loading indicator at the bottom
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFCDFF00), // Home page accent
                                      ),
                                    ),
                                  );
                                }
                                
                                // Create a mini stock list widget for single item
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  height: 80, // Fixed height to prevent unbounded height error
                                  child: StockListWidget(
                                    stockSymbols: [_displayedStocks[index]],
                                  ),
                                );
                              },
                            ),
                          ),
                          /*if (_displayedStocks.length < _allStockSymbols.length && !_isLoadingMore)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: _loadMoreStocks,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFCDFF00), // Home page accent
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Load More Stocks',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),*/
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D1F), // Home page background color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.search, 1),
                _buildNavItem(Icons.work_outline, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // Navigate back to home if home icon is tapped
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
          return;
        } else if (index == 2) {
          // Navigate to investment page when work icon is tapped
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const InvestmentPage(),
            ),
          );
          return;
        }
        
        setState(() {
          _selectedIndex = index;
        });
        
        // Stay on explore page if search icon is tapped (index 1)
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCDFF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}