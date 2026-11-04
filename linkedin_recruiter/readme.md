# 🤖 LinkedIn Recruiter Agent API - Quick Start Guide

This project is a high-performance **Dual-Architecture Recruiter Optimization Engine**. It automatically processes your profile metrics against target job descriptions to maximize your search visibility within the LinkedIn Recruiter indexing algorithms.

The server is currently containerized, healthy, and listening on **`http://localhost:8000`**.

---

## 🚀 How to Access and Use the Application

### 🖥️ Option 1: The Interactive Web Dashboard (Recommended)
Because the static assets layer is mounted natively to the application root, you can access a beautiful user interface straight from your browser.
1. Open your web browser.
2. Navigate to: **`http://localhost:8000/`**
3. Paste any live target Job Description URL, select your preferred AI Orchestrator Core from the dropdown menu, and click **"Analyze & Generate Strategy"**.

### 📖 Option 2: Interactive API Documentation (Swagger UI)
To explore the endpoints, inspect Pydantic schemas, or run test execution payloads directly from an interactive API wrapper:
* Navigate to: **`http://localhost:8000/docs`**

### 📈 Option 3: Real-Time Prometheus Telemetry Monitoring
Your application is fully instrumented to expose operational telemetry state metrics (request latencies, status counts, background worker jobs processed) to your scrapers:
* Navigate to: **`http://localhost:8000/metrics`**

---

## 💻 How to Trigger an Alignment Sweep via Terminal (cURL)

To simulate an automated sweep or integrate this microservice into your external scripting workflows, execute this payload from your terminal shell window:

```bash
curl -X 'POST' \
  'http://localhost:8000/api/v1/match' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "resume_id": "res_apple_retail_mgr",
  "job_url": "https://jobs.apple.com/en-us/details/200543210/retail-store-manager",
  "provider": "gemini"
}'
```

### 📥 Expected Asynchronous Server Acknowledgment
Because heavy language processing sweeps run in decoupled background workers to prevent client timeouts, the server responds **instantly** with an tracking execution token:

```json
{
  "task_id": "task_1700000000",
  "status": "QUEUED"
}
```

---

## 📊 How to Fetch the Finished Profile Optimization Report

Copy the exact `"task_id"` returned by the POST request above and run a `GET` query against the local task tracking database layer:

```bash
curl -X 'GET' 'http://localhost:8000/api/v1/tasks/task_1700000000'
```

### 📦 Structure of the Returned Optimization Payload
Once the background worker pool completes the sweep, your get request returns a valid JSON object tracking the calculated structural differentials:

```json
{
  "task_id": "task_1700000000",
  "status": "SUCCESS",
  "result": {
    "match_percentage": 89.40,
    "matched_keywords": ["Floor Leadership", "Team Coaching", "Inclusion"],
    "missing_critical_keywords": ["Asset Protection"],
    "linkedin_optimization": {
      "optimized_headline": "Store Manager | Retail Operations & Team Leader...",
      "about_appendix": "CORE COMPETENCIES: People Leadership, Floor Operations...",
      "recommended_top_3_skills": ["Retail Management", "Team Leadership", "Customer Experience"]
    },
    "resume_bullet_updates": [
      {
        "original_bullet": "Managed daily team schedules and operations...",
        "optimized_bullet": "Led high-touch Floor Leadership parameters and aligned team configurations...",
        "justification": "Directly matches Apple Retail criteria for active floor coaching patterns."
      }
    ]
  }
}
```

---

## 🛠️ Modifying the Orchestration Core on the Fly
You can change model backends instantly by updating the `"provider"` field inside your POST payload. The universal client mapping layer handles token packaging and communication automatically:
* `"gemini"`: Employs the high-speed primary default type-safe model via Google GenAI SDK.
* `"anthropic"`: Routes the alignment processing to Claude 3.5 Sonnet.
* `"kimi"`: Triggers the Moonshot Core text engineering loop.
* `"ollama"`: Processes the entire payload **100% on-premise** using your local containerized Llama 3 instance.
