import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_flutter_firebase/components/ad_native.dart';
import 'package:study_flutter_firebase/pages/add_memo_page.dart';
import 'package:study_flutter_firebase/pages/top_page.dart';
import 'package:study_flutter_firebase/pages/privacypolicy.dart';
import 'package:study_flutter_firebase/pages/servicerule.dart';
import 'package:study_flutter_firebase/pages/our_information.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:study_flutter_firebase/components/ad_mob.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CollectionInputPage extends StatefulWidget {
  final String deviceId;

  // コンストラクタで deviceId を受け取るように修正
  const CollectionInputPage({super.key, required this.deviceId});

  @override
  _CollectionInputPageState createState() => _CollectionInputPageState();
}

class _CollectionInputPageState extends State<CollectionInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();
  final AdMob _adMob = AdMob();
  final AdNative _adNative = AdNative();

  @override
  void initState() {
    super.initState();
    _adMob.load();
    _adNative.load();
  }

  @override
  void dispose() {
    super.dispose();
    _adMob.dispose();
    _adNative.dispose();
  }

  // Firestoreに新しいグループがすでに存在するかを確認する非同期関数
  Future<bool> _checkIfGroupExists(String groupName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(groupName).get();
      return snapshot.docs.isNotEmpty; // ドキュメントがあれば、グループ名は既に存在
    } catch (e) {
      print("Error checking group: $e");
      return false;
    }
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // 既存グループに移動
  void _navigateToNextPage(String collectionName) async {
    if (collectionName.isNotEmpty) {
      // グループが存在するか確認
      bool groupExists = await _checkIfGroupExists(collectionName);

      if (groupExists) {
        saveGroup(widget.deviceId, collectionName);
        // グループが存在すればページ遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(collectionName: collectionName),
          ),
        );
      } else {
        // グループが存在しない場合、エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('指定されたグループは存在しません')),
        );
      }
    } else {
      // グループ名が空の場合、エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループ名を入力してください')),
      );
    }
  }

  String hashTimeWithSHA256(DateTime currentTime) {
    String timeString = currentTime.toString();
    var bytes = utf8.encode(timeString); // データをバイト列に変換
    var digest = sha256.convert(bytes); // SHA-256でハッシュ化
    return digest.toString(); // ハッシュを16進数文字列として返す
  }

  /// 新しいグループを作成
  void _createNewGroupAndNavigate(String groupName) async {
    if (groupName.isNotEmpty) {
      String currentTime = hashTimeWithSHA256(DateTime.now());

      // 新しいコレクションを作成し、指定ドキュメントを追加
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection("$groupName|$currentTime")
          .doc("korehahyoujishinaiyo")
          .set({"key": "$groupName|$currentTime"});

      // グループを保存して画面遷移
      saveGroup(widget.deviceId, "$groupName|$currentTime");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddMemoPage(collectionName: "$groupName|$currentTime"),
        ),
      );

      // 作成成功のメッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいグループが作成されました')),
      );
    } else {
      // 空のグループ名の場合のエラーメッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいグループ名を入力してください')),
      );
    }
  }

  Future<void> saveGroup(String deviceId, String groupName) async {
    final deviceRef =
        FirebaseFirestore.instance.collection('devices').doc(deviceId);

    final doc = await deviceRef.get();

    if (doc.exists) {
      // 既存のグループリストに追加
      final groups = List<String>.from(doc['groups'] ?? []);
      if (!groups.contains(groupName)) {
        groups.add(groupName);
        await deviceRef.update({'groups': groups});
      }
    } else {
      // 新規デバイスの場合
      await deviceRef.set({
        'groups': [groupName]
      });
    }
  }

  Future<List<String>> getGroups(String deviceId) async {
    final doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .get();
    if (doc.exists) {
      return List<String>.from(doc['groups'] ?? []);
    }
    return [];
  }

  Future<List<String>> getValidGroups(String deviceId) async {
    final firestore = FirebaseFirestore.instance;

    // グループ一覧を取得
    final allGroups = await getGroups(deviceId);

    List<String> validGroups = [];
    for (String group in allGroups) {
      final collectionSnapshot =
          await firestore.collection(group).limit(1).get();
      if (collectionSnapshot.docs.isNotEmpty) {
        validGroups.add(group);
      }
    }
    return validGroups;
  }

  String processGroupName(String groupName) {
    // "|"が含まれているか確認
    if (groupName.contains('|')) {
      // "|"の位置を取得して、その前を切り取る
      return groupName.split('|').first;
    }
    // "|"が含まれていなければそのまま返す
    return groupName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "グループ名入力",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF75A9D6), // AppBarの色
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        // スクロール可能にする
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'グループごとに管理しましょう',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 既存グループの検索フィールド
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: '作成者からIDを受け取ってください',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigateToNextPage(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75A9D6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '既存グループに移動',
                  style: TextStyle(fontFamily: "Roboto", fontSize: 16),
                ),
              ),
              const Divider(
                height: 40,
                color: Colors.blueGrey,
                thickness: 1.0,
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'イベントの出費管理をグループごとに行いましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              // 新しいグループ名の入力フィールド
              TextField(
                controller: _newGroupController,
                decoration: InputDecoration(
                  labelText: '例) 〇〇ゼミ、〇〇部、仲良しトリオ',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    _createNewGroupAndNavigate(_newGroupController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75A9D6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '新しいグループを作成',
                  style: TextStyle(fontFamily: "Roboto", fontSize: 16),
                ),
              ),
              const Divider(
                height: 40,
                color: Colors.blueGrey,
                thickness: 1.0,
              ),
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

              // グループリストを表示するFutureBuilder
              FutureBuilder<List<String>>(
                future: getValidGroups(widget.deviceId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('エラーが発生しました: ${snapshot.error}');
                  }
                  final groups = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '参加しているグループ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'リンクボタンでIDをグループメンバーに共有しましょう',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              _navigateToNextPage(groups[index]);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF75A9D6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                title: Text(
                                  processGroupName(groups[index]),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                leading: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                ),
                                trailing: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // 必須: 横幅をアイコンに合わせる
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.link,
                                          color: Colors.white),
                                      onPressed: () {
                                        // groups[index]をクリップボードにコピー
                                        Clipboard.setData(
                                            ClipboardData(text: groups[index]));
                                        // SnackBarで通知
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('IDがクリップボードにコピーされました'),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () async {
                                        // Firestoreからグループを削除
                                        await FirebaseFirestore.instance
                                            .collection('devices')
                                            .doc(widget.deviceId)
                                            .update({
                                          'groups': FieldValue.arrayRemove(
                                              [groups[index]]),
                                        });

                                        // UIからグループを削除
                                        setState(() {
                                          groups.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // 水平方向の中央揃え
                  children: [
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => _navigateToPrivacyPolicy(context),
                      child: const Text(
                        'プライバシーポリシー',
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
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
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
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
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFE0ECF8),
    );
  }
}
