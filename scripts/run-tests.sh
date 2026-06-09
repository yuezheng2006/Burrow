#!/bin/bash
#
# run-tests.sh
# 运行 Fuchen 测试套件
#
# 使用方法:
#   ./scripts/run-tests.sh              # 运行所有测试
#   ./scripts/run-tests.sh --coverage   # 运行测试并生成覆盖率报告
#   ./scripts/run-tests.sh --verbose    # 详细输出
#

set -e

cd "$(dirname "$0")/.."

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 解析参数
ENABLE_COVERAGE=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --coverage)
            ENABLE_COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --coverage    生成代码覆盖率报告"
            echo "  --verbose     显示详细测试输出"
            echo "  --help        显示此帮助信息"
            exit 0
            ;;
    esac
done

echo -e "${BLUE}=== Fuchen 测试套件 ===${NC}"
echo ""

# 检查 xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}✗ 错误: 未找到 xcodegen${NC}"
    echo "  请运行: brew install xcodegen"
    exit 1
fi

# 检查 mo
if ! command -v mo &> /dev/null; then
    echo -e "${YELLOW}⚠ 警告: 未找到 mole CLI (mo)${NC}"
    echo "  部分集成测试将被跳过"
    echo "  安装: brew install mole"
    echo ""
else
    echo -e "${GREEN}✓ Mole CLI 已安装:${NC} $(which mo)"
fi

# 生成项目文件（如果需要）
if [ ! -d "Fuchen.xcodeproj" ]; then
    echo -e "${BLUE}→ 生成 Xcode 项目...${NC}"
    xcodegen generate
    echo -e "${GREEN}✓ 项目已生成${NC}"
else
    echo -e "${GREEN}✓ Xcode 项目存在${NC}"
fi

echo ""
echo -e "${BLUE}→ 运行测试...${NC}"
echo ""

# 构建 xcodebuild 命令
XCODEBUILD_CMD="xcodebuild test \
    -project Fuchen.xcodeproj \
    -scheme Fuchen \
    -destination 'platform=macOS'"

if [ "$ENABLE_COVERAGE" = true ]; then
    XCODEBUILD_CMD="$XCODEBUILD_CMD -enableCodeCoverage YES"
fi

if [ "$VERBOSE" = false ]; then
    XCODEBUILD_CMD="$XCODEBUILD_CMD | xcpretty"
    if command -v xcpretty &> /dev/null; then
        XCODEBUILD_CMD="$XCODEBUILD_CMD"
    else
        XCODEBUILD_CMD="$XCODEBUILD_CMD 2>&1 | grep -E 'Test Suite|Test Case|passed|failed|error'"
    fi
fi

# 执行测试
if eval $XCODEBUILD_CMD; then
    echo ""
    echo -e "${GREEN}✓ 所有测试通过${NC}"

    # 如果启用了覆盖率，显示报告位置
    if [ "$ENABLE_COVERAGE" = true ]; then
        echo ""
        echo -e "${BLUE}→ 查找覆盖率报告...${NC}"

        DERIVED_DATA=$(xcodebuild -project Fuchen.xcodeproj -scheme Fuchen -showBuildSettings | grep -m 1 "BUILD_DIR" | awk '{print $3}' | sed 's/\/Build\/Products//')

        if [ -n "$DERIVED_DATA" ]; then
            COVERAGE_DIR="$DERIVED_DATA/Logs/Test"
            if [ -d "$COVERAGE_DIR" ]; then
                COVERAGE_FILE=$(find "$COVERAGE_DIR" -name "*.xcresult" | head -1)
                if [ -n "$COVERAGE_FILE" ]; then
                    echo -e "${GREEN}✓ 覆盖率报告:${NC} $COVERAGE_FILE"
                    echo ""
                    echo "查看报告:"
                    echo "  open $COVERAGE_FILE"
                    echo ""
                    echo "或使用命令行:"
                    echo "  xcrun xccov view --report $COVERAGE_FILE"
                fi
            fi
        fi
    fi

    exit 0
else
    echo ""
    echo -e "${RED}✗ 测试失败${NC}"
    exit 1
fi
