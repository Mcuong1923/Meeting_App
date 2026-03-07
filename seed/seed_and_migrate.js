/**
 * Seed Teams + Backfill Users Migration Script
 * 
 * Project: mettingapp-aef60
 * 
 * What this script does:
 * 1. Seeds teams from teams_seed.json into Firestore `teams` collection (idempotent upsert)
 * 2. Backfills users who have departmentId but missing teamId with default team
 * 
 * SAFETY:
 * - NEVER overwrites: role, status, isRoleApproved, accountType, departmentId, departmentName, email, displayName
 * - Only updates: teamId, teamName, teamIds, teamNames, updatedAt
 * - Idempotent: running multiple times is safe
 * 
 * Prerequisites:
 * - Place your Firebase service account key as `serviceAccountKey.json` in this directory
 *   (Download from Firebase Console → Project Settings → Service Accounts → Generate New Private Key)
 * 
 * Usage:
 *   cd seed
 *   npm install firebase-admin
 *   node seed_and_migrate.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ====== Configuration ======
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'serviceAccountKey.json');
const SEED_DATA_PATH = path.join(__dirname, 'teams_seed.json');
const BATCH_SIZE = 450; // Firestore batch limit is 500, leave some margin

// ====== Initialize Firebase Admin ======
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error('❌ Missing serviceAccountKey.json!');
    console.error('   Download from: Firebase Console → Project Settings → Service Accounts → Generate New Private Key');
    console.error(`   Save to: ${SERVICE_ACCOUNT_PATH}`);
    process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ====== STEP A: Seed Teams (idempotent upsert) ======
async function seedTeams() {
    console.log('\n=== STEP A: Seeding Teams ===\n');

    const seedData = JSON.parse(fs.readFileSync(SEED_DATA_PATH, 'utf-8'));
    let createdCount = 0;
    let updatedCount = 0;
    let skippedCount = 0;

    for (const dept of seedData.departments) {
        const departmentId = dept.departmentId;
        console.log(`\n📂 Department: ${departmentId}`);

        for (const team of dept.teams) {
            const teamId = team.teamId;
            const teamDocRef = db.collection('teams').doc(teamId);
            const docSnapshot = await teamDocRef.get();

            const teamData = {
                name: team.name,
                departmentId: departmentId,
                departmentName: departmentId, // Same as departmentId for legacy compat
                isActive: true,
                managerIds: [],
                memberIds: [],
                memberNames: [],
                description: `Team ${team.name} thuộc ${departmentId}`,
            };

            if (!docSnapshot.exists) {
                // CREATE
                await teamDocRef.set({
                    ...teamData,
                    order: team.order || 0,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`   ✅ Created: ${teamId} (${team.name})`);
                createdCount++;
            } else {
                // CHECK if update needed
                const existing = docSnapshot.data();
                const needsUpdate =
                    existing.name !== teamData.name ||
                    existing.departmentId !== teamData.departmentId ||
                    existing.isActive !== true ||
                    existing.order !== (team.order || 0);

                if (needsUpdate) {
                    await teamDocRef.update({
                        name: teamData.name,
                        departmentId: teamData.departmentId,
                        departmentName: teamData.departmentName,
                        order: team.order || 0,
                        isActive: true,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`   🔄 Updated: ${teamId} (fields corrected)`);
                    updatedCount++;
                } else {
                    console.log(`   ⏭️  Skipped: ${teamId} (already correct)`);
                    skippedCount++;
                }
            }
        }
    }

    console.log(`\n📊 Seed Summary:`);
    console.log(`   Created: ${createdCount}`);
    console.log(`   Updated: ${updatedCount}`);
    console.log(`   Skipped: ${skippedCount}`);
    console.log(`   Total:   ${createdCount + updatedCount + skippedCount}`);

    return { createdCount, updatedCount, skippedCount };
}

// ====== STEP B: Backfill Users ======
async function backfillUsers() {
    console.log('\n=== STEP B: Backfilling Users (teamId) ===\n');

    // Query ALL users (not just pending — active directors/managers also need teamId)
    const usersSnapshot = await db.collection('users').get();

    let backfilledCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    const errors = [];

    // Process in batches
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const uid = doc.id;
        const email = userData.email || 'unknown';
        const departmentId = userData.departmentId;
        const currentTeamId = userData.teamId;
        const currentRole = userData.role || 'guest';

        // Skip users without departmentId
        if (!departmentId || departmentId === '') {
            skippedCount++;
            continue;
        }

        // Skip users who already have a valid teamId
        if (currentTeamId && currentTeamId !== '') {
            console.log(`   ⏭️  Skip: ${email} (already has teamId=${currentTeamId})`);
            skippedCount++;
            continue;
        }

        try {
            // Determine the teamId to assign
            let newTeamId;
            let newTeamName;

            // Check legacy teamIds array
            const legacyTeamIds = userData.teamIds || [];
            const legacyTeamNames = userData.teamNames || [];

            if (legacyTeamIds.length > 0 && legacyTeamIds[0] !== '') {
                // Use first legacy teamId
                newTeamId = legacyTeamIds[0];
                newTeamName = legacyTeamNames.length > 0 ? legacyTeamNames[0] : null;

                // Verify team exists in Firestore
                const teamDoc = await db.collection('teams').doc(newTeamId).get();
                if (!teamDoc.exists) {
                    // Fallback to default team
                    console.log(`   ⚠️  Legacy teamId "${newTeamId}" not found, using default`);
                    newTeamId = `${departmentId}__general`;
                    newTeamName = 'Chung (Chưa phân team)';
                }
            } else {
                // No legacy team → assign default
                newTeamId = `${departmentId}__general`;
                newTeamName = 'Chung (Chưa phân team)';
            }

            // Build update (ONLY safe fields)
            const updateData = {
                teamId: newTeamId,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            // Optional: sync teamIds/teamNames arrays if empty
            if (!legacyTeamIds.length || legacyTeamIds[0] === '') {
                updateData.teamIds = [newTeamId];
            }
            if (!legacyTeamNames.length || legacyTeamNames[0] === '') {
                updateData.teamNames = [newTeamName];
            }

            batch.update(db.collection('users').doc(uid), updateData);
            batchCount++;
            backfilledCount++;

            console.log(`   ✅ Backfill: ${email} (role=${currentRole}, dept=${departmentId}) → teamId=${newTeamId}`);

            // Commit batch if approaching limit
            if (batchCount >= BATCH_SIZE) {
                await batch.commit();
                console.log(`   📦 Committed batch of ${batchCount} writes`);
                batch = db.batch();
                batchCount = 0;
            }
        } catch (e) {
            errorCount++;
            errors.push({ uid, email, error: e.message });
            console.error(`   ❌ Error: ${email} — ${e.message}`);
        }
    }

    // Commit remaining batch
    if (batchCount > 0) {
        await batch.commit();
        console.log(`   📦 Committed final batch of ${batchCount} writes`);
    }

    console.log(`\n📊 Backfill Summary:`);
    console.log(`   Backfilled: ${backfilledCount}`);
    console.log(`   Skipped:    ${skippedCount}`);
    console.log(`   Errors:     ${errorCount}`);

    if (errors.length > 0) {
        console.log(`\n❌ Errors:`);
        errors.forEach(e => console.log(`   - ${e.email} (${e.uid}): ${e.error}`));
    }

    return { backfilledCount, skippedCount, errorCount };
}

// ====== STEP C: Verification ======
async function verify() {
    console.log('\n=== STEP C: Verification ===\n');

    // Count teams
    const teamsSnapshot = await db.collection('teams').get();
    console.log(`📊 Total teams in Firestore: ${teamsSnapshot.size}`);

    // List all teams grouped by department
    const teamsByDept = {};
    teamsSnapshot.forEach(doc => {
        const data = doc.data();
        const dept = data.departmentId || 'Unknown';
        if (!teamsByDept[dept]) teamsByDept[dept] = [];
        teamsByDept[dept].push({ id: doc.id, name: data.name, isActive: data.isActive });
    });

    for (const [dept, teams] of Object.entries(teamsByDept)) {
        console.log(`\n📂 ${dept} (${teams.length} teams):`);
        teams.forEach(t => console.log(`   - ${t.id} → "${t.name}" (active=${t.isActive})`));
    }

    // Sample users verification
    console.log('\n📋 Sample Users Check:');
    const usersSnapshot = await db.collection('users').limit(10).get();
    usersSnapshot.forEach(doc => {
        const data = doc.data();
        console.log(`   ${data.email || doc.id}: role=${data.role || 'null'}, dept=${data.departmentId || 'null'}, teamId=${data.teamId || 'null'}, status=${data.status || 'null'}`);
    });

    // Users still missing teamId
    const missingTeam = await db.collection('users')
        .where('departmentId', '!=', null)
        .get();

    let missingCount = 0;
    missingTeam.forEach(doc => {
        const data = doc.data();
        if (data.departmentId && (!data.teamId || data.teamId === '')) {
            missingCount++;
        }
    });
    console.log(`\n⚠️  Users with departmentId but missing teamId: ${missingCount}`);
}

// ====== Main ======
async function main() {
    console.log('🚀 Starting Seed + Migration for project: mettingapp-aef60');
    console.log(`   Timestamp: ${new Date().toISOString()}\n`);

    try {
        const seedResult = await seedTeams();
        const backfillResult = await backfillUsers();
        await verify();

        console.log('\n✅ All done!');
        console.log(`   Teams: ${seedResult.createdCount} created, ${seedResult.updatedCount} updated`);
        console.log(`   Users: ${backfillResult.backfilledCount} backfilled, ${backfillResult.skippedCount} skipped`);
    } catch (e) {
        console.error('\n💥 Fatal error:', e);
        process.exit(1);
    }
}

main();
