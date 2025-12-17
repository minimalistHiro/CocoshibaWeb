# CocoshibaWeb (Flutter Web)

既存の Firebase プロジェクト（CocoshibaApp と同一）を使って、Flutter Web で認証（Email/Password）と基本ページを提供します。

## ルーティング

- `/` ホーム
- `/calendar` カレンダー（仮）
- `/menu` メニュー（仮）
- `/store` 店舗情報（仮）
- `/_/login` ログイン
- `/_/signup` サインアップ
- `/_/account` アカウント管理（ログイン必須）

## セットアップ

### 1) Flutter / Firebase CLI

- Flutter (stable)
- Firebase CLI: `npm i -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 2) Firebase 設定（重要）

このリポジトリは `lib/firebase_options.dart` を **プレースホルダ**として同梱しています。
既存 Firebase プロジェクト（CocoshibaApp と同一）に紐づく実データで置き換えてください。

推奨手順（例）:

```bash
flutterfire configure
```

完了後、`lib/firebase_options.dart` が実プロジェクトの値になります。

### 3) 依存取得

```bash
flutter pub get
```

## ローカル起動

```bash
flutter run -d chrome
```

## ビルド

```bash
flutter build web --release
```

## Firebase Hosting (SPA) デプロイ

このリポジトリは `firebase.json` に SPA rewrite（`** -> /index.html`）を設定済みです。

```bash
firebase login
firebase use --add
flutter build web --release
firebase deploy --only hosting
```

## 本番ドメイン

想定ドメイン: `https://newcocoshiba.com`

- Firebase Hosting のカスタムドメイン設定を行い、案内に従って DNS（TXT / A）を設定してください
- SSL は Firebase Hosting 側で自動発行されます
