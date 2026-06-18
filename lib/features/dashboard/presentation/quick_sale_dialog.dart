import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/products/presentation/daily_stock_providers.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';

// class QuickSaleDialog extends ConsumerWidget {
//   const QuickSaleDialog({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final products = ref.watch(productsProvider).value ?? [];

class QuickSaleDialog extends ConsumerStatefulWidget {
  const QuickSaleDialog({super.key});

  @override
  ConsumerState<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends ConsumerState<QuickSaleDialog> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, bool> _addBag = {};
  final Map<int, bool> _breakEven = {};
  final TextEditingController _customerController = TextEditingController(
    text: 'Walk-in',
  );
  int? _selectedBagId;

  int? _selectedAddonId = 0;
  String? _addonName;
  double? _addonPrice;
  double? _addonCost;
  double _addonAmount = 1.0;

  @override
  void dispose() {
    _customerController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final products = ref.watch(productsProvider).value ?? [];
    final availabilityAsync = ref.watch(walkInAvailabilityProvider(today));
    final addons = ref.watch(addonsProvider).value ?? [];

    // Filter products
    final activeProducts = products.where((p) => !p.isVoid).toList();

    // Find all "Bag" products
    final bagProducts = activeProducts.where((p) {
      final name = p.name.toLowerCase();
      return name.contains('bag') || name.contains('festal');
    }).toList();

    // Initialize selected bag if not set
    if (_selectedBagId == null && bagProducts.isNotEmpty) {
      _selectedBagId = bagProducts.first.id;
    }

    final currentBag = bagProducts
        .where((p) => p.id == _selectedBagId)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TextField(
              controller: _customerController,
              decoration: InputDecoration(
                hintText: 'Customer Name (Optional)',
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Color(0xFF818CF8),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedAddonId,
              dropdownColor: const Color(0xFF1E293B),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: [
                const DropdownMenuItem<int>(
                  value: 0,
                  child: Text('NONE (NO ADD-ON)'),
                ),
                ...addons.map(
                  (a) => DropdownMenuItem<int>(
                    value: a.id,
                    child: Text(
                      '${a.name.toUpperCase()} (${a.price.toStringAsFixed(0)} ETB)',
                    ),
                  ),
                ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text(
                    '+ ADD CUSTOM ADD-ON',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              onChanged: (val) async {
                if (val == 0) {
                  setState(() {
                    _selectedAddonId = 0;
                    _addonName = null;
                    _addonPrice = null;
                    _addonCost = null;
                  });
                } else if (val == -1) {
                  final result = await _showCustomAddonDialog(context, ref);
                  if (result != null) {
                    setState(() {
                      _selectedAddonId = result.id;
                      _addonName = result.name;
                      _addonPrice = result.price;
                      _addonCost = result.cost;
                    });
                  } else {
                    setState(() {
                      _selectedAddonId = 0;
                      _addonName = null;
                      _addonPrice = null;
                      _addonCost = null;
                    });
                  }
                } else if (val != null) {
                  final selectedAddon = addons.firstWhere((a) => a.id == val);
                  setState(() {
                    _selectedAddonId = val;
                    _addonName = selectedAddon.name;
                    _addonPrice = selectedAddon.price;
                    _addonCost = selectedAddon.cost;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Add-on / Service (Optional)',
                labelStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.add_box_rounded,
                  size: 20,
                  color: Color(0xFF818CF8),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            if (_addonName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _addonName!.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Colors.amberAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Price: ${_addonPrice?.toStringAsFixed(0)} ETB',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              if (_addonAmount > 1) {
                                setState(() => _addonAmount--);
                              }
                            },
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              _addonAmount.toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              setState(() => _addonAmount++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUICK SALE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 14,
                    color: Color(0xFF818CF8),
                  ),
                ),
                if (bagProducts.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedBagId,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF818CF8),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                        onChanged: (val) =>
                            setState(() => _selectedBagId = val),
                        items: bagProducts
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bagProducts.isNotEmpty
                  ? 'Bundle with ${currentBag?.name ?? "Bag"} to fulfill instantly.'
                  : 'Select a product and quantity for instant fulfillment.',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: availabilityAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF818CF8)),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (availability) => activeProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No products in stock.',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: activeProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = activeProducts[index];
                          final status =
                              availability[product.id] ??
                              (
                                walkInAvailable: 0.0,
                                physicalRemaining: 0.0,
                                reserved: 0.0,
                                totalReceived: 0.0,
                                totalSold: 0.0,
                              );

                          return _buildQuickSaleTile(
                            product,
                            currentBag,
                            bagProducts,
                            status,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSaleTile(
    dynamic product,
    dynamic bagProduct,
    List<dynamic> allBagProducts,
    StockStatus status,
  ) {
    final hasBag = _addBag[product.id] ?? false;
    final isBreakEven = _breakEven[product.id] ?? false;
    final isAnyBag = allBagProducts.any((p) => p.id == product.id);
    final walkInAvailable = status.walkInAvailable;
    final isOutOfStock = walkInAvailable <= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOutOfStock
              ? Colors.redAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Product Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    product.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${isBreakEven ? product.costPrice : product.sellingPrice} ETB',
                          style: TextStyle(
                            color: isBreakEven ? Colors.orangeAccent : const Color(0xFF818CF8),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isBreakEven) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BREAK-EVEN',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        if (status.reserved > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${status.reserved.toStringAsFixed(0)} RSV',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stock Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    walkInAvailable.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isOutOfStock ? Colors.redAccent : Colors.white70,
                    ),
                  ),
                  Text(
                    '${status.physicalRemaining.toStringAsFixed(0)} PHYSICAL',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  if (isOutOfStock && status.totalReceived > 0)
                    Text(
                      'REC: ${status.totalReceived.toStringAsFixed(0)} / SOLD: ${status.totalSold.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white24,
                      ),
                    )
                  else
                    Text(
                      'AVAILABLE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: isOutOfStock ? Colors.redAccent : Colors.white38,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Custom Stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    _IconButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        final currentQty =
                            double.tryParse(
                              _quantityControllers[product.id]?.text ?? '1',
                            ) ??
                            1.0;
                        if (currentQty > 1) {
                          setState(() {
                            _quantityControllers[product.id]?.text =
                                (currentQty - 1).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _quantityControllers[product.id] ??=
                            TextEditingController(text: '1'),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          // Force state rebuild if needed, though controller handles text
                          setState(() {});
                        },
                      ),
                    ),
                    _IconButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        final currentQty =
                            double.tryParse(
                              _quantityControllers[product.id]?.text ?? '1',
                            ) ??
                            1.0;
                        setState(() {
                          _quantityControllers[product.id]?.text =
                              (currentQty + 1).toStringAsFixed(0);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Break-Even Toggle
              GestureDetector(
                onTap: () => setState(() => _breakEven[product.id] = !isBreakEven),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBreakEven
                        ? Colors.orangeAccent.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBreakEven
                          ? Colors.orangeAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(
                    Icons.balance_rounded,
                    color: isBreakEven ? Colors.orangeAccent : Colors.white24,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bag Toggle
              if (!isAnyBag && bagProduct != null) ...[
                GestureDetector(
                  onTap: () => setState(() => _addBag[product.id] = !hasBag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasBag
                          ? const Color(0xFFFACC15).withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasBag
                            ? const Color(0xFFFACC15).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: hasBag ? const Color(0xFFFACC15) : Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              // Sell Button
              Flexible(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isOutOfStock)
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isOutOfStock
                        ? null
                        : () {
                            final qty =
                                double.tryParse(
                                  _quantityControllers[product.id]?.text ?? '1',
                                ) ??
                                1.0;
                            _processSale(
                              product,
                              qty,
                              hasBag ? bagProduct : null,
                              status,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock
                          ? Colors.white10
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isOutOfStock ? 'OUT' : 'SELL NOW',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processSale(
    dynamic product,
    double quantity,
    dynamic bagProduct,
    StockStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (quantity > status.walkInAvailable) {
      String message =
          'You are attempting to sell $quantity ${product.name}, but only ${status.walkInAvailable} are currently available for walk-in.';
      if (quantity <= status.physicalRemaining) {
        message += '\n\nNote: This will dip into reserved stock.';
      } else {
        message +=
            '\n\nWarning: This exceeds total physical stock (${status.physicalRemaining}).';
      }

      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text(
                'LOW STOCK WARNING',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                elevation: 4,
                shadowColor: Colors.orangeAccent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'PROCEED',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final now = DateTime.now();

    // 1. Process the main product sale
    final customerName = _customerController.text.trim();
    final isBreakEven = _breakEven[product.id] ?? false;
    final sellPrice = isBreakEven ? product.costPrice : product.sellingPrice;
    final totalPrice =
        quantity * sellPrice +
        (_addonName != null ? _addonAmount * (_addonPrice ?? 0.0) : 0.0);
    final order = CustomerOrder()
      ..productId = product.id
      ..customerName = customerName.isEmpty ? "Walk-in Customer" : customerName
      ..amount = quantity
      ..dueDate = now
      ..status = OrderStatus.sold
      ..paymentMethod = PaymentMethod.cash
      ..costPriceAtTime = product.costPrice
      ..sellingPriceAtTime = sellPrice
      ..advancePayment = totalPrice
      ..fulfilledAt = now
      ..addonName = _addonName
      ..addonPrice = _addonPrice
      ..addonCost = _addonCost
      ..addonAmount = _addonName != null ? _addonAmount : null;

    print('DEBUG: QuickSale processing. Name: ${order.customerName}');
    await ref.read(orderRepositoryProvider).saveOrder(order);

    // 2. Process the bag sale if selected
    if (bagProduct != null) {
      final bagOrder = CustomerOrder()
        ..productId = bagProduct.id
        ..customerName = "Walk-in Customer"
        ..amount = 1.0
        ..dueDate = now
        ..status = OrderStatus.sold
        ..paymentMethod = PaymentMethod.cash
        ..costPriceAtTime = bagProduct.costPrice
        ..sellingPriceAtTime = bagProduct.sellingPrice
        ..advancePayment = bagProduct.sellingPrice
        ..fulfilledAt = now;

      await ref.read(orderRepositoryProvider).saveOrder(bagOrder);
    }

    if (navigator.canPop()) {
      navigator.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Sale processed: ${quantity.toStringAsFixed(0)} ${product.name}${bagProduct != null ? ' + Bag' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

Future<Addon?> _showCustomAddonDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final costController = TextEditingController();

  return showDialog<Addon>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      title: const Text(
        'NEW CUSTOM ADD-ON',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 1.5,
          color: Color(0xFF818CF8),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Add-on Name',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price (ETB)',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost Price (ETB)',
                labelStyle: TextStyle(color: Colors.white38),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final price = double.tryParse(priceController.text) ?? 0.0;
            final cost = double.tryParse(costController.text) ?? 0.0;
            if (name.isEmpty || price <= 0 || cost < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill all fields with valid data'),
                ),
              );
              return;
            }
            final newAddon = Addon()
              ..name = name
              ..price = price
              ..cost = cost;
            await ref.read(addonRepositoryProvider).saveAddon(newAddon);
            if (context.mounted) {
              Navigator.pop(context, newAddon);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'CREATE',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

//   }
// }
