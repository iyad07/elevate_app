import 'package:dio/dio.dart';

class StockService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl = 'https://finnhub.io/api/v1';

  StockService({
    String? apiKey,
    Dio? dio,
  })  : _apiKey = apiKey ?? 'd3nphq1r01qkgr8r7a2gd3nphq1r01qkgr8r7a30',
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Fetches current stock quote for a given symbol
  Future<StockQuote> getStockQuote(String symbol) async {
    try {
      final response = await _dio.get(
        '/quote',
        queryParameters: {
          'symbol': symbol,
          'token': _apiKey,
        },
      );

      if (response.data == null || response.data['c'] == null) {
        throw StockException('Stock symbol not found or invalid API response');
      }

      return StockQuote.fromJson(symbol, response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches company profile for a given symbol
  Future<CompanyProfile> getCompanyProfile(String symbol) async {
    try {
      final response = await _dio.get(
        '/stock/profile2',
        queryParameters: {
          'symbol': symbol,
          'token': _apiKey,
        },
      );

      if (response.data == null || response.data.isEmpty) {
        throw StockException('Company profile not found');
      }

      return CompanyProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches candle/OHLC data for a given symbol
  Future<List<StockDataPoint>> getCandleData(
    String symbol, {
    required DateTime from,
    required DateTime to,
    String resolution = 'D', // D = daily, W = weekly, M = monthly
  }) async {
    try {
      final response = await _dio.get(
        '/stock/candle',
        queryParameters: {
          'symbol': symbol,
          'resolution': resolution,
          'from': from.millisecondsSinceEpoch ~/ 1000,
          'to': to.millisecondsSinceEpoch ~/ 1000,
          'token': _apiKey,
        },
      );

      if (response.data['s'] == 'no_data') {
        throw StockException('No candle data available for this period');
      }

      if (response.data['c'] == null) {
        throw StockException('Invalid candle data response');
      }

      return _parseCandleData(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Searches for stock symbols
  Future<List<StockSearchResult>> searchSymbol(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'token': _apiKey,
        },
      );

      if (response.data['result'] == null) {
        return [];
      }

      final results = response.data['result'] as List;
      return results.map((r) => StockSearchResult.fromJson(r)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches market news
  Future<List<NewsArticle>> getMarketNews({String category = 'general'}) async {
    try {
      final response = await _dio.get(
        '/news',
        queryParameters: {
          'category': category,
          'token': _apiKey,
        },
      );

      if (response.data == null) {
        return [];
      }

      final articles = response.data as List;
      return articles.map((a) => NewsArticle.fromJson(a)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  List<StockDataPoint> _parseCandleData(Map<String, dynamic> data) {
    final List<dynamic> timestamps = data['t'];
    final List<dynamic> opens = data['o'];
    final List<dynamic> highs = data['h'];
    final List<dynamic> lows = data['l'];
    final List<dynamic> closes = data['c'];
    final List<dynamic> volumes = data['v'];

    List<StockDataPoint> points = [];
    for (int i = 0; i < timestamps.length; i++) {
      points.add(StockDataPoint(
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
        open: (opens[i] as num).toDouble(),
        high: (highs[i] as num).toDouble(),
        low: (lows[i] as num).toDouble(),
        close: (closes[i] as num).toDouble(),
        volume: (volumes[i] as num).toInt(),
      ));
    }
    return points;
  }

  StockException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return StockException('Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        return StockException(
          'Server error: ${e.response?.statusCode}',
        );
      case DioExceptionType.connectionError:
        return StockException('No internet connection');
      default:
        return StockException('An unexpected error occurred: ${e.message}');
    }
  }
}

class StockQuote {
  final String symbol;
  final double currentPrice; // c
  final double change; // d
  final double changePercent; // dp
  final double highPrice; // h
  final double lowPrice; // l
  final double openPrice; // o
  final double previousClose; // pc
  final int timestamp; // t

  StockQuote({
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.previousClose,
    required this.timestamp,
  });

  factory StockQuote.fromJson(String symbol, Map<String, dynamic> json) {
    return StockQuote(
      symbol: symbol,
      currentPrice: (json['c'] as num?)?.toDouble() ?? 0.0,
      change: (json['d'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['dp'] as num?)?.toDouble() ?? 0.0,
      highPrice: (json['h'] as num?)?.toDouble() ?? 0.0,
      lowPrice: (json['l'] as num?)?.toDouble() ?? 0.0,
      openPrice: (json['o'] as num?)?.toDouble() ?? 0.0,
      previousClose: (json['pc'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  // Legacy compatibility properties
  double get price => currentPrice;
  double get high => highPrice;
  double get low => lowPrice;
  int get volume => 0; // Finnhub quote doesn't include volume
  DateTime get latestTradingDay => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

class CompanyProfile {
  final String name;
  final String ticker;
  final String country;
  final String currency;
  final String exchange;
  final String industry;
  final String logo;
  final double marketCapitalization;
  final String weburl;

  CompanyProfile({
    required this.name,
    required this.ticker,
    required this.country,
    required this.currency,
    required this.exchange,
    required this.industry,
    required this.logo,
    required this.marketCapitalization,
    required this.weburl,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] ?? '',
      ticker: json['ticker'] ?? '',
      country: json['country'] ?? '',
      currency: json['currency'] ?? '',
      exchange: json['exchange'] ?? '',
      industry: json['finnhubIndustry'] ?? '',
      logo: json['logo'] ?? '',
      marketCapitalization: (json['marketCapitalization'] as num?)?.toDouble() ?? 0.0,
      weburl: json['weburl'] ?? '',
    );
  }
}

class StockDataPoint {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  StockDataPoint({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockSearchResult {
  final String symbol;
  final String description;
  final String displaySymbol;
  final String type;

  StockSearchResult({
    required this.symbol,
    required this.description,
    required this.displaySymbol,
    required this.type,
  });

  factory StockSearchResult.fromJson(Map<String, dynamic> json) {
    return StockSearchResult(
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      displaySymbol: json['displaySymbol'] ?? '',
      type: json['type'] ?? '',
    );
  }

  // Legacy compatibility properties
  String get name => description;
  String get region => '';
  String get currency => '';
}

class NewsArticle {
  final int id;
  final String category;
  final DateTime datetime;
  final String headline;
  final String image;
  final String source;
  final String summary;
  final String url;

  NewsArticle({
    required this.id,
    required this.category,
    required this.datetime,
    required this.headline,
    required this.image,
    required this.source,
    required this.summary,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      datetime: DateTime.fromMillisecondsSinceEpoch((json['datetime'] ?? 0) * 1000),
      headline: json['headline'] ?? '',
      image: json['image'] ?? '',
      source: json['source'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class StockException implements Exception {
  final String message;
  StockException(this.message);

  @override
  String toString() => 'StockException: $message';
}