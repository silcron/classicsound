import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Firebase 콘솔에 생성된 데이터베이스 ID를 사용합니다.
FirebaseFirestore get musicFirestore => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'music',
    );
