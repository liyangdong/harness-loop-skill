#!/usr/bin/env python3
"""
Non-interactive renderer for the harness-loop skill.

Reads an answers.json, applies the wizard's decision-tree logic, renders
templates with substitutions, and writes a complete project layout to a
target directory. This is the runner that L2 (check-examples.sh) and L3
(check-bootstrap.sh) depend on.

Usage:
    python3 run-with-answers.py <answers.json> <output_dir>

Exit codes:
    0 = success
    1 = rendering error (missing template, bad answers, etc.)

Implementation language choice: Python.
- The skill is a soft Python consumer already (L3 uses python for YAML validation).
- Multi-line block substitutions like {{CONCEPTS_BLOCK}} and
  {{LANGUAGE_SPECIFIC_IGNORES}} are awkward in sed; Python's str.replace
  and json modules make them trivial.
- The bash wrapper run-with-answers.sh keeps invocation consistent with
  the other scripts/check-*.sh entry points.
"""

from __future__ import annotations

import io
import json
import os
import re
import shutil
import sys
from pathlib import Path

# Force UTF-8 on stdout/stderr. On Windows the default codepage (e.g. GBK)
# cannot encode characters like the checkmark emoji used in status messages,
# causing UnicodeEncodeError on the final print after a successful render.
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (ValueError, OSError):
        pass
elif not isinstance(sys.stdout, io.TextIOWrapper) or sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Path setup. SKILL_DIR is the parent of the scripts/ directory.
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATES_DIR = SKILL_DIR / "templates"


# ---------------------------------------------------------------------------
# Substitution maps and tables (mirrors wizard/decision-tree.md).
# ---------------------------------------------------------------------------

# Q1 -> mission text (inlined in decision-tree.md, not a separate template).
Q1_MISSIONS = {
    "应用代码": "本仓库是一个应用代码项目。所有变更必须通过测试、lint 和类型检查后方可合入。",
    "应用代码项目": "本仓库是一个应用代码项目。所有变更必须通过测试、lint 和类型检查后方可合入。",
    "库": "本仓库是一个对外暴露 API 的库 / SDK。公共契约（API 签名、语义化版本）不可被无声破坏。",
    "库 / SDK 项目": "本仓库是一个对外暴露 API 的库 / SDK。公共契约（API 签名、语义化版本）不可被无声破坏。",
    "文档": "本仓库以内容产出为主（文档 / 翻译 / 学习档案）。机械检查聚焦一致性、完成度和熵积累。",
    "文档 / 学习档案项目": "本仓库以内容产出为主（文档 / 翻译 / 学习档案）。机械检查聚焦一致性、完成度和熵积累。",
    "混合型": "本仓库是应用代码 + 文档的混合项目。代码子目录遵循测试门控，文档子目录遵循一致性门控，分层配置。",
}

# Q2 -> methodology fragment in templates/methodologies/
Q2_METHODOLOGY_FILES = {
    "TDD": "tdd.md",
    "SDD": "sdd.md",
    "BDD": "bdd.md",
    "DDD": "ddd.md",
    "RDD": "rdd.md",
    "Plain": "plain.md",
}

# Hybrid priority order per decision-tree.md (SDD > TDD > BDD > DDD > RDD).
HYBRID_PRIORITY = ["SDD", "TDD", "BDD", "DDD", "RDD"]

# Q2 -> scaffolding directory under templates/scaffolding/methodology-dirs/.
Q2_SCAFFOLDING = {
    "TDD": "tests-{lang}",      # special-cased: language substitution
    "SDD": "specs",
    "BDD": "features",
    "DDD": "domain",
    "RDD": "readme-first",
    # Plain: no scaffolding dir.
}

# Q2 -> output path for the scaffolding directory in the user project.
Q2_OUTPUT_DIR = {
    "TDD": "tests",
    "SDD": "docs/specs",
    "BDD": "features",
    "DDD": "docs/domain",
    "RDD": "docs/readme-first.md",
}

