# GitHub 托管前 · 隐私与密钥检查清单

> 2026-11-22 核查结论 + 以后每次提交前的固定动作。
> 自检脚本：`_tools/privacy_scan.ps1`（只读，可随时跑）

---

## 一、本次核查结论

| 检查项 | 结果 | 说明 |
|---|---|---|
| GitHub / OpenAI / Google / AWS / Slack 令牌 | ✅ 无 | 全仓库（160 个待提交文本文件）零命中 |
| PEM 私钥 / 证书私钥 | ✅ 无 | — |
| 签名材料 `release.jks` / `key.properties` | ✅ 未入库 | 本机存在，被 `android/.gitignore` 与根 `.gitignore` 双重挡住 |
| 明文密码 / apikey 字段 | ✅ 无 | `build.gradle.kts` 只读 `keystoreProperties["..."]`，没有硬编码值 |
| git 历史里的明文密码 | ✅ 无 | 对 4 个历史提交逐个 `git grep` 真实密码值，0 命中 |
| git 历史里的 `.jks` / `.apk` / `.db` | ✅ 无 | 历史文件清单里只有源码与 `assets/data/*.csv`（公开营养数据） |
| 本机绝对路径（项目盘符、RE 工作区、Gradle 缓存目录） | ✅ 已清除 | 4 个文档 + 5 个脚本改为 `<repo>` / `$env:GRADLE_USER_HOME` / `$PSScriptRoot` 相对推导 |
| 手机号 / 邮箱 / MAC / UUID | ✅ 无 | 仅 `git@github.com:…` 这种 SSH 地址被误报，已排除 |
| 用户健康数据 | ✅ 不在代码里 | 数据库在手机本地（SQLCipher），仓库里没有任何真实记录；截图均为演示数据 |
| 网络行为 | ⚠️ 需知悉 | v1.1.0 起申请 `INTERNET`，**仅**用于「检查更新」拉 manifest + 下载 APK |
| 第三方 SDK | ✅ 无 | 无统计、无广告、无崩溃上报 |

**结论：可以托管到 GitHub。** 唯一需要你手动确认的是下面第二节的账号级设置。

---

## 二、托管前需要你手动做的 5 件事

1. **选可见性**：个人自用建议 **Private**。若选 Public，请确认接受源码公开（含更新通道的占位符与全部业务逻辑）。
2. **开启 Secret scanning + Push protection**（仓库 Settings → Code security）：
   以后误提交 token/keystore，GitHub 会直接拦截推送。
3. **配置 Actions Secrets**（`release.yml` 需要）：
   `KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`，可选 `NAS_DEPLOY_HOOK`。
4. **填三个占位符**：`lib/features/update/update_config.dart` 里的 `YOUR_GITHUB/cycle_note`、`YOUR_NAS_DOMAIN`；
   `update/latest.json` 里的两个下载地址（发布脚本会自动写）。
5. **装提交钩子**（可选但推荐）：
   ```powershell
   git config core.hooksPath .githooks
   ```

---

## 三、本次发现并已修掉的风险

| 风险 | 影响 | 处理 |
|---|---|---|
| `dist/*.apk`（30MB × 2）未被忽略 | `git add .` 会把 60MB 二进制塞进仓库，且以后每次发版都翻倍 | `.gitignore` 增加 `/dist/`、`*.apk` |
| `_shots_new/`（160 个调试截图/日志）未忽略 | 体积 + 含本机路径与模拟器窗口信息 | 忽略该目录 |
| `_mumu_out/`（模拟器 RPC 信息，含 VM 名、磁盘大小、时间戳） | 设备/环境指纹 | 忽略该目录 |
| 根目录 `_jstack.txt`、`_verify_*.txt`、`_probe_*.java` | 含本机绝对路径与构建日志 | 忽略根级 `_*` 草稿 |
| 文档/脚本里的本机绝对路径 | 暴露目录结构与本机用户名习惯 | 统一改为 `<repo>`、`$env:GRADLE_USER_HOME`、`$PSScriptRoot` 相对推导 |

> 注意：签名密码与 keystore 文件**从来没有进入过 git 历史**，因此不需要轮换。
> 如果哪天发现 `key.properties` 被误提交，正确做法是：立刻换 keystore + 换密码，并重发一版（旧包无法覆盖安装）。

---

## 四、每次提交前的固定动作

```powershell
# 1) 自检（有阻断项会返回 1，钩子会拦住提交）
powershell -ExecutionPolicy Bypass -File _tools\privacy_scan.ps1

# 2) 看一遍将要提交的文件清单（尤其确认没有 dist / 截图 / 草稿）
git status --short

# 3) 可选：历史级扫描（第一次托管前跑一次就够）
powershell -ExecutionPolicy Bypass -File _tools\privacy_scan.ps1 -CheckHistory
```

**绝对不要**：
- `git add -f` 强塞 `key.properties` / `*.jks` / `dist/`；
- 把签名密码写进 `build.gradle.kts` 或 CI 的 `env:` 明文；
- 把真实 NAS 域名 / 内网 IP 写进发布文档（用 `--dart-define` 或 Secrets）。

---

## 五、关于"隐私"本身（不只是密钥）

月记的隐私承诺是产品的一部分，托管到 GitHub 后依然成立，因为：

- **数据在手机上**：drift + SQLCipher，密钥由 Android Keystore 保护，仓库里没有任何用户记录；
- **联网只有一件事**：`/me/update` 里的检查更新，拉 `latest.json` + 下载 APK，不带任何健康字段；
- **无第三方 SDK**：`pubspec.yaml` 里没有统计/广告/推送云服务；
- **可核对**：任何人 clone 后都能看到 `INTERNET` 权限的唯一使用点是 `update_service.dart`。

如果要更严格的"零联网"：把 `android/app/src/main/AndroidManifest.xml` 里的 `INTERNET` 权限删掉、
`lib/features/update/` 整体移除，即可回到完全离线版本（代价是没有在线更新）。
