const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Import nowej składni v2
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

// Zmień region na europe-west1
exports.sendOrderNotification = onDocumentUpdated(
  { document: "orders/{orderId}", region: "europe-west1" },
  async (event) => {
    // W v2 dane są w obiekcie event.data
    const snapshot = event.data;
    if (!snapshot) {
      functions.logger.log("Brak danych w zdarzeniu");
      return;
    }

    const newValue = snapshot.after.data();
    const previousValue = snapshot.before.data();

    // Sprawdź, czy status zmienił się na "Gotowe"
    if (newValue.status === "Gotowe" && previousValue.status !== "Gotowe") {
      const userId = newValue.userId;
      if (!userId) {
        functions.logger.log("Brak userId w zamówieniu.");
        return;
      }

      // Pobierz dokument użytkownika, aby uzyskać token FCM
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        functions.logger.log("Nie znaleziono użytkownika.", { userId: userId });
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        functions.logger.log("Użytkownik nie ma tokenu FCM.", { userId: userId });
        return;
      }

      // Zdefiniuj treść powiadomienia
      const payload = {
        notification: {
          title: "Twoje zamówienie jest gotowe!",
          body: "Odbierz je wkrótce przy kasie.",
          sound: "default",
        },
      };

      // Wyślij powiadomienie
      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
        functions.logger.log("Powiadomienie zostało wysłane pomyślnie.", { userId: userId });
      } catch (error) {
        functions.logger.error("Błąd podczas wysyłania powiadomienia:", error);
      }
    }
    return null;
  }
);
