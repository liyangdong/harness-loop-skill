### Analyzer 管线入口
`Analyzer` 是文本分析入口，封装从读取输入文本到产出 token 流的全过程。Lucene 提供多种预置 Analyzer（如 `StandardAnalyzer`），也可用 `CustomAnalyzer.builder()` 通过工厂组装自定义管线。`Analyzer` 内部按线程重用 `TokenStreamComponents`。

### CharFilter / Tokenizer / TokenFilter 链
- `CharFilter`（可选）：tokenize 前预处理字符流，如 `HTMLStripCharFilterFactory` 剥离 HTML 标签，可链式拼接。
- `Tokenizer`：把字符流切成 token，是 `TokenStream` 链的第一个组件（`WhitespaceTokenizer`、`StandardTokenizer` 等），由 `TokenizerFactory` 创建。
- `TokenFilter`：处理 `Tokenizer` 产出的 token 流，可修改/增删 token（`LowerCaseFilter`、`StopFilter`、`SynonymGraphFilter`）。

### 高级过滤与图分析
`ConditionalTokenFilter` 按当前 token 属性动态应用过滤器（`shouldFilter()` 为真才执行）。现代 analyzer 常产出 token 图而非线性流：`GraphTokenFilter` 是 `FixedShingleFilter`、`SynonymGraphFilter` 等的基类，用 `PositionLengthAttribute` 表示跨多位置的 token，供 `PhraseQuery` 使用。
