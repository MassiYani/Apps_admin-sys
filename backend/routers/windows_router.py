from pathlib import Path
from fastapi import APIRouter, HTTPException
from utils.powershell import run_json
from utils.security import hostname
router = APIRouter(prefix="/windows", tags=["Windows"])
BASE_DIR = Path(__file__).resolve().parents[2]
ALLOWED = {"system", "disks", "gpos", "ports", "services", "events", "reboots"}
@router.get("/{action}/{server}")
def diagnostics(action: str, server: str):
    if action not in ALLOWED: raise HTTPException(404, "Action Windows inconnue.")
    return run_json(BASE_DIR / "scripts" / "Get-SystemDiagnostics.ps1", {"ComputerName": hostname(server), "Action": action})
