use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Statement {
    Scan(ScanStatement),
    Find(FindStatement),
    Generate(GenerateStatement),
    Alert(AlertStatement),
    Analyse(AnalyseStatement),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanStatement {
    pub domain: String,
    pub compare: Option<CompareClause>,
    pub where_clause: Option<WhereExpr>,
    pub convert: Option<ConvertClause>,
    pub generate: Option<GenerateClause>,
    pub rank: Option<RankClause>,
    pub limit: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompareClause {
    pub subject: CompareSubject,
    pub top: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CompareSubject {
    Competitors,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WhereExpr {
    Condition(Comparison),
    And(Box<WhereExpr>, Box<WhereExpr>),
    Or(Box<WhereExpr>, Box<WhereExpr>),
    Not(Box<WhereExpr>),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Comparison {
    pub field: FieldPath,
    pub op: CompareOp,
    pub value: Literal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CompareOp {
    Gt,
    Lt,
    Gte,
    Lte,
    Eq,
    Neq,
    In,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FieldPath {
    pub parts: Vec<String>,
}

impl FieldPath {
    pub fn as_str(&self) -> String {
        self.parts.join(".")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Literal {
    Str(String),
    Int(i64),
    Float(f64),
    List(Vec<Literal>),
    Bool(bool),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvertClause {
    pub target_field: String,
    pub to_currency: String,
    pub using: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateClause {
    pub style: String,
    pub language: String,
    pub framework: Option<String>,
    pub platform: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RankClause {
    pub field: FieldPath,
    pub direction: SortDir,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SortDir {
    Asc,
    Desc,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FindStatement {
    pub target: String,
    pub where_clause: Option<WhereExpr>,
    pub rank: Option<RankClause>,
    pub limit: Option<u32>,
    pub generate: Option<GenerateClause>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateStatement {
    pub asset_type: String,
    pub for_domain: Option<String>,
    pub style: String,
    pub language: String,
    pub framework: Option<String>,
    pub platform: Option<String>,
    pub currency: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertStatement {
    pub condition: AlertCondition,
    pub notify_via: String,
    pub message: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlertCondition {
    pub subject: AlertSubject,
    pub op: CompareOp,
    pub value: Literal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AlertSubject {
    /// Currency pair (e.g. "USD", "GBP") + field path (e.g. "rate.change")
    Currency(String, String),
    /// Domain string + field path
    Domain(String, String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnalyseStatement {
    pub domain: String,
    pub dimensions: Vec<String>,
    pub timeframe: Option<String>,
    pub benchmark: Option<String>,
}
