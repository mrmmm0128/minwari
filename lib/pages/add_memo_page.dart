import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_flutter_firebase/pages/top_page.dart';

class AddMemoPage extends StatefulWidget {
  const AddMemoPage({super.key, required this.collectionName});
  final String collectionName;

  @override
  State<AddMemoPage> createState() => _AddMemoPageState();
}

class _AddMemoPageState extends State<AddMemoPage> {
  TextEditingController titleController = TextEditingController();
  List<TextEditingController> participantControllers = [
    TextEditingController()
  ];

  List<String> selectedCurrencies = ["JPY"]; // 初期値を設定
  List<String> currencies = [
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

  List<String> currencies_explain = [
    'USD (米ドル)',
    'AED (UAEディルハム)',
    'AFN (アフガニスタン・アフガニ)',
    'ALL (アルバニア・レク)',
    'AMD (アルメニア・ドラム)',
    'ANG (オランダ領アンティル・ギルダー)',
    'AOA (アンゴラ・クワンザ)',
    'ARS (アルゼンチン・ペソ)',
    'AUD (オーストラリア・ドル)',
    'AWG (アルバ・フロリン)',
    'AZN (アゼルバイジャン・マナト)',
    'BAM (ボスニア・ヘルツェゴビナ・兌換マルク)',
    'BBD (バルバドス・ドル)',
    'BDT (バングラデシュ・タカ)',
    'BGN (ブルガリア・レフ)',
    'BHD (バーレーン・ディナール)',
    'BIF (ブルンジ・フラン)',
    'BMD (バミューダ・ドル)',
    'BND (ブルネイ・ドル)',
    'BOB (ボリビア・ボリビアーノ)',
    'BRL (ブラジル・レアル)',
    'BSD (バハマ・ドル)',
    'BTN (ブータン・ニュルタム)',
    'BWP (ボツワナ・プラ)',
    'BYN (ベラルーシ・ルーブル)',
    'BZD (ベリーズ・ドル)',
    'CAD (カナダ・ドル)',
    'CDF (コンゴ民主共和国・フラン)',
    'CHF (スイス・フラン)',
    'CLP (チリ・ペソ)',
    'CNY (中国・人民元)',
    'COP (コロンビア・ペソ)',
    'CRC (コスタリカ・コロン)',
    'CUP (キューバ・ペソ)',
    'CVE (カーボベルデ・エスクード)',
    'CZK (チェコ・コルナ)',
    'DJF (ジブチ・フラン)',
    'DKK (デンマーク・クローネ)',
    'DOP (ドミニカ共和国・ペソ)',
    'DZD (アルジェリア・ディナール)',
    'EGP (エジプト・ポンド)',
    'ERN (エリトリア・ナクファ)',
    'ETB (エチオピア・ブル)',
    'EUR (ユーロ)',
    'FJD (フィジー・ドル)',
    'FKP (フォークランド諸島・ポンド)',
    'FOK (フェロー諸島・クローネ)',
    'GBP (イギリス・ポンド)',
    'GEL (ジョージア・ラリ)',
    'GGP (ガーンジー・ポンド)',
    'GHS (ガーナ・セディ)',
    'GIP (ジブラルタル・ポンド)',
    'GMD (ガンビア・ダラシ)',
    'GNF (ギニア・フラン)',
    'GTQ (グアテマラ・ケツァル)',
    'GYD (ガイアナ・ドル)',
    'HKD (香港・ドル)',
    'HNL (ホンジュラス・レンピラ)',
    'HRK (クロアチア・クーナ)',
    'HTG (ハイチ・グールド)',
    'HUF (ハンガリー・フォリント)',
    'IDR (インドネシア・ルピア)',
    'ILS (イスラエル・新シェケル)',
    'IMP (マン島・ポンド)',
    'INR (インド・ルピー)',
    'IQD (イラク・ディナール)',
    'IRR (イラン・リアル)',
    'ISK (アイスランド・クローナ)',
    'JEP (ジャージー・ポンド)',
    'JMD (ジャマイカ・ドル)',
    'JOD (ヨルダン・ディナール)',
    'JPY (日本・円)',
    'KES (ケニア・シリング)',
    'KGS (キルギス・ソム)',
    'KHR (カンボジア・リエル)',
    'KID (キリバス・ドル)',
    'KMF (コモロ・フラン)',
    'KRW (韓国・ウォン)',
    'KWD (クウェート・ディナール)',
    'KYD (ケイマン諸島・ドル)',
    'KZT (カザフスタン・テンゲ)',
    'LAK (ラオス・キープ)',
    'LBP (レバノン・ポンド)',
    'LKR (スリランカ・ルピー)',
    'LRD (リベリア・ドル)',
    'LSL (レソト・ロティ)',
    'LYD (リビア・ディナール)',
    'MAD (モロッコ・ディルハム)',
    'MDL (モルドバ・レウ)',
    'MGA (マダガスカル・アリアリ)',
    'MKD (マケドニア・ディナール)',
    'MMK (ミャンマー・チャット)',
    'MNT (モンゴル・トゥグルグ)',
    'MOP (モーリシャス・ルピー)',
    'MRU (モーリタニア・ウギア)',
    'MUR (モーリシャス・ルピー)',
    'MVR (モルディブ・ルフィヤ)',
    'MWK (マラウイ・クワチャ)',
    'MXN (メキシコ・ペソ)',
    'MYR (マレーシア・リンギット)',
    'MZN (モザンビーク・メティカル)',
    'NAD (ナミビア・ドル)',
    'NGN (ナイジェリア・ナイラ)',
    'NIO (ニカラグア・コルドバ)',
    'NOK (ノルウェー・クローネ)',
    'NPR (ネパール・ルピー)',
    'NZD (ニュージーランド・ドル)',
    'OMR (オマーン・リアル)',
    'PAB (パナマ・バルボア)',
    'PEN (ペルー・ヌエボ・ソル)',
    'PGK (パプアニューギニア・キナ)',
    'PHP (フィリピン・ペソ)',
    'PKR (パキスタン・ルピー)',
    'PLN (ポーランド・ズロチ)',
    'PYG (パラグアイ・グアラニ)',
    'QAR (カタール・リアル)',
    'RON (ルーマニア・レウ)',
    'RSD (セルビア・ディナール)',
    'RUB (ロシア・ルーブル)',
    'RWF (ルワンダ・フラン)',
    'SAR (サウジアラビア・リヤル)',
    'SBD (ソロモン諸島・ドル)',
    'SCR (セーシェル・ルピー)',
    'SDG (スーダン・ポンド)',
    'SEK (スウェーデン・クローナ)',
    'SGD (シンガポール・ドル)',
    'SHP (セントヘレナ・ポンド)',
    'SLE (シエラレオネ・レオウ)',
    'SLL (シエラレオネ・リオン)',
    'SOS (ソマリア・シリング)',
    'SRD (スリナム・ドル)',
    'SSP (南スーダン・ポンド)',
    'STN (サントメ・プリンシペ・ドブラ)',
    'SYP (シリア・ポンド)',
    'SZL (スワジランド・リランゲニ)',
    'THB (タイ・バーツ)',
    'TJS (タジキスタン・ソモニ)',
    'TMT (トルクメニスタン・マナト)',
    'TND (チュニジア・ディナール)',
    'TOP (トンガ・パアンガ)',
    'TRY (トルコ・リラ)',
    'TTD (トリニダード・トバゴ・ドル)',
    'TVD (トバゴ・ドル)',
    'TWD (台湾・ドル)',
    'TZS (タンザニア・シリング)',
    'UAH (ウクライナ・フリヴニャ)',
    'UGX (ウガンダ・シリング)',
    'UYU (ウルグアイ・ペソ)',
    'UZS (ウズベキスタン・スム)',
    'VES (ベネズエラ・ボリバル)',
    'VND (ベトナム・ドン)',
    'VUV (バヌアツ・バツ)',
    'WST (サモア・タラ)',
    'XAF (中央アフリカ諸国・CFAフラン)',
    'XCD (東カリブ諸国・東カリブ・ドル)',
    'XDR (特別引き出し権)',
    'XOF (西アフリカ諸国・CFAフラン)',
    'XPF (フランス領太平洋諸島・CFAフラン)',
    'YER (イエメン・リアル)',
    'ZAR (南アフリカ・ランド)',
    'ZMW (ザンビア・クワチャ)',
    'ZWL (ジンバブエ・ジンバブエドル)'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLatestParticipants();
  }

  Future<void> _fetchLatestParticipants() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final participants = latestDoc.data()['participants'];

        if (participants != null && participants is List) {
          setState(() {
            participantControllers = participants
                .map((participant) => TextEditingController(text: participant))
                .toList();
          });
        }
      }
    } catch (e) {
      // エラー処理（必要ならログを追加）
      print('Error fetching participants: $e');
    }
  }

  void _addCurrencyField() {
    setState(() {
      selectedCurrencies.add("JPY");
    });
  }

  Future<void> createMemo() async {
    final memoCollection =
        FirebaseFirestore.instance.collection(widget.collectionName);
    List<String> participants = participantControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();

    // 各参加者に空の履歴リストを用意
    Map<String, List<double>> amounts = {
      for (var participant in participants) participant: []
    };

    await memoCollection.add({
      "title": titleController.text,
      "participants": participants,
      "amounts": amounts,
      "date": Timestamp.now(),
      "currency": selectedCurrencies
    });
  }

  void _addParticipantField() {
    setState(() {
      participantControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    // スクリーンサイズ取得
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "イベント追加",
          style: TextStyle(
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: const Color(0xFF75A9D6), // AppBarの色
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 画面幅が600px以上の場合はタブレットレイアウトを適用
          final isWide = constraints.maxWidth > 600;
          final padding = isWide ? 40.0 : 20.0;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "タイトル",
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: "イベント名を入力",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "参加者",
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  ...participantControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: "参加者の名前を入力",
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                participantControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addParticipantField,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "参加者を追加",
                        style: TextStyle(fontFamily: "Roboto"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "通貨を選択",
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...selectedCurrencies.asMap().entries.map((entry) {
                    int index = entry.key;
                    String selectedCurrency = entry.value;
                    return Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade100,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                              dropdownColor: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                              items: currencies.asMap().entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.value,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxWidth: 250), // 幅を制限
                                    child: SingleChildScrollView(
                                      scrollDirection:
                                          Axis.horizontal, // 横スクロール対応
                                      child: Text(
                                        currencies_explain[entry.key],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1, // 1行に制限
                                        softWrap: false, // 自動改行禁止
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCurrencies[index] = newValue ?? "JPY";
                                });
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedCurrencies.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addCurrencyField,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75A9D6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("通貨を追加",
                          style: TextStyle(fontFamily: "Roboto")),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: isWide ? 300 : screenSize.width * 0.8,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('タイトルを入力してください')),
                            );
                            return;
                          }
                          if (participantControllers
                              .every((controller) => controller.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('少なくとも1人の参加者を入力してください')),
                            );
                            return;
                          }
                          await createMemo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyHomePage(
                                  collectionName: widget.collectionName),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF75A9D6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 30),
                        ),
                        child: const Text(
                          "確定",
                          style: TextStyle(fontFamily: "Roboto"),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFE0ECF8), // 背景色
    );
  }
}
