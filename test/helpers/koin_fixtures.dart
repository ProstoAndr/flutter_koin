import 'package:flutter_koin/flutter_koin.dart';

abstract class ShopInfoRepository {
  String get title;
}

class CoffeeShopInfo implements ShopInfoRepository {
  CoffeeShopInfo(this.id);

  final int id;

  @override
  String get title => 'Aurora Coffee';
}

class AlternativeShopInfo implements ShopInfoRepository {
  @override
  String get title => 'Another Coffee';
}

abstract class ReceiptGenerator {
  int get id;
}

class ReceiptFactory implements ReceiptGenerator {
  ReceiptFactory(this.id);

  @override
  final int id;

  String makeReceipt() => 'receipt-$id';
}

abstract class TableSessionContract {
  int get id;
}

class TableSession implements TableSessionContract {
  TableSession(this.id);

  @override
  final int id;

  String get label => 'session-$id';
}

class TableService {
  TableService(
    this.shopInfo,
    this.session, {
    required this.receiptGenerator,
  });

  final ShopInfoRepository shopInfo;
  final TableSessionContract session;
  final ReceiptGenerator receiptGenerator;
}

class AppLogger {}

class MissingDependency {}

class DisposableResource implements KoinDisposable {
  DisposableResource({this.onDispose});

  final Future<void> Function()? onDispose;
  int disposeCount = 0;

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (onDispose != null) {
      await onDispose!();
    }
  }
}

class DisposableRootResource extends DisposableResource {
  DisposableRootResource({super.onDispose});
}

class DisposableScopedResource extends DisposableResource {
  DisposableScopedResource({super.onDispose});
}

class DisposableSecondResource extends DisposableResource {
  DisposableSecondResource({super.onDispose});
}

class TestScopeObserver implements KoinScopeObserver {
  TestScopeObserver({
    this.onCreated,
    this.onDisposed,
  });

  final void Function(KoinScope scope)? onCreated;
  final void Function(KoinScope scope)? onDisposed;
  final List<String> events = [];

  @override
  void onScopeCreated(KoinScope scope) {
    events.add('created:${scope.name}');
    onCreated?.call(scope);
  }

  @override
  void onScopeDisposed(KoinScope scope) {
    events.add('disposed:${scope.name}');
    onDisposed?.call(scope);
  }
}

class ScopedAwareFactory {
  ScopedAwareFactory(this.session);

  final TableSession session;
}
