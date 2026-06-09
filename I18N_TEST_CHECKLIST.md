# i18n 翻译测试清单

## 📋 测试步骤

### 1. 清理功能翻译测试

**操作流程**：
1. 确保语言设置为"中文"（右上角蓝色按钮显示"中文"）
2. 点击顶部"清理"标签
3. 点击"预览"按钮
4. 等待扫描完成，检查以下内容：

**应该显示的中文**：
- ✅ "概览" (SUMMARY)
- ✅ "系统" (SYSTEM)
- ✅ "用户数据" (USER ESSENTIALS)
- ✅ "已启用系统级清理，管理员权限激活"
- ✅ "用户级清理将自动进行"
- ✅ "白名单：21个核心规则生效"
- ✅ "系统崩溃报告"
- ✅ "系统日志"
- ✅ "可重建的 GPU 缓存"
- ✅ "系统诊断日志"
- ✅ "电源日志"
- ✅ "无需清理"
- ✅ "用户应用缓存 91项，445.1MB"
- ✅ "用户应用日志 12项，13KB"

### 2. 优化功能翻译测试

**操作流程**：
1. 点击顶部"优化"标签
2. 点击"预览"按钮
3. 检查维护任务项是否正确翻译

**应该显示的中文**：
- ✅ 各类维护项的中文描述
- ✅ 状态提示为中文

### 3. 英文模式验证

**操作流程**：
1. 点击右上角"EN"切换到英文
2. 重新执行清理预览
3. 确认文本保持英文原样

---

## 🔍 对比截图

### 修复前
- "SUMMARY" → ❌ 显示为英文
- "System logs" → ❌ 显示为英文
- "User app cache" → ❌ 显示为英文

### 修复后
- "SUMMARY" → ✅ "概览"
- "System logs" → ✅ "系统日志"
- "User app cache" → ✅ "用户应用缓存"

---

## 📝 翻译覆盖清单

| 英文原文 | 中文翻译 | 出现位置 |
|---------|---------|---------|
| SUMMARY | 概览 | 清理/优化结果顶部 |
| SYSTEM | 系统 | 清理结果分类 |
| USER ESSENTIALS | 用户数据 | 清理结果分类 |
| BROWSER | 浏览器 | 清理结果分类 |
| DEVELOPER | 开发工具 | 清理结果分类 |
| APPLICATIONS | 应用程序 | 清理结果分类 |
| System-level cleanup enabled | 已启用系统级清理 | 概览部分 |
| User-level cleanup will proceed | 用户级清理将自动进行 | 概览部分 |
| Whitelist | 白名单 | 概览部分 |
| core patterns active | 个核心规则生效 | 概览部分 |
| System crash reports | 系统崩溃报告 | 系统分类 |
| System logs | 系统日志 | 系统分类 |
| Accessible rebuildable GPU caches | 可重建的 GPU 缓存 | 系统分类 |
| System diagnostic logs | 系统诊断日志 | 系统分类 |
| Power logs | 电源日志 | 系统分类 |
| Nothing to clean | 无需清理 | 各分类 |
| User app cache | 用户应用缓存 | 用户数据分类 |
| User app logs | 用户应用日志 | 用户数据分类 |
| items | 项 | 数量单位 |

---

## ✅ 验收标准

- [ ] 中文模式下，所有清理结果都显示中文
- [ ] 英文模式下，保持原始英文输出
- [ ] 翻译准确、自然
- [ ] 无乱码或显示错误
- [ ] 数字、单位正确显示

---

## 🐛 问题排查

**如果还有英文显示**：
1. 检查是否真的在中文模式（右上角显示"中文"蓝色按钮）
2. 尝试切换到英文再切回中文
3. 重启应用
4. 检查是否是 Mole CLI 的新输出格式（需要添加新的翻译规则）

**如果翻译不完整**：
- 复制未翻译的英文文本
- 在 `Sources/L10n.swift` 的 `translateMoleString` 函数中添加翻译对
- 重新编译

---

## 🚀 快速测试命令

```bash
# 1. 重启应用
killall Fuchen 2>/dev/null
open build/Fuchen.app

# 2. 或运行 release 版本
./scripts/release-swiftc.sh
open build/Fuchen.app

# 3. 测试 Mole CLI 原始输出
mo clean --dry-run
```

---

当前应用已启动，请开始测试中文翻译！
