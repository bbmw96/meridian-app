use crate::ast::*;

pub struct SQLCodegen;

impl SQLCodegen {
    /// Converts a FIND statement with WHERE filters into a ClickHouse SQL query.
    pub fn emit_analytics(statement: &Statement) -> Option<String> {
        match statement {
            Statement::Find(f) => Some(Self::build_find_query(f)),
            Statement::Analyse(a) => Some(Self::build_analyse_query(a)),
            _ => None,
        }
    }

    fn build_find_query(f: &FindStatement) -> String {
        let mut sql = String::from(
            "SELECT domain, traffic_monthly, geography, market, opportunity_score, scanned_at\nFROM intelligence_signals",
        );

        if let Some(ref w) = f.where_clause {
            let predicate = Self::where_expr_to_sql(w);
            sql.push_str("\nWHERE ");
            sql.push_str(&predicate);
        }

        if let Some(ref rank) = f.rank {
            let col = Self::field_path_to_column(&rank.field.as_str());
            let dir = match rank.direction {
                SortDir::Asc => "ASC",
                SortDir::Desc => "DESC",
            };
            sql.push_str(&format!("\nORDER BY {} {}", col, dir));
        }

        if let Some(limit) = f.limit {
            sql.push_str(&format!("\nLIMIT {}", limit));
        }

        sql
    }

    fn build_analyse_query(a: &AnalyseStatement) -> String {
        let cols = if a.dimensions.is_empty() {
            "domain, traffic_monthly, geography, market, opportunity_score, scanned_at".to_string()
        } else {
            a.dimensions
                .iter()
                .map(|d| Self::field_path_to_column(d))
                .collect::<Vec<_>>()
                .join(", ")
        };

        let mut sql = format!("SELECT {}\nFROM intelligence_signals\nWHERE domain = {}", cols, Self::escape_string(&a.domain));

        if let Some(ref tf) = a.timeframe {
            sql.push_str(&format!(" AND scanned_at >= now() - INTERVAL {}", Self::escape_string(tf)));
        }

        sql
    }

    fn where_expr_to_sql(expr: &WhereExpr) -> String {
        match expr {
            WhereExpr::Condition(cmp) => Self::comparison_to_sql(cmp),
            WhereExpr::And(l, r) => {
                format!("({}) AND ({})", Self::where_expr_to_sql(l), Self::where_expr_to_sql(r))
            }
            WhereExpr::Or(l, r) => {
                format!("({}) OR ({})", Self::where_expr_to_sql(l), Self::where_expr_to_sql(r))
            }
            WhereExpr::Not(inner) => {
                format!("NOT ({})", Self::where_expr_to_sql(inner))
            }
        }
    }

    fn comparison_to_sql(cmp: &Comparison) -> String {
        let col = Self::field_path_to_column(&cmp.field.as_str());
        let val = Self::literal_to_sql(&cmp.value);

        match cmp.op {
            CompareOp::Gt => format!("{} > {}", col, val),
            CompareOp::Lt => format!("{} < {}", col, val),
            CompareOp::Gte => format!("{} >= {}", col, val),
            CompareOp::Lte => format!("{} <= {}", col, val),
            CompareOp::Eq => format!("{} = {}", col, val),
            CompareOp::Neq => format!("{} != {}", col, val),
            CompareOp::In => format!("{} IN {}", col, val),
        }
    }

    fn literal_to_sql(lit: &Literal) -> String {
        match lit {
            Literal::Str(s) => Self::escape_string(s),
            Literal::Int(n) => n.to_string(),
            Literal::Float(f) => format!("{:.6}", f),
            Literal::Bool(b) => if *b { "1".to_string() } else { "0".to_string() },
            Literal::List(items) => {
                let parts: Vec<String> = items.iter().map(Self::literal_to_sql).collect();
                format!("({})", parts.join(", "))
            }
        }
    }

    fn escape_string(s: &str) -> String {
        // Escape backslashes first, then single quotes
        let escaped = s.replace('\\', "\\\\").replace('\'', "\\'");
        format!("'{}'", escaped)
    }

    fn field_path_to_column(path: &str) -> &'static str {
        match path {
            "traffic.monthly" => "traffic_monthly",
            "traffic.trend" => "traffic_trend",
            "traffic.change" => "traffic_change",
            "revenue" => "revenue",
            "geography" => "geography",
            "currency.stability" => "currency_stability",
            "rate.blended" => "rate_blended",
            "opportunity_score" => "opportunity_score",
            "competitor" => "competitor",
            "domain" => "domain",
            "market" => "market",
            "technology" => "technology",
            "rate.change" => "rate_change",
            "competitor.traffic.trend" => "competitor_traffic_trend",
            _ => "unknown_field",
        }
    }
}
