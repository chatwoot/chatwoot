from fastapi import FastAPI

app = FastAPI(
    title="Identity Service",
    description="Manages users, accounts, and authentication for Conversate AI.",
    version="0.1.0",
)

@app.get("/")
def read_root():
    return {"service": "Identity Service", "status": "ok"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
