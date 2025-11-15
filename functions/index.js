// -----------------------------
// Firebase Functions v2 Imports
// -----------------------------
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
require("dotenv").config();

// Initialize Admin SDK
admin.initializeApp();

/* ============================================================
   1️⃣ CHATBOT FUNCTION (UNCHANGED LOGIC, UPDATED TO v2)
   ============================================================ */
exports.chatbot = onRequest(async (req, res) => {
  try {
    const { message, context } = req.body;

    if (!message) {
      return res.status(400).json({ error: "No message provided" });
    }

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: "Missing OpenAI API Key" });
    }

    const fullPrompt = context
      ? `${context}\nUser: ${message}`
      : message;

    const openaiResponse = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content:
                "You are a concise and smart financial assistant that provides direct, helpful insights about budgeting, spending, and financial planning.",
            },
            {
              role: "user",
              content: fullPrompt,
            },
          ],
        }),
      }
    );

    const data = await openaiResponse.json();
    const reply =
      data?.choices?.[0]?.message?.content ||
      "Sorry, I couldn't generate a response.";

    res.status(200).json({ reply });
  } catch (err) {
    console.error("Chatbot Error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/* ============================================================
   2️⃣ RANDOM HOURLY PUSH NOTIFICATIONS (FULLY v2)
   ============================================================ */

const potatoMessages = [
  "Your money’s been working 9 to 5. Have you checked in yet?",
  "Budget left the chat. Time to bring it back.",
  "Somewhere a wallet just sighed. Log your expenses!",
  "You spent ₹200 on coffee again, didn’t you?",
  "Your funds are playing hide & seek. They're losing.",
  "Savings goals ignored like unread emails.",
  "Potato Book misses you. Your wallet doesn’t.",
  "Money can’t talk, but your balance is screaming.",
  "Hey, future millionaire 👋 Log expenses today!",
  "Instant noodles: 10. Budget discipline: 0.",
  "Ignoring finances = borrowing from friends later.",
  "It’s not about being broke. It's awareness.",
  "We can’t stop inflation, but we can track pizza.",
  "Check your money before your money checks you.",
  "Your wallet just DMed us: ‘help.’",
  "You're one log away from control.",
  "Your bank statement is writing a horror story.",
  "Tracking money is cheaper than therapy.",
  "Expenses won’t log themselves.",
  "Small savings now = guilt-free weekend later.",
];

// Run every hour using v2 scheduler
exports.randomPotatoNotifications = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    // 30% chance
    if (Math.random() > 0.30) {
      console.log("Random skip — not sending this hour.");
      return null;
    }

    const message =
      potatoMessages[Math.floor(Math.random() * potatoMessages.length)];

    const snapshot = await admin.firestore().collection("fcmTokens").get();
    const tokens = snapshot.docs.map((d) => d.data().token);

    if (tokens.length === 0) {
      console.log("No FCM tokens found.");
      return null;
    }

    await admin.messaging().sendMulticast({
      tokens,
      notification: {
        title: "Potato Book 🥔",
        body: message,
      },
    });

    console.log("Notification sent:", message);
    return null;
  }
);
