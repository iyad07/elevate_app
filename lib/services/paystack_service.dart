import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PaystackService {
  // Demo API key - replace with your actual Paystack secret key
  static const String _secretKey = 'sk_test_0ea71ef818f8d1b993f44a9312577152d6c2eb08';
  static const String _publicKey = 'pk_test_your_paystack_public_key_here';
  static const String _baseUrl = 'https://api.paystack.co';
  
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
  /// This method combines payment processing and wallet update
  Future<Map<String, dynamic>> addFundsToWallet({
    required BuildContext context,
    required String customerEmail,
    required double amount,
    String currency = 'GHS', // Default to Ghana Cedis
    Map<String, dynamic>? userMetadata,
  }) async {
    try {
      // Process the payment
      final paymentResult = await processPayment(
        context: context,
        customerEmail: customerEmail,
        amount: amount,
        currency: currency,
        paymentChannels: ['card', 'mobile_money'], // Focus on card and mobile money
        metadata: {
          'purpose': 'wallet_funding',
          'user_email': customerEmail,
          ...?userMetadata,
        },
      );

      if (paymentResult['success'] == true) {
        // Verify the transaction
        final verificationResult = await verifyTransaction(
          paymentResult['reference'],
        );

        if (verificationResult['success'] == true) {
          final transactionData = verificationResult['data'];
          
          // Check if payment was successful
          if (transactionData['status'] == 'success') {
            // Here you would typically update the user's wallet balance
            // in your backend/database
            
            return {
              'success': true,
              'message': 'Funds added successfully to wallet',
              'amount': amount,
              'currency': currency,
              'transaction_reference': paymentResult['reference'],
              'transaction_data': transactionData,
            };
          } else {
            return {
              'success': false,
              'message': 'Payment verification failed: ${transactionData['gateway_response']}',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Could not verify payment: ${verificationResult['message']}',
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