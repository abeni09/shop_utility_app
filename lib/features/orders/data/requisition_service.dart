import 'package:shopsync/features/orders/data/order_repository.dart';
import 'package:shopsync/features/products/data/product_repository.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/products/data/product_model.dart';

class RequisitionItem {
  final Product product;
  final double orderAmount;
  final double bufferAmount;
  
  double get totalNeeded => orderAmount + bufferAmount;

  RequisitionItem({
    required this.product,
    required this.orderAmount,
    this.bufferAmount = 0.0,
  });
}

class RequisitionService {
  final OrderRepository orderRepo;
  final ProductRepository productRepo;

  RequisitionService({required this.orderRepo, required this.productRepo});

  Future<List<RequisitionItem>> calculateTomorrowRequisition() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final orders = await orderRepo.getOrdersForDate(tomorrow);
    final products = await productRepo.getAllProducts();

    final Map<int, double> productTotals = {};

    for (var order in orders) {
      if (order.status == OrderStatus.pending && !order.isVoid) {
        productTotals[order.productId] = (productTotals[order.productId] ?? 0.0) + order.amount;
      }
    }

    return products.map((p) {
      return RequisitionItem(
        product: p,
        orderAmount: productTotals[p.id] ?? 0.0,
        // For now, buffer is 0. In future, could be based on history or user setting.
        bufferAmount: (productTotals[p.id] ?? 0.0) * 0.1, // 10% default buffer
      );
    }).where((item) => item.totalNeeded > 0).toList();
  }
}
