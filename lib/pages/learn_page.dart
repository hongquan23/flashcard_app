// pages/learn_page.dart - GHI NHẬN HỌC
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../widgets/flip_card.dart';
import '../services/flashcard_service.dart';

class LearnPage extends StatefulWidget {
  final List<Flashcard> cards;
  const LearnPage({super.key, required this.cards});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int currentIndex = 0;
  final service = FlashcardService();

  @override
  void initState() {
    super.initState();
    // GHI NHẬN KHI VÀO HỌC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      service.recordStudySession(widget.cards.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Học Flashcard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              setState(() {
                widget.cards.shuffle();
                currentIndex = 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          FlipCard(frontText: card.term, backText: card.meaning),
          if (card.note != null && card.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Ghi chú: ${card.note}", style: TextStyle(color: Colors.grey[600])),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 32),
                  onPressed: currentIndex > 0 ? () => setState(() => currentIndex--) : null,
                ),
                Text("${currentIndex + 1} / ${widget.cards.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 32),
                  onPressed: currentIndex < widget.cards.length - 1 ? () => setState(() => currentIndex++) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}