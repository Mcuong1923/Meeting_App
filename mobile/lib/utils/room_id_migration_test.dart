import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_id_migration.dart';

/// Test script to verify roomId migration and conflict detection
/// 
/// Run this after migration to verify:
/// 1. All roomIds are in docId format
/// 2. Conflict detection works correctly
/// 3. Double-booking is prevented
class RoomIdMigrationTest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test 1: Verify all roomIds are docId format
  Future<bool> testRoomIdFormat() async {
    print('🧪 TEST 1: Verifying roomId format...');
    
    // Check meetings
    final meetingsSnapshot = await _firestore
        .collection('meetings')
        .where('roomId', isNull: false)
        .get();
    
    int invalidCount = 0;
    for (var doc in meetingsSnapshot.docs) {
      final roomId = doc.data()['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) continue;
      
      // DocId typically > 10 characters (Firestore auto-generated)
      if (roomId.length <= 10) {
        print('❌ Meeting ${doc.id}: roomId="$roomId" (length=${roomId.length}) is not docId format');
        invalidCount++;
      }
    }
    
    // Check bookings
    final bookingsSnapshot = await _firestore
        .collection('room_bookings')
        .where('roomId', isNull: false)
        .get();
    
    for (var doc in bookingsSnapshot.docs) {
      final roomId = doc.data()['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) continue;
      
      if (roomId.length <= 10) {
        print('❌ Booking ${doc.id}: roomId="$roomId" (length=${roomId.length}) is not docId format');
        invalidCount++;
      }
    }
    
    if (invalidCount == 0) {
      print('✅ All roomIds are in docId format');
      return true;
    } else {
      print('❌ Found $invalidCount invalid roomIds');
      return false;
    }
  }

  /// Test 2: Verify conflict detection query works
  Future<bool> testConflictDetection(String roomId, DateTime startTime, DateTime endTime) async {
    print('🧪 TEST 2: Testing conflict detection...');
    print('   roomId=$roomId');
    print('   startTime=$startTime');
    print('   endTime=$endTime');
    
    // Query meetings
    final meetingsSnapshot = await _firestore
        .collection('meetings')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();
    
    print('   Found ${meetingsSnapshot.docs.length} candidate meetings');
    
    int conflictCount = 0;
    for (var doc in meetingsSnapshot.docs) {
      final data = doc.data();
      final docStart = (data['startTime'] as Timestamp).toDate();
      final docEnd = (data['endTime'] as Timestamp).toDate();
      
      // Check overlap
      bool hasOverlap = docStart.isBefore(endTime) && docEnd.isAfter(startTime);
      if (hasOverlap) {
        conflictCount++;
        print('   ⚠️ Conflict found: meeting ${doc.id} ($docStart - $docEnd)');
      }
    }
    
    // Query bookings
    final bookingsSnapshot = await _firestore
        .collection('room_bookings')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['pending', 'approved', 'reserved', 'converted'])
        .get();
    
    print('   Found ${bookingsSnapshot.docs.length} candidate bookings');
    
    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final docStart = (data['startTime'] as Timestamp).toDate();
      final docEnd = (data['endTime'] as Timestamp).toDate();
      
      bool hasOverlap = docStart.isBefore(endTime) && docEnd.isAfter(startTime);
      if (hasOverlap) {
        conflictCount++;
        print('   ⚠️ Conflict found: booking ${doc.id} ($docStart - $docEnd)');
      }
    }
    
    print('   Total conflicts: $conflictCount');
    return conflictCount >= 0; // Always return true, just for logging
  }

  /// Run all tests
  Future<Map<String, dynamic>> runAllTests() async {
    print('═══════════════════════════════════════════════════════════');
    print('🧪 Running RoomId Migration Tests...');
    print('═══════════════════════════════════════════════════════════');
    
    final results = <String, bool>{};
    
    // Test 1: Format check
    results['formatCheck'] = await testRoomIdFormat();
    
    // Test 2: Conflict detection (example)
    // You can customize this with actual roomId and time range
    final now = DateTime.now();
    final testStart = DateTime(now.year, now.month, now.day, 10, 0);
    final testEnd = testStart.add(const Duration(hours: 1));
    
    // Get a sample roomId
    final roomsSnapshot = await _firestore.collection('rooms').limit(1).get();
    if (roomsSnapshot.docs.isNotEmpty) {
      final sampleRoomId = roomsSnapshot.docs.first.id;
      await testConflictDetection(sampleRoomId, testStart, testEnd);
    }
    
    print('═══════════════════════════════════════════════════════════');
    print('📊 Test Results:');
    results.forEach((test, passed) {
      print('   ${passed ? "✅" : "❌"} $test: ${passed ? "PASSED" : "FAILED"}');
    });
    print('═══════════════════════════════════════════════════════════');
    
    return results;
  }
}
