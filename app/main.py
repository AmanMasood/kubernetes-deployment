"""Demo service for Kubernetes: reads ConfigMap/Secret values, exposes probes."""
import os
import socket
import time

from flask import Flask, jsonify

app = Flask(__name__)
STARTED = time.time()
WARMUP_SECONDS = float(os.environ.get("WARMUP_SECONDS", "3"))


@app.get("/")
def index():
    return jsonify(
        message=os.environ.get("WELCOME_MESSAGE", "Hello from Kubernetes"),
        pod=socket.gethostname(),
        environment=os.environ.get("APP_ENV", "dev"),
        api_key_configured=bool(os.environ.get("API_KEY")),
    )


@app.get("/healthz")
def liveness():
    """Liveness: the process is running."""
    return jsonify(status="alive")


@app.get("/readyz")
def readiness():
    """Readiness: only accept traffic after warm-up (simulates cache loading)."""
    if time.time() - STARTED < WARMUP_SECONDS:
        return jsonify(status="warming-up"), 503
    return jsonify(status="ready")
