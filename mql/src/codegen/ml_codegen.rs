use crate::ast::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

const AIDA_TEMPLATE: &str = r#"You are a world-class copywriter. Write using the AIDA framework:

ATTENTION: Open with a bold, attention-grabbing headline that speaks directly to the target audience's pain point or desire.
INTEREST: Build interest by highlighting key features and unique value propositions. Use specific facts and statistics.
DESIRE: Create desire by showing transformation - before vs after. Use social proof and emotional triggers.
ACTION: Close with a clear, urgent call-to-action that removes friction and guides next steps.

Tone: Professional yet conversational. Language: {language}.
Format: {format}.
Domain context: {domain_context}
"#;

const PAS_TEMPLATE: &str = r#"You are an expert direct-response copywriter. Write using the PAS framework:

PROBLEM: Identify and articulate the core problem your audience faces. Make them feel understood.
AGITATE: Intensify the problem - explore the consequences, frustrations, and costs of not solving it.
SOLUTION: Present your offer as the clear, logical solution. Be specific about benefits, not features.

Tone: Empathetic and urgent. Language: {language}.
Format: {format}.
Domain context: {domain_context}
"#;

const BAB_TEMPLATE: &str = r#"You are a conversion-focused copywriter. Write using the Before-After-Bridge framework:

BEFORE: Paint a vivid picture of the audience's current reality - their struggles, frustrations, and unmet needs.
AFTER: Describe the aspirational future state after using the product/service. Be specific and emotionally resonant.
BRIDGE: Show exactly how you get them from Before to After. This is your product/service. Make the path clear and credible.

Tone: Inspiring and clear. Language: {language}.
Format: {format}.
Domain context: {domain_context}
"#;

const BEFORE_AFTER_BRIDGE_TEMPLATE: &str = r#"You are a master storyteller-copywriter. Write using the extended Before-After-Bridge framework:

BEFORE: Describe life before your solution in vivid, relatable detail. Capture the emotional weight of the problem.
AFTER: Paint the transformed future. What does success look, feel, and sound like? Be concrete.
BRIDGE: Present your solution as the inevitable path between before and after. Use specifics: features, timeline, proof.
CALL TO ACTION: End with a single, frictionless next step.

Language: {language}.
Format: {format}.
Domain context: {domain_context}
"#;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MLTask {
    pub model_hint: String,
    pub prompt: String,
    pub params: HashMap<String, serde_json::Value>,
}

pub struct MLCodegen;

impl MLCodegen {
    pub fn emit(statement: &GenerateStatement) -> MLTask {
        let model_hint = Self::select_model(&statement.style);
        let prompt = Self::build_prompt(statement);
        let mut params: HashMap<String, serde_json::Value> = HashMap::new();

        params.insert("style".to_string(), serde_json::Value::String(statement.style.clone()));
        params.insert("language".to_string(), serde_json::Value::String(statement.language.clone()));
        params.insert("asset_type".to_string(), serde_json::Value::String(statement.asset_type.clone()));

        if let Some(ref fw) = statement.framework {
            params.insert("framework".to_string(), serde_json::Value::String(fw.clone()));
        }
        if let Some(ref p) = statement.platform {
            params.insert("platform".to_string(), serde_json::Value::String(p.clone()));
            params.insert(
                "aspect_ratio".to_string(),
                serde_json::Value::String(Self::platform_aspect_ratio(p).to_string()),
            );
        }
        if let Some(ref d) = statement.for_domain {
            params.insert("domain".to_string(), serde_json::Value::String(d.clone()));
        }

        // Temperature and sampling
        params.insert("temperature".to_string(), serde_json::json!(0.8));
        params.insert("max_tokens".to_string(), serde_json::json!(2048));

        MLTask { model_hint, prompt, params }
    }

    fn select_model(style: &str) -> String {
        match style {
            "ugc-video" => "kling-v2".to_string(),
            "static" => "stable-diffusion-xl".to_string(),
            "carousel" => "dall-e-3".to_string(),
            "story" => "stable-diffusion-xl".to_string(),
            _ => "gpt-4o".to_string(),
        }
    }

    fn build_prompt(g: &GenerateStatement) -> String {
        let language = &g.language;
        let format = &g.style;
        let domain_context = g
            .for_domain
            .as_deref()
            .unwrap_or("general business")
            .to_string();

        let framework_template = g.framework.as_deref().unwrap_or("AIDA");

        let base = match framework_template {
            "AIDA" => AIDA_TEMPLATE,
            "PAS" => PAS_TEMPLATE,
            "BAB" => BAB_TEMPLATE,
            "before-after-bridge" => BEFORE_AFTER_BRIDGE_TEMPLATE,
            _ => AIDA_TEMPLATE,
        };

        let prompt = base
            .replace("{language}", language)
            .replace("{format}", format)
            .replace("{domain_context}", &domain_context);

        // Append platform-specific guidance if specified
        if let Some(ref platform) = g.platform {
            format!(
                "{}\nPlatform: {}. Optimise for {} content consumption patterns and character/duration limits.",
                prompt,
                platform,
                platform
            )
        } else {
            prompt
        }
    }

    fn platform_aspect_ratio(platform: &str) -> &'static str {
        match platform {
            "instagram" => "1:1",
            "tiktok" => "9:16",
            "google" => "16:9",
            "linkedin" => "1.91:1",
            "snapchat" => "9:16",
            "pinterest" => "2:3",
            _ => "1:1",
        }
    }
}
