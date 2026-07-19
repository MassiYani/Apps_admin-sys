from fastapi import APIRouter, HTTPException
from utils.security import account
router = APIRouter(prefix="/exchange", tags=["Exchange"])
@router.get("/mailboxes/{identity}")
def mailbox(identity: str):
    account(identity)
    raise HTTPException(501, "Connectez le module Exchange Management Shell pour cette action.")
