from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import subprocess
import json
import os
import re
import io
import time
import requests
import paramiko
from pydantic import BaseModel, Field
from typing import Optional

app = FastAPI()

# --- DÉFINITION DES CHEMINS ---
BASE_DIR = r"D:\Programation\Apps_admin-sys-gimini"
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")  
SCRIPT_PATH = os.path.join(BASE_DIR, "scripts", "Get-SystemDiagnostics.ps1")

# --- Modèle pour les identifiants VMware ---
class VMwareCredentials(BaseModel):
    host: str
    user: str
    password: str

# --- Modèle pour les requêtes Exchange ---
class ExchangeRequest(BaseModel):
    servers: list[str]
    user: str
    password: str
    action: str
    params: dict = {}

# --- Modèle pour les requêtes Linux ---
class LinuxRequest(BaseModel):
    host: str
    user: str
    action: str
    auth_method: str = Field(..., pattern="^(password|key)$")
    password: Optional[str] = None
    private_key: Optional[str] = None
    command: Optional[str] = None

# --- Modèle pour les requêtes NAS ---
class NASRequest(BaseModel):
    path: str
    action: str
    user: Optional[str] = None
    password: Optional[str] = None
    params: dict = {}

# --- Modèle pour les requêtes Zabbix ---
class ZabbixRequest(BaseModel):
    url: str
    token: str
    action: str
    params: dict = {}


