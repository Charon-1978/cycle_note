# -*- coding: utf-8 -*-
"""
GitHub 托管前隐私审计
用法: python privacy_audit.py <repo_dir>

检查四类问题：
  1. 敏感文件（密钥/签名/环境变量/凭证）
  2. 代码硬编码（API key / token / 私钥头）
  3. 个人信息（手机号 / 真实邮箱 / 身份证 / 姓名署名）
  4. 本地痕迹（绝对路径 / 内网 IP / 主机名 / 用户名）
"""
import os
import re
import subprocess
import sys

# ── 敏感文件名（命中即 CRITICAL）
SENSITIVE_NAMES = [
    r'\.jks$', r'\.keystore$', r'\.p12$', r'\.pfx$', r'\.pem$', r'\.key$',
    r'\.p8$', r'\.mobileprovision$',
    r'^key\.properties$', r'^local\.properties$', r'^\.env$', r'\.env$',
    r'^secrets?\.', r'^credentials?\.', r'^google-services\.json$',
    r'^id_rsa', r'^id_ed25519', r'^\.netrc$', r'^\.npmrc$', r'^\.pypirc$',
    r'\.ovpn$', r'^htpasswd$',
]

# ── 代码里的密钥模式（命中即 CRITICAL）
SECRET_PATTERNS = [
    ('GitHub PAT',      r'gh[pousr]_[A-Za-z0-9]{36,}'),
    ('GitHub OAuth',    r'gho_[A-Za-z0-9]{36}'),
    ('AWS AK',          r'AKIA[0-9A-Z]{16}'),
    ('Google API Key',  r'AIza[0-9A-Za-z_\-]{35}'),
    ('Slack Token',     r'xox[baprs]-[0-9A-Za-z\-]{10,}'),
    ('Stripe Key',      r'sk_(live|test)_[0-9a-zA-Z]{24,}'),
    ('私钥头',           r'-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    ('JWT',             r'eyJ[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}'),
    ('Bearer Token',    r'Bearer\s+[A-Za-z0-9_\-\.]{30,}'),
    ('硬编码密码赋值',    r'(?i)(password|passwd|pwd)\s*[=:]\s*["\'][^"\'\s]{8,}["\']'),
    ('硬编码 Secret 赋值', r'(?i)(secret|token|apikey|api_key)\s*[=:]\s*["\'][A-Za-z0-9_\-]{16,}["\']'),
]

# ── 个人信息（命中即 WARN，需人工确认）
PII_PATTERNS = [
    ('中国手机号',   r'(?<![0-9a-fA-F])1[3-9]\d{9}(?![0-9a-fA-F])'),
    ('真实邮箱',     r'[a-zA-Z0-9._%+-]+@(?!localhost|example\.com|users\.noreply\.github\.com)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    ('身份证号',     r'(?<!\d)\d{17}[\dXx](?!\d)'),
]

# ── 本地痕迹（命中即 WARN）
LOCAL_PATTERNS = [
    ('Windows 用户路径', r'[A-Za-z]:\\\\?Users\\\\?[A-Za-z0-9_.\-]+'),
    ('本机绝对路径',     r'[A-Za-z]:\\\\?(DSH|yueji|Work|GradleHome)'),
    ('内网 IP',         r'\b(?:192\.168|10\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01]))\.\d{1,3}\.\d{1,3}\b'),
    ('localhost 端口',   r'127\.0\.0\.1:\d{2,5}'),
]

# 跳过这些扩展名（二进制/压缩包）
SKIP_EXT = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.bmp',
            '.jar', '.aar', '.apk', '.zip', '.gz', '.tar', '.7z',
            '.so', '.dll', '.exe', '.dylib', '.woff', '.woff2', '.ttf',
            '.mp4', '.mp3', '.pdf', '.sqlite', '.db'}

MAX_SIZE = 3 * 1024 * 1024  # 超过 3MB 跳过内容扫描

CRIT, WARN, INFO = '[严重]', '[注意]', '[信息]'


def get_tracked_files(repo):
    """取 git 跟踪的文件（这是真正会上传的集合）"""
    subprocess.run(['git', '-C', repo, 'config', 'core.quotePath', 'false'],
                   capture_output=True, timeout=30)
    r = subprocess.run(['git', '-C', repo, 'ls-files', '-z'],
                       capture_output=True, timeout=60)
    out = r.stdout.decode('utf-8', 'replace')
    return [f for f in out.split('\0') if f.strip()]


def scan_line_rules(text, rules, label):
    hits = []
    for name, pat in rules:
        try:
            for m in re.finditer(pat, text):
                line_no = text.count('\n', 0, m.start()) + 1
                line = text.split('\n')[line_no - 1].strip()
                hits.append((name, line_no, line[:100]))
        except re.error:
            pass
    return hits


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    repo = os.path.abspath(repo)
    if not os.path.isdir(os.path.join(repo, '.git')):
        print(f'✘ {repo} 不是 git 仓库')
        sys.exit(1)

    files = get_tracked_files(repo)
    print(f'═══ 隐私审计: {repo} ═══')
    print(f'跟踪文件: {len(files)} 个\n')

    critical, warning, info = [], [], []

    # 1. 敏感文件名
    print('[1] 敏感文件名')
    name_hits = 0
    for f in files:
        base = os.path.basename(f)
        for pat in SENSITIVE_NAMES:
            if re.search(pat, base, re.I):
                critical.append(f'敏感文件: {f}')
                name_hits += 1
                break
    print(f'    {"⚠ " + str(name_hits) + " 个" if name_hits else "✔ 无"}\n')

    # 2. 内容扫描
    print('[2] 内容扫描')
    sec_hits, pii_hits, loc_hits = 0, 0, 0
    scanned = 0
    for rel in files:
        full = os.path.join(repo, rel.replace('/', os.sep))
        if not os.path.isfile(full):
            continue
        ext = os.path.splitext(rel)[1].lower()
        if ext in SKIP_EXT:
            continue
        try:
            if os.path.getsize(full) > MAX_SIZE:
                continue
            with open(full, 'r', encoding='utf-8', errors='ignore') as fh:
                text = fh.read()
        except Exception:
            continue
        scanned += 1

        for name, line_no, line in scan_line_rules(text, SECRET_PATTERNS, rel):
            critical.append(f'{name}  {rel}:{line_no}  {line}')
            sec_hits += 1
        for name, line_no, line in scan_line_rules(text, PII_PATTERNS, rel):
            warning.append(f'{name}  {rel}:{line_no}  {line}')
            pii_hits += 1
        for name, line_no, line in scan_line_rules(text, LOCAL_PATTERNS, rel):
            info.append(f'{name}  {rel}:{line_no}  {line}')
            loc_hits += 1

    print(f'    扫描 {scanned} 个文本文件')
    print(f'    密钥/凭证: {"⚠ " + str(sec_hits) + " 处" if sec_hits else "✔ 无"}')
    print(f'    个人信息:   {"⚠ " + str(pii_hits) + " 处" if pii_hits else "✔ 无"}')
    print(f'    本地痕迹:   {"ℹ " + str(loc_hits) + " 处" if loc_hits else "✔ 无"}\n')

    # 输出明细
    if critical:
        print(f'═══ {CRIT} 必须处理 ═══')
        for c in critical[:30]:
            print(f'  {c}')
        print()
    if warning:
        print(f'═══ {WARN} 建议确认 ═══')
        for w in warning[:30]:
            print(f'  {w}')
        print()
    if info:
        print(f'═══ {INFO} 本地痕迹（功能必需可保留）═══')
        for i in info[:15]:
            print(f'  {i}')
        if len(info) > 15:
            print(f'  ...另有 {len(info) - 15} 处')
        print()

    # 结论
    print('═══ 结论 ═══')
    if critical:
        print(f'  ✘ 发现 {len(critical)} 个严重问题，禁止上传')
        sys.exit(2)
    elif warning:
        print(f'  ⚠ {len(warning)} 处需人工确认后上传')
        sys.exit(1)
    else:
        print('  ✔ 通过：无敏感文件、无密钥、无个人信息泄露')
        sys.exit(0)


if __name__ == '__main__':
    main()
