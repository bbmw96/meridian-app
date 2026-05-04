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
    #[error("Network error: {0}")]
    NetworkError(String),
    #[error("Deserialisation error: {0}")]
    DeserializationError(String),
    #[error("Execution failed: {0}")]
    ExecutionFailed(String),
}

#[allow(dead_code)]
pub struct Runtime {
    pub base_url: String,
    pub api_key: Option<String>,
}

impl Runtime {
    pub fn new(base_url: impl Into<String>) -> Self {
        Runtime {
            base_url: base_url.into(),
            api_key: None,
        }
    }

    pub fn with_api_key(mut self, key: impl Into<String>) -> Self {
        self.api_key = Some(key.into());
        self
    }
}

/// Execute an ExecutionPlan and return results.
/// In WASM builds, this operates in a simulation mode since reqwest blocking is unavailable.
pub fn execute_plan(plan: &ExecutionPlan) -> Result<Vec<ExecutionResult>, RuntimeError> {
    let mut results = Vec::new();

    for step in &plan.steps {
        let step_results = execute_step(step)?;
        results.extend(step_results);
    }

    Ok(results)
}

fn execute_step(step: &ExecutionStep) -> Result<Vec<ExecutionResult>, RuntimeError> {
    match step {
        ExecutionStep::APICall(inst) => {
            // In WASM / no-network builds, return a structured placeholder
            // In native builds with reqwest this would make real HTTP calls
            let result = serde_json::json!({
                "simulated": true,
                "endpoint": inst.endpoint,
                "method": format!("{:?}", inst.method),
                "params": inst.params,
            });

            let endpoint = &inst.endpoint;
            let exec_result = if endpoint.contains("scan") {
                ExecutionResult::ScanData(result)
            } else if endpoint.contains("opportunities") {
                ExecutionResult::OpportunityList(result)
            } else if endpoint.contains("creative") {
                ExecutionResult::CreativeData(result)
            } else if endpoint.contains("alerts") {
                ExecutionResult::AlertCreated
            } else {
                ExecutionResult::ScanData(result)
            };

            Ok(vec![exec_result])
        }
        ExecutionStep::SQLQuery(sql) => {
            let result = serde_json::json!({
                "simulated": true,
                "sql": sql,
                "rows": [],
            });
            Ok(vec![ExecutionResult::SQLResult(result)])
        }
        ExecutionStep::MLInference(task) => {
            let result = serde_json::json!({
                "simulated": true,
                "model": task.model_hint,
                "prompt_length": task.prompt.len(),
                "params": task.params,
            });
            Ok(vec![ExecutionResult::CreativeData(result)])
        }
        ExecutionStep::Parallel(steps) => {
            let mut results = Vec::new();
            for s in steps {
                results.extend(execute_step(s)?);
            }
            Ok(results)
        }
        ExecutionStep::Sequential(steps) => {
            let mut results = Vec::new();
            for s in steps {
                results.extend(execute_step(s)?);
            }
            Ok(results)
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
pub mod native {
    use super::*;
    use crate::codegen::api_codegen::{APIInstruction, HTTPMethod};

    pub struct NativeRuntime {
        pub client: reqwest::blocking::Client,
        pub base_url: String,
        pub api_key: Option<String>,
    }

    impl NativeRuntime {
        pub fn new(base_url: impl Into<String>) -> Self {
            NativeRuntime {
                client: reqwest::blocking::Client::new(),
                base_url: base_url.into(),
                api_key: None,
            }
        }

        pub fn execute_api_call(
            &self,
            inst: &APIInstruction,
        ) -> Result<serde_json::Value, RuntimeError> {
            let url = format!("{}{}", self.base_url, inst.endpoint);

            let mut builder = match inst.method {
                HTTPMethod::GET => {
                    let mut req = self.client.get(&url);
                    for (k, v) in &inst.params {
                        if let Some(s) = v.as_str() {
                            req = req.query(&[(k.as_str(), s)]);
                        }
                    }
                    req
                }
                HTTPMethod::POST => self.client.post(&url).json(&inst.params),
                HTTPMethod::PUT => self.client.put(&url).json(&inst.params),
                HTTPMethod::DELETE => self.client.delete(&url),
            };

            for (k, v) in &inst.headers {
                builder = builder.header(k.as_str(), v.as_str());
            }

            if let Some(ref key) = self.api_key {
                builder = builder.header("X-API-Key", key.as_str());
            }

            let response = builder
                .send()
                .map_err(|e| RuntimeError::NetworkError(e.to_string()))?;

            let json: serde_json::Value = response
                .json()
                .map_err(|e| RuntimeError::DeserializationError(e.to_string()))?;

            Ok(json)
        }
    }
}