# --- ROUTE API (Le backend) ---
@app.get("/api/{action}/{server}")
def get_diagnostics(action: str, server: str):
    # --- SÉCURITÉ : Vérification des entrées utilisateur ---
    allowed_actions = ['system', 'disks', 'gpos', 'ports', 'services', 'events', 'reboots']
    if action not in allowed_actions:
        raise HTTPException(status_code=400, detail="Action non autorisée.")

    # N'autorise que les lettres, chiffres, points et tirets (IP ou nom d'hôte)
    if not re.match(r"^[\w\.-]+$", server):
        raise HTTPException(status_code=400, detail="Nom de serveur ou adresse IP invalide.")
    # -------------------------------------------------------

    if not os.path.exists(SCRIPT_PATH):
        raise HTTPException(status_code=500, detail="Script PowerShell introuvable.")

    ps_command = f"$OutputEncoding = [System.Text.Encoding]::UTF8; & '{SCRIPT_PATH}' -ComputerName '{server}' -Action '{action}'"
    
    cmd = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-NoProfile", "-Command", ps_command]

    try:
        # Utiliser 'utf-8-sig' pour gérer correctement le BOM (Byte Order Mark) que PowerShell
        # peut ajouter au début du flux de sortie UTF-8.
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8-sig", timeout=30)
        
        if result.returncode != 0:
            # Si le script échoue, renvoyer la sortie d'erreur.
            raise HTTPException(status_code=500, detail=f"Erreur du script PowerShell : {result.stderr or result.stdout}")

        output = result.stdout.strip()
        
        # Le script PowerShell doit renvoyer du JSON. On cherche le début de l'objet ou du tableau.
        start_idx = min([idx for idx in [output.find('{'), output.find('[')] if idx != -1] + [len(output)])
        if start_idx != len(output):
            json_part = output[start_idx:]
            try:
                return json.loads(json_part)
            except json.JSONDecodeError:
                raise HTTPException(status_code=500, detail=f"Réponse invalide du script (JSON malformé): {json_part}")
        else:
            raise HTTPException(status_code=500, detail=f"Aucun JSON valide trouvé dans la sortie du script. Sortie brute: {output}")
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="L'exécution du script a expiré après 30 secondes.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NOUVELLE ROUTE API pour VMware ---
@app.post("/api/vmware/info")
def get_vmware_info(creds: VMwareCredentials):
    # --- SÉCURITÉ : Validation basique ---
    if not re.match(r"^[\w\.-]+$", creds.host) or not re.match(r"^[\w\\@\.-]+$", creds.user):
        raise HTTPException(status_code=400, detail="Nom d'hôte ou utilisateur VMware invalide.")
    
    VMWARE_SCRIPT_PATH = os.path.join(BASE_DIR, "scripts", "Get-VMwareInfo.ps1")
    if not os.path.exists(VMWARE_SCRIPT_PATH):
        raise HTTPException(status_code=500, detail=f"Script PowerShell VMware introuvable: {VMWARE_SCRIPT_PATH}")

    # Le mot de passe est passé en argument. C'est visible dans la liste des processus du serveur.
    # C'est un compromis sécurité/simplicité acceptable pour un outil d'administration interne.
    ps_command = f"$OutputEncoding = [System.Text.Encoding]::UTF8; & '{VMWARE_SCRIPT_PATH}' -VIHost '{creds.host}' -User '{creds.user}' -Password '{creds.password}'"
    
    cmd = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-NoProfile", "-Command", ps_command]

    try:
        # Timeout plus long pour les opérations VMware
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8-sig", timeout=120)
        
        if result.returncode != 0:
            error_output = result.stderr or result.stdout
            if "Connect-VIServer" in error_output:
                 raise HTTPException(status_code=401, detail=f"Échec de la connexion à VMware. Vérifiez les identifiants, la connectivité ou un certificat non approuvé. Erreur: {error_output}")
            raise HTTPException(status_code=500, detail=f"Erreur du script PowerShell VMware : {error_output}")

        output = result.stdout.strip()
        
        start_idx = min([idx for idx in [output.find('{'), output.find('[')] if idx != -1] + [len(output)])
        if start_idx != len(output):
            json_part = output[start_idx:]
            try:
                return json.loads(json_part)
            except json.JSONDecodeError:
                raise HTTPException(status_code=500, detail=f"Réponse invalide du script VMware (JSON malformé): {json_part}")
        else:
            raise HTTPException(status_code=500, detail=f"Aucun JSON valide trouvé dans la sortie du script VMware. Sortie brute: {output}")
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="L'exécution du script VMware a expiré après 120 secondes.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NOUVELLE ROUTE API pour MS Exchange ---
@app.post("/api/exchange/run")
def run_exchange_command(req: ExchangeRequest):
    # --- SÉCURITÉ : Validation ---
    if not req.servers:
        raise HTTPException(status_code=400, detail="Aucun serveur Exchange sélectionné.")
    if not all(re.match(r"^[\w\.-]+$", s) for s in req.servers):
        raise HTTPException(status_code=400, detail="Un ou plusieurs noms de serveur Exchange sont invalides.")
    if not re.match(r"^[\w\\@\.-]+$", req.user):
        raise HTTPException(status_code=400, detail="Nom d'utilisateur Exchange invalide.")
    
    allowed_actions = ['track', 'audit', 'journal']
    if req.action not in allowed_actions:
        raise HTTPException(status_code=400, detail="Action Exchange non autorisée.")

    EXCHANGE_SCRIPT_PATH = os.path.join(BASE_DIR, "scripts", "Get-ExchangeInfo.ps1")
    if not os.path.exists(EXCHANGE_SCRIPT_PATH):
        raise HTTPException(status_code=500, detail=f"Script PowerShell Exchange introuvable: {EXCHANGE_SCRIPT_PATH}")

    # Convertir les paramètres en chaîne JSON et l'échapper pour PowerShell
    params_json = json.dumps(req.params)
    escaped_params_json = params_json.replace("'", "''")

    # Construire le tableau de serveurs pour PowerShell
    servers_ps_array = ", ".join([f"'{s}'" for s in req.servers])
    
    ps_command = (
        f"$OutputEncoding = [System.Text.Encoding]::UTF8; "
        f"& '{EXCHANGE_SCRIPT_PATH}' "
        f"-Action '{req.action}' "
        f"-Servers @({servers_ps_array}) "
        f"-User '{req.user}' "
        f"-Password '{req.password}' "
        f"-ParamsJson '{escaped_params_json}'"
    )
    
    cmd = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-NoProfile", "-Command", ps_command]

    try:
        # Timeout plus long pour les opérations Exchange
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8-sig", timeout=180)
        
        if result.returncode != 0:
            error_output = result.stderr or result.stdout
            if "New-PSSession" in error_output or "Kerberos" in error_output:
                 raise HTTPException(status_code=401, detail=f"Échec de la connexion à Exchange. Vérifiez les identifiants, la connectivité WinRM et la configuration Kerberos. Erreur: {error_output}")
            raise HTTPException(status_code=500, detail=f"Erreur du script PowerShell Exchange : {error_output}")

        output = result.stdout.strip()
        
        if not output: return [] # Si la sortie est vide, retourner un tableau vide
        return json.loads(output)
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="L'exécution du script Exchange a expiré après 180 secondes.")
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail=f"Réponse invalide du script Exchange (JSON malformé): {output}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NOUVELLE ROUTE API pour Serveurs Linux ---
@app.post("/api/linux/run")
def run_linux_command(req: LinuxRequest):
    # --- SÉCURITÉ : Validation ---
    if not re.match(r"^[\w\.-]+$", req.host) or not re.match(r"^[\w\.-]+$", req.user):
        raise HTTPException(status_code=400, detail="Nom d'hôte ou utilisateur Linux invalide.")
    
    allowed_actions = ['health', 'services', 'reboots', 'updates', 'custom']
    if req.action not in allowed_actions:
        raise HTTPException(status_code=400, detail="Action Linux non autorisée.")

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        # --- Gestion de la connexion SSH ---
        if req.auth_method == 'password':
            if not req.password:
                raise HTTPException(status_code=400, detail="Mot de passe requis pour l'authentification.")
            client.connect(hostname=req.host, username=req.user, password=req.password, timeout=15)
        elif req.auth_method == 'key':
            if not req.private_key:
                raise HTTPException(status_code=400, detail="Clé privée requise pour l'authentification.")
            try:
                key_buffer = io.StringIO(req.private_key)
                pkey = None
                # Essayer de charger la clé avec différents types possibles
                for key_class in (paramiko.Ed25519Key, paramiko.RSAKey, paramiko.ECDSAKey, paramiko.DSSKey):
                    try:
                        key_buffer.seek(0)
                        pkey = key_class.from_private_key(key_buffer)
                        break
                    except paramiko.SSHException:
                        continue
                if not pkey:
                    raise HTTPException(status_code=400, detail="Format de clé privée invalide ou non supporté.")
                client.connect(hostname=req.host, username=req.user, pkey=pkey, timeout=15)
            except Exception as e:
                 raise HTTPException(status_code=400, detail=f"Erreur avec la clé privée : {e}")
        
        # --- Exécution des commandes ---
        def exec_ssh(command):
            stdin, stdout, stderr = client.exec_command(command, timeout=20)
            exit_code = stdout.channel.recv_exit_status()
            output = stdout.read().decode().strip()
            error = stderr.read().decode().strip()
            if exit_code != 0:
                raise Exception(f"Erreur (code {exit_code}) pour la commande '{command}': {error or output}")
            return output

        if req.action == 'health':
            # Combinaison de commandes pour l'efficacité
            health_script = """
            uptime
            echo '---'
            free -m
            echo '---'
            df -hP --output=source,pcent,size,used,avail,target
            echo '---'
            lscpu | grep -E 'Model name|CPU\\(s\\)'
            """
            output = exec_ssh(health_script)
            uptime_out, free_out, df_out, lscpu_out = output.split('---', 3)
            
            # Parsing
            load_avg = uptime_out.split('load average:')[1].strip()
            mem_line = [l for l in free_out.splitlines() if l.startswith('Mem:')][0]
            mem_parts = mem_line.split()
            
            disks = []
            for line in df_out.strip().splitlines()[1:]: # Skip header
                parts = line.split()
                disks.append({"Filesystem": parts[0], "Usage": parts[1], "Size": parts[2], "Used": parts[3], "Avail": parts[4], "Mount": parts[5]})

            cpu_info = {line.split(':')[0].strip(): line.split(':')[1].strip() for line in lscpu_out.strip().splitlines()}

            return {
                "LoadAverage": load_avg,
                "Memory": {
                    "TotalMB": int(mem_parts[1]), "UsedMB": int(mem_parts[2]), "FreeMB": int(mem_parts[3]),
                    "UsagePct": round(int(mem_parts[2]) / int(mem_parts[1]) * 100, 1) if int(mem_parts[1]) > 0 else 0
                },
                "CPU": {"Model": cpu_info.get("Model name"), "Cores": int(cpu_info.get("CPU(s)"))},
                "Disks": disks
            }

        elif req.action == 'services':
            output = exec_ssh("systemctl list-units --type=service --state=running --no-pager --no-legend")
            services = []
            for line in output.splitlines():
                parts = line.split(maxsplit=4)
                if len(parts) >= 4:
                    services.append({"Unit": parts[0], "Load": parts[1], "Active": parts[2], "Sub": parts[3], "Description": parts[4] if len(parts) > 4 else ""})
            return services

        elif req.action == 'reboots':
            output = exec_ssh("journalctl --list-boots --no-pager --reverse")
            reboots = []
            for line in output.splitlines():
                parts = line.split()
                if len(parts) >= 5:
                    reboots.append({"ID": parts[0], "BootID": parts[1], "Timestamp": f"{parts[2]} {parts[3]} {parts[4]}"})
            return reboots

        elif req.action == 'updates':
            script = """
            if command -v apt-get &> /dev/null; then
                COUNT=$(apt list --upgradable 2>/dev/null | wc -l);
                if [ "$COUNT" -gt 1 ]; then echo "debian;$(($COUNT - 1))"; else echo "debian;0"; fi;
            elif command -v dnf &> /dev/null; then
                COUNT=$(dnf check-update -q | grep -v '^$' | wc -l); echo "rhel;$COUNT";
            elif command -v yum &> /dev/null; then
                COUNT=$(yum check-update -q | grep -v '^$' | wc -l); echo "rhel;$COUNT";
            else
                echo "unknown;N/A";
            fi
            """
            distro, count = exec_ssh(script).split(';')
            return {"DistributionFamily": distro, "UpdatesAvailable": count}

        elif req.action == 'custom':
            if not req.command:
                raise HTTPException(status_code=400, detail="Aucune commande personnalisée fournie.")
            # AVERTISSEMENT : L'exécution de commandes arbitraires est dangereuse.
            output = exec_ssh(req.command)
            return {"output": output}

    except paramiko.AuthenticationException:
        raise HTTPException(status_code=401, detail="Échec de l'authentification SSH. Vérifiez les identifiants.")
    except paramiko.SSHException as e:
        raise HTTPException(status_code=500, detail=f"Erreur de connexion SSH : {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur inattendue : {e}")
    finally:
        if client:
            client.close()

