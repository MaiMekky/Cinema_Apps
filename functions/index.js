/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// 🔔 HTTP Cloud Function (Spark Plan OK!)
exports.sendVendorNotification = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }

    const { bookingId, movieTitle, seatsCount, customerName } = req.body;

    if (!bookingId || !movieTitle || !seatsCount || !customerName) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    // 1️⃣ Get vendor token
    const vendorDoc = await admin.firestore()
      .collection('appConfig')
      .doc('vendor')
      .get();

    if (!vendorDoc.exists || !vendorDoc.data()?.fcmToken) {
      console.error('❌ Vendor token not found');
      res.status(404).json({ error: 'Vendor token not found' });
      return;
    }

    const token = vendorDoc.data().fcmToken;
    console.log('✅ Vendor token found');

    // 2️⃣ Send FCM
    const message = {
      token: token,
      notification: {
        title: '🎟️ New Booking!',
        body: `${customerName} booked ${seatsCount} seats for "${movieTitle}"`,
      },
      data: {
        route: 'notifications',
        bookingId: bookingId,
        movieTitle: movieTitle,
        seatsCount: seatsCount.toString(),
        customerName: customerName,
      },
      android: {
        priority: 'high',
        notification: { channelId: 'vendor_notifications' },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ FCM sent:', response);

    // 3️⃣ Save notification
    await admin.firestore().collection('notifications').add({
      title: 'New Booking',
      message: `${customerName} booked ${seatsCount} seats for ${movieTitle}`,
      bookingId: bookingId,
      data: message.data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      seen: false,
    });

    res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({ error: error.message });
  }
});
