from fastapi import APIRouter, HTTPException
from utils.security import account
router = APIRouter(prefix="/nas", tags=["NAS"])
@router.get("/audit")
def audit(user: str, path: str):
    account(user)
    if not path.startswith('\\\\'): raise HTTPException(422, "Chemin NAS UNC invalide.")
    raise HTTPException(501, "Associez le script d'audit NAS à ce point d'entrée après validation de ses paramètres.")
