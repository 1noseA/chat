import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  Post({
    required this.text,
    required this.createdAt,
    required this.posterName,
    required this.posterImageUrl,
    required this.posterId,
    required this.reference,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    // data() の中には Map 型のデータが入る
    final map = snapshot.data()!;
    // !はnullableな型をnon-nullableとして扱うという意味

    return Post(
      text: map['text'],
      createdAt: map['createdAt'],
      posterName: map['posterName'],
      posterImageUrl: map['posterImageUrl'],
      posterId: map['posterId'],
      reference: snapshot.reference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': createdAt,
      'posterName': posterName,
      'posterImageUrl': posterImageUrl,
      'posterId': posterId,
      // referenceはfieldに含めなくてよい
      // fieldに含めなくてもDocumentSnapshotにreferenceが存在するため
    };
  }

  /// 投稿文
  final String text;

  /// 投稿日時
  final Timestamp createdAt;

  /// 投稿者の名前
  final String posterName;

  /// 投稿者のアイコン画像URL
  final String posterImageUrl;

  /// 投稿者のユーザーID
  final String posterId;

  /// Firestoreのどこにデータが存在するかを表すpath情報
  final DocumentReference reference;
}