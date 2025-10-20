import 'package:elevate_app/widgets/stock_list.dart';
import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import '../services/paystack_service.dart';
import 'explore_page.dart';
import 'investment_page.dart';
//import 'stock_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockService _stockService = StockService();
  final PaystackService _paystackService = PaystackService();
  final Map<String, StockQuote> _stockQuotes = {};
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  int _selectedIndex = 0;

  final List<String> stockSymbols = [
    'HDFCBANK.BSE',
    'DELHIVERY.BSE',
    'SBIN.BSE',
    'ZOMATO.BSE',
    'RELIANCE.BSE'
  ];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (int i = 0; i < stockSymbols.length; i++) {
        if (i > 0) {
          await Future.delayed(const Duration(seconds: 12));
        }
        final quote = await _stockService.getStockQuote(stockSymbols[i]);
        setState(() {
          _stockQuotes[stockSymbols[i]] = quote;
        });
      }
    } catch (e) {
      // Handle error silently for demo
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddFunds() async {
    // Show amount input dialog
    final amount = await _showAmountInputDialog();
    if (amount == null || amount <= 0) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final result = await _paystackService.addFundsToWallet(
        context: context,
        customerEmail: 'chairman.wontumi@example.com', // Replace with actual user email
        amount: amount,
        currency: 'GHS',
        userMetadata: {
          'user_name': 'Chairman Wontumi',
          'wallet_funding': true,
        },
      );

      if (result['success'] == true) {
        final newBalance = result['balance'];
        _showSuccessDialog(amount, result['transaction_reference'], newBalance?.toString());
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<double?> _showAmountInputDialog() async {
    final TextEditingController amountController = TextEditingController();
    
    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D3A2E),
          title: const Text(
            'Add Funds',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter amount to add to your wallet:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '₵ ',
                  prefixStyle: const TextStyle(color: Color(0xFFCDFF00)),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFCDFF00)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFCDFF00), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment methods: Card, Mobile Money (MTN, Vodafone, AirtelTigo)',
                style: TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                Navigator.of(context).pop(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCDFF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(double amount, String reference, [String? newBalance]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D3A2E),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFFCDFF00)),
              SizedBox(width: 8),
              Text('Payment Successful', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₵${amount.toStringAsFixed(2)} has been added to your wallet.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference: $reference',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (newBalance != null) ...[
                const SizedBox(height: 8),
                Text(
                  'New Balance: ₵$newBalance',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCDFF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D3A2E),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Payment Failed', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCDFF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reset navigation state when returning to home page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    });
    
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
                    'Chairman Wontumi',
                    style: TextStyle(
                      color: Color(0xFFCDFF00),
                      fontSize: 20,
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

            // Net Worth Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        'Net worth',
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
                    '₵ 5,265.78',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '▲ +6.3% of invested',
                    style: TextStyle(
                      color: Color(0xFFCDFF00),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            color: const Color(0xFFCDFF00),
                            Icons.arrow_downward,
                            size: 18,
                          ),
                          label: const Text('Withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFCDFF00),
                            side: const BorderSide(
                              color: Color(0xFFCDFF00),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessingPayment ? null : _handleAddFunds,
                          icon: _isProcessingPayment 
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward,
                                  size: 18,
                                ),
                          label: Text(_isProcessingPayment ? 'Processing...' : 'Add Funds'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCDFF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // My Portfolio Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromARGB(67, 204, 255, 0),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: Text(
                        'My Portfolio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                        child: StockListWidget(
                      stockSymbols: ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN'],
                    )),
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

  Widget _buildStockItem(
    String name,
    String category,
    String price,
    String change,
    bool? isPositive,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (change.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  change,
                  style: TextStyle(
                    color: isPositive == true
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE57373),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
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
        
        // Navigate to explore page when search icon (index 1) is tapped
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExplorePage(),
            ),
          );
        } else if (index == 2) {
          // Navigate to investment page when work icon (index 2) is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvestmentPage(),
            ),
          );
        }
        // Stay on home page if home icon is tapped (index 0)
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