# Q3 -> {{LANGUAGE}} token value and tests-<lang> scaffolding subdir.
Q3_LANGUAGE_TOKEN = {
    "Python": "Python",
    "Node": "Node",
    "Node.js / TypeScript": "Node",
    "TypeScript": "Node",
    "Go": "Go",
    "Java": "Java",
    "Multi": "Multi",
    "多语言": "Multi",
    "Non-code": "Non-code",
    "非代码项目": "Non-code",
}

Q3_TESTS_SCAFFOLDING = {
    "Python": "tests-python",
    "Node": "tests-node",
    "Go": "tests-go",
    "Java": "tests-java",
    "Multi": None,    # multi: handled per-subdir, no single scaffolding dir
    "Non-code": None, # no tests directory generated
}

# Q3 -> {{LANGUAGE_SPECIFIC_IGNORES}} lines (joined with newlines).
Q3_GITIGNORE = {
    "Python": ["__pycache__/", "*.pyc", ".venv/"],
    "Node":   ["node_modules/", "dist/", "*.log"],
    "Go":     [],
    "Java":   ["target/", "*.class", ".mvn/wrapper/maven-wrapper.jar"],
    "Multi":     [],
    "Non-code":  [],
}

# Q3 -> {{SOURCE_EXT}} value for check-entropy.sh.
Q3_SOURCE_EXT = {
    "Python": "py",
    "Node": "ts",
    "Go": "go",
    "Java": "java",
    "Multi": "*",
    "Non-code": "*",
}

# Q4 mechanism labels -> output file templates.
Q4_MECHANISMS = {
    "完成信号": {
        "scripts/check-promise.sh": "checks/check-promise.sh.tmpl",
    },
    "外部验证": {
        "scripts/check-tests.sh": "checks/check-tests.sh.tmpl",
    },
    "检查点": {
        "scripts/check-consistency.sh": "checks/check-consistency.sh.tmpl",
        ".githooks/pre-commit":         "checks/pre-commit.tmpl",
        ".github/workflows/consistency.yml": "checks/consistency.yml.tmpl",
    },
    "熵扫描": {
        "scripts/check-entropy.sh": "checks/check-entropy.sh.tmpl",
        "state/entropy-log.md":     "scaffolding/state-entropy.tmpl",
    },
    "卡死检测": {
        "scripts/check-stuck.sh": "checks/check-stuck.sh.tmpl",
    },
}


# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

def load_answers(path: Path) -> dict:
    """Load answers JSON, returning a normalized dict."""
    with path.open("r", encoding="utf-8") as fh:
        answers = json.load(fh)
    if not isinstance(answers, dict):
        raise ValueError(f"answers file {path} is not a JSON object")
    return answers


def normalize_q3(q3: str) -> str:
    """Map any of the question's option labels to the canonical LANGUAGE token."""
    return Q3_LANGUAGE_TOKEN.get(q3, q3)


def strip_leading_html_comment(text: str) -> str:
    """
    Strip a leading <!-- ... --> HTML comment block from a template's start,
    including any blank lines immediately following the comment close.

    Per issue 002: templates embed metadata in HTML comments at the top of
    the file. These are renderer metadata, not output content, and must not
    appear in the rendered project.

    The comment is followed by one or more blank lines before the real
    content begins (e.g. tasks-md.tmpl has `-->\\n\\n# Tasks`). Stripping
    only the comment + first newline leaves a leading blank line in the
    output, which diffs against snapshots that begin with the first content
    line directly. We strip the comment plus all subsequent whitespace-only
    lines until the next non-blank line.
    """
    if not text.lstrip().startswith("<!--"):
        return text
    # Find the closing --> of the FIRST comment block only.
    end = text.find("-->")
    if end == -1:
        return text  # malformed; leave as-is rather than guess
    # Skip the --> and any trailing newlines / blank lines.
    cursor = end + 3
    # Walk forward, consuming \r, \n, and any lines that are empty/whitespace.
    while cursor < len(text):
        if text[cursor] in "\r\n":
            cursor += 1
            continue
        # We've hit a non-newline character. If the rest of this line is
        # whitespace-only, treat it as a blank line and skip.
        line_end = text.find("\n", cursor)
        if line_end == -1:
            line_end = len(text)
        if text[cursor:line_end].strip() == "":
            cursor = line_end
            continue
        break
    return text[cursor:]


