import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:study_flutter_firebase/components/ad_interstatial.dart';
import 'package:study_flutter_firebase/components/ad_mob.dart';
import 'package:study_flutter_firebase/pages/show_history_page.dart';
import 'package:study_flutter_firebase/pages/suggest_next_pay.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:study_flutter_firebase/pages/explain.dart';
import 'package:study_flutter_firebase/pages/privacypolicy.dart';
import 'package:study_flutter_firebase/pages/servicerule.dart';
import 'package:study_flutter_firebase/pages/our_information.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MemoDetailPage extends StatefulWidget {
  const MemoDetailPage(
      {required this.memoId, required this.collectionName, Key? key})
      : super(key: key);
  final String memoId;
  final String collectionName;

  @override
  _MemoDetailPageState createState() => _MemoDetailPageState();
}

class _MemoDetailPageState extends State<MemoDetailPage> {
  final AdMob _adMob = AdMob();
  final AdInterstitial _adInterstitial = AdInterstitial();
  String title = "";
  List<String> participants = [];
  List<TextEditingController> _amountControllers = []; // 金額のテキストフィールド用のコントローラ
  List<TextEditingController> _memoControllers = []; // メモのテキストフィールド用のコントローラ
  Map<String, List<Map<String, dynamic>>> amounts = {}; // 支払履歴を保持するマップ
  List<String> settlementResults = [];
  List<String> originCurrencies = [
    'JPY',
    'USD',
    'BOB',
    'PEN',
    'AED',
    'AFN',
    'ALL',
    'AMD',
    'ANG',
    'AOA',
    'ARS',
    'AUD',
    'AWG',
    'AZN',
    'BAM',
    'BBD',
    'BDT',
    'BGN',
    'BHD',
    'BIF',
    'BMD',
    'BND',
    'BRL',
    'BSD',
    'BTN',
    'BWP',
    'BYN',
    'BZD',
    'CAD',
    'CDF',
    'CHF',
    'CLP',
    'CNY',
    'COP',
    'CRC',
    'CUP',
    'CVE',
    'CZK',
    'DJF',
    'DKK',
    'DOP',
    'DZD',
    'EGP',
    'ERN',
    'ETB',
    'EUR',
    'FJD',
    'FKP',
    'FOK',
    'GBP',
    'GEL',
    'GGP',
    'GHS',
    'GIP',
    'GMD',
    'GNF',
    'GTQ',
    'GYD',
    'HKD',
    'HNL',
    'HRK',
    'HTG',
    'HUF',
    'IDR',
    'ILS',
    'IMP',
    'INR',
    'IQD',
    'IRR',
    'ISK',
    'JEP',
    'JMD',
    'JOD',
    'KES',
    'KGS',
    'KHR',
    'KID',
    'KMF',
    'KRW',
    'KWD',
    'KYD',
    'KZT',
    'LAK',
    'LBP',
    'LKR',
    'LRD',
    'LSL',
    'LYD',
    'MAD',
    'MDL',
    'MGA',
    'MKD',
    'MMK',
    'MNT',
    'MOP',
    'MRU',
    'MUR',
    'MVR',
    'MWK',
    'MXN',
    'MYR',
    'MZN',
    'NAD',
    'NGN',
    'NIO',
    'NOK',
    'NPR',
    'NZD',
    'OMR',
    'PAB',
    'PGK',
    'PHP',
    'PKR',
    'PLN',
    'PYG',
    'QAR',
    'RON',
    'RSD',
    'RUB',
    'RWF',
    'SAR',
    'SBD',
    'SCR',
    'SDG',
    'SEK',
    'SGD',
    'SHP',
    'SLE',
    'SLL',
    'SOS',
    'SRD',
    'SSP',
    'STN',
    'SYP',
    'SZL',
    'THB',
    'TJS',
    'TMT',
    'TND',
    'TOP',
    'TRY',
    'TTD',
    'TVD',
    'TWD',
    'TZS',
    'UAH',
    'UGX',
    'UYU',
    'UZS',
    'VES',
    'VND',
    'VUV',
    'WST',
    'XAF',
    'XCD',
    'XDR',
    'XOF',
    'XPF',
    'YER',
    'ZAR',
    'ZMW',
    'ZWL'
  ];

