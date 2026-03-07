import '../models/room_model.dart';
import '../models/meeting_model.dart';

class RoomRecommendationEngine {
  /// Cấu trúc để lưu kết quả gợi ý
  static List<RoomRecommendationResult> recommendRooms({
    required int participantsCount,
    required List<RoomAmenity> requiredAmenities,
    required MeetingLocationType locationType,
    required DateTime startTime,
    required DateTime endTime,
    required List<RoomModel> allRooms,
    required Map<String, RoomBookingStatus> availabilityData,
    String? preferredBuilding,
    String? preferredFloor,
  }) {
    List<RoomRecommendationResult> results = [];

    for (var room in allRooms) {
      double score = 0;
      List<String> reasons = [];
      bool isAvailable = availabilityData[room.id] == RoomBookingStatus.available;

      // 1. Kiểm tra sức chứa (Capacity) - Yếu tố quan trọng nhất
      if (room.capacity >= participantsCount) {
        score += 50;
        reasons.add('Đủ ${room.capacity} chỗ');
        // Điểm thưởng nếu sức chứa vừa phải (không quá lãng phí phòng lớn)
        if (room.capacity <= participantsCount * 1.5) {
          score += 10;
        }
      } else {
        // Trừ điểm nặng nếu không đủ chỗ
        score -= 100;
        reasons.add('Không đủ chỗ (${room.capacity}/$participantsCount)');
      }

      // 2. Kiểm tra tiện ích (Amenities)
      if (requiredAmenities.isNotEmpty) {
        int matchedAmenities = 0;
        for (var amenity in requiredAmenities) {
          if (room.amenities.contains(amenity)) {
            matchedAmenities++;
            score += 10;
          } else {
            score -= 5; // Trừ nhẹ nếu thiếu
          }
        }
        
        if (matchedAmenities == requiredAmenities.length) {
          reasons.add('Đủ $matchedAmenities tiện ích yêu cầu');
          score += 20; // Thưởng thêm nếu đáp ứng mọi tiện ích
        } else if (matchedAmenities > 0) {
          reasons.add('Có $matchedAmenities/${requiredAmenities.length} tiện ích yêu cầu');
        } else {
          reasons.add('Thiếu tiện ích yêu cầu');
        }
      }

      // 3. Loại cuộc họp (Location Type)
      if (locationType == MeetingLocationType.hybrid || locationType == MeetingLocationType.virtual) {
        if (room.amenities.contains(RoomAmenity.videoConference) || 
            room.amenities.contains(RoomAmenity.camera) ||
            room.amenities.contains(RoomAmenity.wifi)) {
          score += 20;
          reasons.add('Phù hợp họp trực tuyến');
        }
      } else if (locationType == MeetingLocationType.physical) {
        if (room.amenities.contains(RoomAmenity.projector) || 
            room.amenities.contains(RoomAmenity.whiteboard)) {
          score += 10;
          reasons.add('Phù hợp họp trực tiếp');
        }
      }

      // 4. Ưu tiên vị trí (Preferred Location)
      if (preferredBuilding != null && room.building == preferredBuilding) {
        score += 15;
        reasons.add('Cùng tòa nhà');
        if (preferredFloor != null && room.floor == preferredFloor) {
          score += 10;
          reasons.add('Cùng tầng');
        }
      }

      // 5. Tính sẵn sàng (Availability)
      if (isAvailable) {
        score += 100;
        reasons.add('Trống giờ bạn chọn');
      } else {
        score -= 200; // Phạt nặng nếu không trống
        reasons.add('Đã có người đặt');
      }

      results.add(RoomRecommendationResult(
        room: room,
        score: score,
        reasons: reasons,
        isAvailable: isAvailable,
      ));
    }

    // Sort: Available first, then by score descending
    results.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return b.score.compareTo(a.score);
    });

    return results;
  }
}

class RoomRecommendationResult {
  final RoomModel room;
  final double score;
  final List<String> reasons;
  final bool isAvailable;

  RoomRecommendationResult({
    required this.room,
    required this.score,
    required this.reasons,
    required this.isAvailable,
  });
}
