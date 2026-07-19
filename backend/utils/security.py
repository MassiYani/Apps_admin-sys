import re
from fastapi import HTTPException
HOST_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$")
ACCOUNT_RE = re.compile(r"^[A-Za-z0-9._-]{1,128}$")
def hostname(value: str) -> str:
    if not value or not HOST_RE.fullmatch(value): raise HTTPException(422, "Nom d'hôte ou adresse IP invalide.")
    return value
def account(value: str) -> str:
    if not value or not ACCOUNT_RE.fullmatch(value): raise HTTPException(422, "Identifiant invalide.")
    return value
