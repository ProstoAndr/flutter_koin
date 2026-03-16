import 'package:flutter/material.dart';
import 'package:flutter_koin/flutter_koin.dart';

part 'main.koin.dart';

void main() {
  startKoin([koinModule]);
  runApp(const KoinDemoApp());
}

@RootScoped()
class CoffeeShopInfo {
  CoffeeShopInfo() : id = _Ids.next();

  final int id;

  String get title => 'Aurora Coffee';
  String get address => '7 Bean Street';
}

@Factory()
class ReceiptFactory {
  ReceiptFactory() : id = _Ids.next();

  final int id;

  String createReceipt() => 'receipt-$id';
}

@Scoped()
class TableSession {
  TableSession() : id = _Ids.next();

  final int id;

  String get label => 'session-$id';
}

@Scoped()
class TableService {
  TableService(
      this.shopInfo,
      this.tableSession, {
        required this.receiptFactory,
      }) : id = _Ids.next();

  final int id;
  final CoffeeShopInfo shopInfo;
  final TableSession tableSession;
  final ReceiptFactory receiptFactory;

  String describeOrder() {
    return '${shopInfo.title} • ${tableSession.label} • ${receiptFactory.createReceipt()}';
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
    final infoA = get<CoffeeShopInfo>();
    final infoB = get<CoffeeShopInfo>();

    final factoryA = get<ReceiptFactory>();
    final factoryB = get<ReceiptFactory>();

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
            'The module is generated from @RootScoped, @Factory and @Scoped classes.',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'RootScoped',
            description:
            'CoffeeShopInfo is shared across the whole app.\n'
                'Same instance: ${identical(infoA, infoB)}\n'
                'Shop id: ${infoA.id}\n'
                'Shop: ${infoA.title}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Factory',
            description:
            'ReceiptFactory creates a new object every time.\n'
                'New instance each call: ${!identical(factoryA, factoryB)}\n'
                'Factory A receipt: ${factoryA.createReceipt()}\n'
                'Factory B receipt: ${factoryB.createReceipt()}',
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
    final sessionA = context.scopeGet<TableSession>();
    final sessionB = context.scopeGet<TableSession>();

    final serviceA = context.scopeGet<TableService>();
    final serviceB = context.scopeGet<TableService>();

    final shopFromScope = context.scopeGet<CoffeeShopInfo>();
    final shopGlobal = get<CoffeeShopInfo>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tableName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'Scoped',
            description:
            'TableSession is reused inside one scope.\n'
                'Same instance in this page: ${identical(sessionA, sessionB)}\n'
                'Session id: ${sessionA.id}\n'
                'Label: ${sessionA.label}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Root fallback',
            description:
            'A scoped page can still resolve root-scoped dependencies.\n'
                'Same root object: ${identical(shopFromScope, shopGlobal)}\n'
                'Shop id: ${shopFromScope.id}\n'
                'Address: ${shopFromScope.address}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Constructor injection',
            description:
            'TableService is generated with injected dependencies.\n'
                'Same service in this scope: ${identical(serviceA, serviceB)}\n'
                'Service id: ${serviceA.id}\n'
                'Order preview: ${serviceA.describeOrder()}',
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