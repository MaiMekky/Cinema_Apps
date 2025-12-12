const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onSeatBooking = functions.firestore
  .document("movies/{movieId}/slots/{slotId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const movieId = context.params.movieId;
    const slotId = context.params.slotId;

    const beforeSeats = before.seats || {};
    const afterSeats = after.seats || {};

    // Detect newly booked seats
    const newlyBooked = [];
    for (const seatId of Object.keys(afterSeats)) {
      const wasBooked = beforeSeats[seatId]?.booked === true;
      const nowBooked = afterSeats[seatId]?.booked === true;

      if (!wasBooked && nowBooked) {
        newlyBooked.push({
          seatId,
          userId: afterSeats[seatId].userId || null,
        });
      }
    }

    if (newlyBooked.length === 0) return null;

    // Fetch movie title
    const movieSnap = await admin.firestore().doc(`movies/${movieId}`).get();
    const movie = movieSnap.data() || {};
    const movieTitle = movie.title || "Movie";

    // Fetch user name
    let customerName = "Customer";
    const userId = newlyBooked[0].userId;

    if (userId) {
      const userSnap = await admin.firestore().doc(`users/${userId}`).get();
      if (userSnap.exists) {
        const u = userSnap.data();
        customerName = u.fullName || u.name || "Customer";
      }
    }

    // Count total booked seats
    let totalBooked = 0;
    for (const seat of Object.values(afterSeats)) {
      if (seat.booked === true) totalBooked++;
    }

    // Get vendor token (one global vendor)
    const configRef = admin.firestore().doc("appConfig/vendor");
    const vendorConfig = (await configRef.get()).data() || {};
    const vendorToken = vendorConfig.fcmToken;

    // Notification payload
    const notificationPayload = {
      notification: {
        title: `New booking — ${movieTitle}`,
        body: `${customerName} booked ${newlyBooked.length} seat(s). Total booked: ${totalBooked}.`
      },
      data: {
        movieId,
        slotId,
        movieTitle,
        customerName,
        numberBookedNow: String(newlyBooked.length),
        totalBooked: String(totalBooked),
      }
    };

    // Save notification in Firestore
    await admin.firestore().collection("notifications").add({
      title: `New booking — ${movieTitle}`,
      message: `${customerName} booked ${newlyBooked.length} seat(s).`,
      movieId,
      slotId,
      customerName,
      numberBookedNow: newlyBooked.length,
      totalBooked,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      seen: false
    });

    // Send push notif to vendor
   if (vendorToken) {
  try {
    console.log('Sending notification to token:', vendorToken);
    const response = await admin.messaging().sendToDevice(vendorToken, notificationPayload);
    console.log('Notification sent successfully:', response);
  } catch (err) {
    console.error('Failed to send notification:', err);
  }
}

    return null;
  });
