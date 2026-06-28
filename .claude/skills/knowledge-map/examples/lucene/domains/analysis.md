---
domain: Analysis System
deepwiki: https://deepwiki.com/apache/lucene/5-analysis-system
status: verified
---

# Analysis System

## 业务说明

分析系统在索引与搜索时处理文本，把原始文本转换成适合索引与搜索的 token 流。核心是 `Analyzer` 编排整个处理管线：可选的 `CharFilter` 链（tokenize 前预处理字符流）、一个 `Tokenizer`（切分为 token）、可选的 `TokenFilter` 链（转换 token 流：小写化、词干、停用词、同义词等）。

## 核心概念簇

### Analyzer 管线入口
`Analyzer` 是文本分析入口，封装从读取输入文本到产出 token 流的全过程。Lucene 提供多种预置 Analyzer（如 `StandardAnalyzer`），也可用 `CustomAnalyzer.builder()` 通过工厂组装自定义管线。`Analyzer` 内部按线程重用 `TokenStreamComponents`。

### CharFilter / Tokenizer / TokenFilter 链
- `CharFilter`（可选）：tokenize 前预处理字符流，如 `HTMLStripCharFilterFactory` 剥离 HTML 标签，可链式拼接。
- `Tokenizer`：把字符流切成 token，是 `TokenStream` 链的第一个组件（`WhitespaceTokenizer`、`StandardTokenizer` 等），由 `TokenizerFactory` 创建。
- `TokenFilter`：处理 `Tokenizer` 产出的 token 流，可修改/增删 token（`LowerCaseFilter`、`StopFilter`、`SynonymGraphFilter`）。

### 高级过滤与图分析
`ConditionalTokenFilter` 按当前 token 属性动态应用过滤器（`shouldFilter()` 为真才执行）。现代 analyzer 常产出 token 图而非线性流：`GraphTokenFilter` 是 `FixedShingleFilter`、`SynonymGraphFilter` 等的基类，用 `PositionLengthAttribute` 表示跨多位置的 token，供 `PhraseQuery` 使用。

## 代码锚点

| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| Analyzer 管线入口 | `Analyzer` | core/src/java/org/apache/lucene/analysis/Analyzer.java:97 | ✅ | Analyzer→TokenStreamComponents→tokenStream；ReuseStrategy |
| Analyzer 管线入口 | `StandardAnalyzer` | core/src/java/org/apache/lucene/analysis/standard/StandardAnalyzer.java:34 | ✅ | StandardTokenizer→LowerCaseFilter→StopFilter |
| Analyzer 管线入口 | `CustomAnalyzer` | analysis/common/src/java/org/apache/lucene/analysis/custom/CustomAnalyzer.java:99 | ✅ | builder→TokenizerFactory+TokenFilterFactory+CharFilterFactory |
| Tokenizer | `Tokenizer` | core/src/java/org/apache/lucene/analysis/Tokenizer.java | ✅ | TokenStream→Tokenizer（输入为 Reader） |
| TokenFilter | `TokenFilter` | core/src/java/org/apache/lucene/analysis/TokenFilter.java | ✅ | TokenStream→TokenFilter（输入为另一 TokenStream） |
| CharFilter | `CharFilter` | core/src/java/org/apache/lucene/analysis/CharFilter.java | ✅ | Analyzer.initReader→CharFilter（预处理 Reader） |
| 图分析基类 | `TokenStream` | core/src/java/org/apache/lucene/analysis/TokenStream.java:78 | ✅ | Analyzer→TokenStream（incrementToken/reset/end/close）；1399 callers |

## 漂移标记

- orphan：无
- blindspot：无（`TokenStream`(1399 callers) 等高中心度符号均被概念簇覆盖）

## 交叉链接

- → indexing.md（Analyzer 产出的 token 流由 IndexingChain/DWPT 在索引时消费，写入倒排索引）
