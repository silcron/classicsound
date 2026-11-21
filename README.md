# Chapter 6: Classic Sound

**모바일프로그래밍 수업 · Flutter와 Firebase를 활용한 클래식 음악 앱**

Chapter 5의 부동산 앱에 이어 진행한 클래식 음악 앱 실습입니다. 수업에서 제공된 소스를 바탕으로 음원 파일을 Firebase Storage에 올리고, 파일에 대한 정보를 Cloud Firestore에 저장하는 흐름을 구성했습니다. 음악 목록 조회, 검색, 다운로드와 재생 화면 코드도 함께 정리했습니다.

개발일지는 **2026년 11월 18일에 진행한 작업**을 기준으로 작성했습니다. GitHub 공개 등록일은 2026년 11월 21일입니다.

- [모바일프로그래밍 수업 프로젝트 목록](https://github.com/silcron/mobile-programming)
- [Chapter 4: Personality Test](https://github.com/silcron/personalitytest)
- [Chapter 5: My 부동산](https://github.com/silcron/mybudongsan)

## 주요 구현 내용

| 구성 | 코드에서 확인할 내용 |
|---|---|
| 관리자 업로드 화면 | 작곡가, 태그, 카테고리를 입력하고 음원 및 선택한 이미지 파일을 업로드 |
| Firebase Storage | 파일 바이트 업로드 후 다운로드 URL을 받아 음악 정보에 연결 |
| Cloud Firestore | `music` 데이터베이스의 `files` 컬렉션에 파일명, 작곡가, 태그, 분류, 크기, 형식과 URL 저장 |
| 업로드 상태 처리 | 음원 업로드 → 이미지 업로드 → 음악 정보 저장 단계를 표시하고 중복 업로드 방지 |
| 저장 결과 안내 | Storage와 Firestore 저장이 모두 끝난 뒤 완료 표시, 실패 시 진행 단계와 오류 코드 안내 |
| 음악 목록·검색 | Firestore 문서를 음악 모델로 변환하고 검색 대화상자에서 반환한 쿼리로 목록 조회 |
| 다운로드·재생 | Dio를 이용한 파일 다운로드, SQLite 음악 정보 관리, audioplayers 재생 화면 소스 포함 |
| 사용자 관련 화면 | Firebase Authentication 로그인·회원가입, 사용자 정보와 태그, 설정 화면 소스 포함 |

현재 `main.dart`의 시작 화면은 **관리자 업로드 페이지 `UploadPage`**입니다. 목록·로그인·재생 관련 화면은 별도로 포함된 실습 코드이며, 앱 시작 시 모두 차례로 열리는 구조는 아닙니다.

## 관리자 페이지의 저장 흐름

```text
작곡가·태그·카테고리 입력
  → 음원 선택 / 이미지 선택(선택 사항)
  → Storage에 음원·이미지 저장
  → 다운로드 URL 가져오기
  → Music.toMap()으로 음악 정보 구성
  → Firestore music 데이터베이스의 files 컬렉션에 저장
  → 두 저장 작업이 끝나면 완료 안내
```

Storage는 실제 파일을 보관하고, Firestore는 파일을 조회하고 화면에 표시할 때 사용할 정보를 보관합니다. 따라서 Storage 업로드 성공과 Firestore 저장 성공을 각각 확인하도록 처리했습니다. 두 서비스에 걸친 원자적 트랜잭션은 아니므로 Firestore 저장이 실패하면 Storage 파일이 남을 수 있습니다.

## 개발 타임라인

| 날짜 | 작업 내용 |
|---|---|
| 2026.11.18 | **프로젝트 구조 확인과 실행 경로 정리.** Firebase 초기화 이후 `runApp()`이 실행되도록 앱 시작 코드를 정리하고, 관리자 페이지를 시작 화면으로 연결했습니다. 웹 관리자 화면 구동에 필요하지 않은 SQLite 초기화 대기를 시작 경로에서 분리했습니다. |
| 2026.11.18 | **파일 업로드 흐름 보완.** FilePicker에서 파일 바이트를 읽어 Storage에 전달하도록 구성했습니다. 파일 선택 여부를 확인하고, 업로드 시작부터 완료까지 상태를 관리해 같은 작업이 반복 실행되지 않도록 했습니다. |
| 2026.11.18 | **Firestore 저장 실패 원인 수정.** 실제 데이터베이스 ID가 `music`인데 코드에서 기본 데이터베이스 `(default)`를 사용하던 차이를 확인했습니다. `FirebaseFirestore.instanceFor()`를 사용하는 공통 연결을 만들고 업로드·목록·검색·상세·사용자 정보 저장 코드에 적용했습니다. |
| 2026.11.18 | **파일과 정보의 연결 정리.** Storage에서 받은 다운로드 URL을 `Music` 모델에 담고, `toMap()`으로 변환해 `files` 컬렉션에 저장했습니다. 음원 업로드 성공만으로 완료 처리하지 않고 Firestore 저장까지 기다리도록 했습니다. |
| 2026.11.18 | **진행 상태와 오류 안내 추가.** 음원, 이미지, 음악 정보 저장 단계를 구분하고, 실패한 단계와 Firebase 오류 코드를 화면에 표시하도록 했습니다. 파일 선택 후 화면이 바뀌는 경우를 고려해 `mounted` 확인과 입력 컨트롤러 해제도 적용했습니다. |
| 2026.11.18 | **Chrome 실행 환경 점검.** Chrome 디버그 연결 실패를 앱 코드 오류와 구분해 확인하고, Android Studio의 관리자 권한 실행 여부를 점검했습니다. 일반 실행 환경과 관리자 업로드 화면을 확인하고, 필요한 경우 사용할 웹 서버 실행 보조 파일을 정리했습니다. |
| 2026.11.21 | **GitHub 공개본 정리.** 위 작업 내역을 개발일지로 정리하고, 실제 API 키는 예제 값으로 바꿨습니다. 빌드 결과·캐시·개인 환경 설정을 제외한 소스를 별도 공개 저장소에 등록하고 수업 프로젝트 목록에 연결했습니다. |

## 코드 구조

```text
lib/
  main.dart                         Firebase 초기화, UploadPage 진입
  firebase_options.dart             플랫폼별 Firebase 설정 예제
  admin/upload_page.dart            파일 선택, Storage 업로드, Firestore 저장
  data/firestore_database.dart      music 데이터베이스 공통 연결
  data/music.dart                   Music 모델과 Map 변환
  data/local_database.dart          SQLite 음악 정보 관리
  view/intro/intro_page.dart        연결·로그인 확인 화면
  view/auth/auth_page.dart          로그인·회원가입, 사용자 정보 저장
  view/main/main_page.dart          음악 목록 조회
  view/main/sound/                  검색, 다운로드, 상세 및 재생 화면
  view/user/                       사용자와 태그 관련 화면
  view/setting/                    설정과 라이선스 화면
```

## Firestore 데이터 구조

현재 공통 연결의 데이터베이스 ID는 **`music`**입니다. Firebase 콘솔에서도 이 데이터베이스를 선택한 뒤 `files` 컬렉션을 확인합니다.

| 필드 | 내용 |
|---|---|
| `name` | 업로드한 파일 이름 |
| `composer` | 작곡가 |
| `tag` | 입력한 태그 문자열 |
| `category` | 선택한 카테고리 |
| `size` | 파일 크기(바이트) |
| `type` | 파일 형식 |
| `downloadUrl` | 음원 다운로드 URL |
| `imageDownloadUrl` | 이미지 다운로드 URL, 이미지가 없으면 빈 문자열 |

## 실행 준비

공개본의 실제 Firebase API 키는 `YOUR_FIREBASE_API_KEY`로 대체했습니다. 로컬에서 사용 중인 원본 설정은 변경하지 않았으며, 공개본을 실행할 때는 본인이 관리하는 Firebase 프로젝트 설정을 준비해야 합니다.

1. Flutter SDK와 실행할 플랫폼의 개발 환경을 준비합니다. Dart SDK 조건은 `pubspec.yaml`의 `^3.6.1`입니다.
2. 프로젝트 폴더에서 의존성을 설치합니다.

   ```sh
   flutter pub get
   ```

3. Firebase CLI와 FlutterFire CLI를 준비하고 본인의 프로젝트로 설정을 생성합니다.

   ```sh
   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android,ios,web
   ```

4. Firebase Storage와 Cloud Firestore를 준비합니다. 현재 코드를 그대로 사용할 경우 Firestore에 ID가 `music`인 데이터베이스가 필요합니다. 다른 ID를 사용한다면 `lib/data/firestore_database.dart`의 `databaseId`를 맞춥니다. 로그인 화면을 사용할 경우 Authentication의 이메일·비밀번호 로그인 설정도 필요합니다.
5. Android Studio에서 프로젝트를 열고, 일반 권한으로 Chrome을 선택해 관리자 페이지를 실행합니다.

   ```sh
   flutter run -d chrome
   ```

6. 작곡가·태그·카테고리와 파일을 선택해 업로드합니다. Storage 파일과 Firestore의 `music → files` 문서가 모두 생성되는지 확인합니다.

Windows용 `run_admin.bat`·`run_admin.ps1`은 Chrome 자동 디버그 연결이 어려울 때 사용하는 선택적인 웹 서버 실행 보조 파일입니다. 보조 파일의 Flutter 경로는 `C:\src\flutter\bin\flutter.bat` 기준입니다. 일반적인 수업 작업은 Android Studio에서 진행합니다.

## 확인 범위

- 관리자 페이지 구동과 업로드 관련 수정 사항은 11월 18일 작업 내역을 기준으로 정리했습니다.
- 공개 정리 시 `main.dart`, `upload_page.dart`, `firestore_database.dart`의 정적 검사를 수행했습니다.
- 사용자 목록·다운로드·재생 기능은 소스에서 구조를 확인했으며, 이번 공개 작업에서 모든 화면의 기기별 동작을 새로 검증한 것은 아닙니다. SQLite와 로컬 파일 재생을 사용하는 사용자 화면은 Chrome 관리자 페이지와 실행 조건이 다릅니다.
- Storage와 Firestore 접근 규칙은 사용하는 프로젝트의 인증·권한 설계에 맞춰 별도로 구성해야 합니다. 로그인 정보의 로컬 저장 방식 등은 수업 실습 수준의 코드이므로 후속 개선 대상으로 남아 있습니다.
