import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import './Dashboard.css';

// カスタム辞書のlocalStorageキー
const LOCAL_STORAGE_KEY = 'custom_dictionary';
// エスケープ関数（カスタムキーワード用）
function escapeRegex(str: string) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// エントロピー計算
function calculateEntropy(str: string) {
  const map: Record<string, number> = {};
  for (const char of str) map[char] = (map[char] || 0) + 1;
  let entropy = 0;
  const length = str.length;
  for (const char in map) {
    const p = map[char] / length;
    entropy -= p * Math.log2(p);
  }
  return entropy;
}

// 高エントロピー文字列のマスク
function maskHighEntropyStrings(text: string) {
  const regex = /[A-Za-z0-9+/_\-=:\.]{20,}/g;
  return text.replace(regex, (match) => {
    const hasLetter = /[A-Za-z]/.test(match);
    const hasNumber = /\d/.test(match);
    if (!hasLetter || !hasNumber) return match;
    const entropy = calculateEntropy(match);
    if (entropy > 3.5) return '[HIGH_ENTROPY_SECRET]';
    return match;
  });
}


// マスキングルール
const rules = [
  { name: "IPv4", regex: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g, replace: "[IP_ADDRESS]" },
  { name: "Email", regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g, replace: "[EMAIL]" },
  { name: "URL", regex: /https?:\/\/[^\s]+/g, replace: "[URL]" },
  { name: "AWS Access Key", regex: /AKIA[0-9A-Z]{16}/g, replace: "[AWS_ACCESS_KEY]" },
  { name: "JWT", regex: /eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+/g, replace: "[JWT_TOKEN]" },
  { name: "Bearer Token", regex: /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi, replace: "Bearer [TOKEN]" },
  { name: "Cookie", regex: /(cookie\s*:\s*)(.+)/gi, replace: "$1[MASKED_COOKIE]" },
  { name: "Authorization", regex: /(authorization\s*:\s*)(.+)/gi, replace: "$1[MASKED_AUTH]" },
  { name: "Generic Secret", regex: /((password|passwd|pwd|secret|secret_key|apikey|api_key|token|access_token|refresh_token|client_secret|private_key)\s*[=:]\s*)(.+)/gi, replace: "$1[MASKED]" },
  { name: "JSON Secret", regex: /("(password|secret|token|apikey|api_key|client_secret|private_key)"\s*:\s*")([^"]+)"/gi, replace: "$1[MASKED]\"" },
  { name: ".env Secret", regex: /^([A-Z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY)[A-Z0-9_]*=)(.+)$/gim, replace: "$1[MASKED]" },
  { name: "Private Key", regex: /-----BEGIN PRIVATE KEY-----[\s\S]+?-----END PRIVATE KEY-----/g, replace: "[PRIVATE_KEY]" },
  { name: "Credit Card", regex: /\b(?:\d[ -]*?){13,16}\b/g, replace: "[CREDIT_CARD]" }
];

