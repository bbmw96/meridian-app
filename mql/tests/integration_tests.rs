#[cfg(test)]
mod tests {
    use mql_compiler::{
        ast::*,
        codegen::{generate, sql_codegen::SQLCodegen, ml_codegen::MLCodegen, ExecutionStep},
        lexer::{LexError, Lexer},
        parser::Parser,
        token::Token,
        typechecker::{TypeError, TypeChecker},
        compile,
    };

    fn lex(src: &str) -> Vec<Token> {
        Lexer::new(src).tokenise().expect("lexer should succeed")
    }

    fn parse(src: &str) -> Vec<Statement> {
        let tokens = lex(src);
        Parser::new(tokens).parse().expect("parser should succeed")
    }

    // ── Lexer tests ───────────────────────────────────────────────

    #[test]
    fn lexer_handles_all_token_types() {
        let src = r#"SCAN COMPARE WHERE AND OR NOT IN GENERATE FIND ALERT ANALYSE CONVERT USING FOR FROM RANK LIMIT BY NOTIFY WITH AS TOP ASC DESC WHEN VIA"#;
        let tokens = lex(src);
        // Should produce keyword tokens, not Ident
        assert!(tokens.contains(&Token::Scan));
        assert!(tokens.contains(&Token::Compare));
        assert!(tokens.contains(&Token::Where));
        assert!(tokens.contains(&Token::And));
        assert!(tokens.contains(&Token::Or));
        assert!(tokens.contains(&Token::Not));
        assert!(tokens.contains(&Token::In));
        assert!(tokens.contains(&Token::Generate));
        assert!(tokens.contains(&Token::Find));
        assert!(tokens.contains(&Token::Alert));
        assert!(tokens.contains(&Token::Analyse));
        assert!(tokens.contains(&Token::Convert));
        assert!(tokens.contains(&Token::Using));
        assert!(tokens.contains(&Token::For));
        assert!(tokens.contains(&Token::Rank));
        assert!(tokens.contains(&Token::Limit));
        assert!(tokens.contains(&Token::By));
        assert!(tokens.contains(&Token::Notify));
        assert!(tokens.contains(&Token::With));
        assert!(tokens.contains(&Token::As));
        assert!(tokens.contains(&Token::Top));
        assert!(tokens.contains(&Token::Asc));
        assert!(tokens.contains(&Token::Desc));
        assert!(tokens.contains(&Token::When));
        assert!(tokens.contains(&Token::Via));
    }

