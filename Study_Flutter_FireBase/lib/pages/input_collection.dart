import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_flutter_firebase/pages/add_memo_page.dart';
import 'package:study_flutter_firebase/pages/top_page.dart';


class CollectionInputPage extends StatefulWidget {
  const CollectionInputPage({super.key});

  @override
  _CollectionInputPageState createState() => _CollectionInputPageState();
}

class _CollectionInputPageState extends State<CollectionInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();

  void _navigateToNextPage(String collectionName) {
    if (collectionName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(collectionName: collectionName),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループ名を入力してください')),
      );
    }
  }

  void _createNewGroupAndNavigate(String groupName) async {
    if (groupName.isNotEmpty) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMemoPage(collectionName: groupName),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいグループが作成されました')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいグループ名を入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("グループ名入力"),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToNextPage(_controller.text),
              child: const Text('既存グループに移動'),
            ),
            const Divider(height: 40),
            TextField(
              controller: _newGroupController,
              decoration: const InputDecoration(
                labelText: '新しいグループ名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _createNewGroupAndNavigate(_newGroupController.text),
              child: const Text('新しいグループを作成'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}

class NewAddMemoPage {
}