# --- NOUVELLE ROUTE API pour NAS / Windows Storage ---
@app.post("/api/nas/run")
def run_nas_command(req: NASRequest):
    # --- SÉCURITÉ : Validation ---
    if not req.path.startswith('\\\\'):
        raise HTTPException(status_code=400, detail="Le chemin doit être un chemin UNC valide (ex: \\\\serveur\\partage).")
    if not re.match(r"^[\\a-zA-Z0-9\s\._-]+$", req.path):
        raise HTTPException(status_code=400, detail="Le chemin UNC contient des caractères invalides.")

    allowed_actions = ['audit', 'scan']
    if req.action not in allowed_actions:
        raise HTTPException(status_code=400, detail="Action NAS non autorisée.")

    NAS_SCRIPT_PATH = os.path.join(BASE_DIR, "scripts", "Get-NASInfo.ps1")
    if not os.path.exists(NAS_SCRIPT_PATH):
        raise HTTPException(status_code=500, detail=f"Script PowerShell NAS introuvable: {NAS_SCRIPT_PATH}")

    params_json = json.dumps(req.params)
    escaped_params_json = params_json.replace("'", "''")
    
    ps_command = (
        f"$OutputEncoding = [System.Text.Encoding]::UTF8; "
        f"& '{NAS_SCRIPT_PATH}' "
        f"-Path '{req.path}' "
        f"-Action '{req.action}' "
        f"-ParamsJson '{escaped_params_json}'"
    )
    if req.user and req.password:
        safe_user = req.user.replace("'", "''")
        safe_password = req.password.replace("'", "''")
        ps_command += f" -User '{safe_user}' -Password '{safe_password}'"

    cmd = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-NoProfile", "-Command", ps_command]

    try:
        # Timeout long pour l'analyse de stockage potentiellement lente
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8-sig", timeout=300) # 5 minutes
        
        if result.returncode != 0:
            error_output = result.stderr or result.stdout
            if "Get-Acl" in error_output or "Get-ChildItem" in error_output:
                 raise HTTPException(status_code=403, detail=f"Accès refusé au chemin. Vérifiez le chemin et les permissions. Erreur: {error_output}")
            raise HTTPException(status_code=500, detail=f"Erreur du script PowerShell NAS : {error_output}")

        output = result.stdout.strip()
        
        if not output: return []
        return json.loads(output)
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="L'analyse du stockage a expiré après 5 minutes.")
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail=f"Réponse invalide du script NAS (JSON malformé): {output}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NOUVELLE ROUTE API pour Zabbix ---
@app.post("/api/zabbix/run")
def run_zabbix_command(req: ZabbixRequest):
    # --- SÉCURITÉ : Validation ---
    if not req.url.startswith(('http://', 'https://')):
        raise HTTPException(status_code=400, detail="L'URL de Zabbix doit commencer par http:// ou https://.")
    if not re.match(r"^[a-f0-9]{32}$", req.token):
        raise HTTPException(status_code=400, detail="Le jeton d'API Zabbix semble invalide (doit faire 32 caractères hexadécimaux).")
    
    allowed_actions = ['sla', 'graph']
    if req.action not in allowed_actions:
        raise HTTPException(status_code=400, detail="Action Zabbix non autorisée.")

    api_url = f"{req.url.rstrip('/')}/api_jsonrpc.php"

    def zabbix_api_request(method: str, params: dict):
        payload = { "jsonrpc": "2.0", "method": method, "params": params, "auth": req.token, "id": 1 }
        try:
            response = requests.post(api_url, json=payload, timeout=30)
            response.raise_for_status()
            data = response.json()
            if 'error' in data:
                raise HTTPException(status_code=400, detail=f"Erreur de l'API Zabbix: {data['error']['code']} - {data['error']['message']} - {data['error']['data']}")
            return data.get('result')
        except requests.exceptions.RequestException as e:
            raise HTTPException(status_code=504, detail=f"Erreur de connexion à l'API Zabbix à {api_url}: {e}")
        except json.JSONDecodeError:
            raise HTTPException(status_code=500, detail="Réponse invalide de l'API Zabbix (JSON malformé).")

    if req.action == 'sla':
        service_id = req.params.get('service_id')
        if not service_id or not service_id.isdigit():
            raise HTTPException(status_code=400, detail="Un ID de service numérique est requis.")
        
        time_till = int(time.time())
        time_from = time_till - (30 * 24 * 60 * 60) # 30 derniers jours

        service_info = zabbix_api_request("service.get", {"output": ["name"], "serviceids": service_id})
        if not service_info:
            raise HTTPException(status_code=404, detail=f"Service IT avec l'ID {service_id} introuvable.")

        sla_data = zabbix_api_request("service.getsla", {"serviceids": service_id, "intervals": [{"from": time_from, "to": time_till}]})
        
        service_sla = sla_data.get(service_id)
        if not service_sla:
            raise HTTPException(status_code=500, detail="Aucune donnée SLA retournée pour ce service.")

        return { "service_name": service_info[0]['name'], "sla_report": service_sla['sla'] }

    elif req.action == 'graph':
        item_id = req.params.get('item_id')
        if not item_id or not item_id.isdigit():
            raise HTTPException(status_code=400, detail="Un ID d'élément numérique est requis.")

        item_info_list = zabbix_api_request("item.get", {"output": ["name", "units", "value_type"], "itemids": item_id})
        if not item_info_list:
            raise HTTPException(status_code=404, detail=f"Élément avec l'ID {item_id} introuvable.")
        item_info = item_info_list[0]

        time_till = int(time.time())
        time_from = time_till - (24 * 60 * 60) # 24 dernières heures

        history_data = zabbix_api_request("history.get", {
            "output": "extend", "history": int(item_info['value_type']), "itemids": item_id,
            "sortfield": "clock", "sortorder": "ASC", "time_from": time_from, "time_to": time_till
        })

        return { "item_info": item_info, "history": history_data }

# --- ROUTES WEB (Le frontend) ---
# 1. Sert le fichier index.html à la racine du site
@app.get("/")
def read_root():
    index_file = os.path.join(FRONTEND_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {"erreur": f"Le fichier index.html est introuvable dans {FRONTEND_DIR}"}

# 2. Sert tous les fichiers statiques (css, js, fonts, etc.) depuis le dossier frontend
if os.path.exists(FRONTEND_DIR):
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")