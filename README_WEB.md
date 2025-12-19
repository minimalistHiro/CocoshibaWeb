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

## 画像が表示されない（CORS）

Flutter Web（特に CanvasKit）では、Firebase Storage の画像を取得する際にブラウザの CORS 制約を受けます。
Console に `blocked by CORS policy: No 'Access-Control-Allow-Origin' header` が出る場合は、**Storage バケットの CORS 設定**が必要です。

### CORS 設定（推奨）

Google Cloud SDK（`gsutil`）が使える環境で、以下を実行してください。

```bash
./scripts/set_storage_cors.sh cocoshibaapp.appspot.com
```

（設定内容は `storage_cors.json`。必要に応じて許可する origin を追加してください）

ローカル開発では Flutter の Web ポートが毎回変わることがあるため、CORS の `origin` と一致しないと再発します。固定ポートで起動するのがおすすめです。

```bash
flutter run -d chrome --web-port 53433
```

### 一時回避（開発用）

環境によっては HTML レンダラーで回避できることがあります。

```bash
flutter run -d chrome --web-renderer html
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
