const rules = [

  // IPv4
  {
    name: "IPv4",
    regex: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g,
    replace: "[IP_ADDRESS]"
  },

  // Email
  {
    name: "Email",
    regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g,
    replace: "[EMAIL]"
  },

  // URL
  {
    name: "URL",
    regex: /https?:\/\/[^\s]+/g,
    replace: "[URL]"
  },

  // AWS Access Key
  {
    name: "AWS Access Key",
    regex: /AKIA[0-9A-Z]{16}/g,
    replace: "[AWS_ACCESS_KEY]"
  },

  // JWT
  {
    name: "JWT",
    regex: /eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+/g,
    replace: "[JWT_TOKEN]"
  },

  // Bearer Token
  {
    name: "Bearer Token",
    regex: /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi,
    replace: "Bearer [TOKEN]"
  },

  // Cookie
  {
    name: "Cookie",
    regex: /(cookie\s*:\s*)(.+)/gi,
    replace: "$1[MASKED_COOKIE]"
  },

  // Authorization Header
  {
    name: "Authorization",
    regex: /(authorization\s*:\s*)(.+)/gi,
    replace: "$1[MASKED_AUTH]"
  },

  // Generic Secrets
  {
    name: "Generic Secret",
    regex: /((password|passwd|pwd|secret|secret_key|apikey|api_key|token|access_token|refresh_token|client_secret|private_key)\s*[=:]\s*)(.+)/gi,
    replace: "$1[MASKED]"
  },

  // JSON style secrets
  {
    name: "JSON Secret",
    regex: /("(password|secret|token|apikey|api_key|client_secret|private_key)"\s*:\s*")([^"]+)"/gi,
    replace: "$1[MASKED]\""
  },

  // .env style
  {
    name: ".env Secret",
    regex: /^([A-Z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY)[A-Z0-9_]*=)(.+)$/gim,
    replace: "$1[MASKED]"
  },

  // PEM Private Key
  {
    name: "Private Key",
    regex: /-----BEGIN PRIVATE KEY-----[\s\S]+?-----END PRIVATE KEY-----/g,
    replace: "[PRIVATE_KEY]"
  },

  // Credit Card
  {
    name: "Credit Card",
    regex: /\b(?:\d[ -]*?){13,16}\b/g,
    replace: "[CREDIT_CARD]"
  }

];

const inputText =
  document.getElementById("inputText");

const outputText =
  document.getElementById("outputText");

const keywordInput =
  document.getElementById("keywordInput");

const saveKeywordsButton =
  document.getElementById("saveKeywordsButton");

const showKeywordsButton =
  document.getElementById("showKeywordsButton");

const clearKeywordsButton =
  document.getElementById("clearKeywordsButton");

let customKeywords = [];

let keywordsVisible = false;

function escapeRegex(str) {

  return str.replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );
}

function loadKeywords() {

  const saved =
    localStorage.getItem("custom_dictionary");

  if (!saved) {

    customKeywords = [];

    return;
  }

  try {

    customKeywords = JSON.parse(saved);

  } catch (e) {

    console.error(e);

    customKeywords = [];
  }
}




function maskCustomKeywords(text) {
  let result = text;
  let count = 0;
  for (const keyword of customKeywords) {
    console.log("Masking with keyword:", keyword);
    if (!keyword) continue;
    const regex = new RegExp(
      escapeRegex(keyword["keyword"]),
      "gu"
    );
    const before = result;
    result = result.replace(regex, function(match) {
      count++;
      return "[CUSTOM_SENSITIVE]";
    });
  }
  return { result, count };
}

function calculateEntropy(str) {

  const map = {};

  for (const char of str) {
    map[char] = (map[char] || 0) + 1;
  }

  let entropy = 0;

  const length = str.length;

  for (const char in map) {

    const p = map[char] / length;

    entropy -= p * Math.log2(p);
  }

  return entropy;
}

function maskHighEntropyStrings(text) {

  const regex =
    /[A-Za-z0-9+/_\-=\.:]{20,}/g;

  return text.replace(regex, (match) => {

    const hasLetter =
      /[A-Za-z]/.test(match);

    const hasNumber =
      /\d/.test(match);

    if (!hasLetter || !hasNumber) {
      return match;
    }

    const entropy =
      calculateEntropy(match);

    if (entropy > 3.5) {

      return "[HIGH_ENTROPY_SECRET]";
    }

    return match;
  });
}


function maskText(text) {
  let result = text;
  let counts = {
    email: 0,
    api: 0,
    custom: 0,
    other: 0
  };

  // カスタム辞書
  const customRes = maskCustomKeywords(result);
  result = customRes.result;
  counts.custom = customRes.count;

  // エントロピー検出（カウント対象外）
  result = maskHighEntropyStrings(result);

  // 通常ルール
  for (const rule of rules) {
    let matchCount = 0;
    result = result.replace(rule.regex, function(match) {
      matchCount++;
      return rule.replace;
    });
    // カウント割り振り
    if (rule.name === "Email") {
      counts.email += matchCount;
    } else if (
      rule.name === "AWS Access Key" ||
      rule.name === "Generic Secret" ||
      rule.name === "JSON Secret" ||
      rule.name === ".env Secret"
    ) {
      counts.api += matchCount;
    } else {
      counts.other += matchCount;
    }
  }

  UpdateMaskedNumber(counts);
  return { maskedText: result, counts };
}

function UpdateMaskedNumber(counts) {

  // 検知数合計
  const total = counts.email + counts.api + counts.custom + counts.other;

  // 各stat-cardの値を更新
  const statCards = document.querySelectorAll('.stat-card .value');
  if (statCards.length >= 4) {
    statCards[0].textContent = total;         // 検知数
    statCards[1].textContent = counts.email;  // メール
    statCards[2].textContent = counts.api;    // APIキー
    statCards[3].textContent = counts.custom; // カスタム
  }

    const detectioSuccess = document.querySelector('.detection.success');
    detectioSuccess.textContent=`${total}件をマスク済み / ${total} items masked`;

    const riskScore = document.querySelector('.risk-score');
    riskScore.classList.remove('low', 'medium', 'high');

    if (total === 0) {
      riskScore.textContent = "LOW";
      riskScore.classList.add('low');
    } else if (total < 5) {
      riskScore.textContent = "MEDIUM";
      riskScore.classList.add('medium');
    } else {
      riskScore.textContent = "HIGH";
      riskScore.classList.add('high');
    }



}

document
  .getElementById("maskButton")
  .addEventListener("click", () => {

    const original =
      inputText.value;

    const masked =
      maskText(original);

    outputText.value = masked;

  });

document
  .getElementById("maskButton")
  .addEventListener("click", () => {
    const original = inputText.value;
    const { maskedText, counts } = maskText(original);
    outputText.value = maskedText;
  });

document
  .getElementById("copyButton")
  .addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(
        outputText.value
      );
      status.textContent =
        "コピーしました";
    } catch (err) {
      console.error(err);
      status.textContent =
        "コピー失敗";
    }
  });

document
  .getElementById("clearButton")
  .addEventListener("click", () => {
    inputText.value = "";
    outputText.value = "";
    status.textContent = "";
  });


// 起動時ロード
loadKeywords();

function exportOutput() {
  const text = outputText.value;
  if (!text) return;
  const blob = new Blob([text], { type: "text/plain" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "masked_output.txt";
  a.click();
  URL.revokeObjectURL(url);
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
