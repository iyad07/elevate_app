import 'package:flutter/material.dart';
import '../screens/stock_detail_page.dart';
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
  final Map<String, CompanyProfile> _companyProfiles = {};
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

        // Fetch company profile for logo FIRST (before quote)
        try {
          final profile = await _stockService.getCompanyProfile(symbol);
          setState(() {
            _companyProfiles[symbol] = profile;
          });
          print('✅ Profile loaded for $symbol - Logo: ${profile.logo}');
        } catch (e) {
          print('❌ Failed to load profile for $symbol: $e');
        }

        // Small delay between profile and quote requests
        await Future.delayed(const Duration(milliseconds: 500));

        // Fetch quote
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
    _companyProfiles.clear();
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
        shrinkWrap: true, // Allow ListView to size itself based on content
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling when used inside another scrollable
        itemCount: widget.stockSymbols.length,
        itemBuilder: (context, index) {
          final symbol = widget.stockSymbols[index];
          final quote = _stockQuotes[symbol];
          final profile = _companyProfiles[symbol];

          if (quote == null) {
            return ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(symbol),
              subtitle: const Text('Loading...'),
            );
          }

          final isPositive = quote.change >= 0;
          final changeColor = isPositive ? Colors.green : Colors.red;

          return Card(
            elevation: 0,
            color: Colors.transparent,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _buildStockLogo(profile, symbol),
              title: Text(
                quote.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                profile?.name ?? 'Vol: ${_formatVolume(quote.volume)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                      color: Colors.white,
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockDetailPage(
                      symbol: quote.symbol,
                      initialQuote: quote,
                      initialProfile: profile,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockLogo(CompanyProfile? profile, String symbol) {
    if (profile != null && profile.logo.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            profile.logo,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackLogo(symbol);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }
    return _buildFallbackLogo(symbol);
  }

  Widget _buildFallbackLogo(String symbol) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          symbol
              .substring(0, symbol.length > 2 ? 2 : symbol.length)
              .toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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

  void _showStockDetails(
      BuildContext context, StockQuote quote, CompanyProfile? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (profile != null && profile.logo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.network(
                  profile.logo,
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote.symbol),
                  if (profile != null)
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Price', '\$${quote.price.toStringAsFixed(2)}'),
              _buildDetailRow('Change', '\$${quote.change.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Change %', '${quote.changePercent.toStringAsFixed(2)}%'),
              _buildDetailRow('High', '\$${quote.high.toStringAsFixed(2)}'),
              _buildDetailRow('Low', '\$${quote.low.toStringAsFixed(2)}'),
              _buildDetailRow('Volume', _formatVolume(quote.volume)),
              _buildDetailRow(
                'Latest Trading',
                '${quote.latestTradingDay.year}-${quote.latestTradingDay.month.toString().padLeft(2, '0')}-${quote.latestTradingDay.day.toString().padLeft(2, '0')}',
              ),
              if (profile != null) ...[
                const Divider(height: 24),
                _buildDetailRow('Exchange', profile.exchange),
                _buildDetailRow('Industry', profile.industry),
                _buildDetailRow('Country', profile.country),
                if (profile.marketCapitalization > 0)
                  _buildDetailRow(
                    'Market Cap',
                    '\$${(profile.marketCapitalization / 1000).toStringAsFixed(2)}B',
                  ),
              ],
            ],
          ),
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
