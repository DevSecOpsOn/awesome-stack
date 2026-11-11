import time
import os
import json
import asyncio
from fastapi import FastAPI, BackgroundTasks, status, HTTPException
from fastapi.responses import PlainTextResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
import asyncpg

from app.services.orchestrator import LLMOrchestrationService
from app.services.universal_client import UniversalAIConnectorService

app = FastAPI(title="LinkedIn Recruiter Search Dual Architecture Agent API", version="3.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@host.docker.internal:5432/linkedin_agent")
db_pool = None

class MatchRequest(BaseModel):
    resume_id: str
    job_url: HttpUrl
    provider: str = "gemini"

@app.on_event("startup")
async def startup_event():
    global db_pool
    db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    async with db_pool.acquire() as conn:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS match_reports (
                id VARCHAR(50) PRIMARY KEY,
                status VARCHAR(20) NOT NULL,
                provider VARCHAR(20) NOT NULL,
                job_url TEXT NOT NULL,
                match_percentage NUMERIC(5,2),
                result_payload JSONB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

@app.on_event("shutdown")
async def shutdown_event():
    if db_pool: await db_pool.close()

def execute_dual_architecture_pipeline(task_id: str, job_url: str, provider: str):
    mock_db_resume = {
        "name": "Rodrigo de Carvalho",
        "current_headline": "Lead Platform Engineer",
        "key_skills": ["AWS", "Kubernetes", "Terraform", "ArgoCD"],
        "recent_bullets": ["Architect multi-cloud Kubernetes platforms."]
    }
    mock_scraped_text = f"Seeking Senior Platform Engineer proficient with AWS, Kubernetes, and ArgoCD for link: {job_url}."

    try:
        provider_clean = provider.lower()
        if provider_clean == "gemini":
            orchestrator = LLMOrchestrationService()
            report = orchestrator.analyze_and_align(mock_db_resume, mock_scraped_text)
            final_json = report.model_dump()
            score = report.match_percentage
        else:
            connector = UniversalAIConnectorService(provider=provider_clean)
            final_json = connector.call_agent_skill(mock_db_resume, mock_scraped_text)
            score = final_json.get("match_percentage", 0.0)

        async def save_success():
            async with db_pool.acquire() as conn:
                await conn.execute(
                    "UPDATE match_reports SET status=$1, match_percentage=$2, result_payload=$3 WHERE id=$4",
                    "SUCCESS", score, json.dumps(final_json), task_id
                )
        asyncio.run(save_success())
    except Exception as e:
        async def save_failure():
            async with db_pool.acquire() as conn:
                await conn.execute(
                    "UPDATE match_reports SET status=$1, result_payload=$2 WHERE id=$3",
                    "FAILED", json.dumps({"error": str(e)}), task_id
                )
        asyncio.run(save_failure())

@app.post("/api/v1/match", status_code=status.HTTP_202_ACCEPTED)
async def trigger_resume_match(payload: MatchRequest, background_tasks: BackgroundTasks):
    task_id = f"task_{int(time.time())}"
    async with db_pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO match_reports (id, status, provider, job_url) VALUES ($1, $2, $3, $4)",
            task_id, "PROCESSING", payload.provider, str(payload.job_url)
        )
    background_tasks.add_task(execute_dual_architecture_pipeline, task_id, str(payload.job_url), payload.provider)
    return {"task_id": task_id, "status": "QUEUED"}

@app.get("/api/v1/tasks/{task_id}")
async def get_task_status(task_id: str):
    async with db_pool.acquire() as conn:
        record = await conn.fetchrow("SELECT status, result_payload FROM match_reports WHERE id=$1", task_id)
    if not record:
        raise HTTPException(status_code=404, detail="Task missing.")
    return {"task_id": task_id, "status": record["status"], "result": json.loads(record["result_payload"]) if record["result_payload"] else None}

app.mount("/", StaticFiles(directory="static", html=True), name="static")
