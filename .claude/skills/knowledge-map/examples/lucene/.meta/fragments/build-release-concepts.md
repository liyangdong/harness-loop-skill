### 构建配置（Gradle 多模块）
Gradle Wrapper 提供一致构建环境。`settings.gradle`（51-90 行）定义所有项目模块（core、analysis、spatial、queries、luke、demo、test-framework、backward-codecs 等）。`gradle/template.gradle.properties` 提供构建参数模板。

### 依赖管理
`gradle/libs.versions.toml` 集中化所有版本声明（依赖、插件），实现跨模块统一版本控制。各模块通过 Gradle 版本目录引用。

### 测试基础设施
项目有完整的测试基础设施（`test-framework` 模块、`AssertingLeafReader` 等测试工具），Jenkins CI 运行 nightly 构建、测试、javadoc 与代码覆盖率。

### 发布流程与版本管理
`dev-tools/scripts/` 下的 Python 脚本处理发布：`buildAndPushRelease.py` 构建并推送发布制品，`releaseWizard.py` 引导发布向导，`addVersion.py` 添加新版本。版本兼容性由 `Version.MIN_SUPPORTED_MAJOR` 控制。
