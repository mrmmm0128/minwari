import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:study_flutter_firebase/pages/show_history_page.dart';
import 'package:study_flutter_firebase/pages/suggest_next_pay.dart';

class MemoDetailPage extends StatefulWidget {
  final String memoId;

  const MemoDetailPage({required this.memoId, Key? key}) : super(key: key);

  @override
  _MemoDetailPageState createState() => _MemoDetailPageState();
}

class _MemoDetailPageState extends State<MemoDetailPage> {
  String title = "";
  List<String> participants = [];
  List<TextEditingController> _amountControllers = []; // 金額のテキストフィールド用のコントローラ
  List<TextEditingController> _memoControllers = []; // メモのテキストフィールド用のコントローラ
  Map<String, List<Map<String, dynamic>>> amounts = {}; // 支払履歴を保持するマップ
  List<String> settlementResults = []; // 清算結果を表示するリスト

  @override
  void initState() {
    super.initState();
    _fetchMemoData(); // データを取得
  }

  Future<void> _fetchMemoData() async {
    try {
      DocumentSnapshot memoDoc = await FirebaseFirestore.instance
          .collection('memo')
          .doc(widget.memoId)
          .get();

      if (memoDoc.exists) {
        setState(() {
          title = memoDoc['title'] ?? "";
          participants = List<String>.from(memoDoc['participants'] ?? []);
          amounts = Map<String, List<Map<String, dynamic>>>.from(
            memoDoc['amounts']?.map(
                  (key, value) => MapEntry(
                key,
                List<Map<String, dynamic>>.from(value.map((entry) => Map<String, dynamic>.from(entry))),
              ),
            ) ?? {},
          );
          _amountControllers = List.generate(participants.length, (index) => TextEditingController());
          _memoControllers = List.generate(participants.length, (index) => TextEditingController());
        });
      } else {
        setState(() {
          title = "メモが見つかりません";
          participants = [];
        });
      }
    } catch (e) {
      print("Error fetching memo data: $e");
      setState(() {
        title = "データ取得エラー";
        participants = [];
      });
    }
  }

  Future<void> saveData() async {
    try {
      DocumentReference memoDocRef = FirebaseFirestore.instance.collection('memo').doc(widget.memoId);
      DocumentSnapshot memoDoc = await memoDocRef.get();

      // Firestoreから既存の履歴データを取得
      if (memoDoc.exists && memoDoc['amounts'] != null) {
        amounts = Map<String, List<Map<String, dynamic>>>.from(
          memoDoc['amounts'].map(
                (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(value.map((entry) => Map<String, dynamic>.from(entry))),
            ),
          ),
        );
      }

      // 各参加者の金額履歴を更新
      for (int i = 0; i < participants.length; i++) {
        String amountText = _amountControllers[i].text;
        double? newAmount = double.tryParse(amountText);

        // 金額が入力されていない場合、スキップ
        if (newAmount == null || newAmount == 0) {
          continue;
        }

        String newMemo = _memoControllers[i].text;

        if (!amounts.containsKey(participants[i])) {
          amounts[participants[i]] = []; // 初めての参加者はリストを初期化
        }

        // 新しい支払いを履歴に追加
        amounts[participants[i]]!.add({
          'amount': newAmount,
          'memo': newMemo,
          'date': Timestamp.now(),
        });

        // 入力フィールドをクリア
        _amountControllers[i].clear();
        _memoControllers[i].clear();
      }

      // Firestoreに保存
      await memoDocRef.update({
        'amounts': amounts,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データが保存されました')),
      );
    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データの保存に失敗しました')),
      );
    }
  }

  void _showHistoryDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return PaymentHistoryPage(
            amounts: amounts, // ここで既存の amounts を渡します
            travelId: widget.memoId, // memoId を渡す
          );
        },
      ),
    );
  }

  void _settlePayments() {
    // 各参加者の合計支払額を計算
    Map<String, double> payMap = {
      for (var entry in amounts.entries)
        entry.key: entry.value.fold(0.0, (sum, payment) => sum + (payment['amount'] as double))
    };

    // 清算ロジックを適用
    setState(() {
      settlementResults = seisan(payMap);
    });
  }

  List<String> seisan(Map<String, double> payMap) {
    int people = payMap.length;
    double sumPay = payMap.values.reduce((a, b) => a + b);
    double aPay = sumPay / people;

    Map<String, double> newPay = {
      for (var entry in payMap.entries) entry.key: entry.value - aPay
    };

    List<String> conceqence = [];

    while (true) {
      double pay = newPay.values.reduce(min);
      List<String> payPeople = newPay.entries
          .where((entry) => entry.value == pay)
          .map((entry) => entry.key)
          .toList();

      double get = newPay.values.reduce(max);
      List<String> getPeople = newPay.entries
          .where((entry) => entry.value == get)
          .map((entry) => entry.key)
          .toList();

      double payment = min(get, pay.abs());

      for (int i = 0; i < min(payPeople.length, getPeople.length); i++) {
        newPay[payPeople[i]] = newPay[payPeople[i]]! + payment;
        newPay[getPeople[i]] = newPay[getPeople[i]]! - payment;
        conceqence.add('${payPeople[i]}が${getPeople[i]}に支払い：¥${payment.round()}');
      }

      if (newPay.values.every((value) => (value).abs() < 1e-9)) {
        return conceqence;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "メンバー一覧",
                style: TextStyle(fontSize: 30, color: Colors.blueGrey),
              ),
              const Divider(thickness: 1.5, color: Colors.blueGrey),
              const SizedBox(height: 20),
              if (participants.isEmpty)
                const Center(
                  child: Text(
                    "参加者がいません",
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                ...List.generate(participants.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            participants[index],
                            style: const TextStyle(fontSize: 20, color: Colors.blueGrey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade100,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _amountControllers[index],
                              decoration: const InputDecoration(
                                labelText: '金額',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade100,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _memoControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'メモ',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      ),
                      child: const Text('保存'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showHistoryDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      ),
                      child: const Text('履歴を見る'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _settlePayments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      ),
                      child: const Text('清算する'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PaymentSuggestionPage(memoId: widget.memoId)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      ),
                      child: const Text('支払提案'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (settlementResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("清算結果:", style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
                    const SizedBox(height: 10),
                    ...settlementResults.map((result) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        result,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    )).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.blue.shade50,
    );
  }
}