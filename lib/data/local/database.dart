import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// This import is for the generated file. It will not exist until you run the build_runner.
part 'database.g.dart';

// Define tables
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Materials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get quantity => real()();
}

class ProductMaterialMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().customConstraint('REFERENCES products(id)')();
  IntColumn get materialId => integer().customConstraint('REFERENCES materials(id)')();
  RealColumn get fixedQuantity => real()();
}

@DriftDatabase(tables: [Products, Materials, ProductMaterialMappings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
