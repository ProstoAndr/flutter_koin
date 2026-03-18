// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'main.dart';

// **************************************************************************
// KoinGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// *************************************************
// Flutter Koin Dependency Injection Codegen
// *************************************************

final koinModule = KoinModule()
  ..register((c) => c.registerFactory<ReceiptFactory>(() => ReceiptFactory(),
      bindAs: [ReceiptGenerator]))
  ..register((c) => c.registerScoped<TableSession>(() => TableSession(),
      bindAs: [TableSessionContract]))
  ..register((c) => c.registerScopedWithScope<TableService>(
          (scope) => TableService(
        scope.get<ShopInfoRepository>(),
        scope.get<TableSessionContract>(),
        receiptGenerator: scope.get<ReceiptGenerator>(),
      ),
      bindAs: [TableOrderService]))
  ..register((c) => c.registerRootScoped<CoffeeShopInfo>(() => CoffeeShopInfo(),
      bindAs: [ShopInfoRepository]));
