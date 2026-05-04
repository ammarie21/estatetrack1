class MaintenanceModel {
  const MaintenanceModel({
    required this.id,
    required this.apartmentId,
    required this.description,
    required this.cost,
    required this.date,
    this.status = 'Pending',
  });

  final int id;
  final String apartmentId;
  final String description;
  final double cost;
  final String date;
  final String status;

  MaintenanceModel copyWith({
    int? id,
    String? apartmentId,
    String? description,
    double? cost,
    String? date,
    String? status,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}