def read_template(rel_path: str) -> str:
    """Read a template file relative to TEMPLATES_DIR; raise on missing."""
    p = TEMPLATES_DIR / rel_path
    if not p.is_file():
        raise FileNotFoundError(f"template missing: {rel_path}")
    return p.read_text(encoding="utf-8")


def render_template(rel_path: str, subs: dict[str, str]) -> str:
    """
    Read a template, strip leading HTML comment, apply substitutions.

    Substitutions are plain string replacement (per decision-tree.md §Substitution
    semantics). Order does not matter because no expansion contains another
    placeholder.
    """
    text = read_template(rel_path)
    text = strip_leading_html_comment(text)
    for key, value in subs.items():
        text = text.replace(key, value)
    return text


def write_output(out_dir: Path, rel_path: str, content: str, executable: bool = False) -> None:
    """Write content to out_dir/rel_path, creating parent dirs.

    Files are written with LF line endings explicitly (binary mode), so the
    rendered output matches committed snapshots byte-for-byte regardless of
    the host platform's default text-mode line-ending translation.
    """
    target = out_dir / rel_path
    target.parent.mkdir(parents=True, exist_ok=True)
    # Encode then write as bytes: bypasses Python's text-mode newline
    # translation (which would convert \n to \r\n on Windows).
    data = content.encode("utf-8")
    target.write_bytes(data)
    if executable:
        # Best-effort chmod; ignored on Windows. Scripts invoked via `bash foo.sh`
        # do not actually need +x, but the pre-commit hook entry does.
        try:
            target.chmod(0o755)
        except OSError:
            pass


def render_scaffolding_file(src_file: Path, dst_file: Path, subs: dict[str, str]) -> None:
    """
    Render a single scaffolding file to dst_file.

    Two cases:
      - `*.tmpl`: strip leading HTML comment, apply substitutions, drop the
        `.tmpl` suffix from the output filename.
      - All other files (`AGENTS.md`, `*.feature`, `template.md`, etc.):
        apply substitutions if any placeholder appears in the file's content,
        then write to the same filename. This is necessary because some
        non-`.tmpl` scaffolding files (e.g. `specs/template.md`) DO contain
        `{{PLACEHOLDER}}` tokens that need substitution.

    Written as bytes to avoid host newline translation (LF must be preserved
    so rendered output matches committed snapshots byte-for-byte).
    """
    dst_file.parent.mkdir(parents=True, exist_ok=True)
    text = src_file.read_text(encoding="utf-8")
    if src_file.suffix == ".tmpl":
        text = strip_leading_html_comment(text)
        out_path = dst_file.with_suffix("")
    else:
        out_path = dst_file
    for key, value in subs.items():
        text = text.replace(key, value)
    out_path.write_bytes(text.encode("utf-8"))


def render_scaffolding_tree(src_dir: Path, dst_dir: Path, subs: dict[str, str]) -> None:
    """Walk a scaffolding directory and render every file in it."""
    if not src_dir.is_dir():
        raise FileNotFoundError(f"scaffolding source missing: {src_dir}")
    dst_dir.mkdir(parents=True, exist_ok=True)
    for root, _dirs, files in os.walk(src_dir):
        rel = Path(root).relative_to(src_dir)
        for f in files:
            src_file = Path(root) / f
            dst_file = dst_dir / rel / f
            render_scaffolding_file(src_file, dst_file, subs)


