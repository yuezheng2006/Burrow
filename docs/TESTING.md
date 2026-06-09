# 测试快速参考 (Testing Quick Reference)

## 🚀 快速开始

### 运行所有测试
```bash
./scripts/run-tests.sh
```

### 生成覆盖率报告
```bash
./scripts/run-tests.sh --coverage
```

### 详细输出
```bash
./scripts/run-tests.sh --verbose
```

## 📋 测试清单

### 新增测试文件 (5个)

1. **SamplerTests.swift** - 192 行
   - ✅ 采样器初始化
   - ✅ DB 水合逻辑
   - ✅ 定时器生命周期
   - ✅ 错误处理文档

2. **QueryServerTests.swift** - 225 行
   - ✅ 查询参数解析
   - ✅ HTTP 路由逻辑
   - ✅ JSON 端点验证
   - ✅ Loopback 安全检查

3. **DiskScannerTests.swift** - 266 行
   - ✅ JSON 解析
   - ✅ 大小排序
   - ✅ 文件类型识别
   - ✅ 日期格式处理

4. **AppListParserTests.swift** - 213 行
   - ✅ Mole JSON 解析
   - ✅ 应用列表合并
   - ✅ 大小单位转换
   - ✅ 边界条件

5. **MoleCLITests.swift** - 184 行
   - ✅ 可执行文件发现
   - ✅ 子进程管理
   - ✅ 超时处理
   - ✅ 输出捕获

## 📊 测试统计

- **总测试文件**: 14 个 (原有 9 + 新增 5)
- **总代码行数**: 1,846 行
- **测试用例数**: 100+ 个
- **覆盖率提升**: 45% → 70% (估算)

## 🧪 测试覆盖的关键组件

| 组件 | 测试文件 | 状态 |
|------|----------|------|
| Sampler | SamplerTests | ✅ 新增 |
| QueryServer | QueryServerTests | ✅ 新增 |
| MoleCLI | MoleCLITests | ✅ 新增 |
| DiskScanner | DiskScannerTests | ✅ 新增 |
| AppListParser | AppListParserTests | ✅ 新增 |
| DB | DBTests | ✅ 已有 |
| MCP | MCPTests | ✅ 已有 |
| Store | StoreTests | ✅ 已有 |
| Treemap | TreemapTests | ✅ 已有 |

## 🔧 故障排除

### 问题：测试失败 "mo not found"
**原因**: Mole CLI 未安装  
**解决**: `brew install mole`

### 问题：xcpretty not found
**原因**: 可选依赖未安装  
**解决**: `gem install xcpretty` 或忽略（脚本会回退）

### 问题：项目文件过期
**解决**: 
```bash
xcodegen generate
```

## 📚 相关文档

- [测试覆盖详细报告](./TEST_COVERAGE.md)
- [项目架构](../CLAUDE.md)
- [构建说明](../README.md)
