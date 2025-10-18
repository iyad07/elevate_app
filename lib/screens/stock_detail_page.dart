import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import 'dart:math' as math;

class StockDetailPage extends StatefulWidget {
  final String symbol;
  final StockQuote? initialQuote;
  final CompanyProfile? initialProfile;

  const StockDetailPage({
    Key? key,
    required this.symbol,
    this.initialQuote,
    this.initialProfile,
  }) : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final StockService _stockService = StockService();
  StockQuote? _quote;
  CompanyProfile? _profile;
  List<StockDataPoint>? _chartData;
  bool _isLoading = true;
  String _selectedTimeframe = '1D';
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y', 'All'];
  bool _useSimulatedData = false;

  @override
  void initState() {
    super.initState();
    _quote = widget.initialQuote;
    _profile = widget.initialProfile;
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    setState(() => _isLoading = true);

    try {
      // Load quote if not provided
      if (_quote == null) {
        _quote = await _stockService.getStockQuote(widget.symbol);
      }

      // Load profile if not provided
      if (_profile == null) {
        _profile = await _stockService.getCompanyProfile(widget.symbol);
      }

      // Try to load chart data, fallback to simulated if fails
      await _loadChartData();
    } catch (e) {
      print('Error loading stock data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChartData() async {
    final now = DateTime.now();
    DateTime from;
    int dataPoints;

    switch (_selectedTimeframe) {
      case '1D':
        from = now.subtract(const Duration(days: 1));
        dataPoints = 24;
        break;
      case '1W':
        from = now.subtract(const Duration(days: 7));
        dataPoints = 7;
        break;
      case '1M':
        from = now.subtract(const Duration(days: 30));
        dataPoints = 30;
        break;
      case '3M':
        from = now.subtract(const Duration(days: 90));
        dataPoints = 90;
        break;
      case '1Y':
        from = now.subtract(const Duration(days: 365));
        dataPoints = 52;
        break;
      case 'All':
        from = now.subtract(const Duration(days: 365 * 5));
        dataPoints = 260;
        break;
      default:
        from = now.subtract(const Duration(days: 30));
        dataPoints = 30;
    }

    try {
      final data = await _stockService.getCandleData(
        widget.symbol,
        from: from,
        to: now,
        resolution: 'D',
      );
      
      if (data.isNotEmpty) {
        setState(() {
          _chartData = data;
          _useSimulatedData = false;
        });
        return;
      }
    } catch (e) {
      print('Error loading chart data: $e');
    }

    // Fallback to simulated data based on current quote
    if (_quote != null) {
      setState(() {
        _chartData = _generateSimulatedData(dataPoints);
        _useSimulatedData = true;
      });
    }
  }

  List<StockDataPoint> _generateSimulatedData(int points) {
    if (_quote == null) return [];
    
    final random = math.Random();
    final data = <StockDataPoint>[];
    final now = DateTime.now();
    
    // Start from previous close and work towards current price
    double currentPrice = _quote!.previousClose;
    final priceChange = _quote!.currentPrice - _quote!.previousClose;
    final incrementPerPoint = priceChange / points;
    
    for (int i = 0; i < points; i++) {
      final timestamp = now.subtract(Duration(hours: points - i));
      
      // Add some realistic variance (±2% of current price)
      final variance = (_quote!.currentPrice * 0.02) * (random.nextDouble() - 0.5);
      currentPrice += incrementPerPoint + variance;
      
      // Keep within reasonable bounds
      final low = currentPrice * 0.995;
      final high = currentPrice * 1.005;
      
      data.add(StockDataPoint(
        timestamp: timestamp,
        open: currentPrice,
        high: high,
        low: low,
        close: currentPrice,
        volume: (1000000 + random.nextInt(5000000)),
      ));
    }
    
    // Ensure last point matches current price
    if (data.isNotEmpty) {
      final last = data.last;
      data[data.length - 1] = StockDataPoint(
        timestamp: last.timestamp,
        open: last.open,
        high: last.high,
        low: last.low,
        close: _quote!.currentPrice,
        volume: last.volume,
      );
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _quote == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFCDFF00)),
        ),
      );
    }

    final quote = _quote!;
    final isPositive = quote.change >= 0;
    final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1F), // Dark green background from image
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Explore',
                style: TextStyle(
                  color: Color(0xFFCDFF00),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_profile?.logo.isNotEmpty ?? false)
                              Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _profile!.logo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildFallbackLogo(),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quote.symbol,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_profile != null)
                                    Text(
                                      _profile!.name,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '\$${quote.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: changeColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${quote.change.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${isPositive ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%)',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chart Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2B1A), // Dark green card background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2D4A2D),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Timeframe Selector
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _timeframes.map((timeframe) {
                              final isSelected = timeframe == _selectedTimeframe;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedTimeframe = timeframe);
                                    _loadChartData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFCDFF00)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      timeframe,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF0F1419) : Colors.grey[400],
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Chart
                        _buildSimpleChart(isPositive),
                        if (_useSimulatedData)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Simulated trend data',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: const Color(0xFFCDFF00)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Buy',
                              style: TextStyle(
                                color: Color(0xFFCDFF00),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCDFF00),
                              foregroundColor: const Color(0xFF0F1419),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Sell',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F1419),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                   const SizedBox(height: 24),

                  // Overview Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2D4A2D),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Day's Range Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Day\'s range',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Low',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'High',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '\$${quote.lowPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${quote.highPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildDayRangeSlider(quote),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Set Alert
                          Row(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFFCDFF00),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Set alert',
                                style: TextStyle(
                                  color: Color(0xFFCDFF00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Statistics
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildOverviewStatRow('Open', '\$${quote.openPrice.toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          _buildOverviewStatRow('Prev. close', '\$${quote.previousClose.toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          _buildOverviewStatRow('Volume', '6,04,165'),
                          const SizedBox(height: 12),
                          _buildOverviewStatRow('Avg. trade price', '\$${((quote.highPrice + quote.lowPrice) / 2).toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          _buildOverviewStatRow('Lower circuit', '\$${(quote.lowPrice * 0.95).toStringAsFixed(2)}'),
                          const SizedBox(height: 12),
                          _buildOverviewStatRow('Upper circuit', '\$${(quote.highPrice * 1.05).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),

                 

                  // Action Buttons
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCDFF00), Color(0xFF9ACD32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.symbol.substring(0, widget.symbol.length > 2 ? 2 : widget.symbol.length),
            style: const TextStyle(
              color: Color(0xFF0F1419),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
  }

  Widget _buildSimpleChart(bool isPositive) {
    return SizedBox(
      height: 200,
      child: _chartData == null || _chartData!.isEmpty
          ? Center(
              child: Text(
                'Loading chart...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          : CustomPaint(
              painter: ChartPainter(
                dataPoints: _chartData!,
                isPositive: isPositive,
              ),
              size: const Size(double.infinity, 200),
            ),
    );
  }

  Widget _buildStatCard(List<_StatItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252541),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDayRangeSlider(StockQuote quote) {
    final range = quote.highPrice - quote.lowPrice;
    final currentPosition = range > 0 ? (quote.currentPrice - quote.lowPrice) / range : 0.5;
    
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color(0xFF374151),
      ),
      child: Stack(
        children: [
          // Background track
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFF374151),
            ),
          ),
          // Progress track
          FractionallySizedBox(
            widthFactor: currentPosition.clamp(0.0, 1.0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: const Color(0xFFCDFF00),
              ),
            ),
          ),
          // Current position indicator
          Positioned(
            left: (currentPosition.clamp(0.0, 1.0) * MediaQuery.of(context).size.width * 0.8) - 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFCDFF00),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

// Chart Painter with smooth curves
class ChartPainter extends CustomPainter {
  final List<StockDataPoint> dataPoints;
  final bool isPositive;

  ChartPainter({required this.dataPoints, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              .withOpacity(0.25),
          (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              .withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final prices = dataPoints.map((d) => d.close).toList();
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final priceRange = (maxPrice - minPrice).abs();
    
    // Add padding to prevent clipping at edges
    final padding = size.height * 0.1;

    final path = Path();
    final gradientPath = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedPrice = priceRange > 0 
          ? (dataPoints[i].close - minPrice) / priceRange
          : 0.5;
      final y = size.height - padding - (normalizedPrice * (size.height - 2 * padding));

      if (i == 0) {
        path.moveTo(x, y);
        gradientPath.moveTo(x, size.height);
        gradientPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        gradientPath.lineTo(x, y);
      }
    }

    gradientPath.lineTo(size.width, size.height);
    gradientPath.close();

    canvas.drawPath(gradientPath, gradientPaint);
    canvas.drawPath(path, paint);

    // Draw current price indicator dot
    if (dataPoints.isNotEmpty) {
      final lastPrice = dataPoints.last.close;
      final normalizedPrice = priceRange > 0
          ? (lastPrice - minPrice) / priceRange
          : 0.5;
      final y = size.height - padding - (normalizedPrice * (size.height - 2 * padding));
      
      final dotPaint = Paint()
        ..color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      
      final dotOutlinePaint = Paint()
        ..color = const Color(0xFF252541)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width, y), 5, dotOutlinePaint);
      canvas.drawCircle(Offset(size.width, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}