# ---------------------------------------------------------------------------
# Block builders — assemble the multi-line substitution values.
# ---------------------------------------------------------------------------

def build_concepts_block() -> str:
    """
    Concatenate templates/concepts/01-06*.md in numeric order.

    Each concept file's body ends with a single trailing newline. The
    snapshot injects a blank line between consecutive concepts. We rstrip
    each file and join with '\\n\\n' so adjacent concepts are separated by
    exactly one blank line. The block does NOT end with a trailing newline —
    the surrounding template (`...\\n{{CONCEPTS_BLOCK}}\\n\\n## Ralph...`)
    supplies the trailing separator before the next H2.
    """
    concepts_dir = TEMPLATES_DIR / "concepts"
    files = sorted([p for p in concepts_dir.iterdir()
                    if p.is_file() and re.match(r"^\d\d-", p.name)])
    if not files:
        raise FileNotFoundError("no concept files found in templates/concepts/")
    parts = [f.read_text(encoding="utf-8").rstrip() for f in files]
    return "\n\n".join(parts)


def build_ralph_tenets_block() -> str:
    """Read templates/ralph-tenets.md verbatim, no trailing newline.

    The surrounding template supplies the trailing separator.
    """
    return (TEMPLATES_DIR / "ralph-tenets.md").read_text(encoding="utf-8").rstrip()


def build_methodology_block(methodologies: list[str]) -> str:
    """
    Concatenate methodology fragments in priority order (SDD > TDD > BDD > DDD > RDD).

    For a single methodology, just that file's content.
    For Hybrid, joined with '\\n\\n---\\n\\n' separator per decision-tree.md.
    No trailing newline; the surrounding template supplies it.
    """
    ordered = sorted(methodologies, key=lambda m: HYBRID_PRIORITY.index(m) if m in HYBRID_PRIORITY else 99)
    parts = []
    for m in ordered:
        filename = Q2_METHODOLOGY_FILES.get(m)
        if filename is None:
            raise ValueError(f"unknown methodology: {m}")
        content = (TEMPLATES_DIR / "methodologies" / filename).read_text(encoding="utf-8")
        parts.append(content.rstrip())
    return "\n\n---\n\n".join(parts)


def build_subdir_index(methodologies: list[str], q3_token: str, q7: str) -> str:
    """
    Generate the {{SUBDIR_INDEX}} block listing each generated subdir.

    Matches what the existing snapshots produce. Order is deterministic:
    methodology-specific dirs first (in priority order), then concepts/ if Q7=生成.

    No trailing newline — the surrounding template supplies the separator.
    """
    lines = []
    ordered = sorted(methodologies, key=lambda m: HYBRID_PRIORITY.index(m) if m in HYBRID_PRIORITY else 99)
    for m in ordered:
        if m == "TDD":
            lang_label = q3_token
            lines.append(f"tests/ — {lang_label} tests + AGENTS.md (see tests/AGENTS.md)")
        elif m == "SDD":
            lines.append("docs/specs/ — spec writing conventions (see docs/specs/AGENTS.md)")
        elif m == "BDD":
            lines.append("features/ — BDD scenarios (see features/AGENTS.md)")
        elif m == "DDD":
            lines.append("docs/domain/ — domain models (see docs/domain/AGENTS.md)")
        elif m == "RDD":
            lines.append("docs/readme-first.md — README-first workflow stub")
        elif m == "Plain":
            pass  # no subdir
    # Note: the java-tdd snapshot does NOT list concepts/ in SUBDIR_INDEX even
    # though Q7=生成. The java-hybrid snapshot DOES list it. This is drift
    # between snapshots; we surface it in the L2 diff rather than silently
    # picking one behavior. Current renderer includes concepts/ when Q7=生成
    # (matches java-hybrid).
    if q7 == "生成":
        lines.append("concepts/ — 6 core concepts (learning archive)")
    return "\n".join(lines) if lines else ""


