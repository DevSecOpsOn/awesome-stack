import os
import json
from typing import Dict, Any

class UniversalAIConnectorService:
    def __init__(self, provider: str = "openai"):
        self.provider = provider.lower()
        self.system_manifest = """
        You are the backend engine of a Recruiter Optimization system. 
        Analyze the Candidate Profile against the Target Job Description.
        Return ONLY a clean, valid JSON object matching the requested schema. No markdown boundaries.
        
        Expected Format:
        {
          "match_percentage": 0.0,
          "matched_keywords": [],
          "missing_critical_keywords": [],
          "linkedin_optimization": {
            "optimized_headline": "",
            "about_appendix": "",
            "recommended_top_3_skills": []
          },
          "resume_bullet_updates": [
            {"original_bullet": "", "optimized_bullet": "", "justification": ""}
          ]
        }
        """

    def call_agent_skill(self, resume_json: Dict[str, Any], jd_text: str) -> Dict[str, Any]:
        prompt_content = f"Candidate Profile:\n{json.dumps(resume_json)}\n\nJob Description:\n{jd_text}"

        if self.provider == "anthropic":
            import anthropic
            client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
            message = client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4000,
                system=self.system_manifest,
                messages=[{"role": "user", "content": prompt_content}]
            )
            return json.loads(message.content.text)

        elif self.provider in ["openai", "kimi"]:
            from openai import OpenAI
            base_url = "https://api.moonshot.cn/v1" if self.provider == "kimi" else None
            api_key = os.getenv("KIMI_API_KEY") if self.provider == "kimi" else os.getenv("OPENAI_API_KEY")
            model_name = "moonshot-v1-8k" if self.provider == "kimi" else "gpt-4o-mini"
            client = OpenAI(api_key=api_key, base_url=base_url)
            response = client.chat.completions.create(
                model=model_name,
                response_format={"type": "json_object"} if self.provider == "openai" else None,
                messages=[
                    {"role": "system", "content": self.system_manifest},
                    {"role": "user", "content": prompt_content}
                ]
            )
            return json.loads(response.choices.message.content)

        elif self.provider == "ollama":
            import httpx
            ollama_url = os.getenv("OLLAMA_URL", "http://ollama-service:11434/api/chat")
            payload = {
                "model": os.getenv("OLLAMA_MODEL", "llama3"),
                "format": "json",
                "messages": [
                    {"role": "system", "content": self.system_manifest},
                    {"role": "user", "content": prompt_content}
                ],
                "stream": False
            }
            response = httpx.post(ollama_url, json=payload, timeout=60.0)
            return json.loads(response.json()["message"]["content"])
        else:
            raise ValueError(f"Provider absent: {self.provider}")
