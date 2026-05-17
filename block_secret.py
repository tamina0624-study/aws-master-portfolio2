import argparse
import subprocess
import sys
import re
import yaml
import os
import tomllib
from pathlib import Path

def load_keywords_section(filepath, section):
    try:
        with open(filepath, encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return data.get(section, [])
    except Exception as e:
        print(f"[INFO] キーワードファイルが取得できませんでした: {e}")
        return []

def check_diff_keywords(section, log_prefix, match_line=True, name_only=False):
    ignorefiles=getallowfilepaths()

    print(ignorefiles)
    keywords = load_keywords_section("projects/00-Secret/keywords.txt", section)
    if not keywords:
        return False
    patterns = [re.compile(re.escape(word), re.IGNORECASE) for word in keywords]
    if name_only:
        result = subprocess.run([
            "git", "diff", "--cached", "--name-only"
        ], stdout=subprocess.PIPE, encoding="utf-8")
    else:
        result = subprocess.run([
            "git", "diff", "--cached", "-U0"
        ], stdout=subprocess.PIPE, encoding="utf-8")
    found = False
    current_file = None
    current_line = None
    already_reported = set()
    try:
        with open("projects/00-Secret/secret_detected.log", "a", encoding="utf-8") as f:
            for line in result.stdout.splitlines():
                if name_only:
                    for pattern in patterns:
                        if pattern.search(line):
                            f.write(f"{log_prefix}: {line}\n")
                            found = True
                            break
                else:
                    if line.startswith('+++ b/'):
                        current_file = line[6:]
                    elif line.startswith('@@'):
                        m = re.search(r'\+(\d+)', line)
                        current_line = int(m.group(1)) if m else None
                    elif line.startswith('+') and not line.startswith('+++'):
                        content = line[1:]
                        key = (current_file, current_line, content.strip())
                        for pattern in patterns:
                            if current_file not in ignorefiles:
                                if pattern.search(content) and key not in already_reported:
                                    f.write(f"{log_prefix} in {current_file} at line {current_line}: {content.strip()}\n")
                                    found = True
                                    already_reported.add(key)
                                    break
    except Exception as e:
        print(f"[INFO] ログファイルに書き込めませんでした: {e}")
    return found

def check_env():
    keywords = load_keywords_section("projects/00-Secret/keywords.txt", "env")
    result = subprocess.run([
        "git", "diff", "--cached", "--name-only"
    ], stdout=subprocess.PIPE, encoding="utf-8")
    found = False
    try:
        with open("projects/00-Secret/secret_detected.log", "a", encoding="utf-8") as f:
            for line in result.stdout.splitlines():
                for keyword in keywords:
                    if line.strip().endswith(keyword):
                        f.write(f"ERROR: .env file detected! Commit blocked. ({line.strip()})\n")
                        found = True
                        break
    except Exception as e:
        print(f"[INFO] ログファイルに書き込めませんでした: {e}")
    return found

def check_log():
    log_file = "projects/00-Secret/secret_detected.log"
    seen = set()
    found = False
    if os.path.exists(log_file):
        try:
            with open(log_file, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and line not in seen:
                        print(line)
                        found = True
                        seen.add(line)
            os.remove(log_file)
        except Exception as e:
            print(f"[INFO] シークレットログファイルが読み込めませんでした: {e}")
    return found

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', required=True, help='チェックするセクション名')
    args, unknown = parser.parse_known_args()
    mode = args.mode

    found = False
    if mode == 'company':
        found = check_diff_keywords('company', 'ERROR: Company detected')
    elif mode == 'env':
        found = check_env()
    elif mode == 'log_aggregator':
        found = check_log()
    elif mode == 'my_name':
        found = check_diff_keywords('name', 'ERROR: Name detected')
    elif mode == 'personal_email':
        found = check_diff_keywords('email', 'ERROR: Personal email detected')
    elif mode == 'secret':
        found = check_diff_keywords('secret', 'Secret keyword detected', match_line=False, name_only=True)
    elif mode == 'windows_path':
        found = check_diff_keywords('windows_path', 'ERROR: Local path detected')
    else:
        print(f"[INFO] 未知のmodeです: {mode}")
        sys.exit(1)
    if found:
        sys.exit(1)



def getallowfilepaths():
    config_path = Path(".gitleaks.toml")

    with open(config_path, "rb") as f:
        config = tomllib.load(f)

    filelist = config.get("allowlist", {}).get("paths", [])

    filelist = [
        file.replace("\\", "")
        for file in filelist
    ]

    return filelist


if __name__ == "__main__":
    main()
