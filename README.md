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
  main.dart                 진입점: main(앱), widgetConfigureMain(위젯 사진 고르기)
  app/                      MaterialApp, 테마
  data/photo/               사진 저장소(앱 폴더 복사본 + photos.json 인덱스), 갤러리 선택
  data/widget/              홈 화면 위젯 연결 (위젯 ID → 사진 경로, 위젯 갱신)
  features/home/            저장한 사진 그리드 (추가 / 길게 눌러 삭제)
  features/photo_detail/    사진 크게 보기 + 위젯 크기별 미리보기
  features/photos/          사진 목록 상태(Riverpod), 공용 그리드·버튼·삭제 확인
  features/widget_configure/ 위젯에 걸 사진 고르기 화면

android/app/src/main/kotlin/com/mikyeong/photowidget/
  WidgetConfigureActivity.kt  위젯 놓을 때 / 위젯 누를 때 뜨는 Flutter 화면
  widget/PhotoWidgetProvider.kt  홈 화면 위젯 (크기 조절 가능, 위젯마다 다른 사진)
  widget/PhotoWidgetStore.kt     위젯 ID → 사진 경로 (home_widget 저장소)
  widget/PhotoBitmapLoader.kt    위젯 크기에 맞춰 줄이고 사진 방향 보정
```

## 위젯 동작

1. 홈 화면에 "사진" 위젯을 놓으면 사진 고르기 화면이 뜬다. 고르지 않고 닫으면 위젯이 추가되지 않는다.
2. 위젯은 1×1 부터 원하는 만큼 늘이고 줄일 수 있고, 크기가 바뀌면 그 크기에 맞는 해상도로 다시 그린다.
3. 위젯을 누르면 다시 사진 고르기 화면이 떠서 다른 사진으로 바꿀 수 있다.
4. 앱에서 위젯에 걸린 사진을 지우면 위젯은 "사진이 지워졌어요 / 눌러서 다시 선택" 으로 바뀐다.

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

## 앱 아이콘

- 원본: `assets/icon/src/*.svg` → PNG: `assets/icon/*.png` (1024×1024)
  - `icon.png` 전체 아이콘(Android 7 이하), `icon_foreground.png` 적응형 아이콘 전경, `icon_monochrome.png` Android 13+ 테마 아이콘
- 이미지를 바꾼 뒤 `dart run flutter_launcher_icons` 를 실행하면 `android/app/src/main/res/` 아이콘이 다시 만들어진다. 설정은 `pubspec.yaml` 의 `flutter_launcher_icons`.
- 전경 그림은 가운데 약 60% 안에 그려야 원형 등으로 잘려도 보인다.
