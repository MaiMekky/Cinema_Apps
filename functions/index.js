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

/**
 * 🔔 Trigger when a new booking is created
 * Path: bookings/{bookingId}
 */
exports.onNewBooking = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    try {
      const booking = snap.data();
      if (!booking) return null;

      const {
        movieTitle,
        seatsCount,
        customerName,
      } = booking;

      // 1️⃣ Get vendor FCM token
      const vendorDoc = await admin
        .firestore()
        .collection("appConfig")
        .doc("vendor")
        .get();

      if (!vendorDoc.exists) return null;

      const token = vendorDoc.data()?.fcmToken;
      if (!token) return null;

      // 2️⃣ Create FCM payload (IMPORTANT: route)
      const message = {
        token: token,
        notification: {
          title: "New Booking 🎟️",
          body: `${customerName} booked ${seatsCount} seats for ${movieTitle}`,
        },
        data: {
          route: "notifications", // ✅ REQUIRED FOR NAVIGATION
          bookingId: context.params.bookingId,
          movieTitle: movieTitle,
          seatsCount: seatsCount.toString(),
          customerName: customerName,
        },
      };

      // 3️⃣ Send FCM
      await admin.messaging().send(message);

      // 4️⃣ Save notification to Firestore
      await admin.firestore().collection("notifications").add({
        title: "New Booking",
        message: `${customerName} booked ${seatsCount} seats for ${movieTitle}`,
        bookingId: context.params.bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        seen: false,
      });

      return null;
    } catch (error) {
      console.error("❌ onNewBooking error:", error);
      return null;
    }
  });
