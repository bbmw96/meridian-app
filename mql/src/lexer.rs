use crate::token::{Token, KEYWORDS};
use thiserror::Error;

#[derive(Debug, Error, Clone)]
pub enum LexError {
    #[error("Unterminated string literal at line {line}, column {column}")]
    UnterminatedString { line: usize, column: usize },
    #[error("Invalid character '{0}'")]
    InvalidCharacter(char),
    #[error("Invalid escape sequence '\\{0}'")]
    InvalidEscape(char),
}

pub struct Lexer<'a> {
    chars: std::iter::Peekable<std::str::CharIndices<'a>>,
    line: usize,
    column: usize,
}

impl<'a> Lexer<'a> {
    pub fn new(source: &'a str) -> Self {
        Lexer {
            chars: source.char_indices().peekable(),
            line: 1,
            column: 1,
        }
    }

    pub fn tokenise(&mut self) -> Result<Vec<Token>, LexError> {
        let mut tokens = Vec::new();
        loop {
            match self.next_token()? {
                Some(tok) => {
                    let is_eof = tok == Token::EOF;
                    tokens.push(tok);
                    if is_eof {
                        break;
                    }
                }
                None => {
                    tokens.push(Token::EOF);
                    break;
                }
            }
        }
        Ok(tokens)
    }

    fn next_token(&mut self) -> Result<Option<Token>, LexError> {
        self.skip_whitespace_and_comments();

        let (_, ch) = match self.chars.peek() {
            Some(&c) => c,
            None => return Ok(Some(Token::EOF)),
        };

        let tok = match ch {
            '"' => {
                self.advance_char();
                let s = self.read_string()?;
                Token::StringLit(s)
            }
            '[' => {
                self.advance_char();
                let list = self.read_list()?;
                Token::ListLit(list)
            }
            '>' => {
                self.advance_char();
                if self.peek_char() == Some('=') {
                    self.advance_char();
                    Token::GreaterEqual
                } else {
                    Token::GreaterThan
                }
            }
            '<' => {
                self.advance_char();
                if self.peek_char() == Some('=') {
                    self.advance_char();
                    Token::LessEqual
                } else {
                    Token::LessThan
                }
            }
            '=' => {
                self.advance_char();
                Token::Equal
            }
            '!' => {
                self.advance_char();
                if self.peek_char() == Some('=') {
                    self.advance_char();
                    Token::NotEqual
                } else {
                    return Err(LexError::InvalidCharacter('!'));
                }
            }
            '%' => {
                self.advance_char();
                Token::Percent
            }
            '.' => {
                self.advance_char();
                Token::Dot
            }
            ',' => {
                self.advance_char();
                Token::Comma
            }
            ']' => {
                self.advance_char();
                Token::RightBracket
            }
            c if c.is_ascii_digit() => {
                let first = c;
                self.advance_char();
                self.read_number(first)
            }
            c if c.is_alphabetic() || c == '_' => {
                let first = c;
                self.advance_char();
                self.read_ident_or_keyword(first)
            }
            c => {
                return Err(LexError::InvalidCharacter(c));
            }
        };

        Ok(Some(tok))
    }

    fn advance_char(&mut self) -> Option<char> {
        if let Some((_, c)) = self.chars.next() {
            if c == '\n' {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
            Some(c)
        } else {
            None
        }
    }

    fn peek_char(&mut self) -> Option<char> {
        self.chars.peek().map(|&(_, c)| c)
    }

    fn read_string(&mut self) -> Result<String, LexError> {
        let start_line = self.line;
        let start_col = self.column;
        let mut s = String::new();
        loop {
            match self.advance_char() {
                None => {
                    return Err(LexError::UnterminatedString {
                        line: start_line,
                        column: start_col,
                    })
                }
                Some('"') => break,
                Some('\\') => {
                    match self.advance_char() {
                        Some('n') => s.push('\n'),
                        Some('t') => s.push('\t'),
                        Some('r') => s.push('\r'),
                        Some('"') => s.push('"'),
                        Some('\\') => s.push('\\'),
                        Some(c) => return Err(LexError::InvalidEscape(c)),
                        None => {
                            return Err(LexError::UnterminatedString {
                                line: start_line,
                                column: start_col,
                            })
                        }
                    }
                }
                Some(c) => s.push(c),
            }
        }
        Ok(s)
    }

    fn read_number(&mut self, first: char) -> Token {
        let mut s = String::new();
        s.push(first);
        let mut is_float = false;

        while let Some(c) = self.peek_char() {
            if c.is_ascii_digit() {
                s.push(c);
                self.advance_char();
            } else if c == '.' {
                // Look ahead to check it's a decimal and not a field path dot
                s.push(c);
                self.advance_char();
                is_float = true;
                // Read fractional digits
                while let Some(d) = self.peek_char() {
                    if d.is_ascii_digit() {
                        s.push(d);
                        self.advance_char();
                    } else {
                        break;
                    }
                }
                break;
            } else {
                break;
            }
        }

        if is_float {
            Token::FloatLit(s.parse().unwrap_or(0.0))
        } else {
            Token::IntLit(s.parse().unwrap_or(0))
        }
    }

    fn read_ident_or_keyword(&mut self, first: char) -> Token {
        let mut s = String::new();
        s.push(first);

        while let Some(c) = self.peek_char() {
            if c.is_alphanumeric() || c == '_' {
                s.push(c);
                self.advance_char();
            } else {
                break;
            }
        }

        // Check keywords (case-sensitive uppercase first, then lowercase for bool)
        for &(kw, ref tok) in KEYWORDS {
            if s == kw {
                return tok.clone();
            }
        }

        Token::Ident(s)
    }

    fn read_list(&mut self) -> Result<Vec<String>, LexError> {
        // Already consumed '[', read comma-separated strings until ']'
        let mut items = Vec::new();
        loop {
            self.skip_whitespace_and_comments();
            match self.peek_char() {
                None => break,
                Some(']') => {
                    self.advance_char();
                    break;
                }
                Some('"') => {
                    self.advance_char();
                    let s = self.read_string()?;
                    items.push(s);
                    self.skip_whitespace_and_comments();
                    if self.peek_char() == Some(',') {
                        self.advance_char();
                    }
                }
                Some(c) => {
                    return Err(LexError::InvalidCharacter(c));
                }
            }
        }
        Ok(items)
    }

    fn skip_whitespace_and_comments(&mut self) {
        loop {
            match self.peek_char() {
                Some(' ') | Some('\t') | Some('\r') | Some('\n') => {
                    self.advance_char();
                }
                Some('#') => {
                    // Line comment: skip to end of line
                    while let Some(c) = self.advance_char() {
                        if c == '\n' {
                            break;
                        }
                    }
                }
                _ => break,
            }
        }
    }
}
