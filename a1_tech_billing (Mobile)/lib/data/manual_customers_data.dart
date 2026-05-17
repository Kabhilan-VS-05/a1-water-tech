import '../models/models.dart';

class ManualCustomersData {
  static final List<Customer> seedCustomers = [
    Customer(
      id: 'MANUAL_001',
      name: 'Walk-in Customer',
      phone: '9999999999',
      address: 'Shop Counter',
      createdAt: DateTime(2024, 1, 1),
    ),
    Customer(
      id: 'MANUAL_002',
      name: 'Cash Sale',
      phone: '0000000000',
      address: 'Manual Entry',
      createdAt: DateTime(2024, 1, 1),
    ),
    Customer(
      id: 'MANUAL_003',
      name: 'Local Contractor',
      phone: '8888888888',
      address: 'Local Area',
      createdAt: DateTime(2024, 1, 1),
    ),
  ];
}