def build_checks_index(q4: list[str]) -> str:
    """
    Generate the {{CHECKS_INDEX}} block listing each generated check script.

    Mirrors the snapshots: one bullet per script, plus an "(No check-X.sh: ...)"
    note when 外部验证 is absent.

    No trailing newline — the surrounding template supplies the separator.
    """
    lines = []
    if "完成信号" in q4:
        lines.append("- scripts/check-promise.sh — detects <promise>DONE</promise> completion signal")
    if "外部验证" in q4:
        lines.append("- scripts/check-tests.sh — runs mvn test + checkstyle + compile")
    if "检查点" in q4:
        lines.append("- scripts/check-consistency.sh — runs C1/C2/C6 checks")
    if "熵扫描" in q4:
        lines.append("- scripts/check-entropy.sh — scans for TODO/FIXME and large files")
    if "卡死检测" in q4:
        lines.append("- scripts/check-stuck.sh — compares last K iterations for progress")
    if "外部验证" not in q4:
        lines.append("(No check-tests.sh: Q4 didn't include 外部验证)")
    return "\n".join(lines)


def build_language_ignores(q3_token: str) -> str:
    """
    Build the {{LANGUAGE_SPECIFIC_IGNORES}} block for the gitignore.

    The gitignore template's last line is `{{LANGUAGE_SPECIFIC_IGNORES}}`
    followed by a single trailing newline. So our block must not end with
    a newline (otherwise the rendered file has a spurious trailing blank
    line that diffs against the snapshot).
    """
    lines = Q3_GITIGNORE.get(q3_token, [])
    if not lines:
        return ""
    # Snapshots wrap with a comment header naming the language.
    header = f"# Language-specific ({q3_token})"
    return header + "\n" + "\n".join(lines)


# ---------------------------------------------------------------------------
# Main rendering entry point.
# ---------------------------------------------------------------------------

