use crate::ast::*;
use crate::token::Token;
use thiserror::Error;

static EOF_TOKEN: Token = Token::EOF;

#[derive(Debug, Error, Clone)]
pub enum ParseError {
    #[error("Unexpected token '{0}', expected {1}")]
    UnexpectedToken(Token, String),
    #[error("Unexpected end of input")]
    UnexpectedEOF,
    #[error("Invalid field path")]
    InvalidFieldPath,
    #[error("Invalid literal")]
    InvalidLiteral,
}

pub struct Parser {
    tokens: Vec<Token>,
    position: usize,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Parser { tokens, position: 0 }
    }

    pub fn parse(&mut self) -> Result<Vec<Statement>, ParseError> {
        let mut statements = Vec::new();
        while self.peek() != &Token::EOF {
            statements.push(self.parse_statement()?);
        }
        Ok(statements)
    }

    fn parse_statement(&mut self) -> Result<Statement, ParseError> {
        match self.peek().clone() {
            Token::Scan => {
                self.advance();
                Ok(Statement::Scan(self.parse_scan()?))
            }
            Token::Find => {
                self.advance();
                Ok(Statement::Find(self.parse_find()?))
            }
            Token::Generate => {
                self.advance();
                Ok(Statement::Generate(self.parse_generate()?))
            }
            Token::Alert => {
                self.advance();
                Ok(Statement::Alert(self.parse_alert()?))
            }
            Token::Analyse => {
                self.advance();
                Ok(Statement::Analyse(self.parse_analyse()?))
            }
            tok => Err(ParseError::UnexpectedToken(
                tok,
                "SCAN, FIND, GENERATE, ALERT, or ANALYSE".to_string(),
            )),
        }
    }

    fn parse_scan(&mut self) -> Result<ScanStatement, ParseError> {
        // SCAN domain "example.com"
        // Expect "domain" identifier
        match self.peek().clone() {
            Token::Ident(ref s) if s == "domain" => {
                self.advance();
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "domain".to_string()));
            }
        }

        let domain = match self.advance() {
            Token::StringLit(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "string literal (domain)".to_string()));
            }
        };

        let mut compare = None;
        let mut where_clause = None;
        let mut convert = None;
        let mut generate = None;
        let mut rank = None;
        let mut limit = None;

        loop {
            match self.peek().clone() {
                Token::Compare => {
                    self.advance();
                    compare = Some(self.parse_compare_clause()?);
                }
                Token::Where => {
                    self.advance();
                    where_clause = Some(self.parse_where()?);
                }
                Token::Convert => {
                    self.advance();
                    convert = Some(self.parse_convert_clause()?);
                }
                Token::Generate => {
                    self.advance();
                    generate = Some(self.parse_generate_clause()?);
                }
                Token::Rank => {
                    self.advance();
                    rank = Some(self.parse_rank_clause()?);
                }
                Token::Limit => {
                    self.advance();
                    match self.advance() {
                        Token::IntLit(n) => limit = Some(n as u32),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "integer limit".to_string()));
                        }
                    }
                }
                _ => break,
            }
        }

        Ok(ScanStatement { domain, compare, where_clause, convert, generate, rank, limit })
    }

    fn parse_find(&mut self) -> Result<FindStatement, ParseError> {
        // FIND <target_ident>
        let target = match self.advance() {
            Token::Ident(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "find target identifier".to_string()));
            }
        };

        let mut where_clause = None;
        let mut rank = None;
        let mut limit = None;
        let mut generate = None;

        loop {
            match self.peek().clone() {
                Token::Where => {
                    self.advance();
                    where_clause = Some(self.parse_where()?);
                }
                Token::Rank => {
                    self.advance();
                    rank = Some(self.parse_rank_clause()?);
                }
                Token::Limit => {
                    self.advance();
                    match self.advance() {
                        Token::IntLit(n) => limit = Some(n as u32),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "integer limit".to_string()));
                        }
                    }
                }
                Token::Generate => {
                    self.advance();
                    generate = Some(self.parse_generate_clause()?);
                }
                _ => break,
            }
        }

        Ok(FindStatement { target, where_clause, rank, limit, generate })
    }

    fn parse_generate(&mut self) -> Result<GenerateStatement, ParseError> {
        // GENERATE <asset_type> [FOR "domain"] STYLE "x" LANGUAGE "y" [FRAMEWORK "z"] [PLATFORM "p"]
        let asset_type = match self.advance() {
            Token::Ident(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "asset type identifier".to_string()));
            }
        };

        let mut for_domain = None;
        let mut style = String::new();
        let mut language = String::new();
        let mut framework = None;
        let mut platform = None;
        let mut currency = None;

        loop {
            match self.peek().clone() {
                Token::For => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => for_domain = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "domain string".to_string()));
                        }
                    }
                }
                Token::Style => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => style = s,
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "style string".to_string()));
                        }
                    }
                }
                Token::Language => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => language = s,
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "language string".to_string()));
                        }
                    }
                }
                Token::Framework => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => framework = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "framework string".to_string()));
                        }
                    }
                }
                Token::Platform => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => platform = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "platform string".to_string()));
                        }
                    }
                }
                Token::Ident(ref s) if s == "currency" => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => currency = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "currency string".to_string()));
                        }
                    }
                }
                _ => break,
            }
        }

        Ok(GenerateStatement { asset_type, for_domain, style, language, framework, platform, currency })
    }

    fn parse_alert(&mut self) -> Result<AlertStatement, ParseError> {
        // ALERT WHEN <condition> NOTIFY via "channel" WITH message "text"
        match self.peek().clone() {
            Token::When => {
                self.advance();
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "WHEN".to_string()));
            }
        }

        let condition = self.parse_alert_condition()?;

        // NOTIFY via "channel"
        match self.peek().clone() {
            Token::Notify => {
                self.advance();
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "NOTIFY".to_string()));
            }
        }
        // optional "via" keyword
        if let Token::Via = self.peek().clone() {
            self.advance();
        }

        let notify_via = match self.advance() {
            Token::StringLit(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "notification channel string".to_string()));
            }
        };

        let mut message = None;
        if let Token::With = self.peek().clone() {
            self.advance();
            // optional "message" keyword
            match self.peek().clone() {
                Token::Message => {
                    self.advance();
                }
                Token::Ident(ref s) if s == "message" => {
                    self.advance();
                }
                _ => {}
            }
            match self.advance() {
                Token::StringLit(s) => message = Some(s),
                tok => {
                    return Err(ParseError::UnexpectedToken(tok, "message string".to_string()));
                }
            }
        }

        Ok(AlertStatement { condition, notify_via, message })
    }

    fn parse_alert_condition(&mut self) -> Result<AlertCondition, ParseError> {
        // currency "USD/GBP" rate.change > 3%
        // or domain "x.com" traffic.monthly > 100000
        let subject = match self.peek().clone() {
            Token::Ident(ref s) if s == "currency" => {
                self.advance();
                let pair = match self.advance() {
                    Token::StringLit(s) => s,
                    tok => {
                        return Err(ParseError::UnexpectedToken(tok, "currency pair string".to_string()));
                    }
                };
                // Now parse the field path (e.g. rate.change)
                let field_path = self.parse_field_path_str()?;
                AlertSubject::Currency(pair, field_path)
            }
            Token::Ident(ref s) if s == "domain" => {
                self.advance();
                let d = match self.advance() {
                    Token::StringLit(s) => s,
                    tok => {
                        return Err(ParseError::UnexpectedToken(tok, "domain string".to_string()));
                    }
                };
                let field_path = self.parse_field_path_str()?;
                AlertSubject::Domain(d, field_path)
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "currency or domain".to_string()));
            }
        };

        let op = self.parse_compare_op()?;
        let value = self.parse_literal()?;

        Ok(AlertCondition { subject, op, value })
    }

    fn parse_field_path_str(&mut self) -> Result<String, ParseError> {
        let field = self.parse_field_path()?;
        Ok(field.as_str())
    }

    fn parse_analyse(&mut self) -> Result<AnalyseStatement, ParseError> {
        // ANALYSE "domain.com" [dimensions...] [timeframe] [benchmark]
        let domain = match self.advance() {
            Token::StringLit(s) => s,
            Token::Ident(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "domain string".to_string()));
            }
        };

        let mut dimensions = Vec::new();
        let mut timeframe = None;
        let mut benchmark = None;

        loop {
            match self.peek().clone() {
                Token::Ident(ref s) if s == "dimensions" => {
                    self.advance();
                    while let Token::StringLit(d) = self.peek().clone() {
                        self.advance();
                        dimensions.push(d);
                        if self.peek() == &Token::Comma {
                            self.advance();
                        }
                    }
                }
                Token::Ident(ref s) if s == "timeframe" => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => timeframe = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "timeframe string".to_string()));
                        }
                    }
                }
                Token::Ident(ref s) if s == "benchmark" => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => benchmark = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "benchmark string".to_string()));
                        }
                    }
                }
                _ => break,
            }
        }

        Ok(AnalyseStatement { domain, dimensions, timeframe, benchmark })
    }

    fn parse_where(&mut self) -> Result<WhereExpr, ParseError> {
        let left = self.parse_where_or()?;
        Ok(left)
    }

    fn parse_where_or(&mut self) -> Result<WhereExpr, ParseError> {
        let mut left = self.parse_where_and()?;
        while self.peek() == &Token::Or {
            self.advance();
            let right = self.parse_where_and()?;
            left = WhereExpr::Or(Box::new(left), Box::new(right));
        }
        Ok(left)
    }

    fn parse_where_and(&mut self) -> Result<WhereExpr, ParseError> {
        let mut left = self.parse_where_atom()?;
        while self.peek() == &Token::And {
            self.advance();
            let right = self.parse_where_atom()?;
            left = WhereExpr::And(Box::new(left), Box::new(right));
        }
        Ok(left)
    }

    fn parse_where_atom(&mut self) -> Result<WhereExpr, ParseError> {
        if self.peek() == &Token::Not {
            self.advance();
            let inner = self.parse_where_atom()?;
            return Ok(WhereExpr::Not(Box::new(inner)));
        }
        let cmp = self.parse_comparison()?;
        Ok(WhereExpr::Condition(cmp))
    }

    fn parse_comparison(&mut self) -> Result<Comparison, ParseError> {
        let field = self.parse_field_path()?;
        let op = self.parse_compare_op()?;
        let value = self.parse_literal()?;
        Ok(Comparison { field, op, value })
    }

    fn parse_compare_op(&mut self) -> Result<CompareOp, ParseError> {
        match self.advance() {
            Token::GreaterThan => Ok(CompareOp::Gt),
            Token::LessThan => Ok(CompareOp::Lt),
            Token::GreaterEqual => Ok(CompareOp::Gte),
            Token::LessEqual => Ok(CompareOp::Lte),
            Token::Equal => Ok(CompareOp::Eq),
            Token::NotEqual => Ok(CompareOp::Neq),
            Token::In => Ok(CompareOp::In),
            tok => Err(ParseError::UnexpectedToken(tok, "comparison operator".to_string())),
        }
    }

    fn parse_field_path(&mut self) -> Result<FieldPath, ParseError> {
        let mut parts = Vec::new();

        let first = match self.advance() {
            Token::Ident(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "field identifier".to_string()));
            }
        };
        parts.push(first);

        while self.peek() == &Token::Dot {
            self.advance(); // consume dot
            match self.advance() {
                Token::Ident(s) => parts.push(s),
                tok => {
                    return Err(ParseError::UnexpectedToken(tok, "field identifier after '.'".to_string()));
                }
            }
        }

        if parts.is_empty() {
            return Err(ParseError::InvalidFieldPath);
        }

        Ok(FieldPath { parts })
    }

    fn parse_literal(&mut self) -> Result<Literal, ParseError> {
        match self.advance() {
            Token::StringLit(s) => Ok(Literal::Str(s)),
            Token::IntLit(n) => {
                // Check if followed by % (percentage literal treated as float)
                if self.peek() == &Token::Percent {
                    self.advance();
                    Ok(Literal::Float(n as f64))
                } else {
                    Ok(Literal::Int(n))
                }
            }
            Token::FloatLit(f) => {
                if self.peek() == &Token::Percent {
                    self.advance();
                }
                Ok(Literal::Float(f))
            }
            Token::ListLit(v) => {
                let lits = v.into_iter().map(Literal::Str).collect();
                Ok(Literal::List(lits))
            }
            Token::BoolTrue => Ok(Literal::Bool(true)),
            Token::BoolFalse => Ok(Literal::Bool(false)),
            tok => Err(ParseError::UnexpectedToken(tok, "literal value".to_string())),
        }
    }

    fn parse_compare_clause(&mut self) -> Result<CompareClause, ParseError> {
        // COMPARE competitors [TOP N]
        let subject = match self.advance() {
            Token::Ident(ref s) if s == "competitors" => CompareSubject::Competitors,
            Token::Ident(s) => {
                return Err(ParseError::UnexpectedToken(
                    Token::Ident(s),
                    "competitors".to_string(),
                ));
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "compare subject".to_string()));
            }
        };

        let mut top = None;
        if self.peek() == &Token::Top {
            self.advance();
            match self.advance() {
                Token::IntLit(n) => top = Some(n as u32),
                tok => {
                    return Err(ParseError::UnexpectedToken(tok, "integer after TOP".to_string()));
                }
            }
        }

        Ok(CompareClause { subject, top })
    }

    fn parse_convert_clause(&mut self) -> Result<ConvertClause, ParseError> {
        // CONVERT <field> TO "CURRENCY" [USING "rate_source"]
        let target_field = match self.advance() {
            Token::Ident(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "field to convert".to_string()));
            }
        };

        match self.peek().clone() {
            Token::To => {
                self.advance();
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "TO".to_string()));
            }
        }

        let to_currency = match self.advance() {
            Token::StringLit(s) => s,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "currency string".to_string()));
            }
        };

        let mut using = None;
        if self.peek() == &Token::Using {
            self.advance();
            match self.advance() {
                Token::StringLit(s) => using = Some(s),
                tok => {
                    return Err(ParseError::UnexpectedToken(tok, "using source string".to_string()));
                }
            }
        }

        Ok(ConvertClause { target_field, to_currency, using })
    }

    fn parse_generate_clause(&mut self) -> Result<GenerateClause, ParseError> {
        // GENERATE [asset_type] STYLE "x" LANGUAGE "y" [FRAMEWORK "z"] [PLATFORM "p"]
        // When used as sub-clause within SCAN/FIND the asset type may or may not be present
        let mut style = String::new();
        let mut language = String::new();
        let mut framework = None;
        let mut platform = None;

        // optional asset type ident before STYLE
        if let Token::Ident(_) = self.peek().clone() {
            // Could be asset type or something else - only consume if next-next is STYLE
            // Simple approach: consume if it's not a keyword that starts another clause
            match self.peek().clone() {
                Token::Ident(_) => {
                    // peek+1 to see if STYLE follows
                    if self.position + 1 < self.tokens.len() {
                        match &self.tokens[self.position + 1] {
                            Token::Style => {
                                self.advance(); // consume asset type ident, ignore it
                            }
                            _ => {}
                        }
                    }
                }
                _ => {}
            }
        }

        loop {
            match self.peek().clone() {
                Token::Style => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => style = s,
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "style string".to_string()));
                        }
                    }
                }
                Token::Language => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => language = s,
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "language string".to_string()));
                        }
                    }
                }
                Token::Framework => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => framework = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "framework string".to_string()));
                        }
                    }
                }
                Token::Platform => {
                    self.advance();
                    match self.advance() {
                        Token::StringLit(s) => platform = Some(s),
                        tok => {
                            return Err(ParseError::UnexpectedToken(tok, "platform string".to_string()));
                        }
                    }
                }
                _ => break,
            }
        }

        Ok(GenerateClause { style, language, framework, platform })
    }

    fn parse_rank_clause(&mut self) -> Result<RankClause, ParseError> {
        // RANK BY <field_path> ASC|DESC
        match self.peek().clone() {
            Token::By => {
                self.advance();
            }
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "BY".to_string()));
            }
        }

        let field = self.parse_field_path()?;

        let direction = match self.advance() {
            Token::Asc => SortDir::Asc,
            Token::Desc => SortDir::Desc,
            tok => {
                return Err(ParseError::UnexpectedToken(tok, "ASC or DESC".to_string()));
            }
        };

        Ok(RankClause { field, direction })
    }

    fn peek(&self) -> &Token {
        self.tokens.get(self.position).unwrap_or(&EOF_TOKEN)
    }

    fn advance(&mut self) -> Token {
        let tok = self.tokens.get(self.position).cloned().unwrap_or(Token::EOF);
        if self.position < self.tokens.len() {
            self.position += 1;
        }
        tok
    }

    #[allow(dead_code)]
    fn expect(&mut self, expected: &Token) -> Result<(), ParseError> {
        let tok = self.advance();
        if &tok == expected {
            Ok(())
        } else {
            Err(ParseError::UnexpectedToken(tok, format!("{}", expected)))
        }
    }

    #[allow(dead_code)]
    fn expect_keyword(&mut self, keyword: &str) -> Result<(), ParseError> {
        match self.advance() {
            Token::Ident(ref s) if s == keyword => Ok(()),
            tok => Err(ParseError::UnexpectedToken(tok, keyword.to_string())),
        }
    }
}
