import 'package:flutter/material.dart';
import 'package:flutter_koin/flutter_koin.dart';

part 'main.koin.dart';

void main() {
  startKoin([koinModule]);
  runApp(const KoinDemoApp());
}

abstract class ShopInfoRepository {
  int get id;
  String get title;
  String get address;
}

abstract class ReceiptGenerator {
  int get id;
  String createReceipt();
}

abstract class TableSessionContract {
  int get id;
  String get label;
}

abstract class TableOrderService {
  int get id;
  String describeOrder();
}

@RootScoped(bindAs: [ShopInfoRepository])
class CoffeeShopInfo implements ShopInfoRepository {
  CoffeeShopInfo() : id = _Ids.next();

  @override
  final int id;

  @override
  String get title => 'Aurora Coffee';

  @override
  String get address => '7 Bean Street';
}

@Factory(bindAs: [ReceiptGenerator])
class ReceiptFactory implements ReceiptGenerator {
  ReceiptFactory() : id = _Ids.next();

  @override
  final int id;

  @override
  String createReceipt() => 'receipt-$id';
}

@Scoped(bindAs: [TableSessionContract])
class TableSession implements TableSessionContract {
  TableSession() : id = _Ids.next();

  @override
  final int id;

  @override
  String get label => 'session-$id';
}

@Scoped(bindAs: [TableOrderService])
class TableService implements TableOrderService {
  TableService(
      this.shopInfoRepository,
      this.tableSessionContract, {
        required this.receiptGenerator,
      }) : id = _Ids.next();

  @override
  final int id;

  final ShopInfoRepository shopInfoRepository;
  final TableSessionContract tableSessionContract;
  final ReceiptGenerator receiptGenerator;

  @override
  String describeOrder() {
    return '${shopInfoRepository.title} • '
        '${tableSessionContract.label} • '
        '${receiptGenerator.createReceipt()}';
  }
}

class KoinDemoApp extends StatelessWidget {
  const KoinDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_koin demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopByConcrete = get<CoffeeShopInfo>();
    final shopByAlias = get<ShopInfoRepository>();

    final receiptFactoryA = get<ReceiptFactory>();
    final receiptFactoryB = get<ReceiptFactory>();
    final receiptByAlias = get<ReceiptGenerator>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_koin demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Code generation'),
          const _InfoCard(
            title: 'This example uses annotations',
            description:
            'The module is generated from @RootScoped, @Factory and @Scoped classes.\n'
                'It also demonstrates bindAs aliases and constructor injection.',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'RootScoped + bindAs',
            description:
            'CoffeeShopInfo is registered as ShopInfoRepository.\n'
                'Concrete and alias return the same instance: '
                '${identical(shopByConcrete, shopByAlias)}\n'
                'Shop id: ${shopByConcrete.id}\n'
                'Shop: ${shopByConcrete.title}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Factory + bindAs',
            description:
            'ReceiptFactory is registered as ReceiptGenerator.\n'
                'Concrete creates a new instance every time: '
                '${!identical(receiptFactoryA, receiptFactoryB)}\n'
                'Factory A receipt: ${receiptFactoryA.createReceipt()}\n'
                'Factory B receipt: ${receiptFactoryB.createReceipt()}\n'
                'Alias resolves to runtime type: ${receiptByAlias.runtimeType}',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KoinScopeHost(
                    scopeName: 'table:7',
                    child: const TablePage(tableName: 'Table 7'),
                  ),
                ),
              );
            },
            child: const Text('Open scoped page'),
          ),
        ],
      ),
    );
  }
}

class TablePage extends StatelessWidget {
  final String tableName;

  const TablePage({
    super.key,
    required this.tableName,
  });

  @override
  Widget build(BuildContext context) {
    final sessionByConcrete = context.scopeGet<TableSession>();
    final sessionByAlias = context.scopeGet<TableSessionContract>();

    final serviceByConcrete = context.scopeGet<TableService>();
    final serviceByAlias = context.scopeGet<TableOrderService>();

    final shopByAlias = context.scopeGet<ShopInfoRepository>();
    final shopByConcrete = get<CoffeeShopInfo>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tableName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'Scoped + bindAs',
            description:
            'TableSession is registered as TableSessionContract.\n'
                'Concrete and alias return the same scoped instance: '
                '${identical(sessionByConcrete, sessionByAlias)}\n'
                'Session id: ${sessionByConcrete.id}\n'
                'Label: ${sessionByConcrete.label}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Root fallback',
            description:
            'A scoped page can still resolve root-scoped dependencies.\n'
                'Concrete and alias point to the same root object: '
                '${identical(shopByAlias, shopByConcrete)}\n'
                'Shop id: ${shopByConcrete.id}\n'
                'Address: ${shopByConcrete.address}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Constructor injection via aliases',
            description:
            'TableService is registered as TableOrderService.\n'
                'Its constructor depends on interfaces, not concrete classes.\n'
                'Concrete and alias return the same scoped instance: '
                '${identical(serviceByConcrete, serviceByAlias)}\n'
                'Service id: ${serviceByConcrete.id}\n'
                'Order preview: ${serviceByConcrete.describeOrder()}',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;

  const _InfoCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ids {
  static int _value = 0;

  static int next() {
    _value += 1;
    return _value;
  }
}