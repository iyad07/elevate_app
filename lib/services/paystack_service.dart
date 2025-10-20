import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';

class PaystackService {
  // Demo API key - replace with your actual Paystack secret key
  static const String _secretKey = 'sk_test_0ea71ef818f8d1b993f44a9312577152d6c2eb08';
  static const String _publicKey = 'pk_test_your_paystack_public_key_here';
  static const String _baseUrl = 'https://api.paystack.co';
  final ApiClient _api = ApiClient();

  final Uuid _uuid = const Uuid();

  /// Initialize a payment transaction
  /// Returns the authorization URL for payment completion
  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
    List<String>? paymentChannels,
  }) async {
    try {
      // Convert amount to kobo/pesewas (smallest currency unit)
      final int amountInKobo = (amount * 100).round();
      
      final Map<String, dynamic> requestBody = {
        'email': email,
        'amount': amountInKobo,
        'currency': currency.toUpperCase(),
        'reference': _uuid.v4(),
        'callback_url': 'https://your-app.com/payment-callback',
      };

      // Add payment channels if specified
      if (paymentChannels != null && paymentChannels.isNotEmpty) {
        requestBody['channels'] = paymentChannels;
      }

      // Add metadata if provided
      if (metadata != null) {
        requestBody['metadata'] = metadata;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Transaction initialization failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify a transaction status
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Transaction verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Process payment using Paystack Flutter SDK
  /// Supports both card and mobile money payments
  Future<Map<String, dynamic>> processPayment({
    required BuildContext context,
    required String customerEmail,
    required double amount,
    required String currency,
    List<String>? paymentChannels,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final String uniqueReference = _uuid.v4();

      // Convert amount to kobo/pesewas (smallest currency unit)
      final int amountInKobo = (amount * 100).round();

      // Available payment channels for Ghana
      final List<String> defaultChannels = [
        'card',
        'mobile_money',
        'bank_transfer',
      ];

      // Web-specific flow: initialize and verify via backend endpoints
      if (kIsWeb) {
        try {
          final initRes = await _api.dio.post(
            '/api/payments/initialize',
            data: {
              'email': customerEmail,
              'amount': amount.toStringAsFixed(2),
              'currency': currency,
              'callback_url': 'https://your-app.com/payment-callback',
            },
          );
          final initData = (initRes.data as Map<String, dynamic>);
          final authUrl = initData['authorization_url'] as String?;
          final reference = initData['reference'] as String?;

          if (authUrl == null || reference == null) {
            return {
              'success': false,
              'message': 'Missing authorization URL or reference',
              'reference': uniqueReference,
            };
          }

          final launched = await launchUrl(
            Uri.parse(authUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            return {
              'success': false,
              'message': 'Could not open checkout URL',
              'reference': reference,
            };
          }

          // Poll verification via backend while user completes payment
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(seconds: 3));
            final verifyRes = await _api.dio.get('/api/payments/verify/$reference');
            final verifyData = (verifyRes.data as Map<String, dynamic>);
            final status = verifyData['status'] as String?;
            if (status == 'success') {
              return {
                'success': true,
                'data': verifyData,
                'reference': reference,
                'message': 'Payment completed successfully',
              };
            } else if (status == 'failed') {
              return {
                'success': false,
                'message': 'Payment failed',
                'reference': reference,
              };
            }
          }

          return {
            'success': false,
            'message': 'Verification timeout. Complete payment then return to the app.',
            'reference': reference,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Payment init/verify error: ${e.toString()}',
            'reference': uniqueReference,
          };
        }
      }

      // Mobile flow (Android/iOS): use SDK
      final payWithPaystack = PayWithPayStack();

      // Create a completer to handle the async payment result
      Map<String, dynamic> paymentResult = {};

      await payWithPaystack.now(
        context: context,
        secretKey: _secretKey,
        customerEmail: customerEmail,
        reference: uniqueReference,
        currency: currency.toUpperCase(),
        amount: amountInKobo.toDouble(),
        callbackUrl: 'https://your-app.com/payment-callback',
        transactionCompleted: (paymentData) {
          paymentResult = {
            'success': true,
            'data': paymentData,
            'reference': uniqueReference,
            'message': 'Payment completed successfully',
          };
        },
        transactionNotCompleted: (reason) {
          paymentResult = {
            'success': false,
            'message': reason ?? 'Payment was not completed',
            'reference': uniqueReference,
          };
        },
      );

      // Wait a bit for the callback to be processed
      await Future.delayed(const Duration(milliseconds: 500));

      return paymentResult.isNotEmpty
          ? paymentResult
          : {
              'success': false,
              'message': 'Payment process was interrupted',
              'reference': uniqueReference,
            };
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment error: ${e.toString()}',
      };
    }
  }

  /// Add funds to wallet using Paystack
  /// This method combines payment processing, verification, and wallet update
  Future<Map<String, dynamic>> addFundsToWallet({
    required BuildContext context,
    required String customerEmail,
    required double amount,
    String currency = 'GHS',
    Map<String, dynamic>? userMetadata,
  }) async {
    try {
      // Process the payment (web via backend, mobile via SDK)
      final paymentResult = await processPayment(
        context: context,
        customerEmail: customerEmail,
        amount: amount,
        currency: currency,
        paymentChannels: ['card', 'mobile_money'],
        metadata: {
          'purpose': 'wallet_funding',
          'user_email': customerEmail,
          ...?userMetadata,
        },
      );

      if (paymentResult['success'] == true) {
        final reference = paymentResult['reference'] as String?;
        if (reference == null || reference.isEmpty) {
          return {
            'success': false,
            'message': 'Missing payment reference for verification',
          };
        }

        // Verify transaction status (web via backend; mobile still direct to Paystack)
        Map<String, dynamic> verificationResult;
        if (kIsWeb) {
          try {
            final verifyRes = await _api.dio.get('/api/payments/verify/$reference');
            verificationResult = {
              'success': true,
              'data': (verifyRes.data as Map<String, dynamic>),
            };
          } catch (e) {
            verificationResult = {
              'success': false,
              'message': 'Could not verify payment: ${e.toString()}',
            };
          }
        } else {
          verificationResult = await verifyTransaction(reference);
        }

        if (verificationResult['success'] == true) {
          final transactionData = verificationResult['data'] as Map<String, dynamic>;
          final status = transactionData['status'] as String?;

          if (status == 'success') {
            // Credit wallet in backend
            try {
              final walletRes = await _api.dio.post(
                '/api/wallet/add-funds',
                data: {
                  'amount': amount.toStringAsFixed(2),
                  'currency': currency,
                },
              );
              final walletData = (walletRes.data as Map<String, dynamic>);

              return {
                'success': true,
                'message': 'Funds added successfully to wallet',
                'amount': amount,
                'currency': currency,
                'transaction_reference': reference,
                'balance': walletData['balance'],
              };
            } on Exception catch (e) {
              return {
                'success': false,
                'message': 'Wallet credit failed: ${e.toString()}',
              };
            }
          } else {
            return {
              'success': false,
              'message': 'Payment verification failed',
            };
          }
        } else {
          return {
            'success': false,
            'message': verificationResult['message'] ?? 'Could not verify payment',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Payment failed: ${paymentResult['message']}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Wallet funding error: ${e.toString()}',
      };
    }
  }

  /// Get list of supported banks for Ghana
  Future<List<Map<String, dynamic>>> getSupportedBanks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bank?country=ghana'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}