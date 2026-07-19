from fastapi import APIRouter, HTTPException
from utils.security import hostname, account
router = APIRouter(prefix="/vmware", tags=["VMware"])
@router.get("/inventory/{host}")
def inventory(host: str, username: str):
    hostname(host); account(username)
    raise HTTPException(501, "Connectez le script PowerCLI d'inventaire avant utilisation en production.")
