/// Payment method options.
enum PaymentMethod { cash, transfer, check }

extension PaymentMethodExt on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.check:
        return 'check';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.transfer:
        return 'تحويل بنكي';
      case PaymentMethod.check:
        return 'شيك';
    }
  }

  static PaymentMethod fromString(String s) {
    switch (s) {
      case 'transfer':
        return PaymentMethod.transfer;
      case 'check':
        return PaymentMethod.check;
      default:
        return PaymentMethod.cash;
    }
  }
}

/// A payment record for a student.
class Payment {
  final int? id;
  final int studentId;
  final double amount;
  final String paymentDate; // ISO date string
  final PaymentMethod paymentMethod;
  final String? month; // yyyy-MM
  final String? notes;

  const Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.month,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] != null ? (map['id'] as num).toInt() : null,
      studentId: (map['studentId'] as num).toInt(),
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0.0,
      paymentDate: (map['paymentDate'] ?? '').toString(),
      paymentMethod: PaymentMethodExt.fromString((map['paymentMethod'] ?? '').toString()),
      month: map['month'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'amount': amount.toString(),
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod.value,
      'month': month,
      'notes': notes,
    };
  }
}
