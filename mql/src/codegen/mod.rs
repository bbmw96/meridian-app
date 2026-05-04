pub mod api_codegen;
pub mod sql_codegen;
pub mod ml_codegen;

pub use api_codegen::APICodegen;
pub use ml_codegen::MLCodegen;
pub use sql_codegen::SQLCodegen;

use crate::ast::Statement;
use api_codegen::APIInstruction;
use ml_codegen::MLTask;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionPlan {
    pub steps: Vec<ExecutionStep>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ExecutionStep {
    APICall(APIInstruction),
    SQLQuery(String),
    MLInference(MLTask),
    Parallel(Vec<ExecutionStep>),
    Sequential(Vec<ExecutionStep>),
}

pub fn generate(statements: &[Statement]) -> ExecutionPlan {
    let mut steps = Vec::new();

    for stmt in statements {
        match stmt {
            Statement::Generate(g) => {
                // Generate gets both API call AND ML task
                let api_instructions = APICodegen::emit(&[stmt.clone()]);
                let ml_task = MLCodegen::emit(g);

                let parallel_steps = vec![
                    ExecutionStep::APICall(api_instructions.into_iter().next().unwrap()),
                    ExecutionStep::MLInference(ml_task),
                ];
                steps.push(ExecutionStep::Parallel(parallel_steps));
            }
            Statement::Find(f) => {
                // Find generates both API call and SQL
                let api_instructions = APICodegen::emit(&[stmt.clone()]);
                let sql = SQLCodegen::emit_analytics(stmt);

                let mut seq_steps = Vec::new();
                if let Some(query) = sql {
                    seq_steps.push(ExecutionStep::SQLQuery(query));
                }
                if let Some(api) = api_instructions.into_iter().next() {
                    seq_steps.push(ExecutionStep::APICall(api));
                }
                steps.push(ExecutionStep::Sequential(seq_steps));
            }
            Statement::Analyse(_) => {
                let api_instructions = APICodegen::emit(&[stmt.clone()]);
                let sql = SQLCodegen::emit_analytics(stmt);

                let mut seq_steps = Vec::new();
                if let Some(query) = sql {
                    seq_steps.push(ExecutionStep::SQLQuery(query));
                }
                if let Some(api) = api_instructions.into_iter().next() {
                    seq_steps.push(ExecutionStep::APICall(api));
                }
                steps.push(ExecutionStep::Sequential(seq_steps));
            }
            _ => {
                let api_instructions = APICodegen::emit(&[stmt.clone()]);
                for inst in api_instructions {
                    steps.push(ExecutionStep::APICall(inst));
                }
            }
        }
    }

    ExecutionPlan { steps }
}
