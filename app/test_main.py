import main


def test_root_reads_config(monkeypatch):
    monkeypatch.setenv("WELCOME_MESSAGE", "hi")
    monkeypatch.setenv("API_KEY", "x")
    body = main.app.test_client().get("/").get_json()
    assert body["message"] == "hi" and body["api_key_configured"] is True


def test_readiness_warmup(monkeypatch):
    client = main.app.test_client()
    monkeypatch.setattr(main, "STARTED", main.time.time())
    monkeypatch.setattr(main, "WARMUP_SECONDS", 60)
    assert client.get("/readyz").status_code == 503
    monkeypatch.setattr(main, "WARMUP_SECONDS", 0)
    assert client.get("/readyz").status_code == 200
    assert client.get("/healthz").status_code == 200
