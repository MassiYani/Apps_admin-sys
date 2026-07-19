from pathlib import Path
from fastapi import APIRouter
from utils.powershell import run_json
from utils.security import account
router = APIRouter(prefix="/ad", tags=["Active Directory"])
BASE_DIR = Path(__file__).resolve().parents[2]
@router.get("/users/{sam_account_name}")
def user(sam_account_name: str):
    return run_json(BASE_DIR / "scripts" / "AD" / "Get-ADUserStatus.ps1", {"SamAccountName": account(sam_account_name)})
