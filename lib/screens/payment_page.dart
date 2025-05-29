import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum PaymentMethod { mpesa, card, bank }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _selectedMethod = PaymentMethod.mpesa; // Default selection

  void _completePayment() {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }
    // Process payment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment processing via ${_selectedMethod.toString().split('.').last} (Simulated)',
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required IconData icon,
    required PaymentMethod value,
  }) {
    bool isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedPaymentMethod
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.appBar : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? AppStyles.cardBoxShadow : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.appBar, size: 28),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppStyles.regularText)),
            Radio<PaymentMethod>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (PaymentMethod? newValue) {
                setState(() {
                  _selectedMethod = newValue;
                });
              },
              activeColor: AppColors.appBar,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment', style: AppStyles.appBarTitleStyle),
        backgroundColor: AppColors.appBar,
        elevation: 2.0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: AppStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Reservation Summary Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.cardBorderRadius,
              ),
              color: AppColors.cardBackground,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppStyles.cardBorderRadius,
                  boxShadow: AppStyles.cardBoxShadow,
                ),
                padding: AppStyles.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Summary',
                      style: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow('Cemetery:', 'Lang’ata Cemetery (Sample)'),
                    _summaryRow('Date:', '2024-08-15 (Sample)'),
                    _summaryRow('Spot Number:', 'A-12 (Sample)'),
                    const Divider(height: 24, thickness: 1),
                    _summaryRow(
                      'Total Amount:',
                      'KES 10,000',
                      isBold: true,
                      color: AppColors.spotsAvailable,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            Text(
              'Select Payment Method',
              style: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12.0),

            // Payment Methods
            _buildPaymentMethodTile(
              title: 'M-Pesa',
              icon: Icons.phone_android, // Example icon
              value: PaymentMethod.mpesa,
            ),
            _buildPaymentMethodTile(
              title: 'Card (Visa, Mastercard)',
              icon: Icons.credit_card,
              value: PaymentMethod.card,
            ),
            _buildPaymentMethodTile(
              title: 'Bank Transfer',
              icon: Icons.account_balance,
              value: PaymentMethod.bank,
            ),
            const SizedBox(height: 32.0),

            // Complete Payment Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _completePayment,
              child: const Text(
                'Complete Payment',
                style: AppStyles.buttonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.regularText.copyWith(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: AppStyles.regularText.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.cardTitle,
            ),
          ),
        ],
      ),
    );
  }
}
