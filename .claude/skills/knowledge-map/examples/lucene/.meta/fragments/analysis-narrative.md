分析系统在索引与搜索时处理文本，把原始文本转换成适合索引与搜索的 token 流。核心是 `Analyzer` 编排整个处理管线：可选的 `CharFilter` 链（tokenize 前预处理字符流）、一个 `Tokenizer`（切分为 token）、可选的 `TokenFilter` 链（转换 token 流：小写化、词干、停用词、同义词等）。
