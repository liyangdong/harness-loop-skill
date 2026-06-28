---
domain: Build and Release System
deepwiki: https://deepwiki.com/apache/lucene/11-build-and-release-system
status: verified
---

# Build and Release System

## 业务说明

构建与发布系统管理 Lucene 多模块 Gradle 项目的编译、依赖、测试、代码质量、文档与发布流程。Gradle Wrapper（`gradlew`/`gradlew.bat`）提供一致的构建环境；`settings.gradle` 定义所有项目模块；`gradle/libs.versions.toml` 集中化版本声明；`dev-tools/scripts/` 下的 Python 脚本（`buildAndPushRelease.py`、`releaseWizard.py`、`addVersion.py`）处理发布流程。

## 核心概念簇

### 构建配置（Gradle 多模块）
Gradle Wrapper 提供一致构建环境。`settings.gradle`（51-90 行）定义所有项目模块（core、analysis、spatial、queries、luke、demo、test-framework、backward-codecs 等）。`gradle/template.gradle.properties` 提供构建参数模板。

### 依赖管理
`gradle/libs.versions.toml` 集中化所有版本声明（依赖、插件），实现跨模块统一版本控制。各模块通过 Gradle 版本目录引用。

### 测试基础设施
项目有完整的测试基础设施（`test-framework` 模块、`AssertingLeafReader` 等测试工具），Jenkins CI 运行 nightly 构建、测试、javadoc 与代码覆盖率。

### 发布流程与版本管理
`dev-tools/scripts/` 下的 Python 脚本处理发布：`buildAndPushRelease.py` 构建并推送发布制品，`releaseWizard.py` 引导发布向导，`addVersion.py` 添加新版本。版本兼容性由 `Version.MIN_SUPPORTED_MAJOR` 控制。

## 代码锚点

| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| 构建配置 | `settings.gradle` | settings.gradle:51 | ✅ | Gradle 根项目→include 模块（core/analysis/queries/...） |
| 依赖管理 | `libs.versions.toml` | gradle/libs.versions.toml | ✅ | 各模块 build.gradle→libs.versions.toml（版本目录） |
| 发布流程 | `dev-tools/scripts/` | dev-tools/scripts/buildAndPushRelease.py | ✅ | releaseWizard→buildAndPushRelease→addVersion |

## 漂移标记

- orphan：无
- blindspot：无（本领域为文件级锚点，均经存在性验证为 RESOLVED）

## 交叉链接

（无）
