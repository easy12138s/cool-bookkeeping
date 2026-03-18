import 'package:flutter_test/flutter_test.dart';
import 'package:cool_bookkeeping/data/models/record_model.dart';

void main() {
  group('RecordModel', () {
    test('should create RecordModel with required fields', () {
      final record = RecordModel(
        id: 'test-id-123',
        amount: 100.0,
        categoryId: 'category-1',
        type: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(record.id, 'test-id-123');
      expect(record.amount, 100.0);
      expect(record.categoryId, 'category-1');
      expect(record.type, 0);
      expect(record.note, isNull);
      expect(record.updatedAt, isNull);
    });

    test('should create RecordModel with all fields', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);

      final record = RecordModel(
        id: 'test-id-456',
        amount: 250.50,
        categoryId: 'category-2',
        type: 1,
        note: 'Test note',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(record.id, 'test-id-456');
      expect(record.amount, 250.50);
      expect(record.categoryId, 'category-2');
      expect(record.type, 1);
      expect(record.note, 'Test note');
      expect(record.createdAt, createdAt);
      expect(record.updatedAt, updatedAt);
    });

    test('should support JSON serialization', () {
      final record = RecordModel(
        id: 'test-id-789',
        amount: 100.0,
        categoryId: 'category-1',
        type: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = record.toJson();
      final fromJson = RecordModel.fromJson(json);

      expect(fromJson.id, record.id);
      expect(fromJson.amount, record.amount);
      expect(fromJson.categoryId, record.categoryId);
      expect(fromJson.type, record.type);
    });

    test('should correctly identify expense type (type=0)', () {
      final expenseRecord = RecordModel(
        id: 'expense-1',
        amount: 50.0,
        categoryId: 'category-1',
        type: 0,
        createdAt: DateTime.now(),
      );

      expect(expenseRecord.type, 0);
    });

    test('should correctly identify income type (type=1)', () {
      final incomeRecord = RecordModel(
        id: 'income-1',
        amount: 5000.0,
        categoryId: 'category-2',
        type: 1,
        createdAt: DateTime.now(),
      );

      expect(incomeRecord.type, 1);
    });
  });
}
