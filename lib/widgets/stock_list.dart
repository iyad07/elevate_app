import 'package:flutter/material.dart';
import '../services/stock_service.dart';


class StockListWidget extends StatefulWidget {
  final List<String> stockSymbols;

  const StockListWidget({
    Key? key,
    required this.stockSymbols,
  }) : super(key: key);

  @override
  State<StockListWidget> createState() => _StockListWidgetState();
}

class _StockListWidgetState extends State<StockListWidget> {
  final StockService _stockService = StockService();
  final Map<String, StockQuote> _stockQuotes = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      for (String symbol in widget.stockSymbols) {
        // Add delay to respect API rate limits (5 requests per minute)
        if (widget.stockSymbols.indexOf(symbol) > 0) {
          await Future.delayed(const Duration(seconds: 12));
        }

        final quote = await _stockService.getStockQuote(symbol);
        setState(() {
          _stockQuotes[symbol] = quote;
        });
      }
    } on StockException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load stocks: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStocks() async {
    _stockQuotes.clear();
    await _loadStocks();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stockQuotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading stocks...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _stockQuotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshStocks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshStocks,
      child: ListView.builder(
        itemCount: widget.stockSymbols.length,
        itemBuilder: (context, index) {
          final symbol = widget.stockSymbols[index];
          final quote = _stockQuotes[symbol];

          if (quote == null) {
            return ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(symbol),
              subtitle: const Text('Loading...'),
            );
          }

          final isPositive = quote.change >= 0;
          final changeColor = isPositive ? Colors.green : Colors.red;
          final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: changeColor.withOpacity(0.1),
                child: Icon(
                  changeIcon,
                  color: changeColor,
                ),
              ),
              title: Text(
                quote.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                'Vol: ${_formatVolume(quote.volume)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${quote.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () => _showStockDetails(context, quote),
            ),
          );
        },
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toString();
  }

  void _showStockDetails(BuildContext context, StockQuote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quote.symbol),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Price', '\$${quote.price.toStringAsFixed(2)}'),
            _buildDetailRow('Change', '\$${quote.change.toStringAsFixed(2)}'),
            _buildDetailRow('Change %', '${quote.changePercent.toStringAsFixed(2)}%'),
            _buildDetailRow('High', '\$${quote.high.toStringAsFixed(2)}'),
            _buildDetailRow('Low', '\$${quote.low.toStringAsFixed(2)}'),
            _buildDetailRow('Volume', _formatVolume(quote.volume)),
            _buildDetailRow(
              'Latest Trading',
              '${quote.latestTradingDay.year}-${quote.latestTradingDay.month.toString().padLeft(2, '0')}-${quote.latestTradingDay.day.toString().padLeft(2, '0')}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage:
// StockListWidget(
//   stockSymbols: ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN'],
// )