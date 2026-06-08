# Fuchen 签名与公证

要让用户**下载后直接双击安装、无需 `xattr -cr`**，Release 必须：

1. 用 **Developer ID Application** 证书签名（Hardened Runtime）
2. 提交 **Apple 公证（Notarization）** 并 staple

## 前置条件

- 加入 [Apple Developer Program](https://developer.apple.com/programs/)（$99/年）
- 在 Keychain 中创建 **Developer ID Application** 证书
- 为 notarytool 创建 [App 专用密码](https://appleid.apple.com)

## 本地发布（已签名证书在本机 Keychain）

```bash
export CODESIGN_IDENTITY="Developer ID Application: 你的名字 (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="XXXXXXXXXX"

./scripts/release-swiftc.sh
./scripts/sign-and-notarize.sh build/Fuchen.app dist/Fuchen-*.dmg dist/Fuchen-*.zip
```

## GitHub Actions 自动签名

在仓库 Settings → Secrets 配置：

| Secret | 说明 |
|---|---|
| `CODESIGN_CERT_P12` | Developer ID .p12 的 base64 |
| `CODESIGN_CERT_PASSWORD` | .p12 密码 |
| `APPLE_ID` | Apple ID |
| `APPLE_APP_PASSWORD` | App 专用密码 |
| `APPLE_TEAM_ID` | Team ID |

推送 tag `v*` 时 workflow 会构建、签名、公证并上传 Release。

## 当前限制

Agent/CI 环境若无上述证书，只能发布**带图标但未公证**的构建；用户仍需右键打开或 `xattr -cr`。
