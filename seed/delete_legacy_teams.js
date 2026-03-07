require('dotenv').config();
const admin = require('firebase-admin');
const path = require('path');

admin.initializeApp({ credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccountKey.json'))) });
const db = admin.firestore();

// Old team codes to delete (legacy from previous seed run)
const OLD_CODES = ['__t1', '__t2', '__t3', '__general']; // keep __general? NO — re-seed will recreate proper ones

// Actually only delete __t1, __t2, __t3. Keep __general docs (they are valid fallback).
const LEGACY_SUFFIXES = ['__t1', '__t2', '__t3'];

async function main() {
    console.log('=== DELETE LEGACY TEAMS (t1/t2/t3) ===');

    const snap = await db.collection('teams').get();
    const toDelete = snap.docs.filter(doc =>
        LEGACY_SUFFIXES.some(suffix => doc.id.endsWith(suffix))
    );

    console.log(`Found ${toDelete.length} legacy team docs to delete:`);
    toDelete.forEach(d => console.log(`  - ${d.id}`));

    if (toDelete.length === 0) {
        console.log('Nothing to delete.');
        return;
    }

    // Batch delete
    const BATCH_SIZE = 450;
    for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        toDelete.slice(i, i + BATCH_SIZE).forEach(d => batch.delete(d.ref));
        await batch.commit();
        console.log(`Deleted batch ${Math.floor(i / BATCH_SIZE) + 1}`);
    }

    console.log(`\n✅ Done. Deleted ${toDelete.length} legacy teams.`);
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