const Dashboard: React.FC = () => {
  const [input, setInput] = useState('');
  const [output, setOutput] = useState('');
  const [maskedCount, setMaskedCount] = useState(0);
  const location = useLocation();
  const navigate = useNavigate();

  const handleMask = () => {
    let masked = input;
    let totalCount = 0;
    let emailCount = 0;
    let apiCount = 0;
    let customCount = 0;
    let otherCount = 0;

    // カスタム辞書マスク
    let customKeywords: { keyword: string }[] = [];
    try {
      const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (saved) customKeywords = JSON.parse(saved);
    } catch (e) { customKeywords = []; }
    for (const entry of customKeywords) {
      if (!entry.keyword) continue;
      const regex = new RegExp(escapeRegex(entry.keyword), 'gu');
      masked = masked.replace(regex, (match) => {
        customCount++;
        return '[CUSTOM_SENSITIVE]';
      });
    }

    // 高エントロピー文字列マスク（カウント対象外）
    masked = maskHighEntropyStrings(masked);

    // 通常ルール
    rules.forEach(rule => {
      let matchCount = 0;
      masked = masked.replace(rule.regex, (match) => {
        matchCount++;
        return typeof rule.replace === 'string' ? rule.replace : '';
      });
      // カウント割り振り
      if (rule.name === 'Email') {
        emailCount += matchCount;
      } else if (
        rule.name === 'AWS Access Key' ||
        rule.name === 'Generic Secret' ||
        rule.name === 'JSON Secret' ||
        rule.name === '.env Secret'
      ) {
        apiCount += matchCount;
      } else {
        otherCount += matchCount;
      }
    });
    totalCount = emailCount + apiCount + customCount + otherCount;
    setOutput(masked);
    setMaskedCount(totalCount);
    // 件数内訳もstat-cardに反映（メール、API、カスタム）
    const statCards = document.querySelectorAll('.stat-card .value');
    if (statCards.length >= 4) {
      statCards[0].textContent = String(totalCount);
      statCards[1].textContent = String(emailCount);
      statCards[2].textContent = String(apiCount);
      statCards[3].textContent = String(customCount);
    }
    // リスクレベルも反映
    const riskScore = document.querySelector('.risk-score');
    if (riskScore) {
      riskScore.classList.remove('low', 'medium', 'high');
      if (totalCount === 0) {
        riskScore.textContent = 'LOW';
        riskScore.classList.add('low');
      } else if (totalCount < 5) {
        riskScore.textContent = 'MEDIUM';
        riskScore.classList.add('medium');
      } else {
        riskScore.textContent = 'HIGH';
        riskScore.classList.add('high');
      }
    }
  };

  // メニューのactive判定
  const isActive = (path: string) => location.pathname === path;

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
        <div className="topbar">
          <div className="title">
            <h2>機密情報検知ワークスペース / Secret Detection Workspace</h2>
            <p>共有前に機密情報を検知・マスクします / Detect and mask sensitive information before sharing.</p>
          </div>
          <div className="risk">
            <div>リスクレベル / Risk Level</div>
            <div className="risk-score low">LOW</div>
          </div>
        </div>
        <div className="cards">
          <div className="stat-card">
            <div className="label">検知数 / Secrets Found</div>
            <div className="value">{maskedCount}</div>
          </div>
          <div className="stat-card">
            <div className="label">メールアドレス / Emails</div>
            <div className="value">0</div>
          </div>
          <div className="stat-card">
            <div className="label">APIキー / API Keys</div>
            <div className="value">0</div>
          </div>
          <div className="stat-card">
            <div className="label">カスタムルール / Custom Rules</div>
            <div className="value">0</div>
          </div>
        </div>
        <div className="workspace">
          <section className="editor">
            <div className="editor-header">
              <div className="editor-title">入力ログ / Input Logs</div>
            </div>
            <textarea id="inputText" placeholder="ログ・設定・スタックトレース・APIレスポンス等を貼り付け..." value={input} onChange={e => setInput(e.target.value)} />
            <div className="bottom-bar">
              <div className="actions">
                <button className="secondary" onClick={() => { setInput(''); setOutput(''); setMaskedCount(0); }}>クリア / Clear</button>
                <button className="primary" onClick={handleMask}>機密情報をマスク / Mask Secrets</button>
              </div>
            </div>
          </section>
          <section className="editor">
            <div className="editor-header">
              <div className="editor-title">マスク後テキスト / Sanitized Output</div>
            </div>
            <textarea id="outputText" placeholder="マスク済みテキストがここに表示されます..." value={output} readOnly />
            <div className="bottom-bar">
              <div className="detections">
                <div className="detection success">{maskedCount}件をマスク済み / {maskedCount} items masked</div>
              </div>
              <div className="actions">
                <button className="secondary" onClick={() => { navigator.clipboard.writeText(output); }}>コピー / Copy Output</button>
              </div>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;
