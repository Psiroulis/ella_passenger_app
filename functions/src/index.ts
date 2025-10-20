import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';


initializeApp();

const db = getFirestore();

export const registerDevice = onCall({ region: 'europe-west1' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Not signed in');

  const device = (request.data as any)?.device;
  if (!device?.deviceId) throw new HttpsError('invalid-argument', 'Missing device ID');

  const ref = db.collection('riders').doc(uid).collection('devices').doc(device.deviceId);
  await ref.set(
    {
      uid,
      ...device,
      forceLogout: false,
      lastActiveAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true };
});