  List<String?> selectedCurrencies = [];
  final String apiKey = 'YOUR_API_KEY'; // APIキーを入れてください
  List<String> memoEntries = List.filled(100, ""); // メモの内容を保持するリスト
  List<String> selectedParticipants = []; // 選択された参加者のリスト
  List<String> currencies = [];

  @override
  void initState() {
    super.initState();
    _fetchMemoData(); // データを取得
    _adMob.load();
    _adInterstitial.load();
  }

  @override
  void dispose() {
    super.dispose();
    _adMob.dispose();
    _adInterstitial.dispose();
  }

  void _showInterstitial() {
    // インターステイシャル広告を表示
    _adInterstitial.show();
  }

  void _navigateToExplain(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Explain()),
    );
  }

  Future<void> _fetchMemoData() async {
    try {
      DocumentSnapshot memoDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.memoId)
          .get();

      if (memoDoc.exists) {
        setState(() {
          title = memoDoc['title'] ?? "";
          participants = List<String>.from(memoDoc['participants'] ?? []);
          currencies = (memoDoc["currency"] as List<dynamic>).cast<String>();

          amounts = Map<String, List<Map<String, dynamic>>>.from(
            memoDoc['amounts']?.map(
                  (key, value) => MapEntry(
                    key,
                    List<Map<String, dynamic>>.from(
                        value.map((entry) => Map<String, dynamic>.from(entry))),
                  ),
                ) ??
                {},
          );
          _amountControllers = List.generate(
              participants.length, (index) => TextEditingController());
          _memoControllers = List.generate(
              participants.length, (index) => TextEditingController());
          // selectedCurrencies に人数分の "JPY" を設定
          selectedCurrencies =
              List.generate(participants.length, (index) => "JPY");
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

  Future<void> _fetchMemoDataBefore() async {
    try {
      DocumentSnapshot memoDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.memoId)
          .get();

      if (memoDoc.exists) {
        setState(() {
          title = memoDoc['title'] ?? "";
          participants = List<String>.from(memoDoc['participants'] ?? []);
          currencies = (memoDoc["currency"] as List<dynamic>).cast<String>();

          amounts = Map<String, List<Map<String, dynamic>>>.from(
            memoDoc['amounts']?.map(
                  (key, value) => MapEntry(
                    key,
                    List<Map<String, dynamic>>.from(
                        value.map((entry) => Map<String, dynamic>.from(entry))),
                  ),
                ) ??
                {},
          );
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

  Future<double> _convertToJPY(double amount, String? currency) async {
    if (currency == 'JPY') {
      return amount;
    }

    final url =
        'https://v6.exchangerate-api.com/v6/645a1985815f1f802148fe2f/latest/$currency';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final rates = json.decode(response.body)['conversion_rates'];
      if (rates.containsKey('JPY')) {
        double rate = rates['JPY'];
        return amount * rate;
      }
    }
    throw Exception("通貨レートの取得に失敗しました");
  }

  Future<void> saveData() async {
    print("saveData called");
    _showInterstitial();
    await _fetchMemoDataBefore();

    try {
      DocumentReference memoDocRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.memoId);

      // 金額が入力されている人をフィルタリング
      List<String> payers = [];
      Map<String, List<int>> selectedPayers = {};
      for (int i = 0; i < participants.length; i++) {
        String amountText = _amountControllers[i].text;
        double? newAmount = double.tryParse(amountText);
        if (newAmount != null && newAmount > 0) {
          payers.add(participants[i]);
        }
      }
      print("payers: $payers");

      // 支払い対象者がいる場合のみダイアログを表示
      if (payers.isNotEmpty) {
        print("支払い対象者がいます");
        selectedPayers = await _showPayerSelectionDialog(payers);
        if (selectedPayers.isEmpty) {
          return; // 何も選択されなかった場合、保存しない
        }
      }

      for (int i = 0; i < participants.length; i++) {
        String amountText = _amountControllers[i].text;
        double? newAmount = double.tryParse(amountText);

        if (newAmount == null || newAmount == 0) {
          continue;
        }

        String newMemo = memoEntries[i];
        double amountInJPY =
            await _convertToJPY(newAmount, selectedCurrencies[i]);
        int selectednumber = selectedPayers[participants[i]]!.length;
        double mustPay = amountInJPY / selectednumber;
        List<double> addAmIn = List.generate(participants.length, (_) => 0.0);
        for (int num in selectedPayers[participants[i]]!) {
          if (num != i) {
            addAmIn[num] = mustPay;
          }
        }

        amounts[participants[i]]!.add({
          'amount': amountInJPY,
          'originalAmount': newAmount,
          'originalCurrency': selectedCurrencies[i],
          'memo': newMemo,
          "selectedMember": selectedPayers[participants[i]],
          'individual': addAmIn,
        });
        _amountControllers[i].clear();
        _memoControllers[i].clear();

        //String newMemo = memoEntries[i];
        //double amountInJPY =
        //    await _convertToJPY(newAmount, selectedCurrencies[i]);

        //if (!amounts.containsKey(participants[i])) {
        //  amounts[participants[i]] = [];
        //}

        //amounts[participants[i]]!.add({
        //  'amount': amountInJPY,
        //  'originalAmount': newAmount,
        //  'originalCurrency': selectedCurrencies[i],
        //  'memo': newMemo,
        //  'date': Timestamp.now(),
        //});

        //_amountControllers[i].clear();
        //_memoControllers[i].clear();
      }

      await memoDocRef.update({'amounts': amounts});

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

  Future<Map<String, List<int>>> _showPayerSelectionDialog(
      List<String> payers) async {
    Map<String, List<String>> selectedPayersMap = {
      for (var payer in payers) payer: List.from(participants) // 初期値は全員選択
    };

    return await showDialog<Map<String, List<int>>>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("支払い対象者を選択"),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: payers.map((payer) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "支払った人：$payer",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Column(
                              children: participants.map((participant) {
                                return CheckboxListTile(
                                  title: Text(participant),
                                  value: selectedPayersMap[payer]!
                                      .contains(participant),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedPayersMap[payer]!
                                            .add(participant);
                                      } else {
                                        selectedPayersMap[payer]!
                                            .remove(participant);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const Divider(), // 区切り線
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({}); // キャンセル時は空のマップを返す
                  },
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 名前のリストをインデックスのリストに変換
                    Map<String, List<int>> selectedIndexesMap = {
                      for (var payer in payers)
                        payer: selectedPayersMap[payer]!
                            .map((participant) =>
                                participants.indexOf(participant))
                            .toList()
                    };
                    Navigator.of(context).pop(selectedIndexesMap);
                  },
                  child: const Text("決定"),
                ),
              ],
            );
          },
        ) ??
        {};
  }

  void _showHistoryDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return PaymentHistoryPage(
            collectionName: widget.collectionName,
            amounts: amounts, // ここで既存の amounts を渡します
            travelId: widget.memoId, // memoId を渡す
            participants: participants,
            currencies: currencies,
          );
        },
      ),
    );
  }

  void _showSettlementResultsDialog() {
    //AdInterstitial.showInterstitialAd();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF75A9D6),
          title: const Text(
            "清算結果",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: settlementResults
                .map((result) => SizedBox(
                    width: 300, // 幅を指定
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.center, // 中央揃え
                          child: Text(
                            result,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center, // テキスト内の改行も中央揃え
                          ),
                        ),
                      ),
                    )))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '閉じる',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _settlePayments() {
    // 各参加者の合計支払額を計算
    //Map<String, double> payMap = {
    //  for (var entry in amounts.entries)
    //    entry.key: entry.value.fold(
    //        0.0,
    //        (sum, payment) =>
    //            sum + (payment['amount'] as num).toDouble()) // ここでキャスト
    //};

    // 清算ロジックを適用
    setState(() {
      settlementResults = seisan(amounts, participants);
    });

    // 清算結果をダイアログで表示
    _showSettlementResultsDialog();
  }

  List<String> seisan(
      Map<String, dynamic> amountsIndividual, List<String> participants) {
    // 立て替え金額を記録する
    Map<String, double> newPay = {for (var person in participants) person: 0.0};

    // 立て替えデータを処理
    for (String lender in amountsIndividual.keys) {
      for (var record in amountsIndividual[lender] ?? []) {
        List<double> individualAmounts =
            List<double>.from(record['individual'] ?? []);

        for (int i = 0; i < individualAmounts.length; i++) {
          double amount = individualAmounts[i];
          if (amount > 0) {
            String borrower = participants[i];
            newPay[lender] = (newPay[lender] ?? 0) + amount; // 立て替えた人の負担増加
            newPay[borrower] =
                (newPay[borrower] ?? 0) - amount; // 立て替えられた人の負担減少
          }
        }
      }
    }

    List<String> conceqence = [];

    // 清算処理
    while (true) {
      if (newPay.isEmpty) return conceqence;

      double minDebt = newPay.values.reduce(min);
      double maxCredit = newPay.values.reduce(max);

      if (minDebt.abs() < 1e-9 && maxCredit.abs() < 1e-9) {
        return conceqence; // すべて清算完了
      }

      String payer = newPay.entries.firstWhere((e) => e.value == minDebt).key;
      String receiver =
          newPay.entries.firstWhere((e) => e.value == maxCredit).key;

      double payment = min(maxCredit, minDebt.abs());
      newPay[payer] = (newPay[payer] ?? 0) + payment;
      newPay[receiver] = (newPay[receiver] ?? 0) - payment;

      conceqence.add('$payer → $receiver ： ¥${payment.round()}');
    }
  }

  void _showMemoInputDialog(int index) {
    TextEditingController memoController =
        TextEditingController(text: memoEntries[index]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${participants[index]}のメモ'),
          content: TextField(
            onChanged: (value) {
              memoEntries[index] = value; // 直接更新
            },
            controller: memoController,
            decoration: const InputDecoration(hintText: "メモを入力してください"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {}); // アイコンの色を更新するための再描画
                Navigator.of(context).pop();
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  Future<void> _addMember(String newName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // ドキュメント参照
    final docRef =
        firestore.collection(widget.collectionName).doc(widget.memoId);

    // トランザクションで更新
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        // 現在のparticipantsを取得
        List<dynamic> participants = snapshot.data()?['participants'] ?? [];
        Map<String, dynamic> amounts = snapshot.data()?['amounts'] ?? [];

        if (!participants.contains(newName)) {
          participants.add(newName);
          amounts[newName] = [];
          transaction.update(
              docRef, {'participants': participants, "amounts": amounts});
          setState(() {});
        }
      } else {
        // ドキュメントが存在しない場合、新規作成
        transaction.set(docRef, {
          'participants': [newName],
          'amounts': []
        });
      }
    });
    // 通知
    _fetchMemoData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$newName を追加しました！")),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 175, 202, 215),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Container(
            height: 200, // ダイアログの高さを制限
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直方向に中央
              crossAxisAlignment: CrossAxisAlignment.center, // 水平方向に中央
              children: [
                const Text(
                  "メンバーを追加",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 200,
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
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "名前を入力してください",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      String newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        // メンバー追加処理
                        _addMember(newName);
                        Navigator.of(context).pop(); // シートを閉じる
                      }
                    },
                    child: const Text(
                      "決定",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: const Color.fromARGB(255, 175, 202, 215),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Container(
            height: 200, // ダイアログの高さを制限
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 垂直方向に中央
              crossAxisAlignment: CrossAxisAlignment.center, // 水平方向に中央
              children: [
                const Text(
                  "メンバーを削除",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 200,
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
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "削除する名前を入力してください",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      String removeName = nameController.text.trim();
                      if (removeName.isNotEmpty) {
                        // メンバー削除処理
                        await _removeMember(removeName);
                        Navigator.of(context).pop(); // シートを閉じる
                      }
                    },
                    child: const Text("決定"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeMember(String removeName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final docRef =
          firestore.collection(widget.collectionName).doc(widget.memoId);

      // ドキュメントを取得
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['amounts'] != null) {
          Map<String, dynamic> amounts =
              Map<String, dynamic>.from(data['amounts']);
          List<dynamic> participants = data['participants'] ?? [];
          if (amounts.containsKey(removeName)) {
            amounts.remove(removeName);
            participants.remove(removeName);
            await docRef
                .update({'amounts': amounts, "participants": participants});
            _fetchMemoData();
          } else {
            print("名前が見つかりません");
          }
        }
      }
    } catch (e) {
      print("削除中にエラーが発生しました: $e");
    }
  }

  Widget _buildResponsiveButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    bool isWideScreen, {
    TextStyle? textStyle,
  }) {
    return SizedBox(
      width: isWideScreen ? 300 : MediaQuery.of(context).size.width * 0.6,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF75A9D6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: textStyle ?? const TextStyle(fontFamily: "Roboto"),
        ),
      ),
    );
  }

  Future<void> _addCurrency() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docRef =
        firestore.collection(widget.collectionName).doc(widget.memoId);
    await docRef.update({"currency": currencies});
  }

  void _showCurrencySelectionDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "追加する通貨を選択",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: originCurrencies.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(originCurrencies[index]),
                      onTap: () {
                        setState(() {
                          if (!currencies.contains(originCurrencies[index])) {
                            currencies.add(originCurrencies[index]);
                          }
                        });
                        _addCurrency();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCenteredButtons(BuildContext context, bool isWideScreen) {
    return Center(
      child: Column(
        children: [
          _buildResponsiveButton(context, '保存', saveData, isWideScreen),
          const SizedBox(height: 20),
          _buildResponsiveButton(
              context, '履歴を見る', _showHistoryDialog, isWideScreen),
          const SizedBox(height: 20),
          _buildResponsiveButton(
            context,
            '支払提案',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PaymentSuggestionPage(
                        collectionName: widget.collectionName,
                        memoId: widget.memoId)),
              );
            },
            isWideScreen,
          ),
          const SizedBox(height: 20),
          _buildResponsiveButton(
              context, '最新情報を取得', _fetchMemoData, isWideScreen),
          const SizedBox(height: 20),
          _buildResponsiveButton(
            context,
            '清算する',
            _settlePayments,
            isWideScreen,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        backgroundColor: const Color(0xFF75A9D6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _navigateToExplain(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          "メンバーを追加",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 146, 193, 148)),
                        onPressed: () => _showAddMemberDialog(context),
                      ),
                      SizedBox(width: 10),
                      //ElevatedButton.icon(
                      //  icon: Icon(Icons.remove, color: Colors.white),
                      //  label: Text(
                      //    "メンバーを削除",
                      //    style: TextStyle(color: Colors.white),
                      //  ),
                      //  style: ElevatedButton.styleFrom(
                      //      backgroundColor:
                      //          const Color.fromARGB(255, 241, 131, 123)),
                      //  onPressed: () => _showRemoveMemberDialog(context),
                      //),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _showHistoryDialog,
                      icon: Icon(Icons.history, size: 16),
                      label: Text(
                        "履歴",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentSuggestionPage(
                              collectionName: widget.collectionName,
                              memoId: widget.memoId,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.payment, size: 16),
                      label: Text(
                        "分析",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _fetchMemoData,
                      icon: Icon(Icons.refresh, size: 16),
                      label: Text(
                        "最新情報",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _settlePayments,
                      icon: Icon(Icons.attach_money, size: 16),
                      label: Text(
                        "清算",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder(
                  future: AdSize.getAnchoredAdaptiveBannerAdSize(
                      Orientation.portrait,
                      MediaQuery.of(context).size.width.truncate()),
                  builder: (BuildContext context,
                      AsyncSnapshot<AnchoredAdaptiveBannerAdSize?> snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        width: double.infinity,
                        child: _adMob.getAdBanner(),
                      );
                    } else {
                      return Container(
                        height: _adMob.getAdBannerHeight(),
                        color: Colors.white,
                      );
                    }
                  }),
              const SizedBox(
                height: 16,
              ),
              if (participants.isEmpty)
                const Center(
                  child: Text(
                    "参加者がいません",
                    style: TextStyle(color: Colors.red, fontFamily: "Roboto"),
                  ),
                )
              else
                Column(
                  children: List.generate(participants.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              participants[index],
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: "Roboto"),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                              width: 100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onTap: () {
                                  FocusScope.of(context).requestFocus();
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: DropdownButton<String>(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                              dropdownColor: Colors.blue.shade100,
                              value: selectedCurrencies[index],
                              items: [
                                ...currencies.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }),
                                const DropdownMenuItem<String>(
                                  value: "ADD_CURRENCY",
                                  child: Row(
                                    children: [
                                      Text("追加"),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue == "ADD_CURRENCY") {
                                  _showCurrencySelectionDialog();
                                } else {
                                  setState(() {
                                    selectedCurrencies[index] =
                                        newValue ?? "JPY";
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.note,
                              color: memoEntries[index].isNotEmpty
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _showMemoInputDialog(index);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: ElevatedButton(
                          onPressed: saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF75A9D6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '支払いを保存',
                            style: TextStyle(
                                fontSize: 18,
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFE0ECF8),
    );
  }
}
