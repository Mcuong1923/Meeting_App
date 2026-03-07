require('dotenv').config();
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
    console.error(`Missing serviceAccountKey.json at ${serviceAccountPath}`);
    process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
const db = admin.firestore();
const auth = admin.auth();

const teamsData = JSON.parse(fs.readFileSync(path.join(__dirname, 'teams_seed.json'), 'utf8'));
const PASSWORD = process.env.SEED_PASSWORD || 'Test@123456';

// Build teamId from departmentId + code
function teamDocId(deptId, code) {
    return `${deptId}__${code}`;
}

async function upsertTeam(deptName, teamDef) {
    const docId = teamDocId(deptName, teamDef.code);
    const ref = db.collection('teams').doc(docId);
    const snap = await ref.get();
    const data = {
        name: teamDef.name,
        departmentId: deptName,
        departmentName: deptName,
        order: teamDef.order,
        isActive: true,
        managerIds: [],
        memberIds: [],
        memberNames: [],
        description: `${teamDef.name} - ${deptName}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
        data.createdAt = admin.firestore.FieldValue.serverTimestamp();
        await ref.set(data);
        return 'created';
    } else {
        await ref.update(data);
        return 'updated';
    }
}

async function upsertAuthUser(email, displayName, password) {
    try {
        const u = await auth.getUserByEmail(email);
        return { uid: u.uid, status: 'existing' };
    } catch (e) {
        if (e.code === 'auth/user-not-found') {
            const u = await auth.createUser({ email, password, displayName });
            return { uid: u.uid, status: 'created' };
        }
        throw e;
    }
}

async function upsertFirestoreUser(uid, email, displayName, deptName, teamDocId, teamName) {
    const ref = db.collection('users').doc(uid);
    const snap = await ref.get();

    const baseData = {
        email, displayName,
        departmentId: deptName, departmentName: deptName,
        teamId: teamDocId, teamName,
        teamIds: [teamDocId], teamNames: [teamName],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
        await ref.set({
            ...baseData,
            photoURL: null,
            role: 'employee', accountType: 'internal',
            status: 'active', isRoleApproved: true, isActive: true,
            createdBy: 'seed_script', registrationMethod: 'seed',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return 'created';
    }

    const existing = snap.data();
    const isHighRole = existing.role && existing.role !== 'employee';

    if (isHighRole) {
        // Only fill missing team fields
        const patch = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        for (const f of ['departmentId', 'departmentName', 'teamId', 'teamName', 'teamIds', 'teamNames']) {
            if (!existing[f]) patch[f] = baseData[f];
        }
        await ref.set(patch, { merge: true });
        return 'skipped-role';
    }

    await ref.set({
        ...baseData,
        role: 'employee', accountType: 'internal',
        status: 'active', isRoleApproved: true, isActive: true,
    }, { merge: true });
    return 'updated';
}

async function main() {
    console.log('=== SEED FULL AUTH ===');
    const stats = {
        teams: { created: 0, updated: 0 },
        auth: { created: 0, existing: 0 },
        users: { created: 0, updated: 0, skipped: 0 },
    };

    for (let d = 0; d < teamsData.departments.length; d++) {
        const dept = teamsData.departments[d];
        const deptName = dept.departmentId;
        const deptIdx = String(d + 1).padStart(2, '0');
        console.log(`\n[${d + 1}/${teamsData.departments.length}] Department: ${deptName}`);

        // Real teams only (exclude general for user seeding)
        const realTeams = dept.teams.filter(t => t.code !== 'general');
        const allTeams = dept.teams;

        // 1) Upsert all teams
        for (const teamDef of allTeams) {
            const r = await upsertTeam(deptName, teamDef);
            stats.teams[r === 'created' ? 'created' : 'updated']++;
            if (r === 'created') console.log(`  [+] Team: ${teamDocId(deptName, teamDef.code)} (${teamDef.name})`);
        }

        // 2) Seed 5 users per real team
        for (let t = 0; t < realTeams.length; t++) {
            const teamDef = realTeams[t];
            const tIdx = String(t + 1).padStart(2, '0');
            const tDocId = teamDocId(deptName, teamDef.code);

            for (let i = 1; i <= 5; i++) {
                const iStr = String(i).padStart(2, '0');
                const email = `user_${deptIdx}_${tIdx}_${iStr}@company.com`;
                const displayName = `User ${deptName} - ${teamDef.name} - ${i}`;

                const { uid, status: authStatus } = await upsertAuthUser(email, displayName, PASSWORD);
                stats.auth[authStatus === 'created' ? 'created' : 'existing']++;
                if (authStatus === 'created') console.log(`    [+] Auth: ${email}`);

                const fsStatus = await upsertFirestoreUser(uid, email, displayName, deptName, tDocId, teamDef.name);
                if (fsStatus === 'created') stats.users.created++;
                else if (fsStatus === 'updated') stats.users.updated++;
                else stats.users.skipped++;
            }
        }
    }

    console.log('\n=== SEEDING COMPLETED ===');
    console.log(`Teams    created: ${stats.teams.created}   updated: ${stats.teams.updated}`);
    console.log(`Auth     created: ${stats.auth.created}    existing: ${stats.auth.existing}`);
    console.log(`Firestore created: ${stats.users.created}  updated: ${stats.users.updated}  skipped(high-role): ${stats.users.skipped}`);
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
