use crate::ast::*;
use thiserror::Error;

#[derive(Debug, Error, Clone)]
pub enum TypeError {
    #[error("Unknown field '{0}'")]
    UnknownField(String),
    #[error("Type mismatch: field '{0}' expects {1}")]
    TypeMismatch(String, String),
    #[error("Invalid currency code '{0}'")]
    InvalidCurrency(String),
    #[error("Invalid style '{0}'")]
    InvalidStyle(String),
    #[error("Invalid framework '{0}'")]
    InvalidFramework(String),
    #[error("Invalid platform '{0}'")]
    InvalidPlatform(String),
}

#[derive(Debug, Clone, PartialEq)]
pub enum FieldType {
    Number,
    Text,
    Percentage,
    Enum,
}

pub static KNOWN_FIELDS: &[(&str, FieldType)] = &[
    ("traffic.monthly", FieldType::Number),
    ("traffic.trend", FieldType::Percentage),
    ("traffic.change", FieldType::Percentage),
    ("revenue", FieldType::Number),
    ("geography", FieldType::Enum),
    ("currency.stability", FieldType::Number),
    ("rate.blended", FieldType::Number),
    ("opportunity_score", FieldType::Number),
    ("competitor", FieldType::Text),
    ("domain", FieldType::Text),
    ("market", FieldType::Text),
    ("technology", FieldType::Text),
    ("rate.change", FieldType::Percentage),
    ("competitor.traffic.trend", FieldType::Percentage),
];

pub static VALID_STYLES: &[&str] = &["static", "ugc-video", "carousel", "story"];
pub static VALID_FRAMEWORKS: &[&str] = &["AIDA", "PAS", "BAB", "before-after-bridge"];
pub static VALID_PLATFORMS: &[&str] = &["instagram", "tiktok", "google", "linkedin", "snapchat", "pinterest"];

pub static VALID_CURRENCIES: &[&str] = &[
    "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN",
    "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BOV",
    "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHE", "CHF",
    "CHW", "CLF", "CLP", "CNY", "COP", "COU", "CRC", "CUC", "CUP", "CVE",
    "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD",
    "FKP", "GBP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD",
    "HNL", "HTG", "HUF", "IDR", "ILS", "INR", "IQD", "IRR", "ISK", "JMD",
    "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD",
    "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA",
    "MKD", "MMK", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MXN", "MXV",
    "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB",
    "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RUB",
    "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE", "SLL",
    "SOS", "SRD", "SSP", "STN", "SVC", "SYP", "SZL", "THB", "TJS", "TMT",
    "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USD", "USN",
    "UYI", "UYU", "UYW", "UZS", "VED", "VES", "VND", "VUV", "WST", "XAF",
    "XAG", "XAU", "XBA", "XBB", "XBC", "XBD", "XCD", "XDR", "XOF", "XPD",
    "XPF", "XPT", "XSU", "XTS", "XUA", "XXX", "YER", "ZAR", "ZMW", "ZWL",
    // Additional commonly used
    "BTC", "ETH", "USDT", "BNB", "USDC", "XRP", "ADA", "SOL", "DOT", "DOGE",
];

pub struct TypeChecker;

impl TypeChecker {
    pub fn check(statements: &[Statement]) -> Result<(), TypeError> {
        for stmt in statements {
            match stmt {
                Statement::Scan(s) => Self::check_scan(s)?,
                Statement::Find(f) => Self::check_find(f)?,
                Statement::Generate(g) => Self::check_generate_stmt(g)?,
                Statement::Alert(a) => Self::check_alert(a)?,
                Statement::Analyse(_) => {}
            }
        }
        Ok(())
    }

    fn check_scan(s: &ScanStatement) -> Result<(), TypeError> {
        if let Some(ref w) = s.where_clause {
            Self::check_where_expr(w)?;
        }
        if let Some(ref c) = s.convert {
            Self::check_currency(&c.to_currency)?;
        }
        if let Some(ref g) = s.generate {
            Self::check_generate_clause(g)?;
        }
        if let Some(ref r) = s.rank {
            Self::check_field_path(&r.field)?;
        }
        Ok(())
    }

    fn check_find(f: &FindStatement) -> Result<(), TypeError> {
        if let Some(ref w) = f.where_clause {
            Self::check_where_expr(w)?;
        }
        if let Some(ref r) = f.rank {
            Self::check_field_path(&r.field)?;
        }
        if let Some(ref g) = f.generate {
            Self::check_generate_clause(g)?;
        }
        Ok(())
    }

