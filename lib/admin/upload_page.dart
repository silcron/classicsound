import 'package:classicsound/data/music.dart';
import 'package:classicsound/data/firestore_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const List<String> list = <String>['piano', 'voice', 'violin', 'test'];

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UploadPageState();
  }
}

class _UploadPageState extends State<UploadPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = musicFirestore;

  // FilePickerResult 인스턴스 생성
  FilePickerResult? _pickedFile;
  FilePickerResult? _imagePickedFile;

  // 로컬에 있는 파일의 이름
  String? _fileName;
  String? _imageFileName;

  // 업로드된 파일의 다운로드 URL
  String? _downloadUrl;

  // 업로드 중인지 여부
  bool _isUploading = false;
  String _uploadStage = '';

  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  String _dropdownValue = list.first;

  // 로컬에서 파일을 선택하는 메서드
  Future<void> _pickFile(int type) async {
    var picked = await FilePicker.platform.pickFiles(withData: true);
    // // 선택된 파일이 있다면
    if (picked != null && mounted) {
      // 파일의 경로와 이름을 저장
      if (type == 1) {
        setState(() {
          _pickedFile = picked;
          _fileName = _pickedFile!.files.first.name;
        });
      } else {
        setState(() {
          _imagePickedFile = picked;
          _imageFileName = _imagePickedFile!.files.first.name;
        });
      }
    }
  }

  // Firebase Storage에 파일을 업로드하는 메서드
  Future<void> _uploadFile() async {
    if (_isUploading) return;
    final audio = _pickedFile?.files.single;
    final image = _imagePickedFile?.files.single;
    if (audio == null ||
        audio.bytes == null ||
        (image != null && image.bytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('음원 파일을 선택해 주세요. 파일을 읽지 못했다면 다시 선택해 주세요.')),
      );
      return;
    }

    final composer = _composerController.text;
    final tag = _tagController.text;
    final category = _dropdownValue;
    setState(() {
      _isUploading = true;
      _downloadUrl = null;
      _uploadStage = '음원 업로드';
    });

    try {
      final audioTask =
          await _storage.ref('files/${audio.name}').putData(audio.bytes!);
      final downloadUrl = await audioTask.ref.getDownloadURL();
      String imageDownloadUrl = '';
      if (image != null) {
        if (mounted) setState(() => _uploadStage = '이미지 업로드');
        final imageTask =
            await _storage.ref('files/${image.name}').putData(image.bytes!);
        imageDownloadUrl = await imageTask.ref.getDownloadURL();
      }

      if (mounted) setState(() => _uploadStage = '음악 정보 저장');
      final music = Music(audio.name, composer, tag, category, audio.size,
          'audio/${audio.extension}', downloadUrl, imageDownloadUrl);
      await _firestore.collection('files').add(music.toMap());

      if (!mounted) return;
      setState(() {
        _downloadUrl = downloadUrl;
        _uploadStage = '파일과 음악 정보 저장 완료';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage 파일과 Firestore 음악 정보를 모두 저장했습니다.')),
      );
    } catch (error) {
      final code = error is FirebaseException ? error.code : 'unexpected-error';
      final message = '$_uploadStage 실패 ($code)';
      debugPrint(message);
      if (mounted) {
        setState(() => _uploadStage = message);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Page'), // const 추가
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                decoration: const InputDecoration(hintText: '작곡가'), // const 추가
                controller: _composerController,
              ),
            ),
            const SizedBox(height: 16), // const 추가
            SizedBox(
              width: 250,
              child: TextField(
                decoration:
                    const InputDecoration(hintText: 'TAG (콤마로 구분)'), // const 추가
                controller: _tagController,
              ),
            ),
            const SizedBox(height: 16), // const 추가
            DropdownButton<String>(
              value: _dropdownValue, // _dropdownValue 사용
              icon: const Icon(Icons.music_note), // const 추가
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? value) {
                if (value != null) {
                  // null check 추가
                  setState(() {
                    _dropdownValue = value; // _dropdownValue 사용
                  });
                }
              },
              items: list.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16), // const 추가
            ElevatedButton(
              onPressed: _isUploading ? null : () => _pickFile(1),
              child: Text('Pick a file $_fileName'),
            ),
            const SizedBox(height: 16), // const 추가
            ElevatedButton(
              onPressed: _isUploading ? null : () => _pickFile(2),
              child: Text('이미지 파일 $_imageFileName'),
            ),
            const SizedBox(height: 16), // const 추가
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: const Text('Upload to Firebase Storage'), // const 추가
            ),
            const SizedBox(height: 16), // const 추가
            _downloadUrl != null
                ? const Text('File uploaded successfully') // const 추가
                : const Text('No file to display'), // const 추가
            const SizedBox(height: 16), // const 추가
            _isUploading
                ? const CircularProgressIndicator(
                    strokeWidth: 10,
                  )
                : Text(
                    _uploadStage.isEmpty ? 'No file uploading' : _uploadStage),
          ],
        ),
      ),
    );
  }
}
