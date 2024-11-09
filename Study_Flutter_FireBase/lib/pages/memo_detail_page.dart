import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:study_flutter_firebase/pages/show_history_page.dart';

class MemoDetailPage extends StatefulWidget {
  final String memoId;

  const MemoDetailPage({required this.memoId, Key? key}) : super(key: key);

  @override
  _MemoDetailPageState createState() => _MemoDetailPageState();
}

class _MemoDetailPageState extends State<MemoDetailPage> {
  String title = "";
  List<String> participants = [];
  List<TextEditingController> _amountControllers = [];
  List<String> memoEntries = []; // メモの内容を保持するリスト
  Map<String, List<Map<String, dynamic>>> amounts = {};
  List<String> settlementResults = [];
  List<String> currencies = ['JPY', 'USD', 'EUR', 'GBP'];
  List<String> selectedCurrencies = [];

  @override
  void initState() {
    super.initState();
    _fetchMemoData();
    selectedCurrencies = List.generate(participants.length, (index) => 'JPY');
    memoEntries = List.filled(participants.length, ""); // メモの初期化
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
          selectedCurrencies = List.generate(participants.length, (index) => 'JPY');
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

      for (int i = 0; i < participants.length; i++) {
        String amountText = _amountControllers[i].text;
        double? newAmount = double.tryParse(amountText);

        if (newAmount == null || newAmount == 0) {
          continue;
        }

        if (!amounts.containsKey(participants[i])) {
          amounts[participants[i]] = [];
        }

        amounts[participants[i]]!.add({
          'amount': newAmount,
          'currency': selectedCurrencies[i],
          'memo': memoEntries[i],
          'date': Timestamp.now(),
        });

        _amountControllers[i].clear();
        memoEntries[i] = ""; // メモをクリア
      }

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

  void _showMemoInputDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${participants[index]}のメモ'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                memoEntries[index] = value;
              });
            },
            controller: TextEditingController(text: memoEntries[index]),
            decoration: const InputDecoration(hintText: "メモを入力してください"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
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
        entry.key: entry.value.fold(0.0, (sum, payment) {
          double amount = payment['amount'] as double;
          String currency = payment['currency'] as String;
          return sum + convertToJPY(amount, currency); // 日本円に換算
        })
    };

    // 清算ロジックを適用
    setState(() {
      settlementResults = seisan(payMap);
    });
  }

  double convertToJPY(double amount, String currency) {
    // ここで為替レートを取得するロジックを実装
    double exchangeRate = getExchangeRate(currency); // 為替レートを取得する関数
    return amount * exchangeRate; // 日本円に換算
  }

  double getExchangeRate(String currency) {
    // 仮の為替レート（実際にはAPIから取得する必要があります）
    switch (currency) {
      case 'USD':
        return 110.0; // 例: 1 USD = 110 JPY
      case 'EUR':
        return 130.0; // 例: 1 EUR = 130 JPY
      case 'GBP':
        return 150.0; // 例: 1 GBP = 150 JPY
      default: // JPY
        return 1.0; // 日本円はそのまま
    }
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
                          child: DropdownButton<String>(
                            value: selectedCurrencies[index],
                            items: currencies.map((String currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCurrencies[index] = newValue!;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.note_add),
                          onPressed: () {
                            _showMemoInputDialog(index); // メモ入力ダイアログを表示
                          },
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
                      onPressed: _showHistoryDialog, // 履歴表示のコード
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
                      onPressed: _settlePayments, // 清算のコード
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
