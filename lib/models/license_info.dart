class LicenseInfo {
  final String ownerName;
  final String phoneNumber;
  final int maxSellers;
  final DateTime expiryDate;
  final String planType;
  final String deviceId;

  LicenseInfo({
    required this.ownerName,
    required this.phoneNumber,
    required this.maxSellers,
    required this.expiryDate,
    required this.planType,
    required this.deviceId,
  });

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      ownerName: json['owner_name'] as String,
      phoneNumber: json['phone'] as String,
      maxSellers: json['max_sellers'] as int,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      planType: json['plan'] as String,
      deviceId: json['device_id'] as String,
    );
  }
}