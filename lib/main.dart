// ignore_for_file: use_build_context_synchronously

import 'package:chat/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'my_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp前に何かを実行したいとき
  await Firebase.initializeApp( // Firebase初期化処理
    options: DefaultFirebaseOptions.android,
  );
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Future<void> signInWithGoogle() async {
    // GoogleSignInをして得られた情報をFirebaseと関連づける
    final googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();

    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoogleSignIn'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('GoogleSignIn'),
          onPressed: () async {
            await signInWithGoogle();
            // ログインが成功すると FirebaseAuth.instance.currentUserにログイン中のユーザーの情報が入る
            // ignore: avoid_print
            print(FirebaseAuth.instance.currentUser?.displayName);

            // ログインに成功したらChatPageに遷移
            // 前のページに戻らせないようにするにはpushAndRemoveUntilを使う
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) {
                  return const ChatPage();
                }),
                (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}

final postsReference = FirebaseFirestore.instance.collection('posts').withConverter<Post>( // <>に変換したい型名を入れる
  fromFirestore: ((snapshot, _) { // 第二引数は使わない場合は「_」と書くことでわかりやすく
    return Post.fromFirestore(snapshot);
  }),
  toFirestore: ((value, _) {
    return value.toMap();
  }),
);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        // actionsプロパティにWidgetを与えると右端に表示される
        actions: [
          // tap可能にするためにInkWellを使う
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const MyPage();
                  },
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                FirebaseAuth.instance.currentUser!.photoURL!,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded (
            child: StreamBuilder<QuerySnapshot<Post>>(
              // streamプロパティにsnapshots()を与えると、コレクションの中のドキュメントをリアルタイムで監視できる
              stream: postsReference.orderBy('createdAt').snapshots(),
              // snapshotにstream で流れてきたデータが入っている
              builder: (context, snapshot) {
                // docsにはCollectionに保存されたすべてのドキュメントが入る
                // 取得までには時間がかかるのではじめはnullが入っている
                // nullの場合は空配列が代入されるようにしている
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // withConverterを使ったことにより得られる恩恵
                    // 何もしなければこのデータ型はMapになる
                    final post = docs[index].data();
                    return Text(post.text);
                  },
                );
              },
            ),
          ),
          TextFormField(
            onFieldSubmitted: (text) {
              // ログイン中のユーザーデータを格納
              final user = FirebaseAuth.instance.currentUser!;
        
              final posterId = user.uid; // ログイン中のユーザーのID
              final posterName = user.displayName!; // Googleアカウントの名前
              final posterImageUrl = user.photoURL!; // Googleアカウントのアイコンデータ
        
              // 先ほど作ったpostsReferenceからランダムなIDのドキュメントリファレンスを作成
              // docの引数を空にするとランダムなIDが採番される
              final newDocumentReference = postsReference.doc();
        
              final newPost = Post(
                text: text,
                createdAt: Timestamp.now(),
                posterName: posterName,
                posterImageUrl: posterImageUrl,
                posterId: posterId,
                reference: newDocumentReference,
              );
        
              // 先ほど作ったnewDocumentReferenceのset関数を実行するとそのドキュメントにデータが保存される
              // 通常はMapしか受け付けないが、withConverterを使用したことにより Postインスタンスを受け取れるようになる
              newDocumentReference.set(newPost);
            },
          ),
        ],
      ),
    );
  }
}