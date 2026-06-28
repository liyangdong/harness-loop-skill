| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| 构建配置 | `settings.gradle` | settings.gradle:51 | ✅ | Gradle 根项目→include 模块（core/analysis/queries/...） |
| 依赖管理 | `libs.versions.toml` | gradle/libs.versions.toml | ✅ | 各模块 build.gradle→libs.versions.toml（版本目录） |
| 发布流程 | `dev-tools/scripts/` | dev-tools/scripts/buildAndPushRelease.py | ✅ | releaseWizard→buildAndPushRelease→addVersion |
