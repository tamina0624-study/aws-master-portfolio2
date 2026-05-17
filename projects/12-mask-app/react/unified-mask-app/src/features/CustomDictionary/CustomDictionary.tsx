
import React, { useState, useEffect, useRef } from 'react';
import './CustomDictionary.css';
import { useNavigate, useLocation } from 'react-router-dom';

type DictionaryEntry = {
  id: string;
  keyword: string;
  category: string;
  description: string;
};

const LOCAL_STORAGE_KEY = 'custom_dictionary';

function escapeHtml(str: string) {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const CustomDictionary: React.FC = () => {
  const [entries, setEntries] = useState<DictionaryEntry[]>([]);
  const [keyword, setKeyword] = useState('');
  const [category, setCategory] = useState('機密情報');
  const [description, setDescription] = useState('');
  const [editId, setEditId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const formRef = useRef<HTMLFormElement>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  useEffect(() => {
    const data = localStorage.getItem(LOCAL_STORAGE_KEY);
    setEntries(data ? JSON.parse(data) : []);
  }, []);

  useEffect(() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(entries));
  }, [entries]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!keyword.trim()) {
      alert('キーワードを入力してください。');
      return;
    }
    if (editId) {
      setEntries(prev => prev.map(item => item.id === editId ? {
        ...item,
        keyword: keyword.trim(),
        category,
        description: description.trim() || '（説明なし）'
      } : item));
      setEditId(null);
    } else {
      setEntries(prev => [
        ...prev,
        {
          id: Date.now().toString(),
          keyword: keyword.trim(),
          category,
          description: description.trim() || '（説明なし）'
        }
      ]);
    }
    setKeyword('');
    setCategory('機密情報');
    setDescription('');
    formRef.current?.reset();
  };

  const handleDelete = (id: string) => {
    if (!window.confirm('この辞書を削除してもよろしいですか？')) return;
    setEntries(prev => prev.filter(item => item.id !== id));
  };

  const handleEdit = (id: string) => {
    const item = entries.find(e => e.id === id);
    if (!item) return;
    setKeyword(item.keyword);
    setCategory(item.category);
    setDescription(item.description === '（説明なし）' ? '' : item.description);
    setEditId(id);
    document.querySelector('.panel-left')?.scrollIntoView({ behavior: 'smooth' });
  };

  const getBadgeClass = (cat: string) => {
    if (cat === 'API Key') return 'tag-api';
    if (cat === '個人情報') return 'tag-privacy';
    return 'tag-secret';
  };

  // 検索フィルタ
  const filteredEntries = entries.filter(item =>
    (!search || item.keyword.includes(search) || item.category.includes(search) || item.description.includes(search))
  );

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="logo">
          <div className="logo-icon">S</div>
          <div className="logo-text">
            <h1>機密情報マスクツール</h1>
            <p>ローカル機密情報保護 / Local Privacy Protection</p>
          </div>
        </div>
        <div className="menu">
          <div className={`menu-item${isActive('/mask-app-react/dashboard') ? ' active' : ''}`} onClick={() => navigate('/mask-app-react/dashboard')}>ダッシュボード / Dashboard</div>
          <div className={`menu-item${isActive('/mask-app-react/detection-rules') ? ' active' : ''}`} onClick={() => navigate('/mask-app-react/detection-rules')}>検知ルール / Detection Rules</div>
          <div className={`menu-item${isActive('/mask-app-react/custom-dictionary') ? ' active' : ''}`} onClick={() => navigate('/mask-app-react/custom-dictionary')}>カスタム辞書 / Custom Dictionary</div>
        </div>
        <div className="local-card">
          <h3>✓ ローカル処理専用モード / Local Only Mode</h3>
          <ul>
            <li>外部アップロードなし / No External Upload</li>
            <li>ブラウザ内のみで処理 / Browser-only Processing</li>
            <li>オフライン対応 / Offline Compatible</li>
            <li>ローカル辞書対応 / Custom Local Dictionary</li>
          </ul>
        </div>
      </aside>
      <main className="main">
        {/* サイドメニューボタン（アイコン表示） main直下用 */}
        <button className="hamburger" aria-label="メニューを開く" style={{ border: 'none', display: 'none' }}>
          <i className="fas fa-bars" style={{ fontSize: '2rem', color: 'white' }}></i>
        </button>

        <div className="dict-header">
          <div>
            <div className="dict-title">Custom Dictionary</div>
            <div className="dict-sub">カスタム辞書の登録・削除・管理</div>
          </div>
        </div>

        <div className="dict-grid">
          <div className="dict-panel panel-left">
            <div>
              <h2 className="panel-title">辞書登録</h2>
              <form className="dictionary-form" ref={formRef} onSubmit={handleSubmit}>
                <div className="form-group">
                  <label className="form-label">キーワード</label>
                  <input className="form-input" name="keyword" type="text" placeholder="例: API_KEY"
                    value={keyword} onChange={e => setKeyword(e.target.value)} />
                </div>
                <div className="form-group">
                  <label className="form-label">カテゴリ</label>
                  <select className="form-select" name="category" value={category} onChange={e => setCategory(e.target.value)}>
                    <option value="個人情報">個人情報</option>
                    <option value="API Key">API Key</option>
                    <option value="機密情報">機密情報</option>
                    <option value="認証情報">認証情報</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">説明</label>
                  <textarea className="form-textarea" name="description" rows={5} placeholder="辞書の用途や説明を入力"
                    value={description} onChange={e => setDescription(e.target.value)} />
                </div>
                <button className="btn-submit" type="submit">{editId ? '更新' : '登録する'}</button>
              </form>
            </div>
          </div>
          <div className="dict-panel panel-right">
            <div>
              <div className="list-header-wrapper">
                <div>
                  <h2 className="panel-title" style={{ marginBottom: 0 }}>登録済み辞書一覧</h2>
                  <p className="dict-sub" style={{ fontSize: 12, color: '#52525b', marginTop: 2 }}>Registered Custom Dictionary Entries</p>
                </div>
                <div className="search-box-group">
                  <input type="text" placeholder="検索..." className="search-input" value={search} onChange={e => setSearch(e.target.value)} />
                  <button className="btn-filter" type="button" tabIndex={-1} style={{ pointerEvents: 'none', opacity: 0.5 }}>Filter</button>
                </div>
              </div>
              <div className="table-grid table-th-row">
                <div className="col-keyword">キーワード</div>
                <div className="col-category">カテゴリ</div>
                <div className="col-desc">説明</div>
                <div className="col-actions" style={{ paddingRight: 8 }}>操作</div>
              </div>
              <div className="table-tr-rows">
                {filteredEntries.length === 0 ? (
                  <div style={{ padding: 24, textAlign: 'center', color: '#52525b', fontSize: 14 }}>
                    登録されているカスタム辞書はありません。
                  </div>
                ) : (
                  filteredEntries.map(item => (
                    <div className="table-grid table-td-row" key={item.id} data-id={item.id}>
                      <div className="col-keyword">{escapeHtml(item.keyword)}</div>
                      <div className="col-category">
                        <span className={`tag-badge ${getBadgeClass(item.category)}`}>{escapeHtml(item.category)}</span>
                      </div>
                      <div className="col-desc">{escapeHtml(item.description)}</div>
                      <div className="col-actions">
                        <button className="btn-action btn-edit" type="button" onClick={() => handleEdit(item.id)}>編集</button>
                        <button className="btn-action btn-delete" type="button" onClick={() => handleDelete(item.id)}>削除</button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
            <div className="list-footer">
              <div>合計 {filteredEntries.length} 件の辞書が登録されています</div>
              <div className="pagination">
                <button className="btn-page-arrow" type="button" tabIndex={-1} style={{ pointerEvents: 'none', opacity: 0.5 }}>←</button>
                <button className="btn-page-num" type="button" tabIndex={-1} style={{ pointerEvents: 'none', opacity: 0.5 }}>1</button>
                <button className="btn-page-arrow" type="button" tabIndex={-1} style={{ pointerEvents: 'none', opacity: 0.5 }}>→</button>
              </div>
            </div>
          </div>
        </div>

        <div className="info-section">
          <h3 className="info-title">辞書機能について</h3>
          <div className="info-grid">
            <div className="info-card">
              <div className="info-card-title text-cyan">Keyword Detection</div>
              <p className="info-card-desc">指定したキーワードをログやテキストから検知します。</p>
            </div>
            <div className="info-card">
              <div className="info-card-title text-emerald">Masking Support</div>
              <p className="info-card-desc">検知したワードを自動でマスキング対象にできます。</p>
            </div>
            <div className="info-card">
              <div className="info-card-title text-orange">Rule Management</div>
              <p className="info-card-desc">カテゴリごとに検知ルールを管理可能です。</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default CustomDictionary;
