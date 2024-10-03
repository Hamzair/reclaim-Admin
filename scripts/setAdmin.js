// Script to set admin permission for certain users.
//
// 1. Go download service account credentials.
//    a. in console.firebase.console.com
//    b. go to "Project Settings"
//    c. go to the "Service accounts" tab
//    d. Under "Firebase Admin SDK", click the "Generate new private key"
// 2. The private key file will be downloaded to your machine.
// 3. export GOOGLE_APPLICATION_CREDENTIALS=<path to your downloaded service account.json file>
// 4. run this script
//

const admin = require('firebase-admin');

// Initialize the app with a service account, granting admin privileges
admin.initializeApp({
  credential: admin.credential.cert(require('C:/OfficeWork/Reclaim-AdminPanel/scripts/servicekey.json')),
});

// Admin emails array
const adminEmails = [
  "hamzairshad126@gmail.com",
  "hamzaansari9776@gmail.com"
];

async function setAdminClaims() {
  for (let adminEmail of adminEmails) {
    try {
      console.log("Setting credentials for " + adminEmail);
      const userRecord = await admin.auth().getUserByEmail(adminEmail);
      console.log('Successfully fetched user data:', userRecord.toJSON());
      await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
      console.log(`Admin role set for ${adminEmail}`);
    } catch (error) {
      console.error('Error fetching user data:', error);
    }
  }
}

setAdminClaims();

