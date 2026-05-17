import React from 'react';
import './DetectionRules.css';
import { useNavigate, useLocation } from 'react-router-dom';

const DetectionRules: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;
  return (
    <div className="layout">
      {/* Sidebar */}
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

      {/* Main */}
      <main className="main">
        {/* ハンバーガーメニュー（スマホ用） */}
        <button className="hamburger" aria-label="メニューを開く" style={{ border: 'none' }}>
          <i className="fas fa-bars" style={{ fontSize: '2rem', color: 'white' }}></i>
        </button>

        <div className="header">
          <div>
            <div className="title">機密情報検知ルール</div>
            <div className="sub">APIキー・個人情報・秘密情報などを自動検知してマスキングします</div>
          </div>
        </div>

        {/* High Entropy Detection */}
        <section className="entropy-box">
          <div className="entropy-title">High Entropy Detection</div>
          <div className="entropy-desc">
            ランダム性の高い文字列を検知します。<br />
            APIキーや秘密情報の漏洩検知に有効です。
          </div>
          <div className="conditions">
            <div className="condition">20文字以上</div>
            <div className="condition">英数字混在</div>
            <div className="condition">エントロピー &gt; 3.5</div>
          </div>
        </section>

        {/* Detection Rules Section */}
        <section className="section">
          <div className="section-title">Detection Rules</div>
          <div className="section-desc">
            登録済みの検知ルール一覧。各ルールごとに説明・検知例・置換後文字列を設定できます。
          </div>
          <div className="rule-grid">
            {/* JWT */}
            <div className="rule-card">
              <div className="rule-header">
                <div className="rule-name">JWT Token</div>
              </div>
              <div className="rule-body">
                <div className="label">説明</div>
                <div className="value">JWTアクセストークンを検知します</div>
                <div className="label">検知例</div>
                <div className="code">eyJhbGciOiJIUzI1NiIs...</div>
                <div className="label">置換後</div>
                <div className="replace">[JWT_TOKEN]</div>
              </div>
            </div>
            {/* AWS */}
            <div className="rule-card">
              <div className="rule-header">
                <div className="rule-name">AWS Access Key</div>
              </div>
              <div className="rule-body">
                <div className="label">説明</div>
                <div className="value">AWS IAMアクセスキーを検知します</div>
                <div className="label">検知例</div>
                <div className="code">AKIAIOSFODNN7EXAMPLE</div>
                <div className="label">置換後</div>
                <div className="replace">[AWS_ACCESS_KEY]</div>
              </div>
            </div>
            {/* Email */}
            <div className="rule-card">
              <div className="rule-header">
                <div className="rule-name">Email Address</div>
              </div>
              <div className="rule-body">
                <div className="label">説明</div>
                <div className="value">メールアドレスを検知します</div>
                <div className="label">検知例</div>
                <div className="code">test@example.com</div>
                <div className="label">置換後</div>
                <div className="replace">[EMAIL]</div>
              </div>
            </div>
            {/* IPv4 */}
            <div className="rule-card">
              <div className="rule-header">
                <div className="rule-name">IPv4 Address</div>
              </div>
              <div className="rule-body">
                <div className="label">説明</div>
                <div className="value">IPv4形式のIPアドレスを検知します</div>
                <div className="label">検知例</div>
                <div className="code">192.168.1.1</div>
                <div className="label">置換後</div>
                <div className="replace">[IP_ADDRESS]</div>
                <div className="label">Regex</div>
                <div className="regex">\b(?:\d{1,3}\.){3}\d{1,3}\b</div>
              </div>
            </div>
          </div>
        </section>

        {/* Custom Dictionary Section */}
        <section className="section">
          <div className="section-title">Custom Dictionary</div>
          <div className="section-desc">
            ユーザー独自の機密ワードを登録可能
          </div>
          <div className="dictionary">
            <div className="tag">カスタム辞書説明</div>
            <div style={{ lineHeight: 1.8, color: '#475569' }}>
              社内独自のワードや機密情報を登録し、<br />
              自動検知ルールとして利用できます。
            </div>
            <div className="dict-list">
              <div className="dict-item">・顧客名</div>
              <div className="dict-item">・社員番号</div>
              <div className="dict-item">・内部プロジェクト名</div>
              <div className="dict-item">・秘密コード</div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
};

export default DetectionRules;
