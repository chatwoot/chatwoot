# Heredocs

Heredocs are one of the most complicated pieces of this parser. There are many different forms, there can be multiple open at the same time, and they can be nested. In order to support parsing them, we keep track of a lot of metadata. Below is a basic overview of how it works.

## 1. Lexing the identifier

When a heredoc identifier is encountered in the regular process of lexing, we push the `PM_LEX_HEREDOC` mode onto the stack with the following metadata:

* `ident_start`: A pointer to the start of the identifier for the heredoc. We need this to match against the end of the heredoc.
* `ident_length`: The length of the identifier for the heredoc. We also need this to match.
* `next_start`: A pointer to the place in source that the parser should resume lexing once it has completed this heredoc.

We also set the special `parser.next_start` field which is a pointer to the place in the source where we should start lexing the next token. This is set to the pointer of the character immediately following the next newline.

Note that if the `parser.heredoc_end` field is already set, then it means we have already encountered a heredoc on this line. In that case the `parser.next_start` field will be set to the `parser.heredoc_end` field. This is because we want to skip past the previous heredocs on this line and instead lex the body of this heredoc.

## 2. Lexing the body

The next time the lexer is asked for a token, it will be in the `PM_LEX_HEREDOC` mode. In this mode we are lexing the body of the heredoc. It will start by checking if the `next_start` field is set. If it is, then this is the first token within the body of the heredoc so we'll start lexing from there. Otherwise we'll start lexing from the end of the previous token.

Lexing these fields is extremely similar to lexing an interpolated string. The only difference is that we also do an additional check at the beginning of each line to check if we have hit the terminator.

## 3. Lexing the terminator

On every newline within the body of a heredoc, we check to see if it matches the terminator followed by a newline or a carriage return and a newline. If it does, then we pop the lex mode off the stack and set a couple of fields on the parser:

* `next_start`: This is set to the value that we previously stored on the heredoc to indicate where the lexer should resume lexing when it is done with this heredoc.
* `heredoc_end`: This is set to the end of the heredoc. When a newline character is found, this indicates that the lexer should skip past to this next point.

## 4. Lexing the rest of the line

Once the heredoc has been lexed, the lexer will resume lexing from the `next_start` field. Lexing will continue until the next newline character. When the next newline character is found, it will check to see if the `heredoc_end` field is set. If it is it will skip to that point, unset the field, and continue lexing.

## Compatibility with Ripper

The order in which tokens are emitted is different from that of Ripper. Ripper emits each token in the file in the order in which it appears. prism instead will emit the tokens that makes the most sense for the lexer, using the process described above. Therefore to line things up, `Prism.lex_compat` will shuffle the tokens around to match Ripper's output.
