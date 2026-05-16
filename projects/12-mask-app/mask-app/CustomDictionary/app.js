// 画面読み込み時の初期化処理
document.addEventListener('DOMContentLoaded', () => {
  // 1. 登録ボタンのイベントリスナーを設定
  const submitBtn = document.querySelector('.btn-submit');
  if (submitBtn) {
    submitBtn.addEventListener('click', handleRegister);
  }

  // 2. 初回読み込み時にローカルストレージからデータを取得して描画
  renderDictionaryList();
});

/**
 * ローカルストレージからデータを取得する共通関数
 */
function getDictionaryData() {
  const data = localStorage.getItem('custom_dictionary');
  return data ? JSON.parse(data) : [];
}

/**
 * 登録ボタンが押されたときの処理
 */
function handleRegister(event) {
  event.preventDefault(); // フォームのデフォルト挙動を防止

  // 入力フォームの要素を取得
  const keywordInput = document.querySelector('.form-input');
  const categorySelect = document.querySelector('.form-select');
  const textareaInput = document.querySelector('.form-textarea');

  // 値の取得
  const keyword = keywordInput.value.trim();
  const category = categorySelect.value;
  const description = textareaInput.value.trim();

  // 簡易バリデーション（キーワードが空の場合は処理しない）
  if (!keyword) {
    alert('キーワードを入力してください。');
    return;
  }

  // 保存するオブジェクトの作成 (一意のIDを持たせる)
  const newEntry = {
    id: Date.now().toString(), // 削除や編集で特定しやすいようタイムスタンプをIDに利用
    keyword: keyword,
    category: category,
    description: description || '（説明なし）'
  };

  // 既存のデータを取得して新しいデータを追加
  const currentData = getDictionaryData();
  currentData.push(newEntry);

  // ローカルストレージに保存
  localStorage.setItem('custom_dictionary', JSON.stringify(currentData));

  // フォームの入力をクリア
  keywordInput.value = '';
  textareaInput.value = '';
  categorySelect.selectedIndex = 0;

  // 一覧リストを再描画
  renderDictionaryList();
}

/**
 * ローカルストレージの内容をもとに、テーブル一覧を再描画する関数
 */
function renderDictionaryList() {
  const tableRowsContainer = document.querySelector('.table-tr-rows');
  const footerCountContainer = document.querySelector('.list-footer div:first-child');

  if (!tableRowsContainer) return;

  // 現在保存されているデータを取得
  const dataList = getDictionaryData();

  // いったんテーブル内を空にする
  tableRowsContainer.innerHTML = '';

  // データがない場合の表示
  if (dataList.length === 0) {
    tableRowsContainer.innerHTML = `
      <div style="padding: 24px; text-align: center; color: #52525b; font-size: 14px;">
        登録されているカスタム辞書はありません。
      </div>
    `;
    if (footerCountContainer) footerCountContainer.textContent = '合計 0 件の辞書が登録されています';
    return;
  }

  // データを1件ずつHTML組み立ててループ追加
  dataList.forEach(item => {
    // カテゴリごとに適用するCSSバッジクラスを判定
    let badgeClass = 'tag-secret'; // デフォルト
    if (item.category === 'API Key') badgeClass = 'tag-api';
    if (item.category === '個人情報') badgeClass = 'tag-privacy';

    const rowHtml = `
      <div class="table-grid table-td-row" data-id="${item.id}">
        <div class="col-keyword">${escapeHtml(item.keyword)}</div>
        <div class="col-category">
          <span class="tag-badge ${badgeClass}">${escapeHtml(item.category)}</span>
        </div>
        <div class="col-desc">${escapeHtml(item.description)}</div>
        <div class="col-actions">
          <button class="btn-action btn-edit" onclick="editEntry('${item.id}')">編集</button>
          <button class="btn-action btn-delete" onclick="deleteEntry('${item.id}')">削除</button>
        </div>
      </div>
    `;
    tableRowsContainer.insertAdjacentHTML('beforeend', rowHtml);
  });

  // フッターの件数表示を更新
  if (footerCountContainer) {
    footerCountContainer.textContent = `合計 ${dataList.length} 件の辞書が登録されています`;
  }
}

/**
 * 削除処理の関数
 */
function deleteEntry(id) {
  if (!confirm('この辞書を削除してもよろしいですか？')) return;

  const currentData = getDictionaryData();
  // 指定されたID以外のデータを残すことで削除を実現
  const filteredData = currentData.filter(item => item.id !== id);

  localStorage.setItem('custom_dictionary', JSON.stringify(filteredData));

  // 一覧リストを再描画
  renderDictionaryList();
}

/**
 * 編集処理の関数 (簡易実装：フォームに値を書き戻してリストから一度消す)
 */
function editEntry(id) {
  const currentData = getDictionaryData();
  const targetItem = currentData.find(item => item.id === id);

  if (!targetItem) return;

  // フォームに値をセット
  document.querySelector('.form-input').value = targetItem.keyword;
  document.querySelector('.form-select').value = targetItem.category;
  document.querySelector('.form-textarea').value = targetItem.description === '（説明なし）' ? '' : targetItem.description;

  // ローカルストレージから該当データを一旦削除（再登録させる形）
  const filteredData = currentData.filter(item => item.id !== id);
  localStorage.setItem('custom_dictionary', JSON.stringify(filteredData));

  renderDictionaryList();

  // 入力フォームへスクロール（任意）
  document.querySelector('.panel-left').scrollIntoView({ behavior: 'smooth' });
}

/**
 * XSS対策用のエスケープ関数
 */
function escapeHtml(str) {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}



function moveToDetectionRule() {
    // 検知ルールページへの遷移処理をここに追加
    window.location.href = "../DetectionRules/index.html";
}

function moveToCustomDictionary() {
    // カスタム辞書ページへの遷移処理をここに追加
    window.location.href = "../CustomDictionary/index.html";
}

function moveToDashboard() {
    // ダッシュボードページへの遷移処理をここに追加
    window.location.href = "../Dashboard/index.html";
}
