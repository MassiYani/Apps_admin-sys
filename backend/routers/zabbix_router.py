from fastapi import APIRouter, HTTPException
router = APIRouter(prefix="/zabbix", tags=["Zabbix"])
@router.get("/sla")
def sla(period: str = "monthly"):
    if period not in {"daily", "weekly", "monthly", "yearly"}: raise HTTPException(422, "Période SLA invalide.")
    raise HTTPException(501, "Configurez l'URL et le jeton API Zabbix via variables d'environnement.")
