const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const plantsData = require('./plants.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadPlants() {
  const plants = plantsData.plants;

  for (const plantId in plants) {
    await db.collection('plants').doc(plantId).set({
      ...plants[plantId],
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Uploaded: ${plantId}`);
  }

  console.log('All plants uploaded successfully.');
}

uploadPlants();