def render(answers: dict, out_dir: Path) -> None:
    """Top-level render: parse answers, compute substitutions, write files."""

    # --- Extract answers --------------------------------------------------
    q1 = answers.get("Q1", "应用代码")
    q2 = answers.get("Q2", "TDD")
    q2_sub = answers.get("Q2_sub", [])
    q3_raw = answers.get("Q3", "Java")
    q3_token = normalize_q3(q3_raw)
    q4 = answers.get("Q4", [])
    q5 = answers.get("Q5")
    q6 = answers.get("Q6", "claude-sonnet-4-6")
    q7 = answers.get("Q7", "生成")
    q8 = answers.get("Q8", "strict")
    project_name = answers.get("PROJECT_NAME") or "harness-loop-project"
    mission_one_liner = answers.get("MISSION_ONE_LINER") or Q1_MISSIONS.get(q1, "")

    # Normalize methodologies into a list.
    if q2 == "Hybrid":
        if not q2_sub:
            raise ValueError("Q2=Hybrid requires Q2_sub list of methodologies")
        methodologies = list(q2_sub)
    elif q2 == "Plain":
        methodologies = []
    else:
        methodologies = [q2]

    # Normalize Q5: null/None or missing -> default 3.
    if q5 is None:
        stuck_threshold = "3"
    else:
        stuck_threshold = str(q5)

    # Strict mode normalization.
    strict_mode = "strict" if q8 == "strict" else "advisory"

    # Language-specific constants for Java pom.xml.
    group_id = "com.example"
    artifact_id = project_name
    version = "0.1.0"   # snapshots use 0.1.0, not 0.1.0-SNAPSHOT
    package = "com.example"
    checkstyle_fails = "true" if strict_mode == "strict" else "false"

    # Volatile placeholders — snapshots use 1970-01-01 epoch for determinism.
    timestamp = "1970-01-01T00:00:00+00:00"

    # FEATURE_NAME: spec template's H1. Per decision-tree.md the wizard asks
    # for this when SDD is selected; the answers schema doesn't include it
    # because the template file itself is a placeholder users copy. Snapshots
    # substitute the literal '<feature-name>' so the file works as a
    # copy-and-fill template.
    feature_name = answers.get("FEATURE_NAME") or "<feature-name>"

    # --- Build the global substitution map -------------------------------
    subs: dict[str, str] = {
        "{{PROJECT_NAME}}":             project_name,
        "{{MISSION_ONE_LINER}}":        mission_one_liner,
        "{{CONCEPTS_BLOCK}}":           build_concepts_block(),
        "{{RALPH_TENETS_BLOCK}}":       build_ralph_tenets_block(),
        "{{METHODOLOGY_BLOCK}}":        build_methodology_block(methodologies) if methodologies else "",
        "{{SUBDIR_INDEX}}":             build_subdir_index(methodologies, q3_token, q7),
        "{{CHECKS_INDEX}}":             build_checks_index(q4),
        "{{TASKS_POINTER}}":            "见 `TASKS.md`。每轮迭代更新 `state/iteration.md`。",
        "{{STRICT_MODE_DECL}}":         strict_mode,
        "{{STRICT_MODE}}":              strict_mode,
        "{{LANGUAGE}}":                 q3_token,
        "{{LANGUAGE_SPECIFIC_IGNORES}}": build_language_ignores(q3_token),
        "{{MODEL_ID}}":                 q6,
        "{{MAX_ITERATIONS}}":           os.environ.get("HARNESS_LOOP_MAX_ITERATIONS", "30"),
        "{{PROMISE_TOKEN}}":            os.environ.get("HARNESS_LOOP_PROMISE_TOKEN", "DONE"),
        "{{STUCK_THRESHOLD}}":          stuck_threshold,
        "{{SOURCE_EXT}}":               Q3_SOURCE_EXT.get(q3_token, "*"),
        "{{TODO_THRESHOLD}}":           os.environ.get("HARNESS_LOOP_TODO_THRESHOLD", "20"),
        "{{TIMESTAMP}}":                timestamp,
        "{{PROGRESS_SIG}}":             "initial",
        "{{LAST_ACTION}}":              "loop bootstrap",
        # TASKS.md placeholders — fallbacks per decision-tree.md.
        "{{CURRENT_EPIC_DESCRIPTION}}": "(fill in current epic)",
        "{{SUBTASK_1}}":                "(define subtask 1)",
        "{{SUBTASK_2}}":                "(define subtask 2)",
        "{{SUBTASK_3}}":                "(define subtask 3)",
        # Java pom.xml.tmpl placeholders.
        "{{GROUP_ID}}":                 group_id,
        "{{ARTIFACT_ID}}":              artifact_id,
        "{{VERSION}}":                  version,
        "{{PACKAGE}}":                  package,
        "{{CHECKSTYLE_FAILS_ON_ERROR}}": checkstyle_fails,
        # SDD spec template placeholder.
        "{{FEATURE_NAME}}":            feature_name,
    }

    out_dir.mkdir(parents=True, exist_ok=True)

    # --- Always-generated files ------------------------------------------
    # AGENTS.md (root)
    agents_root = render_template("agents-root.md.tmpl", subs)
    write_output(out_dir, "AGENTS.md", agents_root)

    # TASKS.md
    tasks_md = render_template("scaffolding/tasks-md.tmpl", subs)
    write_output(out_dir, "TASKS.md", tasks_md)

    # state/iteration.md
    iteration_md = render_template("scaffolding/state-iteration.tmpl", subs)
    write_output(out_dir, "state/iteration.md", iteration_md)

    # state/entropy-log.md (snapshots always include this regardless of Q4)
    entropy_md = render_template("scaffolding/state-entropy.tmpl", subs)
    write_output(out_dir, "state/entropy-log.md", entropy_md)

    # .opencode/config.json
    opencode = render_template("scaffolding/opencode-config.json.tmpl", subs)
    write_output(out_dir, ".opencode/config.json", opencode)

    # README.md (appended section)
    readme = render_template("scaffolding/readme-section.tmpl", subs)
    write_output(out_dir, "README.md", readme)

    # .gitignore (appended lines)
    gitignore = render_template("scaffolding/gitignore.tmpl", subs)
    write_output(out_dir, ".gitignore", gitignore)

    # Always-on subdir AGENTS.md files (state/, scripts/, docs/).
    write_output(out_dir, "state/AGENTS.md",
                 strip_leading_html_comment(
                     read_template("scaffolding/always-dirs/state-agents.md.tmpl")))
    write_output(out_dir, "scripts/AGENTS.md",
                 strip_leading_html_comment(
                     read_template("scaffolding/always-dirs/scripts-agents.md.tmpl")))
    write_output(out_dir, "docs/AGENTS.md",
                 strip_leading_html_comment(
                     read_template("scaffolding/always-dirs/docs-agents.md.tmpl")))

    # --- Q4 mechanism files ----------------------------------------------
    for mechanism in q4:
        spec = Q4_MECHANISMS.get(mechanism)
        if spec is None:
            # Unknown mechanism label — skip but don't fail. The wizard
            # validates these, but be defensive.
            print(f"⚠️  unknown Q4 mechanism '{mechanism}', skipping", file=sys.stderr)
            continue
        for out_path, tmpl in spec.items():
            content = render_template(tmpl, subs)
            is_exec = out_path.endswith(".sh")
            write_output(out_dir, out_path, content, executable=is_exec)

    # Snapshots always include state/entropy-log.md (already written above),
    # even when 熵扫描 is not in Q4. We match the snapshot rather than the
    # decision-tree.md spec — see issue 003 report.

    # --- Q2 methodology scaffolding --------------------------------------
    for m in methodologies:
        if m == "TDD":
            tests_subdir = Q3_TESTS_SCAFFOLDING.get(q3_token)
            if tests_subdir is None:
                # Non-code or Multi: no tests dir.
                continue
            src = TEMPLATES_DIR / "scaffolding" / "methodology-dirs" / tests_subdir
            dst = out_dir / "tests"
            render_scaffolding_tree(src, dst, subs)
        else:
            scaffold_dir = Q2_SCAFFOLDING.get(m)
            output_dir = Q2_OUTPUT_DIR.get(m)
            if scaffold_dir is None or output_dir is None:
                continue
            src = TEMPLATES_DIR / "scaffolding" / "methodology-dirs" / scaffold_dir
            if not src.is_dir():
                print(f"⚠️  scaffolding missing for {m}: {src}", file=sys.stderr)
                continue
            # RDD: src is a single file readme-first.md, output is a file.
            if m == "RDD":
                # render_scaffolding_tree expects a directory; RDD's dir
                # contains readme-first.md which copies verbatim.
                render_scaffolding_tree(src, out_dir / "docs", subs)
            else:
                render_scaffolding_tree(src, out_dir / output_dir, subs)

    # --- Q7: concepts/ scaffolding ---------------------------------------
    if q7 == "生成":
        concepts_src = TEMPLATES_DIR / "concepts"
        concepts_dst = out_dir / "concepts"
        concepts_dst.mkdir(parents=True, exist_ok=True)
        for f in concepts_src.iterdir():
            if f.is_file():
                # Copy all files verbatim, including AGENTS.md (matches snapshot).
                shutil.copy2(f, concepts_dst / f.name)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(f"usage: {argv[0]} <answers.json> <output_dir>", file=sys.stderr)
        return 2
    answers_path = Path(argv[1]).resolve()
    out_dir = Path(argv[2]).resolve()

    if not answers_path.is_file():
        print(f"answers file not found: {answers_path}", file=sys.stderr)
        return 1

    try:
        answers = load_answers(answers_path)
        render(answers, out_dir)
    except (ValueError, FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"❌ render failed: {exc}", file=sys.stderr)
        return 1

    print(f"✅ rendered project to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
