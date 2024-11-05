import 'package:cloud_firestore/cloud_firestore.dart';

class Memo {
  final String id; // IDを追加
  final String title;
  final DateTime date;
  final List<String> participants;

  Memo({required this.id, required this.title, required this.date, required this.participants});
}