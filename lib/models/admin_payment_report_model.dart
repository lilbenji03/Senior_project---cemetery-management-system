// lib/models/admin_payment_report_model.dart

import 'package:intl/intl.dart';

class PaymentDetail {
  final double amount;
  final DateTime paymentDate;
  final String customerName;

  PaymentDetail({
    required this.amount,
    required this.paymentDate,
    required this.customerName,
  });

  // This factory now correctly parses the FLAT output from our RPC function.
  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    try {
      return PaymentDetail(
        amount: (json['final_total_cost'] as num?)?.toDouble() ?? 0.0,
        paymentDate: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime(1970),
        customerName: json['user_full_name'] as String? ??
            'N/A', // The RPC renames the column for us
      );
    } catch (e) {
      print("Error parsing PaymentDetail: $e, from JSON: $json");
      return PaymentDetail(
          amount: 0,
          paymentDate: DateTime(1970),
          customerName: 'Error Parsing Data');
    }
  }

  // MODIFIED: Changed currency symbol to 'Ksh.'
  String get formattedAmount =>
      NumberFormat.currency(symbol: 'Ksh. ', decimalDigits: 2).format(amount);
  String get formattedDate => DateFormat.yMMMd().format(paymentDate);
}

class AdminPaymentReport {
  final double totalRevenue;
  final int totalTransactions;
  final DateTime startDate;
  final DateTime endDate;
  final List<PaymentDetail> payments;
  final String cemeteryName;

  AdminPaymentReport({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.startDate,
    required this.endDate,
    required this.payments,
    required this.cemeteryName,
  });

  factory AdminPaymentReport.fromResponse({
    required List<dynamic> responseData,
    required DateTime startDate,
    required DateTime endDate,
    required String cemeteryName,
  }) {
    double calculatedRevenue = 0.0;
    final paymentDetails = responseData.map((item) {
      final detail = PaymentDetail.fromJson(item as Map<String, dynamic>);
      calculatedRevenue += detail.amount;
      return detail;
    }).toList();
    return AdminPaymentReport(
      totalRevenue: calculatedRevenue,
      totalTransactions: paymentDetails.length,
      startDate: startDate,
      endDate: endDate,
      payments: paymentDetails,
      cemeteryName: cemeteryName,
    );
  }

  // MODIFIED: Changed currency symbol to 'Ksh.'
  String get formattedTotalRevenue =>
      NumberFormat.currency(symbol: 'Ksh. ', decimalDigits: 2)
          .format(totalRevenue);
  String get formattedDateRange =>
      '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}';
}
