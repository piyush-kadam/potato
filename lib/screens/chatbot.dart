import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  Map<String, dynamic>? userData;
  bool isInitialized = false;
  bool hasShownQuickActions = false;

  final List<String> quickActions = [
    "How can I save more money?",
    "Analyze my spending patterns",
    "Tips for my highest spending category",
    "How much have I spent this month?",
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print("🔥 INIT CHAT STARTED");
    try {
      final user = FirebaseAuth.instance.currentUser;
      print("🔥 USER: ${user?.uid}");

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        print("🔥 DOC EXISTS: ${doc.exists}");

        if (doc.exists) {
          final data = doc.data()!;
          print("🔥 DATA: $data");

          String name = data['name']?.toString().isNotEmpty == true
              ? data['name']
              : data['username'] ?? 'there';

          int monthlyBudget = (data['monthlyBudget'] ?? 25000).toInt();
          int remainingBudget = (data['remainingBudget'] ?? monthlyBudget)
              .toInt();
          int spent = monthlyBudget - remainingBudget;
          String percentUsed = monthlyBudget > 0
              ? ((spent / monthlyBudget) * 100).toStringAsFixed(1)
              : '0.0';

          final initialMessage =
              "Hi $name 👋\nYou've set a ₹${_formatNumber(monthlyBudget)} budget and used ₹${_formatNumber(spent)} (${percentUsed}%).\nHow can I help you manage your money today? 💰";

          print("🔥 INITIAL MESSAGE: $initialMessage");
          print("🔥 MESSAGES BEFORE: ${messages.length}");

          setState(() {
            userData = data;
            messages.add({
              "role": "bot",
              "text": initialMessage,
              "timestamp": DateTime.now(),
              "isPermanent": true,
            });
            isInitialized = true;
          });

          print("🔥 MESSAGES AFTER: ${messages.length}");
          print("🔥 IS INITIALIZED: $isInitialized");
        }
      }
    } catch (e) {
      print("🔥 ERROR: $e");
      setState(() {
        isInitialized = true;
      });
    }
  }

  String _formatNumber(num number) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(number);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Mark that user has interacted, so quick actions won't show again
    if (!hasShownQuickActions) {
      setState(() {
        hasShownQuickActions = true;
      });
    }

    setState(() {
      messages.add({
        "role": "user",
        "text": message,
        "timestamp": DateTime.now(),
      });
      isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      String userContext = "";
      if (userData != null) {
        final name = userData!['name'] ?? userData!['username'] ?? 'User';
        final monthlyBudget = userData!['monthlyBudget'] ?? 0;
        final remainingBudget = userData!['remainingBudget'] ?? 0;
        final age = userData!['age'] ?? 'unknown';
        final profession = userData!['profession'] ?? 'unknown';
        final categoryBudgets = userData!['categoryBudgets'] ?? {};

        userContext =
            """
User:
- Name: $name
- Age: $age
- Profession: $profession
- Monthly Budget: ₹$monthlyBudget
- Remaining Budget: ₹$remainingBudget
- Category Budgets: ${categoryBudgets.entries.map((e) => '${e.key}: ₹${e.value}').join(', ')}
Give short, direct financial insights.
""";
      }

      // ✅ Instead of OpenAI direct API call, call your Firebase Function
      final url = Uri.parse(
        "https://us-central1-slideme-87da5.cloudfunctions.net/chatbot",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message, "context": userContext}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data["reply"] ?? "No response.";

        setState(() {
          messages.add({
            "role": "bot",
            "text": botReply.trim(),
            "timestamp": DateTime.now(),
          });
          isLoading = false;
        });
      } else {
        _addErrorMessage("Sorry, I couldn't connect. Try again.");
      }
    } catch (e) {
      _addErrorMessage("Something went wrong. Try again.");
    }
  }

  void _addErrorMessage(String text) {
    setState(() {
      messages.add({"role": "bot", "text": text, "timestamp": DateTime.now()});
      isLoading = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),

          Column(
            children: [
              // ✅ Custom AppBar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/images/mascot.png',
                      height: 25,
                      width: 30,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Assistant',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Messages
              Expanded(
                child: !isInitialized
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Builder(
                        builder: (context) {
                          print(
                            "🔥 BUILDING LISTVIEW - Messages: ${messages.length}",
                          );
                          print("🔥 isInitialized: $isInitialized");
                          print(
                            "🔥 hasShownQuickActions: $hasShownQuickActions",
                          );

                          if (messages.isEmpty) {
                            return Center(
                              child: Text(
                                "🔥 NO MESSAGES IN LIST",
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            itemCount:
                                messages.length +
                                (!hasShownQuickActions && messages.isNotEmpty
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              print("🔥 Building item $index");

                              // Show quick actions only after initial message and before user interaction
                              if (index >= messages.length) {
                                return _buildQuickActions();
                              }

                              final msg = messages[index];
                              final isUser = msg['role'] == 'user';
                              final timestamp = msg['timestamp'] as DateTime;

                              return Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom: 4,
                                      left: isUser ? 60 : 0,
                                      right: isUser ? 0 : 60,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFF7C4DFF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(
                                          isUser ? 16 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          isUser ? 4 : 16,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: GoogleFonts.poppins(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isUser ? 0 : 8,
                                      right: isUser ? 8 : 0,
                                      bottom: 16,
                                    ),
                                    child: Text(
                                      _formatTime(timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),

              // Typing Indicator
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Typing...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Input field
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: sendMessage,
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => sendMessage(_controller.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
          child: Text(
            'Try asking:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickActions.map((action) {
            return InkWell(
              onTap: () => sendMessage(action),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Text(
                  action,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
