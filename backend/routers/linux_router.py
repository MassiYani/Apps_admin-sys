from fastapi import APIRouter, HTTPException
from utils.security import hostname, account
router = APIRouter(prefix="/linux", tags=["Linux"])
@router.get("/health/{host}")
def health(host: str, username: str):
    hostname(host); account(username)
    raise HTTPException(501, "Configurez la clé SSH et le connecteur Paramiko pour ce serveur.")
