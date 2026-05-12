class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? products;
  final String? notes;

  Supplier({
    this.id,
    required this.name,
    this.phone,
    this.products,
    this.notes,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      products: map['products'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'products': products,
      'notes': notes,
    };
  }
}
