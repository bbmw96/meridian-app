use crate::codegen::{ExecutionPlan, ExecutionStep};
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ExecutionResult {
    ScanData(serde_json::Value),
    OpportunityList(serde_json::Value),
    CreativeData(serde_json::Value),
    AlertCreated,
    SQLResult(serde_json::Value),
    Error(String),
}

#[derive(Debug, Error)]
pub enum RuntimeError {
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
}

/// Dry-run executor — evaluates an ExecutionPlan and returns structured
/// simulation results. Actual HTTP calls are made by the caller (iOS
/// APIClient.swift) using the plan's steps directly.
pub struct Runtime {
    pub base_url: String,
    pub api_key: Option<String>,
}

impl Runtime {
    pub fn new(base_url: impl Into<String>) -> Self {
        Runtime { base_url: base_url.into(), api_key: None }
    }

    pub fn with_api_key(mut self, key: impl Into<String>) -> Self {
        self.api_key = Some(key.into());
        self
    }

    pub fn dry_run(&self, plan: &ExecutionPlan) -> Result<Vec<ExecutionResult>, RuntimeError> {
        execute_plan(plan)
    }
}

pub fn execute_plan(plan: &ExecutionPlan) -> Result<Vec<ExecutionResult>, RuntimeError> {
    let mut results = Vec::new();
    for step in &plan.steps {
        results.extend(execute_step(step)?);
    }
    Ok(results)
}

fn execute_step(step: &ExecutionStep) -> Result<Vec<ExecutionResult>, RuntimeError> {
    match step {
        ExecutionStep::APICall(inst) => {
            let result = serde_json::json!({
                "endpoint": inst.endpoint,
                "method": format!("{:?}", inst.method),
                "params": inst.params,
            });
            let exec_result = if inst.endpoint.contains("scan") {
                ExecutionResult::ScanData(result)
            } else if inst.endpoint.contains("opportunities") {
                ExecutionResult::OpportunityList(result)
            } else if inst.endpoint.contains("creative") {
                ExecutionResult::CreativeData(result)
            } else if inst.endpoint.contains("alerts") {
                ExecutionResult::AlertCreated
            } else {
                ExecutionResult::ScanData(result)
            };
            Ok(vec![exec_result])
        }
        ExecutionStep::SQLQuery(sql) => Ok(vec![ExecutionResult::SQLResult(
            serde_json::json!({"sql": sql, "rows": []}),
        )]),
        ExecutionStep::MLInference(task) => Ok(vec![ExecutionResult::CreativeData(
            serde_json::json!({"model": task.model_hint, "prompt_length": task.prompt.len()}),
        )]),
        ExecutionStep::Parallel(steps) | ExecutionStep::Sequential(steps) => {
            let mut results = Vec::new();
            for s in steps {
                results.extend(execute_step(s)?);
            }
            Ok(results)
        }
    }
}
