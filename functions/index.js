const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
require("dotenv").config();

admin.initializeApp();

exports.chatbot = functions.https.onRequest(async (req, res) => {
  try {
    const { message, context } = req.body; // ✅ now also reading context

    if (!message) {
      return res.status(400).json({ error: "No message provided" });
    }

    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({ error: "Missing OpenAI API key" });
    }

    // ✅ Combine context + user message for better personalized responses
    const fullPrompt = context
      ? `${context}\nUser: ${message}`
      : message;

    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
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
    });

    const data = await openaiResponse.json();

    const reply =
      data?.choices?.[0]?.message?.content ||
      "Sorry, I couldn't generate a response.";

    res.status(200).json({ reply });
  } catch (error) {
    console.error("Chatbot Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
