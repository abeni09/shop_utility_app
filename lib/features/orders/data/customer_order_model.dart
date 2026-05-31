import 'package:isar/isar.dart';

part 'customer_order_model.g.dart';

enum OrderStatus { pending, sold, cancelled }
enum PaymentMethod { cash, mobile, credit }

@collection
class CustomerOrder {
  Id id = Isar.autoIncrement;

  int productId = 0;
  String customerName = '';
  String? phoneNumber;
  double amount = 0.0;
  
  @Index()
  DateTime dueDate = DateTime.now();

  @enumerated
  OrderStatus status = OrderStatus.pending;

  @enumerated
  PaymentMethod paymentMethod = PaymentMethod.cash;

  double costPriceAtTime = 0.0;
  double sellingPriceAtTime = 0.0;
  
  double advancePayment = 0.0;

  DateTime? fulfilledAt;
  
  bool isVoid = false;

  String? addonName;
  double? addonPrice;
  double? addonCost;
  double? addonAmount;
}

