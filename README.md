# Photo Widget

갤러리에서 고른 사진을 원하는 크기의 홈 화면 위젯으로 걸어두고 보는 앱. 현재 대상 플랫폼은 Android.

## 구조

| 영역 | 위치 | 역할 |
|---|---|---|
| Flutter 앱 | `lib/` | 사진 선택, 위젯에 걸 사진 관리, 미리보기 |
| Android 위젯 | `android/app/src/main/kotlin/...` | 홈 화면에 사진 표시 (네이티브) |
| 앱 ↔ 위젯 연결 | `home_widget` 패키지 | 공유 저장소에 사진 경로 저장 + 위젯 갱신 요청 |

```
lib/
  main.dart            진입점 (ProviderScope)
  app/                 MaterialApp, 테마
  data/photo/          사진 저장소(앱 폴더 복사본 + photos.json 인덱스), 갤러리 선택
  features/home/       저장한 사진 그리드 (추가 / 길게 눌러 삭제)
  features/photo_detail/  사진 크게 보기 + 위젯 크기별 미리보기
  features/photos/     사진 목록 상태(Riverpod) 공용 코드
```

## 여러 PC에서 빌드하기 (재설치 없이 덮어쓰기)

Android는 같은 `applicationId` 라도 **서명 키가 다르면** 기존 앱을 지워야 설치된다.
기본 debug 키는 PC마다 따로 생성되는 `~/.android/debug.keystore` 라서, PC를 바꿔 빌드하면 재설치가 필요해진다.

이 프로젝트는 다음처럼 막아둔다.

- **debug 빌드:** 저장소에 포함된 `android/app/debug.keystore` 로 서명한다. 어느 PC에서 빌드해도 서명이 같다.
- **release 빌드:** `android/key.properties` 가 있으면 그 키로 서명하고, 없으면 위 공용 debug 키로 서명한다.
  - `key.properties` 와 `.jks` 파일은 git에 올리지 않는다 (`android/key.properties.example` 참고).
- **`applicationId`(`com.mikyeong.photowidget`)는 바꾸지 않는다.** 바뀌면 다른 앱으로 인식된다.
- `pubspec.yaml` 의 `version: x.y.z+N` 에서 `N`(versionCode)을 낮추지 않는다. 낮은 버전은 위에 설치되지 않는다.

> 공용 debug 키는 개발용이다. 스토어 출시에는 반드시 별도 release 키를 만들어 `key.properties` 로 지정한다.

## 개발

```bash
flutter pub get
flutter run          # 연결된 Android 기기/에뮬레이터
flutter analyze
flutter test
```
