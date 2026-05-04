use crate::ast::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum HTTPMethod {
    GET,
    POST,
    PUT,
    DELETE,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct APIInstruction {
    pub method: HTTPMethod,
    pub endpoint: String,
    pub params: HashMap<String, serde_json::Value>,
    pub headers: HashMap<String, String>,
}

pub struct APICodegen;

impl APICodegen {
    pub fn emit(statements: &[Statement]) -> Vec<APIInstruction> {
        let mut instructions = Vec::new();
        for stmt in statements {
            match stmt {
                Statement::Scan(s) => instructions.push(Self::emit_scan(s)),
                Statement::Find(f) => instructions.push(Self::emit_find(f)),
                Statement::Generate(g) => instructions.push(Self::emit_generate(g)),
                Statement::Alert(a) => instructions.push(Self::emit_alert(a)),
                Statement::Analyse(a) => instructions.push(Self::emit_analyse(a)),
            }
        }
        instructions
    }

    fn emit_scan(s: &ScanStatement) -> APIInstruction {
        let mut params: HashMap<String, serde_json::Value> = HashMap::new();
        params.insert("domain".to_string(), serde_json::Value::String(s.domain.clone()));

        if let Some(ref cmp) = s.compare {
            match cmp.subject {
                CompareSubject::Competitors => {
                    params.insert("compare".to_string(), serde_json::Value::String("competitors".to_string()));
                }
            }
            if let Some(top) = cmp.top {
                params.insert("top".to_string(), serde_json::Value::Number(top.into()));
            }
        }

        if let Some(ref w) = s.where_clause {
            params.insert("filter".to_string(), where_expr_to_json(w));
        }

        if let Some(ref conv) = s.convert {
            params.insert("convert_field".to_string(), serde_json::Value::String(conv.target_field.clone()));
            params.insert("convert_to".to_string(), serde_json::Value::String(conv.to_currency.clone()));
        }

        if let Some(ref rank) = s.rank {
            params.insert("rank_by".to_string(), serde_json::Value::String(rank.field.as_str()));
            params.insert("direction".to_string(), serde_json::Value::String(
                match rank.direction {
                    SortDir::Asc => "asc".to_string(),
                    SortDir::Desc => "desc".to_string(),
                }
            ));
        }

        if let Some(limit) = s.limit {
            params.insert("limit".to_string(), serde_json::Value::Number(limit.into()));
        }

        let mut headers = HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        headers.insert("X-MQL-Version".to_string(), "1.0".to_string());

        APIInstruction {
            method: HTTPMethod::GET,
            endpoint: "/api/v1/intelligence/scan".to_string(),
            params,
            headers,
        }
    }

    fn emit_find(f: &FindStatement) -> APIInstruction {
        let mut body: HashMap<String, serde_json::Value> = HashMap::new();
        body.insert("target".to_string(), serde_json::Value::String(f.target.clone()));

        if let Some(ref w) = f.where_clause {
            body.insert("filter".to_string(), where_expr_to_json(w));
        }

        if let Some(ref rank) = f.rank {
            body.insert("rank_by".to_string(), serde_json::Value::String(rank.field.as_str()));
            body.insert("direction".to_string(), serde_json::Value::String(
                match rank.direction {
                    SortDir::Asc => "asc".to_string(),
                    SortDir::Desc => "desc".to_string(),
                }
            ));
        }

        if let Some(limit) = f.limit {
            body.insert("limit".to_string(), serde_json::Value::Number(limit.into()));
        }

        let mut headers = HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        headers.insert("X-MQL-Version".to_string(), "1.0".to_string());

        APIInstruction {
            method: HTTPMethod::POST,
            endpoint: "/api/v1/radar/opportunities".to_string(),
            params: body,
            headers,
        }
    }

    fn emit_generate(g: &GenerateStatement) -> APIInstruction {
        let mut body: HashMap<String, serde_json::Value> = HashMap::new();
        body.insert("asset_type".to_string(), serde_json::Value::String(g.asset_type.clone()));
        body.insert("style".to_string(), serde_json::Value::String(g.style.clone()));
        body.insert("language".to_string(), serde_json::Value::String(g.language.clone()));

        if let Some(ref fw) = g.framework {
            body.insert("framework".to_string(), serde_json::Value::String(fw.clone()));
        }
        if let Some(ref p) = g.platform {
            body.insert("platform".to_string(), serde_json::Value::String(p.clone()));
        }
        if let Some(ref d) = g.for_domain {
            body.insert("domain".to_string(), serde_json::Value::String(d.clone()));
        }
        if let Some(ref c) = g.currency {
            body.insert("currency".to_string(), serde_json::Value::String(c.clone()));
        }

        let mut headers = HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        headers.insert("X-MQL-Version".to_string(), "1.0".to_string());

        APIInstruction {
            method: HTTPMethod::POST,
            endpoint: "/api/v1/creative/generate".to_string(),
            params: body,
            headers,
        }
    }

    fn emit_alert(a: &AlertStatement) -> APIInstruction {
        let mut body: HashMap<String, serde_json::Value> = HashMap::new();

        let (subject_type, subject_value, field) = match &a.condition.subject {
            AlertSubject::Currency(pair, f) => ("currency", pair.clone(), f.clone()),
            AlertSubject::Domain(d, f) => ("domain", d.clone(), f.clone()),
        };

        body.insert("subject_type".to_string(), serde_json::Value::String(subject_type.to_string()));
        body.insert("subject_value".to_string(), serde_json::Value::String(subject_value));
        body.insert("field".to_string(), serde_json::Value::String(field));
        body.insert("op".to_string(), serde_json::Value::String(op_to_str(&a.condition.op).to_string()));
        body.insert("threshold".to_string(), literal_to_json(&a.condition.value));
        body.insert("notify_via".to_string(), serde_json::Value::String(a.notify_via.clone()));

        if let Some(ref msg) = a.message {
            body.insert("message".to_string(), serde_json::Value::String(msg.clone()));
        }

        let mut headers = HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        headers.insert("X-MQL-Version".to_string(), "1.0".to_string());

        APIInstruction {
            method: HTTPMethod::POST,
            endpoint: "/api/v1/alerts".to_string(),
            params: body,
            headers,
        }
    }

    fn emit_analyse(a: &AnalyseStatement) -> APIInstruction {
        let mut body: HashMap<String, serde_json::Value> = HashMap::new();
        body.insert("domain".to_string(), serde_json::Value::String(a.domain.clone()));
        body.insert(
            "dimensions".to_string(),
            serde_json::Value::Array(
                a.dimensions.iter().map(|d| serde_json::Value::String(d.clone())).collect(),
            ),
        );
        if let Some(ref tf) = a.timeframe {
            body.insert("timeframe".to_string(), serde_json::Value::String(tf.clone()));
        }
        if let Some(ref bm) = a.benchmark {
            body.insert("benchmark".to_string(), serde_json::Value::String(bm.clone()));
        }

        let mut headers = HashMap::new();
        headers.insert("Content-Type".to_string(), "application/json".to_string());
        headers.insert("X-MQL-Version".to_string(), "1.0".to_string());

        APIInstruction {
            method: HTTPMethod::POST,
            endpoint: "/api/v1/intelligence/analyse".to_string(),
            params: body,
            headers,
        }
    }
}

fn where_expr_to_json(expr: &WhereExpr) -> serde_json::Value {
    match expr {
        WhereExpr::Condition(cmp) => {
            let mut m = serde_json::Map::new();
            m.insert("type".to_string(), serde_json::Value::String("condition".to_string()));
            m.insert("field".to_string(), serde_json::Value::String(cmp.field.as_str()));
            m.insert("op".to_string(), serde_json::Value::String(op_to_str(&cmp.op).to_string()));
            m.insert("value".to_string(), literal_to_json(&cmp.value));
            serde_json::Value::Object(m)
        }
        WhereExpr::And(l, r) => {
            let mut m = serde_json::Map::new();
            m.insert("type".to_string(), serde_json::Value::String("and".to_string()));
            m.insert("left".to_string(), where_expr_to_json(l));
            m.insert("right".to_string(), where_expr_to_json(r));
            serde_json::Value::Object(m)
        }
        WhereExpr::Or(l, r) => {
            let mut m = serde_json::Map::new();
            m.insert("type".to_string(), serde_json::Value::String("or".to_string()));
            m.insert("left".to_string(), where_expr_to_json(l));
            m.insert("right".to_string(), where_expr_to_json(r));
            serde_json::Value::Object(m)
        }
        WhereExpr::Not(inner) => {
            let mut m = serde_json::Map::new();
            m.insert("type".to_string(), serde_json::Value::String("not".to_string()));
            m.insert("inner".to_string(), where_expr_to_json(inner));
            serde_json::Value::Object(m)
        }
    }
}

fn op_to_str(op: &CompareOp) -> &'static str {
    match op {
        CompareOp::Gt => "gt",
        CompareOp::Lt => "lt",
        CompareOp::Gte => "gte",
        CompareOp::Lte => "lte",
        CompareOp::Eq => "eq",
        CompareOp::Neq => "neq",
        CompareOp::In => "in",
    }
}

pub fn literal_to_json(lit: &Literal) -> serde_json::Value {
    match lit {
        Literal::Str(s) => serde_json::Value::String(s.clone()),
        Literal::Int(n) => serde_json::Value::Number((*n).into()),
        Literal::Float(f) => {
            serde_json::Number::from_f64(*f)
                .map(serde_json::Value::Number)
                .unwrap_or(serde_json::Value::Null)
        }
        Literal::List(items) => {
            serde_json::Value::Array(items.iter().map(literal_to_json).collect())
        }
        Literal::Bool(b) => serde_json::Value::Bool(*b),
    }
}
