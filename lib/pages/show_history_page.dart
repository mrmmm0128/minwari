import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:study_flutter_firebase/components/ad_mob.dart';
import 'package:study_flutter_firebase/components/ad_native.dart';
import 'package:study_flutter_firebase/pages/privacypolicy.dart';
import 'package:study_flutter_firebase/pages/servicerule.dart';
import 'package:study_flutter_firebase/pages/our_information.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentHistoryPage extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> amounts;
  final String travelId;
  final String collectionName;
  final List<String> participants;
  final List<String> currencies;

  const PaymentHistoryPage(
      {Key? key,
      required this.amounts,
      required this.travelId,
      required this.collectionName,
      required this.participants,
      required this.currencies})
      : super(key: key);

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late Map<String, List<Map<String, dynamic>>> amounts;
  final AdMob _adMob = AdMob();
  late List<String> participants;
  List<String> originCurrencies = [
    //
    'USD', 'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN',
    'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL', 'BSD',
    'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 'COP', 'CRC',
    'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB', 'EUR',
    'FJD', 'FKP', 'FOK', 'GBP', 'GEL', 'GGP', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ',
    'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', 'IDR', 'ILS', 'IMP', 'INR', 'IQD',
    'IRR', 'ISK', 'JEP', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KID', 'KMF',
    'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD',
    'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRU', 'MUR', 'MVR', 'MWK', 'MXN',
    'MYR', 'MZN', 'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN',
    'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR',
    'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLE', 'SLL', 'SOS', 'SRD', 'SSP',
    'STN', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TVD',
    'TWD', 'TZS', 'UAH', 'UGX', 'UYU', 'UZS', 'VES', 'VND', 'VUV', 'WST', 'XAF',
    'XCD', 'XDR', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWL'
  ];

  @override
  void initState() {
    super.initState();
    amounts = Map.from(widget.amounts); // amountsの初期化
    participants = widget.participants;
    _adMob.load();
  }

  @override
  void dispose() {
    _adMob.dispose();
  }

  /// 一人当たりの支払いを計算するメソッド
  double calculatePerPersonPayment() {
    double totalAmount = 0;

    amounts.forEach((_, payments) {
      for (var payment in payments) {
        totalAmount += payment['amount'] ?? 0.0;
      }
    });

    return totalAmount;
  }

  Future<void> _addCurrency() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docRef =
        firestore.collection(widget.collectionName).doc(widget.travelId);
    await docRef.update({"currency": widget.currencies});
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
                          if (!widget.currencies
                              .contains(originCurrencies[index])) {
                            widget.currencies.add(originCurrencies[index]);
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

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
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

  Future<void> editPayment(String participant, int index) async {
    var payment = amounts[participant]?[index];
    if (payment == null) return;

    final TextEditingController amountController = TextEditingController(
      text: (payment['originalAmount'] != null)
          ? payment['originalAmount'].toString()
          : payment['amount'].toString(),
    );
    final TextEditingController memoController = TextEditingController(
      text: payment['memo'] ?? '',
    );
    String selectedCurrency = payment['originalCurrency'] ?? 'JPY'; // デフォルトの通貨

    // 既存の対象者を取得
    List<int> selectedMembers = List<int>.from(payment["selectedMember"] ?? []);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButton<String>(
                  borderRadius: BorderRadius.circular(6),
                  dropdownColor: Colors.blue.shade100,
                  value: selectedCurrency,
                  items: [
                    ...widget.currencies.map((String currency) {
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
                        selectedCurrency = newValue ?? "JPY";
                      });
                    }
                  },
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "金額"),
                ),
                TextField(
                  controller: memoController,
                  decoration: const InputDecoration(labelText: "メモ"),
                ),
                const SizedBox(height: 10),
                const Text("対象者を選択"),
                SizedBox(
                  height: 170, // 適切な高さを指定
                  child: SingleChildScrollView(
                    child: Column(
                      children: participants.map((participant) {
                        int index = participants.indexOf(participant);
                        return CheckboxListTile(
                          title: Text(participant),
                          value: selectedMembers.contains(index),
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedMembers.add(index);
                              } else {
                                selectedMembers.remove(index);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                )
              ]),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text("キャンセル"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'originalAmount': double.tryParse(amountController.text),
                      'memo': memoController.text,
                      'originalCurrency': selectedCurrency,
                      'selectedMember': selectedMembers,
                    });
                  },
                  child: const Text("保存"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result['originalAmount'] != null) {
      try {
        // 通貨変換を待機
        double convertedAmount = await _convertToJPY(
          result['originalAmount'],
          result["originalCurrency"],
        );

        Timestamp now = Timestamp.now();
        double mustPay = convertedAmount / (result['selectedMember'].length);
        int i = participants.indexOf(participant);
        List<double> addAmIn = List.generate(participants.length, (_) => 0.0);
        for (int num in result['selectedMember']) {
          if (num != i) {
            addAmIn[num] = mustPay;
          }
        }

        var updatedPayment = {
          'originalAmount': result['originalAmount'],
          'memo': result['memo'],
          'originalCurrency': result['originalCurrency'],
          'amount': convertedAmount,
          'date': now,
          'selectedMember': result['selectedMember'],
          "individual": addAmIn
        };

        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.travelId)
            .update({
          'amounts.$participant': FieldValue.arrayRemove([payment]),
        });
        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.travelId)
            .update({
          'amounts.$participant': FieldValue.arrayUnion([updatedPayment]),
        });

        setState(() {
          amounts[participant]?[index] = updatedPayment;
        });
      } catch (e) {
        print('編集に失敗しました: $e');
      }
    }
  }

  Future<void> deletePayment(String participant, int index) async {
    var payment = amounts[participant]?[index];
    if (payment != null) {
      try {
        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.travelId)
            .update({
          'amounts.$participant': FieldValue.arrayRemove([payment]),
        });

        setState(() {
          amounts[participant]?.removeAt(index);
          if (amounts[participant]?.isEmpty ?? false) {
            amounts.remove(participant);
          }
        });
      } catch (e) {
        print('削除に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double perPersonPayment = calculatePerPersonPayment();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("支払い履歴", style: TextStyle(fontFamily: "Roboto")),
        backgroundColor: const Color(0xFF75A9D6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: amounts.isEmpty
          ? const Center(
              child:
                  Text("支払い履歴がありません", style: TextStyle(fontFamily: "Roboto")),
            )
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 一人当たりの金額表示
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "合計金額 : ¥$perPersonPayment",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Roboto",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder(
                        future: AdSize.getAnchoredAdaptiveBannerAdSize(
                            Orientation.portrait,
                            MediaQuery.of(context).size.width.truncate()),
                        builder: (BuildContext context,
                            AsyncSnapshot<AnchoredAdaptiveBannerAdSize?>
                                snapshot) {
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
                    ...amounts.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                                fontSize: 18, fontFamily: "Roboto"),
                          ),
                          ...entry.value.map((payment) {
                            String memoText = payment['memo'] ?? 'メモなし';
                            List<int> selectedMember =
                                (payment["selectedMember"] as List<dynamic>)
                                    .map<int>((item) => item as int)
                                    .toList();
                            List<String> IndMem = selectedMember
                                .map((index) => widget.participants[index])
                                .toList();
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                contentPadding: screenWidth < 600
                                    ? const EdgeInsets.all(8.0)
                                    : const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                title: Text(
                                    (payment['originalCurrency'] != null &&
                                            payment['originalAmount'] != null &&
                                            payment['originalCurrency']
                                                is! List)
                                        ? '${payment['originalCurrency']} ${payment['originalAmount']}'
                                        : 'JPY ${payment['amount']}',
                                    style: TextStyle(
                                      fontSize: screenWidth < 600 ? 14 : 16,
                                      fontFamily: "Roboto",
                                    )),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memoText,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: "Roboto",
                                        fontSize: screenWidth < 600 ? 12 : 14,
                                      ),
                                    ),
                                    //const SizedBox(height: 4), // 間隔を追加
                                    IndMem.length == participants.length
                                        ? Text(
                                            '対象者: 全員',
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize:
                                                  screenWidth < 600 ? 12 : 14,
                                            ),
                                          )
                                        : Text(
                                            '対象者: ${IndMem.join(", ")}',
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize:
                                                  screenWidth < 600 ? 12 : 14,
                                            ),
                                          )
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        editPayment(entry.key,
                                            entry.value.indexOf(payment));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        deletePayment(entry.key,
                                            entry.value.indexOf(payment));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () => _navigateToPrivacyPolicy(context),
                          child: const Text(
                            'プライバシーポリシー',
                            style:
                                TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => servicerule(),
                              ),
                            );
                          },
                          child: const Text(
                            '利用規約',
                            style:
                                TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsPage(),
                              ),
                            );
                          },
                          child: const Text(
                            '運営元情報',
                            style:
                                TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFFE0ECF8),
    );
  }
}
