import 'package:uuid/uuid.dart';

class TravelMemory {
  final String id;
  final String place; // Place name
  final double latitude;
  final double longitude;
  final DateTime visitedDate;
  final String memory; // Memory/description
  final String? note; // Optional note about the trip
  final List<String> photos; // Local paths to photos
  final bool isPublic;

  final String? userId;
  final String? userDisplayName;
  final String? userAvatarUrl;

  TravelMemory({
    String? id,
    required this.place,
    required this.latitude,
    required this.longitude,
    DateTime? visitedDate,
    this.memory = '',
    this.note,
    this.photos = const [],
    this.isPublic = false,
    this.userId,
    this.userDisplayName,
    this.userAvatarUrl,
  })  : id = id ?? const Uuid().v4(),
        visitedDate = visitedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'place': place,
      'latitude': latitude,
      'longitude': longitude,
      'visitedDate': visitedDate.toIso8601String(),
      'memory': memory,
      'note': note,
      'photos': photos,
      'isPublic': isPublic,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userAvatarUrl': userAvatarUrl,
    };
  }

  factory TravelMemory.fromMap(Map<String, dynamic> map) {
    return TravelMemory(
      id: map['id'],
      place: map['place'] ?? 'Unknown Place',
      latitude: map['latitude'],
      longitude: map['longitude'],
      visitedDate: DateTime.parse(map['visitedDate']),
      memory: map['memory'] ?? '',
      note: map['note'],
      photos: List<String>.from(map['photos'] ?? []),
      isPublic: map['isPublic'] ?? false,
      userId: map['userId'],
      userDisplayName: map['userDisplayName'],
      userAvatarUrl: map['userAvatarUrl'],
    );
  }
}
