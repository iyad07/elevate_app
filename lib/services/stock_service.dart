import 'package:dio/dio.dart';

class StockService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl = 'https://www.alphavantage.co/query';

  StockService({
    String? apiKey,
    Dio? dio,
  })  : _apiKey = apiKey ?? 'FNO0LGFVNDYIFRJ5',
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Fetches current stock quote for a given symbol
  Future<StockQuote> getStockQuote(String symbol) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'function': 'GLOBAL_QUOTE',
          'symbol': symbol,
          'apikey': _apiKey,
        },
      );

      if (response.data['Global Quote'] == null) {
        throw StockException('Stock symbol not found or invalid API response');
      }

      return StockQuote.fromJson(response.data['Global Quote']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches intraday stock data
  Future<List<StockDataPoint>> getIntradayData(
    String symbol, {
    String interval = '5min',
  }) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'function': 'TIME_SERIES_INTRADAY',
          'symbol': symbol,
          'interval': interval,
          'apikey': _apiKey,
        },
      );

      final timeSeriesKey = 'Time Series ($interval)';
      if (response.data[timeSeriesKey] == null) {
        throw StockException('No intraday data available');
      }

      final timeSeries = response.data[timeSeriesKey] as Map<String, dynamic>;
      return timeSeries.entries
          .map((e) => StockDataPoint.fromJson(e.key, e.value))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches daily stock data
  Future<List<StockDataPoint>> getDailyData(String symbol) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'function': 'TIME_SERIES_DAILY',
          'symbol': symbol,
          'apikey': _apiKey,
        },
      );

      if (response.data['Time Series (Daily)'] == null) {
        throw StockException('No daily data available');
      }

      final timeSeries = response.data['Time Series (Daily)'] as Map<String, dynamic>;
      return timeSeries.entries
          .map((e) => StockDataPoint.fromJson(e.key, e.value))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Searches for stock symbols
  Future<List<StockSearchResult>> searchSymbol(String keywords) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'function': 'SYMBOL_SEARCH',
          'keywords': keywords,
          'apikey': _apiKey,
        },
      );

      if (response.data['bestMatches'] == null) {
        return [];
      }

      final matches = response.data['bestMatches'] as List;
      return matches.map((m) => StockSearchResult.fromJson(m)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
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
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final int volume;
  final DateTime latestTradingDay;

  StockQuote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.volume,
    required this.latestTradingDay,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      symbol: json['01. symbol'] ?? '',
      price: double.parse(json['05. price'] ?? '0'),
      change: double.parse(json['09. change'] ?? '0'),
      changePercent: double.parse(
        (json['10. change percent'] ?? '0%').replaceAll('%', ''),
      ),
      high: double.parse(json['03. high'] ?? '0'),
      low: double.parse(json['04. low'] ?? '0'),
      volume: int.parse(json['06. volume'] ?? '0'),
      latestTradingDay: DateTime.parse(json['07. latest trading day'] ?? ''),
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

  factory StockDataPoint.fromJson(String timestamp, Map<String, dynamic> json) {
    return StockDataPoint(
      timestamp: DateTime.parse(timestamp),
      open: double.parse(json['1. open'] ?? '0'),
      high: double.parse(json['2. high'] ?? '0'),
      low: double.parse(json['3. low'] ?? '0'),
      close: double.parse(json['4. close'] ?? '0'),
      volume: int.parse(json['5. volume'] ?? '0'),
    );
  }
}

class StockSearchResult {
  final String symbol;
  final String name;
  final String type;
  final String region;
  final String currency;

  StockSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    required this.region,
    required this.currency,
  });

  factory StockSearchResult.fromJson(Map<String, dynamic> json) {
    return StockSearchResult(
      symbol: json['1. symbol'] ?? '',
      name: json['2. name'] ?? '',
      type: json['3. type'] ?? '',
      region: json['4. region'] ?? '',
      currency: json['8. currency'] ?? '',
    );
  }
}

class StockException implements Exception {
  final String message;
  StockException(this.message);

  @override
  String toString() => 'StockException: $message';
}