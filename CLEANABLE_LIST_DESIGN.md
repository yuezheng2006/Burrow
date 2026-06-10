# 📋 可交互清理列表设计文档

## 🎯 设计目标

参考 Mole.app 的清理界面，实现：
1. ✅ **可勾选** - 每个分类可以选择是否清理
2. ✅ **可展开** - 点击查看详细信息
3. ✅ **进度显示** - 当前大小 / 最大可清理
4. ✅ **底部统计** - 永久清理总计

---

## 🎨 界面布局

```
┌─────────────────────────────────────────┐
│ 准备开始清理              已选 5/7      │
├─────────────────────────────────────────┤
│                                         │
│ ☑️ 📱 App 缓存   已选 101/101           │
│     应用临时文件...     2.6GB / 4.06GB  │
│     ˅                                   │
│                                         │
│ ☑️ ⚙️ 系统缓存   已选 5/5               │
│     macOS 系统缓存...   1.28GB         │
│     ˅                                   │
│                                         │
│ ☑️ 📝 日志       已选 5/5               │
│     诊断日志...         57 KB           │
│     ˅                                   │
│                                         │
│ ☐ 🔧 开发工具    已选 2/37              │
│     Xcode/SwiftPM...    4.4MB / 19.8GB │
│     ˅                                   │
│                                         │
├─────────────────────────────────────────┤
│ 永久清理                                │
│ 4.43 GB                                 │
└─────────────────────────────────────────┘
```

---

## 🔧 组件结构

### 1. CleanableCategory（数据模型）
```swift
struct CleanableCategory: Identifiable {
    let id: UUID
    let icon: String        // SF Symbol
    let title: String       // "App 缓存"
    let subtitle: String    // "已选 101/101"
    let currentSize: String // "2.6 GB"
    let maxSize: String     // "4.06 GB"
    let progress: Double    // 0.0 - 1.0
    var isSelected: Bool    // 是否勾选
    var details: [String]   // 详细信息列表
}
```

### 2. CleanableItemsView（容器）
- 顶部：标题 + 已选统计
- 中间：可滚动列表
- 底部：永久清理总计

### 3. CleanableCategoryRow（单行）
- 左侧：勾选框
- 图标 + 标题 + 副标题
- 右侧：大小信息
- 展开按钮（chevron）
- 展开内容（详细列表）

### 4. CheckboxView（勾选框）
- 未选：空框
- 已选：✓ 图标 + 弹性动画

---

## 🎬 交互动画

### 勾选动画
```swift
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
    isSelected.toggle()
}
```
**效果**：弹性勾选，✓ 从小到大

### 展开动画
```swift
withAnimation(.easeInOut(duration: 0.2)) {
    isExpanded.toggle()
}
```
**效果**：展开/收起流畅

### Chevron 旋转
```swift
.rotationEffect(.degrees(isExpanded ? 180 : 0))
```

---

## 📊 数据流

### 1. 扫描阶段
```
Mole CLI 输出
    ↓
parseTaskReport()
    ↓
TaskGroup + TaskItem
    ↓
转换为 CleanableCategory
    ↓
显示在列表中
```

### 2. 清理阶段
```
用户勾选分类
    ↓
计算总大小
    ↓
显示在底部
    ↓
点击清理按钮
    ↓
只清理已勾选的分类
```

---

## 🎨 视觉规格

### 颜色
- 未选：透明背景 + hairline 边框
- 已选：accent 8% 背景 + accent 30% 边框
- 文字：textPrimary / textSecondary / textTertiary

### 字体
- 标题：Sans 13 semibold
- 副标题：Sans 11 regular
- 大小：Mono 12/10 (加粗/普通)

### 间距
- 行间距：8px
- 内边距：horizontal 14px, vertical 12px
- 圆角：10px

### 图标大小
- 分类图标：18px
- Checkbox：20x20
- Chevron：10px

---

## 🔄 与现有架构集成

### 需要修改的文件

1. **CleanView.swift**
   - 添加状态：`@State private var cleanableCategories: [CleanableCategory] = []`
   - 解析结果时转换为 CleanableCategory
   - 完成后显示 CleanableItemsView

2. **TaskReport.swift**
   - 添加辅助函数：`parseToCleanableCategories()`
   - 从 Mole 输出提取：icon, title, sizes, details

3. **L10n.swift**
   - 添加字符串：readyToClean, selectedItems, permanentClean

---

## 🧪 测试点

### 功能测试
- [ ] 勾选/取消勾选正常
- [ ] 展开/收起流畅
- [ ] 底部总计实时更新
- [ ] 大小解析正确（GB/MB/KB）
- [ ] 默认全选

### 视觉测试
- [ ] 勾选动画弹性
- [ ] Chevron 旋转
- [ ] 颜色对比度
- [ ] 文字对齐

### 交互测试
- [ ] 点击行展开
- [ ] 点击 checkbox 勾选
- [ ] 滚动流畅
- [ ] 响应式布局

---

## 💡 后续优化

### v0.0.2
- [ ] **批量操作**：全选/全不选按钮
- [ ] **搜索过滤**：按名称搜索分类
- [ ] **排序**：按大小/名称排序
- [ ] **预估时间**：显示清理预计耗时

### v0.1.0
- [ ] **自定义规则**：用户可以添加自定义清理路径
- [ ] **安全提示**：某些分类显示警告（如开发工具）
- [ ] **历史记录**：记录每次清理的内容
- [ ] **撤销功能**：清理后可以恢复（如果可能）

---

## 📝 实现状态

- ✅ 数据模型（CleanableCategory）
- ✅ 容器视图（CleanableItemsView）
- ✅ 单行组件（CleanableCategoryRow）
- ✅ 勾选框（CheckboxView）
- ✅ 动画效果
- ⏳ 集成到 CleanView（下一步）
- ⏳ 数据解析器（下一步）

---

当前已完成组件实现，下一步需要：
1. 从 Mole CLI 输出解析为 CleanableCategory
2. 集成到 CleanView 的完成状态
3. 实现只清理已勾选项的逻辑
