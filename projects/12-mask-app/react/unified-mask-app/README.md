# 機密情報マスクツール（React統合版）

## 概要

このアプリは、ローカル環境で動作する「機密情報マスクツール」です。以下の3機能をReactで統合しています。

- **Dashboard**：テキスト入力に対して各種マスキングルールを適用し、機密情報を自動でマスキングします。
- **Detection Rules**：マスキングルール（正規表現・置換文字列）の一覧表示・追加・編集・削除ができます。
- **Custom Dictionary**：独自のキーワードや説明をローカル辞書として登録・編集・削除できます。

すべてのデータはブラウザのlocalStorageに保存され、外部サーバーへの通信はありません。

---


## セットアップ・ビルド・公開方法

### 1. 必要なパッケージのインストール
```bash
npm install
```

### 2. 開発サーバーの起動（ローカル動作確認用）
```bash
npm start
```
ブラウザで `http://localhost:3000` を開くとアプリが利用できます。

### 3. 本番ビルド（静的ファイル出力）
```bash
npm run build
```
`build` フォルダに静的ファイル一式が出力されます。

### 4. フリーのレンタルサーバー等で公開
- `build` フォルダ内のファイルをそのままサーバーにアップロードしてください。
- ルートパス以外で公開する場合は、`package.json` の `homepage` 設定や `PUBLIC_URL` の調整が必要な場合があります。
- React Routerのルーティングは「HashRouter」方式に変更すると、静的サーバーでも動作が安定します。

#### 例: HashRouterへの変更
`src/App.tsx` のRouter部分を `BrowserRouter` → `HashRouter` に変更してください。
```tsx
import { HashRouter as Router, ... } from 'react-router-dom';
```

---

## 機能詳細

### Dashboard
- テキストエリアに貼り付けた内容に対し、検知ルールを適用してマスキング結果を表示
- ルールはDetection Rules画面で編集可能

### Detection Rules
- 正規表現と置換文字列でルールを自由に追加・編集・削除
- ルールはlocalStorageに保存

### Custom Dictionary
- キーワード・カテゴリ・説明を登録し、独自の辞書を管理
- 編集・削除も可能

---

## 技術スタック
- React (TypeScript)
- React Router
- localStorage
- CSS（各画面ごとに分離）

---

## 注意事項
- 本アプリはローカル専用です。外部サーバーにデータは送信されません。
- ブラウザのlocalStorageをクリアすると登録内容も消去されます。
- create-react-appベースですが、今後のReact公式推奨は[Vite](https://vitejs.dev/)等もご検討ください。

---

## ライセンス
MIT License
