# Config Summary Format

After collecting all 8 answers (Q1-Q8), render this template with the answers
substituted in, and print it to the user. **Wait for `Y/n` before writing any
files** (per SKILL.md step 8). Only proceed on explicit `Y`; on `n` or any other
reply, discard all collected answers and exit cleanly.

## Template

```
📋 即将生成 harness-loop 约束系统：

**项目类型**: {{Q1}}
**方法论**: {{Q2}}{{Q2_sub_if_hybrid}}
**语言/技术栈**: {{Q3}}
**验证机制**: {{Q4_list_comma_separated}}
**卡死阈值**: {{Q5_or_default_3}}{{Q5_skip_note_if_not_applicable}}
**opencode 模型**: {{Q6}}
**学习档案目录**: {{Q7_action}}
**严格度**: {{Q8}}

**将创建的文件**:
{{created_files_as_bullets}}

**将修改的文件**:
{{modified_files_as_bullets}}

继续？(Y/n)
```

## Field rendering rules

- **`{{Q1}}`** — verbatim answer label (e.g., `应用代码项目`).
- **`{{Q2}}`** — verbatim answer label. If Hybrid, also render `{{Q2_sub_if_hybrid}}`
  as ` (组合: SDD + TDD)` listing the selected sub-methodologies in priority order.
- **`{{Q3}}`** — verbatim answer label (e.g., `Java`).
- **`{{Q4_list_comma_separated}}`** — join selected labels with `、`
  (e.g., `完成信号、外部验证、检查点`). At least one is guaranteed (multiSelect enforced).
- **`{{Q5_or_default_3}}`** — the integer chosen in Q5 if asked; otherwise the
  literal string `3 (默认)`. Append `{{Q5_skip_note_if_not_applicable}}` as
  ` (未启用卡死检测，仅文档化)` when Q4 does not include `卡死检测`.
- **`{{Q6}}`** — verbatim model ID string.
- **`{{Q7_action}}`** — `生成 concepts/ 目录` if 生成; `不生成 concepts/` if 不生成.
- **`{{Q8}}`** — `strict` or `advisory`.

## File list rules

**`{{created_files_as_bullets}}`** MUST enumerate every file the skill is about
to write. Compute the list from `decision-tree.md` §"Output path computation".
Use this format (one bullet per file, sorted by path):

```
- AGENTS.md
- TASKS.md
- state/iteration.md
- scripts/check-tests.sh
- scripts/check-consistency.sh
- .githooks/pre-commit
- .github/workflows/consistency.yml
- .opencode/config.json
- tests/AGENTS.md
- tests/pom.xml
- tests/src/test/java/FirstTest.java
- concepts/01-repo-as-truth.md
- ... (etc.)
```

**`{{modified_files_as_bullets}}`** lists files that already exist in the project
and will be patched/appended rather than created from scratch. These are listed
separately to make patches visible to the user before approval:

```
- README.md (追加 "How AI works on this repo" 段)
- .gitignore (追加 5 行语言特定忽略规则)
```

### Path display rules

- **Print user-facing output paths only** (e.g., `AGENTS.md`, `scripts/check-tests.sh`).
  Never print internal template paths (e.g., `templates/methodologies/tdd.md`)
  — the user does not need to see skill internals.
- For files inside subdirectories, use forward slashes regardless of OS
  (consistent with the rest of the skill's docs).
- If a path would be backed up (because it already exists), annotate it with
  ` (将备份为 <path>.bak)` so the user knows the existing file is preserved.

## Confirmation behavior

- **`Y` or `y` or empty Enter**: proceed with writes. Existing files are backed
  up to `<path>.bak` first per spec §5.6. New files are written directly.
- **`n` or `N`**: abort. Discard all collected answers. Print `已取消，未写入任何文件。`
  and exit. Do not write any file, even backups.
- **Any other reply**: re-print the prompt with `(请回答 Y 或 n)`. Do not abort;
  the user may have mistyped.

## Example render (Java + TDD + strict)

```
📋 即将生成 harness-loop 约束系统：

**项目类型**: 应用代码项目
**方法论**: TDD
**语言/技术栈**: Java
**验证机制**: 完成信号、外部验证、检查点
**卡死阈值**: 3 (默认) (未启用卡死检测，仅文档化)
**opencode 模型**: claude-sonnet-4-6
**学习档案目录**: 生成 concepts/ 目录
**严格度**: strict

**将创建的文件**:
- AGENTS.md
- TASKS.md
- state/iteration.md
- scripts/check-promise.sh
- scripts/check-tests.sh
- scripts/check-consistency.sh
- .githooks/pre-commit
- .github/workflows/consistency.yml
- .opencode/config.json
- tests/AGENTS.md
- tests/pom.xml
- tests/src/test/java/FirstTest.java
- concepts/01-repo-as-truth.md
- concepts/02-map-not-manual.md
- concepts/03-mechanical-enforcement.md
- concepts/04-agent-readability.md
- concepts/05-throughput-merges.md
- concepts/06-entropy-gc.md

**将修改的文件**:
- README.md (追加 "How AI works on this repo" 段)
- .gitignore (追加 3 行 Java 特定忽略规则)

继续？(Y/n)
```
