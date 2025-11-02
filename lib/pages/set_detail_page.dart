import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import 'add_edit_flashcard_page.dart';
import 'learn_page.dart';
import '../widgets/gradient_learn_button.dart';

class SetDetailPage extends StatefulWidget {
  final FlashcardSet set;
  const SetDetailPage({super.key, required this.set});

  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  late FlashcardSet _currentSet;
  final FlashcardService _service = FlashcardService();
  List<FlashcardSet> _allSets = [];

  @override
  void initState() {
    super.initState();
    _currentSet = widget.set;
    _loadCurrentSet();
  }

  Future<void> _loadCurrentSet() async {
    await _service.loadData();
    _allSets = _service.sets;

    final updatedSet = _allSets.firstWhere(
          (set) => set.id == _currentSet.id,
      orElse: () => _currentSet,
    );

    if (mounted) {
      setState(() {
        _currentSet = updatedSet;
      });
    }
  }

  void _refresh() async {
    await _loadCurrentSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSet.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditSetDialog,
            tooltip: "Sửa tên bộ thẻ",
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteSetDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa bộ thẻ'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
        tooltip: "Thêm thẻ mới",
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_currentSet.cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Chưa có thẻ nào trong bộ này",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Hãy thêm thẻ đầu tiên để bắt đầu học!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Tổng thẻ", _currentSet.cards.length.toString()),
              _buildStatItem("Đã học", "0"),
              _buildStatItem("Thành thạo", "0"),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _currentSet.cards.length,
            itemBuilder: (context, index) {
              final card = _currentSet.cards[index];
              return _buildCardItem(card, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCardItem(Flashcard card, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Dismissible(
        key: Key('${card.term}_$index'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteCardDialog(card);
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text('${index + 1}'),
          ),
          title: Text(
            card.term,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.meaning),
              if (card.note != null && card.note!.isNotEmpty)
                Text(
                  card.note!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editCard(card),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientLearnButton(
            onPressed: _currentSet.cards.isEmpty
                ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Hãy thêm thẻ để bắt đầu học!"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
                : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearnPage(cards: _currentSet.cards),
              ),
            ),
            cardCount: _currentSet.cards.length,
            isEnabled: _currentSet.cards.isNotEmpty,
          ),
        ],
      ),
    );
  }

  void _addCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFlashcardPage(
          onSave: (card) async {
            await _service.addCard(_currentSet.id, card);
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã thêm thẻ mới!")),
            );
          },
        ),
      ),
    );
  }

  void _editCard(Flashcard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFlashcardPage(
          card: card,
          onSave: (newCard) async {
            await _service.updateCard(_currentSet.id, card.term, newCard);
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã cập nhật thẻ!")),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteCardDialog(Flashcard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa thẻ?"),
        content: Text("Bạn có chắc muốn xóa thẻ \"${card.term}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _service.deleteCard(_currentSet.id, card.term);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xóa thẻ \"${card.term}\"")),
      );
    }

    return result ?? false;
  }

  void _showDeleteSetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa bộ thẻ?"),
        content: Text("Bạn có chắc muốn xóa bộ thẻ \"${_currentSet.title}\" và tất cả ${_currentSet.cards.length} thẻ bên trong?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteSet(_currentSet.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã xóa bộ thẻ \"${_currentSet.title}\"")),
              );
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSetDialog() {
    final controller = TextEditingController(text: _currentSet.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa tên bộ thẻ"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên bộ thẻ",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _service.updateSet(_currentSet.id, controller.text.trim());
                setState(() {
                  _currentSet = FlashcardSet(
                      id: _currentSet.id,
                      userId: _currentSet.userId, // QUAN TRỌNG: THÊM USER ID
                      title: controller.text.trim(),
                      cards: _currentSet.cards
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã cập nhật tên bộ thẻ!")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}