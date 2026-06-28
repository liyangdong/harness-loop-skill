| 概念 | 符号 | 位置:行 | 状态 | callPath |
| --- | --- | --- | --- | --- |
| Analyzer 管线入口 | `Analyzer` | core/src/java/org/apache/lucene/analysis/Analyzer.java:97 | ✅ | Analyzer→TokenStreamComponents→tokenStream；ReuseStrategy |
| Analyzer 管线入口 | `StandardAnalyzer` | core/src/java/org/apache/lucene/analysis/standard/StandardAnalyzer.java:34 | ✅ | StandardTokenizer→LowerCaseFilter→StopFilter |
| Analyzer 管线入口 | `CustomAnalyzer` | analysis/common/src/java/org/apache/lucene/analysis/custom/CustomAnalyzer.java:99 | ✅ | builder→TokenizerFactory+TokenFilterFactory+CharFilterFactory |
| Tokenizer | `Tokenizer` | core/src/java/org/apache/lucene/analysis/Tokenizer.java | ✅ | TokenStream→Tokenizer（输入为 Reader） |
| TokenFilter | `TokenFilter` | core/src/java/org/apache/lucene/analysis/TokenFilter.java | ✅ | TokenStream→TokenFilter（输入为另一 TokenStream） |
| CharFilter | `CharFilter` | core/src/java/org/apache/lucene/analysis/CharFilter.java | ✅ | Analyzer.initReader→CharFilter（预处理 Reader） |
| 图分析基类 | `TokenStream` | core/src/java/org/apache/lucene/analysis/TokenStream.java:78 | ✅ | Analyzer→TokenStream（incrementToken/reset/end/close）；1399 callers |
