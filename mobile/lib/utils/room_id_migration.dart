import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration script to standardize roomId format
/// 
/// Problem:
/// - meetings.roomId: stored as code (e.g., "room_training_01")
/// - room_bookings.roomId: stored as docId (e.g., "JAT7xHfDmoDGHmySQ8xA")
/// 
/// Solution:
/// - Standardize both to use rooms/{docId} format
/// - Map old code-based roomId to docId by looking up rooms collection
/// 
/// Usage:
/// Run this script once to migrate existing data
class RoomIdMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Run migration for all meetings and room_bookings
  Future<MigrationResult> migrateAll() async {
    print('🔄 Starting roomId migration...');
    
    // Step 1: Load all rooms and create mapping
    final roomMap = await _buildRoomMapping();
    print('📋 Found ${roomMap.length} rooms for mapping');
    
    // Step 2: Migrate meetings
    final meetingsResult = await _migrateMeetings(roomMap);
    print('✅ Migrated ${meetingsResult.migrated} meetings, ${meetingsResult.failed} failed');
    
    // Step 3: Migrate room_bookings
    final bookingsResult = await _migrateRoomBookings(roomMap);
    print('✅ Migrated ${bookingsResult.migrated} bookings, ${bookingsResult.failed} failed');
    
    return MigrationResult(
      totalRooms: roomMap.length,
      meetingsMigrated: meetingsResult.migrated,
      meetingsFailed: meetingsResult.failed,
      bookingsMigrated: bookingsResult.migrated,
      bookingsFailed: bookingsResult.failed,
      errors: [
        ...meetingsResult.errors,
        ...bookingsResult.errors,
      ],
    );
  }

  /// Build mapping from room code/name to docId
  /// Supports multiple lookup strategies:
  /// 1. Direct match: roomId == docId (already correct)
  /// 2. Code match: roomId matches room's id field (legacy code)
  /// 3. Name match: roomId matches room's name field
  Future<Map<String, String>> _buildRoomMapping() async {
    final snapshot = await _firestore.collection('rooms').get();
    final Map<String, String> mapping = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final docId = doc.id;
      final roomId = data['id'] as String? ?? '';
      final roomName = data['name'] as String? ?? '';
      
      // Map docId to itself (already correct)
      mapping[docId] = docId;
      
      // Map legacy code/id to docId
      if (roomId.isNotEmpty && roomId != docId) {
        mapping[roomId] = docId;
        print('📌 Mapped room code "$roomId" -> docId "$docId"');
      }
      
      // Map name to docId (fallback)
      if (roomName.isNotEmpty) {
        mapping[roomName] = docId;
      }
    }
    
    return mapping;
  }

  /// Migrate meetings collection
  Future<CollectionMigrationResult> _migrateMeetings(Map<String, String> roomMap) async {
    final snapshot = await _firestore
        .collection('meetings')
        .where('roomId', isNull: false)
        .get();
    
    int migrated = 0;
    int failed = 0;
    List<String> errors = [];
    
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final oldRoomId = data['roomId'] as String?;
      
      if (oldRoomId == null || oldRoomId.isEmpty) continue;
      
      // Check if already in correct format (docId)
      if (roomMap.containsKey(oldRoomId) && roomMap[oldRoomId] == oldRoomId) {
        // Already correct format, skip
        continue;
      }
      
      // Lookup new roomId
      final newRoomId = roomMap[oldRoomId];
      
      if (newRoomId == null) {
        failed++;
        final error = 'Meeting ${doc.id}: roomId "$oldRoomId" not found in rooms';
        errors.add(error);
        print('❌ $error');
        continue;
      }
      
      if (newRoomId == oldRoomId) {
        // No change needed
        continue;
      }
      
      // Update meeting
      batch.update(doc.reference, {
        'roomId': newRoomId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      batchCount++;
      migrated++;
      
      print('✅ Meeting ${doc.id}: "$oldRoomId" -> "$newRoomId"');
      
      // Commit batch every 500 operations (Firestore limit)
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    
    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
    }
    
    return CollectionMigrationResult(
      migrated: migrated,
      failed: failed,
      errors: errors,
    );
  }

  /// Migrate room_bookings collection
  Future<CollectionMigrationResult> _migrateRoomBookings(Map<String, String> roomMap) async {
    final snapshot = await _firestore
        .collection('room_bookings')
        .where('roomId', isNull: false)
        .get();
    
    int migrated = 0;
    int failed = 0;
    List<String> errors = [];
    
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final oldRoomId = data['roomId'] as String?;
      
      if (oldRoomId == null || oldRoomId.isEmpty) continue;
      
      // Check if already in correct format (docId)
      if (roomMap.containsKey(oldRoomId) && roomMap[oldRoomId] == oldRoomId) {
        // Already correct format, skip
        continue;
      }
      
      // Lookup new roomId
      final newRoomId = roomMap[oldRoomId];
      
      if (newRoomId == null) {
        failed++;
        final error = 'Booking ${doc.id}: roomId "$oldRoomId" not found in rooms';
        errors.add(error);
        print('❌ $error');
        continue;
      }
      
      if (newRoomId == oldRoomId) {
        // No change needed
        continue;
      }
      
      // Update booking
      batch.update(doc.reference, {
        'roomId': newRoomId,
      });
      
      batchCount++;
      migrated++;
      
      print('✅ Booking ${doc.id}: "$oldRoomId" -> "$newRoomId"');
      
      // Commit batch every 500 operations (Firestore limit)
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    
    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
    }
    
    return CollectionMigrationResult(
      migrated: migrated,
      failed: failed,
      errors: errors,
    );
  }

  /// Dry run: Check what would be migrated without making changes
  Future<MigrationResult> dryRun() async {
    print('🔍 Running dry-run migration check...');
    
    final roomMap = await _buildRoomMapping();
    print('📋 Found ${roomMap.length} rooms for mapping');
    
    // Check meetings
    final meetingsSnapshot = await _firestore
        .collection('meetings')
        .where('roomId', isNull: false)
        .get();
    
    int meetingsToMigrate = 0;
    List<String> meetingErrors = [];
    
    for (var doc in meetingsSnapshot.docs) {
      final data = doc.data();
      final oldRoomId = data['roomId'] as String?;
      
      if (oldRoomId == null || oldRoomId.isEmpty) continue;
      
      if (roomMap.containsKey(oldRoomId) && roomMap[oldRoomId] == oldRoomId) {
        continue; // Already correct
      }
      
      final newRoomId = roomMap[oldRoomId];
      if (newRoomId == null) {
        meetingErrors.add('Meeting ${doc.id}: roomId "$oldRoomId" not found');
      } else if (newRoomId != oldRoomId) {
        meetingsToMigrate++;
      }
    }
    
    // Check bookings
    final bookingsSnapshot = await _firestore
        .collection('room_bookings')
        .where('roomId', isNull: false)
        .get();
    
    int bookingsToMigrate = 0;
    List<String> bookingErrors = [];
    
    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final oldRoomId = data['roomId'] as String?;
      
      if (oldRoomId == null || oldRoomId.isEmpty) continue;
      
      if (roomMap.containsKey(oldRoomId) && roomMap[oldRoomId] == oldRoomId) {
        continue; // Already correct
      }
      
      final newRoomId = roomMap[oldRoomId];
      if (newRoomId == null) {
        bookingErrors.add('Booking ${doc.id}: roomId "$oldRoomId" not found');
      } else if (newRoomId != oldRoomId) {
        bookingsToMigrate++;
      }
    }
    
    print('📊 Dry-run results:');
    print('   Meetings to migrate: $meetingsToMigrate');
    print('   Bookings to migrate: $bookingsToMigrate');
    print('   Meeting errors: ${meetingErrors.length}');
    print('   Booking errors: ${bookingErrors.length}');
    
    return MigrationResult(
      totalRooms: roomMap.length,
      meetingsMigrated: meetingsToMigrate,
      meetingsFailed: meetingErrors.length,
      bookingsMigrated: bookingsToMigrate,
      bookingsFailed: bookingErrors.length,
      errors: [...meetingErrors, ...bookingErrors],
    );
  }
}

class CollectionMigrationResult {
  final int migrated;
  final int failed;
  final List<String> errors;

  CollectionMigrationResult({
    required this.migrated,
    required this.failed,
    required this.errors,
  });
}

class MigrationResult {
  final int totalRooms;
  final int meetingsMigrated;
  final int meetingsFailed;
  final int bookingsMigrated;
  final int bookingsFailed;
  final List<String> errors;

  MigrationResult({
    required this.totalRooms,
    required this.meetingsMigrated,
    required this.meetingsFailed,
    required this.bookingsMigrated,
    required this.bookingsFailed,
    required this.errors,
  });

  @override
  String toString() {
    return '''
Migration Results:
  Total rooms: $totalRooms
  Meetings migrated: $meetingsMigrated
  Meetings failed: $meetingsFailed
  Bookings migrated: $bookingsMigrated
  Bookings failed: $bookingsFailed
  Total errors: ${errors.length}
''';
  }
}