    fn check_generate_stmt(g: &GenerateStatement) -> Result<(), TypeError> {
        if !g.style.is_empty() {
            Self::check_style(&g.style)?;
        }
        if let Some(ref fw) = g.framework {
            Self::check_framework(fw)?;
        }
        if let Some(ref p) = g.platform {
            Self::check_platform(p)?;
        }
        if let Some(ref c) = g.currency {
            Self::check_currency(c)?;
        }
        Ok(())
    }

    fn check_alert(a: &AlertStatement) -> Result<(), TypeError> {
        match &a.condition.subject {
            AlertSubject::Currency(pair, field) => {
                // Validate currency pair components
                for code in pair.split('/') {
                    Self::check_currency(code)?;
                }
                Self::check_field_path_str(field)?;
            }
            AlertSubject::Domain(_, field) => {
                Self::check_field_path_str(field)?;
            }
        }
        Ok(())
    }

    fn check_generate_clause(g: &GenerateClause) -> Result<(), TypeError> {
        if !g.style.is_empty() {
            Self::check_style(&g.style)?;
        }
        if let Some(ref fw) = g.framework {
            Self::check_framework(fw)?;
        }
        if let Some(ref p) = g.platform {
            Self::check_platform(p)?;
        }
        Ok(())
    }

    fn check_where_expr(expr: &WhereExpr) -> Result<(), TypeError> {
        match expr {
            WhereExpr::Condition(cmp) => {
                Self::check_comparison(cmp)?;
            }
            WhereExpr::And(l, r) | WhereExpr::Or(l, r) => {
                Self::check_where_expr(l)?;
                Self::check_where_expr(r)?;
            }
            WhereExpr::Not(inner) => {
                Self::check_where_expr(inner)?;
            }
        }
        Ok(())
    }

    fn check_comparison(cmp: &Comparison) -> Result<(), TypeError> {
        let path = cmp.field.as_str();
        let field_type = Self::lookup_field(&path)?;

        // Validate IN operator: only valid on Text/Enum fields
        if let CompareOp::In = &cmp.op {
            match field_type {
                FieldType::Text | FieldType::Enum => {}
                ft => {
                    return Err(TypeError::TypeMismatch(
                        path,
                        format!("IN operator not valid for {:?}", ft),
                    ));
                }
            }
        }

        // Validate numeric fields get numeric values
        if matches!(field_type, FieldType::Number | FieldType::Percentage) {
            if let Literal::Str(s) = &cmp.value {
                return Err(TypeError::TypeMismatch(
                    path,
                    format!("expected number, got string \"{}\"", s),
                ));
            }
        }

        Ok(())
    }

    fn check_field_path(fp: &FieldPath) -> Result<(), TypeError> {
        let path = fp.as_str();
        Self::lookup_field(&path)?;
        Ok(())
    }

    fn check_field_path_str(path: &str) -> Result<(), TypeError> {
        Self::lookup_field(path)?;
        Ok(())
    }

    fn lookup_field(path: &str) -> Result<&'static FieldType, TypeError> {
        for (known, ft) in KNOWN_FIELDS {
            if *known == path {
                return Ok(ft);
            }
        }
        Err(TypeError::UnknownField(path.to_string()))
    }

    fn check_currency(code: &str) -> Result<(), TypeError> {
        if VALID_CURRENCIES.contains(&code) {
            Ok(())
        } else {
            Err(TypeError::InvalidCurrency(code.to_string()))
        }
    }

    fn check_style(style: &str) -> Result<(), TypeError> {
        if VALID_STYLES.contains(&style) {
            Ok(())
        } else {
            Err(TypeError::InvalidStyle(style.to_string()))
        }
    }

    fn check_framework(fw: &str) -> Result<(), TypeError> {
        if VALID_FRAMEWORKS.contains(&fw) {
            Ok(())
        } else {
            Err(TypeError::InvalidFramework(fw.to_string()))
        }
    }

    fn check_platform(p: &str) -> Result<(), TypeError> {
        if VALID_PLATFORMS.contains(&p) {
            Ok(())
        } else {
            Err(TypeError::InvalidPlatform(p.to_string()))
        }
    }
}
