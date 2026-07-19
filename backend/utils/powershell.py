import json
import subprocess
from pathlib import Path

from fastapi import HTTPException


def _decode_json_output(output: str):
    """Find the first valid JSON value amid non-fatal PowerShell messages."""
    decoder = json.JSONDecoder()
    for position, character in enumerate(output):
        if character not in "[{":
            continue
        try:
            value, _ = decoder.raw_decode(output[position:])
            return value
        except json.JSONDecodeError:
            continue
    raise HTTPException(502, "La sortie du script n'est pas un JSON valide.")


def run_json(script: Path, parameters: dict[str, str], timeout: int = 45):
    if not script.is_file():
        raise HTTPException(500, "Script d'intégration introuvable.")
    command = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", str(script)]
    for key, value in parameters.items():
        command.extend([f"-{key}", value])
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding="mbcs", errors="replace", timeout=timeout)
    except subprocess.TimeoutExpired:
        raise HTTPException(504, "Le script a dépassé le délai autorisé.")
    output = result.stdout.strip()
    if result.returncode and not output:
        raise HTTPException(502, result.stderr.strip() or "Le script a échoué sans renvoyer de donnée.")
    if not output:
        raise HTTPException(502, result.stderr.strip() or "Le script n'a renvoyé aucune donnée.")
    return _decode_json_output(output)