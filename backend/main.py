import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from routers import ad_router, exchange_router, linux_router, nas_router, vmware_router, windows_router, zabbix_router

BASE_DIR = Path(__file__).resolve().parent.parent
FRONTEND_DIR = BASE_DIR / "frontend"
app = FastAPI(title="SysAdmin Control Center", version="1.0.0")
for router in (windows_router.router, ad_router.router, vmware_router.router, linux_router.router, exchange_router.router, nas_router.router, zabbix_router.router):
    app.include_router(router, prefix="/api")

@app.get("/", include_in_schema=False)
def dashboard():
    return FileResponse(FRONTEND_DIR / "index.html")

@app.get("/api/status", tags=["System"])
def status():
    """Expose connector readiness without ever exposing credentials."""
    return {
        "application": "SysAdmin Control Center",
        "connectors": {
            "active_directory": (BASE_DIR / "scripts" / "AD" / "Get-ADUserStatus.ps1").is_file(),
            "windows": (BASE_DIR / "scripts" / "Get-SystemDiagnostics.ps1").is_file(),
            "vmware": bool(os.getenv("SACC_VMWARE_ENABLED")),
            "linux": bool(os.getenv("SACC_LINUX_ENABLED")),
            "exchange": bool(os.getenv("SACC_EXCHANGE_ENABLED")),
            "nas": bool(os.getenv("SACC_NAS_ENABLED")),
            "zabbix": bool(os.getenv("ZABBIX_URL") and os.getenv("ZABBIX_TOKEN")),
        },
    }

app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")
