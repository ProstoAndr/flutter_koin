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
  ..register((c) => c.registerFactory<ReceiptFactory>(() => ReceiptFactory()))
  ..register((c) => c.registerScoped<TableSession>(() => TableSession()))
  ..register(
      (c) => c.registerScopedWithScope<TableService>((scope) => TableService(
            scope.get<CoffeeShopInfo>(),
            scope.get<TableSession>(),
            receiptFactory: scope.get<ReceiptFactory>(),
          )))
  ..register(
      (c) => c.registerRootScoped<CoffeeShopInfo>(() => CoffeeShopInfo()));
