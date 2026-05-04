pub mod ast;
pub mod codegen;
pub mod lexer;
pub mod parser;
pub mod runtime;
pub mod token;
pub mod typechecker;

pub use parser::Parser;
pub use runtime::{ExecutionResult, Runtime};
pub use codegen::ExecutionPlan;

use lexer::{LexError, Lexer};
use parser::ParseError;
use typechecker::{TypeChecker, TypeError};
use wasm_bindgen::prelude::*;

#[derive(Debug, thiserror::Error)]
pub enum MQLError {
    #[error("Lex error: {0}")]
    LexError(#[from] LexError),
    #[error("Parse error: {0}")]
    ParseError(#[from] ParseError),
    #[error("Type error: {0}")]
    TypeError(#[from] TypeError),
    #[error("Runtime error: {0}")]
    RuntimeError(#[from] runtime::RuntimeError),
}

/// Compile MQL source into an ExecutionPlan.
pub fn compile(source: &str) -> Result<ExecutionPlan, MQLError> {
    let mut lexer = Lexer::new(source);
    let tokens = lexer.tokenise()?;

    let mut parser = Parser::new(tokens);
    let statements = parser.parse()?;

    TypeChecker::check(&statements)?;

    let plan = codegen::generate(&statements);
    Ok(plan)
}

/// WASM-exported entry point. Returns JSON string of ExecutionPlan or an error object.
#[wasm_bindgen]
pub fn compile_mql(source: &str) -> String {
    match compile(source) {
        Ok(plan) => {
            let result = serde_json::json!({
                "ok": true,
                "plan": plan,
            });
            result.to_string()
        }
        Err(e) => {
            let result = serde_json::json!({
                "ok": false,
                "error": e.to_string(),
            });
            result.to_string()
        }
    }
}
