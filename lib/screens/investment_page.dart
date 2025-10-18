import 'package:flutter/material.dart';
import '../widgets/stock_list.dart';
import 'home.dart';
import 'explore_page.dart';

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({Key? key}) : super(key: key);

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  int _selectedIndex = 2; // Investment/Work icon is selected

  // Stock symbols for the investment portfolio
  final List<String> _portfolioStocks = [
    'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Investments',
                    style: TextStyle(
                      color: Color(0xFFCDFF00),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[700],
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Portfolio Overview Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 200, // Fixed height to allow Expanded widgets to work
                child: Row(
                  children: [
                    // Current Value Card
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3A2E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current value',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.more_vert,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '₵5,265.78',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: Color(0xFFCDFF00),
                                ),
                                label: const Text(
                                  'Withdraw',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFCDFF00),
                                  side: const BorderSide(
                                    color: Color(0xFFCDFF00),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Column with Invested and Returns
                    Expanded(
                      child: Column(
                        children: [
                          // Invested Card
                          Expanded(

                            flex: 2,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3A2E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Invested',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '₵5K',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Returns Card
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3A2E),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: const Color(0xFFCDFF00),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '+5.3%',
                                        style: TextStyle(
                                          color: Color(0xFFCDFF00),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stock Holdings Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(67, 204, 255, 0),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '5 Stocks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_exchange,
                                    color: const Color(0xFFCDFF00),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Today's returns",
                                    style: TextStyle(
                                      color: Color(0xFFCDFF00),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stock List
                    Expanded(
                      child: StockListWidget(
                        stockSymbols: _portfolioStocks,
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
          color: const Color(0xFF1A1D1F),
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
        setState(() {
          _selectedIndex = index;
        });
        
        // Navigate based on selected index
        if (index == 0) {
          // Navigate to home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else if (index == 1) {
          // Navigate to explore page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ExplorePage(),
            ),
          );
        }
        // Stay on investment page if work icon (index 2) is tapped
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