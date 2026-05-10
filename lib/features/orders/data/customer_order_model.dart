import 'package:isar/isar.dart';

part 'customer_order_model.g.dart';

enum OrderStatus { pending, sold, cancelled }
enum PaymentMethod { cash, mobile, credit }

@collection
class CustomerOrder {
  Id id = Isar.autoIncrement;

  late int productId;
  late String customerName;
  String? phoneNumber;
  late double amount;
  
  @Index()
  late DateTime dueDate;

  @enumerated
  late OrderStatus status;

  @enumerated
  late PaymentMethod paymentMethod;

  late double costPriceAtTime;
  late double sellingPriceAtTime;
  
  double advancePayment = 0.0;

  DateTime? fulfilledAt;
  
  bool isVoid = false;
}