    #[test]
    fn lexer_handles_string_literal() {
        let tokens = lex(r#""hello world""#);
        assert!(tokens.contains(&Token::StringLit("hello world".to_string())));
    }

    #[test]
    fn lexer_handles_int_literal() {
        let tokens = lex("100000");
        assert!(tokens.contains(&Token::IntLit(100000)));
    }

    #[test]
    fn lexer_handles_float_literal() {
        let tokens = lex("0.85");
        assert!(tokens.contains(&Token::FloatLit(0.85)));
    }

    #[test]
    fn lexer_handles_list_literal() {
        let tokens = lex(r#"["GB", "DE", "JP"]"#);
        assert!(tokens.contains(&Token::ListLit(vec![
            "GB".to_string(),
            "DE".to_string(),
            "JP".to_string()
        ])));
    }

    #[test]
    fn lexer_handles_operators() {
        let tokens = lex("> < >= <= = != %");
        assert!(tokens.contains(&Token::GreaterThan));
        assert!(tokens.contains(&Token::LessThan));
        assert!(tokens.contains(&Token::GreaterEqual));
        assert!(tokens.contains(&Token::LessEqual));
        assert!(tokens.contains(&Token::Equal));
        assert!(tokens.contains(&Token::NotEqual));
        assert!(tokens.contains(&Token::Percent));
    }

    #[test]
    fn lexer_handles_bool_literals() {
        let tokens = lex("true false");
        assert!(tokens.contains(&Token::BoolTrue));
        assert!(tokens.contains(&Token::BoolFalse));
    }

    #[test]
    fn lexer_rejects_unterminated_string() {
        let result = Lexer::new(r#""unterminated"#).tokenise();
        assert!(matches!(result, Err(LexError::UnterminatedString { .. })));
    }

    // ── Parser tests ──────────────────────────────────────────────

    #[test]
    fn parser_parses_simple_scan() {
        let stmts = parse(r#"SCAN domain "apple.com""#);
        assert_eq!(stmts.len(), 1);
        match &stmts[0] {
            Statement::Scan(s) => assert_eq!(s.domain, "apple.com"),
            _ => panic!("Expected Scan"),
        }
    }

    #[test]
    fn parser_parses_scan_with_compare_and_where() {
        let src = r#"
            SCAN domain "shopify.com"
              COMPARE competitors TOP 5
              WHERE geography IN ["GB", "DE"]
              CONVERT revenue TO "GBP"
        "#;
        let stmts = parse(src);
        assert_eq!(stmts.len(), 1);
        match &stmts[0] {
            Statement::Scan(s) => {
                assert_eq!(s.domain, "shopify.com");
                assert!(s.compare.is_some());
                let cmp = s.compare.as_ref().unwrap();
                assert_eq!(cmp.top, Some(5));
                assert!(s.where_clause.is_some());
                assert!(s.convert.is_some());
            }
            _ => panic!("Expected Scan"),
        }
    }

    #[test]
    fn parser_parses_find_with_where_rank_limit() {
        let src = r#"
            FIND opportunities
              WHERE market = "saas"
              AND currency.stability > 0.9
              RANK BY opportunity_score DESC
              LIMIT 10
        "#;
        let stmts = parse(src);
        assert_eq!(stmts.len(), 1);
        match &stmts[0] {
            Statement::Find(f) => {
                assert_eq!(f.target, "opportunities");
                assert!(f.where_clause.is_some());
                assert!(f.rank.is_some());
                assert_eq!(f.limit, Some(10));
                let rank = f.rank.as_ref().unwrap();
                assert_eq!(rank.field.as_str(), "opportunity_score");
                match rank.direction {
                    SortDir::Desc => {}
                    _ => panic!("Expected DESC"),
                }
            }
            _ => panic!("Expected Find"),
        }
    }

    #[test]
    fn parser_parses_generate() {
        let src = r#"GENERATE ad STYLE "ugc-video" LANGUAGE "en-GB" FRAMEWORK "PAS""#;
        let stmts = parse(src);
        assert_eq!(stmts.len(), 1);
        match &stmts[0] {
            Statement::Generate(g) => {
                assert_eq!(g.style, "ugc-video");
                assert_eq!(g.language, "en-GB");
                assert_eq!(g.framework, Some("PAS".to_string()));
            }
            _ => panic!("Expected Generate"),
        }
    }

    #[test]
    fn parser_parses_alert() {
        let src = r#"
            ALERT WHEN currency "USD/GBP" rate.change > 3%
              NOTIFY via "push"
              WITH message "GBP movement"
        "#;
        let stmts = parse(src);
        assert_eq!(stmts.len(), 1);
        match &stmts[0] {
            Statement::Alert(a) => {
                assert_eq!(a.notify_via, "push");
                assert_eq!(a.message, Some("GBP movement".to_string()));
                match &a.condition.subject {
                    AlertSubject::Currency(pair, field) => {
                        assert_eq!(pair, "USD/GBP");
                        assert_eq!(field, "rate.change");
                    }
                    _ => panic!("Expected Currency alert subject"),
                }
            }
            _ => panic!("Expected Alert"),
        }
    }

    #[test]
    fn parser_rejects_malformed_where_clause() {
        // WHERE without a field path
        let src = r#"FIND opportunities WHERE > 5"#;
        let tokens = lex(src);
        let result = Parser::new(tokens).parse();
        assert!(
            result.is_err(),
            "Expected parse error for malformed WHERE clause"
        );
    }

    #[test]
    fn parser_parses_multiple_statements() {
        let src = r#"
            SCAN domain "apple.com"
            SCAN domain "shopify.com"
        "#;
        let stmts = parse(src);
        assert_eq!(stmts.len(), 2);
    }

    // ── Type checker tests ────────────────────────────────────────

    #[test]
    fn typechecker_passes_valid_find() {
        let stmts = parse(r#"FIND opportunities WHERE opportunity_score > 0.8 RANK BY opportunity_score DESC LIMIT 5"#);
        assert!(TypeChecker::check(&stmts).is_ok());
    }

    #[test]
    fn typechecker_rejects_unknown_field() {
        let src = r#"FIND opportunities WHERE nonexistent_field > 0.9"#;
        let stmts = parse(src);
        let result = TypeChecker::check(&stmts);
        assert!(
            matches!(result, Err(TypeError::UnknownField(_))),
            "Expected UnknownField error, got: {:?}",
            result
        );
    }

    #[test]
    fn typechecker_rejects_invalid_currency() {
        let src = r#"SCAN domain "x.com" CONVERT revenue TO "NOTACURRENCY""#;
        let stmts = parse(src);
        let result = TypeChecker::check(&stmts);
        assert!(
            matches!(result, Err(TypeError::InvalidCurrency(_))),
            "Expected InvalidCurrency error, got: {:?}",
            result
        );
    }

    #[test]
    fn typechecker_accepts_valid_currency() {
        let src = r#"SCAN domain "x.com" CONVERT revenue TO "GBP""#;
        let stmts = parse(src);
        assert!(TypeChecker::check(&stmts).is_ok());
    }

    #[test]
    fn typechecker_rejects_invalid_style() {
        let src = r#"GENERATE ad STYLE "invalid-format" LANGUAGE "en-GB""#;
        let stmts = parse(src);
        let result = TypeChecker::check(&stmts);
        assert!(
            matches!(result, Err(TypeError::InvalidStyle(_))),
            "Expected InvalidStyle error, got: {:?}",
            result
        );
    }

    // ── Code generation tests ─────────────────────────────────────

    #[test]
    fn scan_compiles_to_correct_api_instruction() {
        use mql_compiler::codegen::api_codegen::{APICodegen, HTTPMethod};
        let stmts = parse(r#"SCAN domain "apple.com""#);
        let instructions = APICodegen::emit(&stmts);
        assert_eq!(instructions.len(), 1);
        let inst = &instructions[0];
        assert!(matches!(inst.method, HTTPMethod::GET));
        assert_eq!(inst.endpoint, "/api/v1/intelligence/scan");
        assert_eq!(
            inst.params.get("domain").and_then(|v| v.as_str()),
            Some("apple.com")
        );
    }

    #[test]
    fn find_generates_correct_sql() {
        let src = r#"
            FIND opportunities
              WHERE market = "saas"
              RANK BY opportunity_score DESC
              LIMIT 10
        "#;
        let stmts = parse(src);
        let sql = SQLCodegen::emit_analytics(&stmts[0]);
        assert!(sql.is_some());
        let sql = sql.unwrap();
        assert!(sql.contains("FROM intelligence_signals"), "SQL missing table: {}", sql);
        assert!(sql.contains("market"), "SQL missing market field: {}", sql);
        assert!(sql.contains("'saas'"), "SQL missing value: {}", sql);
        assert!(sql.contains("ORDER BY"), "SQL missing ORDER BY: {}", sql);
        assert!(sql.contains("LIMIT 10"), "SQL missing LIMIT: {}", sql);
    }

    #[test]
    fn generate_emits_correct_ml_task() {
        let g = GenerateStatement {
            asset_type: "ad".to_string(),
            for_domain: Some("shopify.com".to_string()),
            style: "ugc-video".to_string(),
            language: "en-GB".to_string(),
            framework: Some("PAS".to_string()),
            platform: Some("tiktok".to_string()),
            currency: None,
        };
        let task = MLCodegen::emit(&g);
        assert_eq!(task.model_hint, "kling-v2");
        assert!(task.prompt.contains("PROBLEM"), "Prompt missing PAS PROBLEM section: {}", task.prompt);
        assert!(task.prompt.contains("en-GB"), "Prompt missing language: {}", task.prompt);
        assert_eq!(
            task.params.get("platform").and_then(|v| v.as_str()),
            Some("tiktok")
        );
    }

    #[test]
    fn generate_static_uses_stable_diffusion() {
        let g = GenerateStatement {
            asset_type: "banner".to_string(),
            for_domain: None,
            style: "static".to_string(),
            language: "en-US".to_string(),
            framework: Some("AIDA".to_string()),
            platform: None,
            currency: None,
        };
        let task = MLCodegen::emit(&g);
        assert_eq!(task.model_hint, "stable-diffusion-xl");
    }

    #[test]
    fn generate_carousel_uses_dalle() {
        let g = GenerateStatement {
            asset_type: "carousel".to_string(),
            for_domain: None,
            style: "carousel".to_string(),
            language: "en-US".to_string(),
            framework: None,
            platform: Some("instagram".to_string()),
            currency: None,
        };
        let task = MLCodegen::emit(&g);
        assert_eq!(task.model_hint, "dall-e-3");
    }

    #[test]
    fn alert_compiles_correctly() {
        use mql_compiler::codegen::api_codegen::{APICodegen, HTTPMethod};
        let src = r#"
            ALERT WHEN currency "USD/GBP" rate.change > 3%
              NOTIFY via "push"
              WITH message "GBP movement"
        "#;
        let stmts = parse(src);
        let instructions = APICodegen::emit(&stmts);
        assert_eq!(instructions.len(), 1);
        let inst = &instructions[0];
        assert!(matches!(inst.method, HTTPMethod::POST));
        assert_eq!(inst.endpoint, "/api/v1/alerts");
        assert_eq!(
            inst.params.get("notify_via").and_then(|v| v.as_str()),
            Some("push")
        );
        assert_eq!(
            inst.params.get("subject_value").and_then(|v| v.as_str()),
            Some("USD/GBP")
        );
    }

    #[test]
    fn full_compile_pipeline_succeeds() {
        let src = r#"
            SCAN domain "shopify.com"
              COMPARE competitors TOP 5
              WHERE geography IN ["GB", "DE"]
              CONVERT revenue TO "GBP"
        "#;
        let plan = compile(src).expect("compile should succeed");
        assert!(!plan.steps.is_empty());
    }

    #[test]
    fn execution_plan_find_has_sequential_steps() {
        let src = r#"
            FIND opportunities
              WHERE market = "saas"
              RANK BY opportunity_score DESC
              LIMIT 10
        "#;
        let stmts = parse(src);
        TypeChecker::check(&stmts).unwrap();
        let plan = generate(&stmts);
        assert!(!plan.steps.is_empty());
        match &plan.steps[0] {
            ExecutionStep::Sequential(steps) => {
                assert!(!steps.is_empty());
            }
            _ => panic!("Expected Sequential step for FIND"),
        }
    }
}
