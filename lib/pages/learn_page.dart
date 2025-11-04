// pages/learn_page.dart - ĐÃ THÊM GHI NHẬN HỌC
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../widgets/flip_card.dart';
import '../services/flashcard_service.dart';

class LearnPage extends StatefulWidget {
  final List<Flashcard> cards;
  final String? setName;
  const LearnPage({super.key, required this.cards, this.setName});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int currentIndex = 0;
  final FlashcardService _service = FlashcardService();
  bool _hasRecordedStudy = false;

  @override
  void initState() {
    super.initState();
    // GHI NHẬN KHI VÀO HỌC - chỉ ghi nhận 1 lần
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRecordedStudy && widget.cards.isNotEmpty) {
        _service.recordStudySession(widget.cards.length);
        _hasRecordedStudy = true;
        debugPrint('Đã ghi nhận học ${widget.cards.length} thẻ từ bộ ${widget.setName}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Học Flashcard")),
        body: const Center(
          child: Text("Không có thẻ nào để học"),
        ),
      );
    }

    final card = widget.cards[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setName ?? "Học Flashcard"),
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
          LinearProgressIndicator(
            value: (currentIndex + 1) / widget.cards.length,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
          const SizedBox(height: 30),
          FlipCard(frontText: card.term, backText: card.meaning),
          if (card.note != null && card.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Ghi chú: ${card.note}",
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
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
                  color: currentIndex > 0 ? Colors.blue : Colors.grey,
                ),
                Text(
                  "${currentIndex + 1} / ${widget.cards.length}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 32),
                  onPressed: currentIndex < widget.cards.length - 1 ? () => setState(() => currentIndex++) : null,
                  color: currentIndex < widget.cards.length - 1 ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}