const app = document.querySelector('#app');
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const field = (id, label, value = 'localhost') => `<label class="form-label" for="${id}">${label}</label><input id="${id}" class="form-control" value="${esc(value)}">`;
const spinner = '<div class="text-center py-5"><div class="spinner-border text-info"></div></div>';
const failure = message => `<div class="alert alert-danger"><i class="bi bi-exclamation-triangle"></i> ${esc(message)}</div>`;

const modules = {
  windows: () => `<h2>Diagnostics Windows</h2><p class="text-secondary">Diagnostic distant sécurisé via PowerShell.</p><div class="row g-2 align-items-end mb-3"><div class="col-md-5">${field('server','Serveur ou IP')}</div><div class="col-md-7 d-flex gap-2 flex-wrap">${[['system','Système'],['disks','Disques'],['gpos','GPO'],['ports','Ports'],['services','Services'],['events','Événements'],['reboots','Audit reboot']].map(([id,label])=>`<button class="btn btn-outline-info" data-action="${id}">${label}</button>`).join('')}</div></div><div id="result" class="card card-body shadow-sm">Choisissez une action.</div>`,
  ad: () => `<h2>Active Directory</h2><p class="text-secondary">Recherche d’un utilisateur : statut, mot de passe, groupes et attributs Office 365.</p><div class="row g-2 align-items-end"><div class="col-md-5">${field('account','SamAccountName','jdupont')}</div><div class="col-auto"><button id="adSearch" class="btn btn-primary"><i class="bi bi-search"></i> Rechercher</button></div></div><div id="result" class="mt-3"></div>`,
  vmware: () => `
    <h2>VMware ESXi / vCenter</h2>
    <p class="text-secondary">Inventaire, capacité et état des machines virtuelles.</p>
    <div class="alert alert-info">
        <i class="bi bi-info-circle-fill"></i> <strong>Authentification requise :</strong> Pour des raisons de sécurité, les identifiants sont demandés à chaque opération et ne sont jamais stockés.
    </div>
    <div class="card card-body shadow-sm">
        <div class="row g-3 align-items-end">
            <div class="col-md-4">${field('vmware_host', 'Hôte ESXi ou vCenter', 'vcenter.domain.local')}</div>
            <div class="col-md-3">${field('vmware_user', 'Utilisateur', 'administrator@vsphere.local')}</div>
            <div class="col-md-3">
                <label class="form-label" for="vmware_pass">Mot de passe</label>
                <input id="vmware_pass" type="password" class="form-control">
            </div>
            <div class="col-md-2 text-end">
                <button id="vmware_connect" class="btn btn-primary w-100">
                    <i class="bi bi-diagram-3"></i> Obtenir
                </button>
            </div>
        </div>
    </div>
    <div id="result" class="mt-3"></div>`,
  linux: () => `
    <h2>Serveurs Linux</h2>
    <p class="text-secondary">Santé système, audit des redémarrages et gestion des services via SSH.</p>
    
    <div class="card card-body shadow-sm mb-3">
        <h5 class="card-title mb-3">1. Paramètres de Connexion SSH</h5>
        <div class="alert alert-info py-2">
            <i class="bi bi-shield-lock-fill"></i> <strong>Connexion sécurisée :</strong> Les identifiants sont utilisés pour une seule opération et ne sont jamais stockés. L'authentification par clé privée est recommandée.
        </div>
        <div class="row g-3 align-items-end">
            <div class="col-md-4">${field('linux_host', 'Hôte ou IP', 'serveur.linux.local')}</div>
            <div class="col-md-3">${field('linux_user', 'Utilisateur', 'root')}</div>
            <div class="col-md-5">
                <label class="form-label" for="linux_auth_method">Méthode d'authentification</label>
                <div class="input-group">
                    <select id="linux_auth_method" class="form-select" style="flex: 0 0 150px;">
                        <option value="password" selected>Mot de passe</option>
                        <option value="key">Clé privée</option>
                    </select>
                    <input id="linux_pass" type="password" class="form-control" placeholder="Mot de passe">
                    <textarea id="linux_key" class="form-control d-none" placeholder="Collez votre clé privée ici (ex: -----BEGIN RSA PRIVATE KEY-----...)" rows="3"></textarea>
                </div>
            </div>
        </div>
    </div>

    <div class="card card-body shadow-sm">
        <h5 class="card-title mb-3">2. Actions</h5>
        <div class="d-flex gap-2 flex-wrap">
            <button class="btn btn-primary" data-linux-action="health"><i class="bi bi-heart-pulse"></i> Santé Système</button>
            <button class="btn btn-outline-secondary" data-linux-action="services"><i class="bi bi-gear"></i> Services Actifs</button>
            <button class="btn btn-outline-secondary" data-linux-action="reboots"><i class="bi bi-arrow-clockwise"></i> Audit Redémarrages</button>
            <button class="btn btn-outline-secondary" data-linux-action="updates"><i class="bi bi-box-arrow-in-down"></i> Mises à jour</button>
        </div>
    </div>

    <div class="card card-body shadow-sm mt-3">
        <h5 class="card-title mb-3">3. Commande Personnalisée</h5>
        <div class="alert alert-warning py-2"><i class="bi bi-exclamation-triangle-fill"></i> <strong>Attention :</strong> L'exécution de commandes personnalisées peut avoir des conséquences importantes sur le serveur. Utilisez avec prudence.</div>
        <p class="text-secondary small">Pour voir les erreurs (stderr), ajoutez `2>&1` à la fin de votre commande.</p>
        <div class="input-group">
            <input type="text" id="linux_custom_cmd" class="form-control font-monospace" placeholder="Ex: ls -la /var/log">
            <button id="linux_run_custom" class="btn btn-danger">Exécuter</button>
        </div>
    </div>

    <div id="result" class="mt-3"></div>`,
  exchange: () => `
    <h2>MS Exchange 2013</h2>
    <p class="text-secondary">Audit des boîtes partagées, journalisation et recherche de messages (message tracking).</p>
    
    <div class="card card-body shadow-sm mb-3">
        <h5 class="card-title mb-3">1. Paramètres de Connexion</h5>
        <div class="alert alert-info py-2">
            <i class="bi bi-info-circle-fill"></i> <strong>Authentification requise :</strong> Les identifiants sont demandés à chaque opération et ne sont jamais stockés. Une session Exchange Management Shell distante sera ouverte.
        </div>
        <div class="row g-3 align-items-end">
            <div class="col-md-5">
                <label class="form-label">Serveurs Exchange à interroger</label>
                <div class="form-check">
                    <input class="form-check-input exchange-server" type="checkbox" value="exchange01.domain.local" id="exchange01" checked>
                    <label class="form-check-label" for="exchange01">exchange01.domain.local</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input exchange-server" type="checkbox" value="exchange02.domain.local" id="exchange02">
                    <label class="form-check-label" for="exchange02">exchange02.domain.local</label>
                </div>
            </div>
            <div class="col-md-4">${field('exchange_user', 'Utilisateur (user@domain)', 'admin.exchange')}</div>
            <div class="col-md-3">
                <label class="form-label" for="exchange_pass">Mot de passe</label>
                <input id="exchange_pass" type="password" class="form-control">
            </div>
        </div>
    </div>

    <div class="card card-body shadow-sm">
        <h5 class="card-title mb-3">2. Actions</h5>
        <nav>
            <div class="nav nav-tabs" id="nav-tab" role="tablist">
                <button class="nav-link active" id="nav-tracking-tab" data-bs-toggle="tab" data-bs-target="#nav-tracking" type="button" role="tab">Message Tracking</button>
                <button class="nav-link" id="nav-shared-mailbox-tab" data-bs-toggle="tab" data-bs-target="#nav-shared-mailbox" type="button" role="tab">Boîtes Partagées</button>
                <button class="nav-link" id="nav-journal-tab" data-bs-toggle="tab" data-bs-target="#nav-journal" type="button" role="tab">Journalisation</button>
            </div>
        </nav>
        <div class="tab-content pt-3" id="nav-tabContent">
            <div class="tab-pane fade show active p-2" id="nav-tracking" role="tabpanel">
                <h6>Rechercher des messages</h6>
                <div class="row g-2 align-items-end">
                    <div class="col-md-4">${field('track_sender', 'Expéditeur', '')}</div>
                    <div class="col-md-4">${field('track_recipient', 'Destinataire', '')}</div>
                    <div class="col-md-4">${field('track_subject', 'Sujet (optionnel)', '')}</div>
                    <div class="col-12 text-end mt-3">
                        <button id="exchange_track_message" class="btn btn-primary">Lancer la recherche</button>
                    </div>
                </div>
            </div>
            <div class="tab-pane fade p-2" id="nav-shared-mailbox" role="tabpanel">
                <h6>Auditer une boîte partagée</h6>
                <div class="input-group">
                    <input type="text" id="exchange_mailbox" class="form-control" placeholder="nom@boitepartagee.com">
                    <button id="exchange_audit_shared" class="btn btn-primary">Auditer les permissions</button>
                </div>
            </div>
            <div class="tab-pane fade p-2" id="nav-journal" role="tabpanel">
                <h6>Vérifier la journalisation</h6>
                <p class="text-secondary">Vérifie la configuration des règles de journalisation sur les serveurs sélectionnés.</p>
                 <div class="text-end">
                    <button id="exchange_check_journal" class="btn btn-primary">Vérifier la journalisation</button>
                </div>
            </div>
        </div>
    </div>

    <div id="result" class="mt-3"></div>`,
  nas: () => `
    <h2>NAS / Windows Storage</h2>
    <p class="text-secondary">Audit des droits effectifs sur les partages et analyse de l'utilisation de l'espace (NTFS).</p>
    
    <div class="card card-body shadow-sm mb-3">
        <h5 class="card-title mb-3">1. Cible et Authentification</h5>
        <div class="alert alert-info py-2">
            <i class="bi bi-person-fill-lock"></i> <strong>Authentification :</strong> Si l'utilisateur et le mot de passe sont laissés vides, les scripts seront exécutés avec les droits du service backend.
        </div>
        <div class="row g-3 align-items-end">
            <div class="col-md-6">${field('nas_path', 'Chemin UNC du dossier', '\\\\serveur\\partage')}</div>
            <div class="col-md-3">${field('nas_user', 'Utilisateur (optionnel)', '')}</div>
            <div class="col-md-3">
                <label class="form-label" for="nas_pass">Mot de passe (optionnel)</label>
                <input id="nas_pass" type="password" class="form-control">
            </div>
        </div>
    </div>

    <div class="card card-body shadow-sm">
        <h5 class="card-title mb-3">2. Actions</h5>
        <div class="row g-3">
            <div class="col-lg-6 border-end">
                <h6><i class="bi bi-person-vcard"></i> Audit des droits effectifs</h6>
                <p class="small text-secondary">Vérifie les droits d'un utilisateur ou d'un groupe sur le chemin spécifié.</p>
                <div class="input-group">
                    <input type="text" id="nas_audit_user" class="form-control" placeholder="Nom d'utilisateur ou groupe">
                    <button id="nas_run_audit" class="btn btn-primary">Auditer</button>
                </div>
            </div>
            <div class="col-lg-6">
                <h6><i class="bi bi-pie-chart"></i> Analyse de l'utilisation</h6>
                <p class="small text-secondary">Analyse la taille des sous-dossiers directs du chemin spécifié.</p>
                <div class="text-end">
                     <button id="nas_run_scan" class="btn btn-primary">Analyser l'espace</button>
                </div>
            </div>
        </div>
    </div>

    <div id="result" class="mt-3"></div>`,
  zabbix: () => `
    <h2>Supervision Zabbix</h2>
    <p class="text-secondary">Rapports SLA personnalisés et visualisation de graphiques via l'API Zabbix.</p>
    
    <div class="card card-body shadow-sm mb-3">
        <h5 class="card-title mb-3">1. Paramètres de Connexion API</h5>
        <div class="alert alert-info py-2">
            <i class="bi bi-key-fill"></i> <strong>Connexion API :</strong> L'URL de votre serveur Zabbix et un jeton d'API avec les droits de lecture sont requis.
        </div>
        <div class="row g-3 align-items-end">
            <div class="col-md-6">${field('zabbix_url', 'URL de l\'interface Zabbix', 'http://zabbix.domain.local/zabbix')}</div>
            <div class="col-md-6">
                <label class="form-label" for="zabbix_token">Jeton d'API (API Token)</label>
                <input id="zabbix_token" type="password" class="form-control" placeholder="Collez votre jeton d'API ici">
            </div>
        </div>
    </div>

    <div class="card card-body shadow-sm">
        <h5 class="card-title mb-3">2. Actions</h5>
        <nav>
            <div class="nav nav-tabs" id="nav-tab" role="tablist">
                <button class="nav-link active" id="nav-sla-tab" data-bs-toggle="tab" data-bs-target="#nav-sla" type="button" role="tab">Rapport SLA</button>
                <button class="nav-link" id="nav-graph-tab" data-bs-toggle="tab" data-bs-target="#nav-graph" type="button" role="tab">Graphiques</button>
            </div>
        </nav>
        <div class="tab-content pt-3" id="nav-tabContent">
            <div class="tab-pane fade show active p-2" id="nav-sla" role="tabpanel">
                <h6>Générer un rapport de disponibilité (SLA)</h6>
                <div class="input-group">
                    <input type="text" id="zabbix_service_id" class="form-control" placeholder="ID du Service IT (ex: 2)">
                    <button id="zabbix_run_sla" class="btn btn-primary">Générer le rapport</button>
                </div>
            </div>
            <div class="tab-pane fade p-2" id="nav-graph" role="tabpanel">
                <h6>Visualiser un graphique d'élément</h6>
                <p class="text-secondary small">Cette fonctionnalité nécessite de connaître l'ID de l'élément (Item ID) à grapher.</p>
                <div class="input-group">
                    <input type="text" id="zabbix_item_id" class="form-control" placeholder="ID de l'élément (ex: 23456)">
                    <button id="zabbix_run_graph" class="btn btn-primary">Afficher le graphique</button>
                </div>
            </div>
        </div>
    </div>

    <div id="result" class="mt-3"></div>`
};
function placeholder(title, description, dependency) { return `<h2>${title}</h2><p class="text-secondary">${description}</p><div class="alert alert-info">Connecteur requis : ${dependency}. Les routes API sont préparées et renvoient un état explicite tant que les accès ne sont pas configurés.</div>`; }
async function request(url, options = {}) { const response = await fetch(url, options); const body = await response.text(); let data; try { data = body ? JSON.parse(body) : null; } catch { throw new Error(response.ok ? 'Réponse du serveur invalide.' : `Erreur HTTP ${response.status} : ${body || 'sans détail'}`); } if (!response.ok) throw new Error(data?.detail || data?.Error || `Erreur HTTP ${response.status}`); if (data?.Error) throw new Error(data.Error); return data; }
function rows(data) { return Array.isArray(data) ? data : [data]; }
function filterInput(id, placeholder) { return `<input id="${id}" class="form-control mb-3" placeholder="${placeholder}">`; }
function genericTable(data, filterId, placeholder) { const list = rows(data); if (!list.length) return '<div class="alert alert-info">Aucune donnée.</div>'; const cols = Object.keys(list[0]); const html = `${filterId ? filterInput(filterId, placeholder) : ''}<div class="table-wrap"><table class="table table-hover table-striped mb-0"><thead class="sticky-top"><tr>${cols.map(c=>`<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${list.map(r=>`<tr>${cols.map(c=>`<td>${esc(typeof r[c] === 'object' ? JSON.stringify(r[c]) : r[c])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; return html; }
function attachFilter(id) { const input = document.querySelector(`#${id}`); if (input) input.oninput = () => document.querySelectorAll('#result tbody tr').forEach(row => row.hidden = !row.textContent.toLowerCase().includes(input.value.toLowerCase())); }
function systemView(data) { const cpu = Number(data.CPU_Usage || 0), ram = Number(data.RAM_UsagePct || 0); const bar = (value, cls) => `<div class="progress" style="height:22px"><div class="progress-bar ${cls}" style="width:${Math.min(100,value)}%">${esc(value)}%</div></div>`; return `<div class="d-flex justify-content-between flex-wrap gap-2 mb-3"><div><h4 class="text-info mb-1">${esc(data.OS)}</h4><span class="badge bg-primary">IP : ${esc(data.IP)}</span></div><small class="text-secondary">${esc(data.CPU_Model)} · RAM totale : ${esc(data.RAM_Total)} Go</small></div><div class="row g-3 mb-4"><div class="col-md-6"><div class="card h-100"><div class="card-body"><div class="d-flex justify-content-between"><strong>CPU global</strong><span>${cpu}%</span></div>${bar(cpu, cpu > 90 ? 'bg-danger' : cpu > 70 ? 'bg-warning text-dark' : 'bg-success')}</div></div></div><div class="col-md-6"><div class="card h-100"><div class="card-body"><div class="d-flex justify-content-between"><strong>RAM utilisée</strong><span>${ram}% · ${esc(data.RAM_UsedGB)} Go</span></div>${bar(ram, ram > 90 ? 'bg-danger' : ram > 70 ? 'bg-warning text-dark' : 'bg-success')}</div></div></div></div><div class="row g-3"><div class="col-md-6"><h5>Top CPU</h5><ul class="list-group">${rows(data.TopCPU || []).map(p=>`<li class="list-group-item d-flex justify-content-between"><span>${esc(p.Name)}</span><span class="badge bg-danger">${esc(p.CPU)}%</span></li>`).join('')}</ul></div><div class="col-md-6"><h5>Top RAM</h5><ul class="list-group">${rows(data.TopRAM || []).map(p=>`<li class="list-group-item d-flex justify-content-between"><span>${esc(p.Name)}</span><span class="badge bg-secondary">${esc(p.RAM_MB)} Mo</span></li>`).join('')}</ul></div></div>`; }
function disksView(data) { return rows(data).map(d => { const used = Number(d.UsedPct || 0), color = used > 90 ? 'bg-danger' : used > 75 ? 'bg-warning text-dark' : 'bg-success'; return `<div class="mb-4"><div class="d-flex justify-content-between"><strong class="fs-5">${esc(d.Drive)}</strong><span>${esc(d.Free)} Go libres / ${esc(d.Total)} Go</span></div><div class="progress" style="height:24px"><div class="progress-bar ${color}" style="width:${Math.min(100,used)}%">${used}% utilisé</div></div></div>`; }).join('') || '<div class="alert alert-info">Aucune partition détectée.</div>'; }
function gposView(data) { return `<h5>Stratégies de groupe appliquées</h5><div class="d-flex gap-2 flex-wrap">${rows(data).map(g=>`<span class="badge bg-secondary fs-6">${esc(typeof g === 'object' ? JSON.stringify(g) : g)}</span>`).join('')}</div>`; }
function servicesView(data) {
    const list = rows(data);
    if (!list.length) return '<div class="alert alert-info">Aucun service.</div>';
    const anomalies = list.filter(s => s.StartMode === 'Auto' && s.State !== 'Running');
    const cols = Object.keys(list[0]);
    const stateColName = cols.find(c => c.toLowerCase() === 'state');

    const stateToBadge = (state) => {
        const stateLower = (state || '').toLowerCase();
        if (stateLower === 'running') return `<span class="badge bg-success">${esc(state)}</span>`;
        if (stateLower === 'stopped') return `<span class="badge bg-danger">${esc(state)}</span>`;
        return `<span class="badge bg-secondary">${esc(state)}</span>`;
    };

    const tableHtml = `${filterInput('serviceSearch','Rechercher un service…')}<div class="table-wrap"><table class="table table-hover table-striped mb-0"><thead class="sticky-top"><tr>${cols.map(c => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${list.map(r => `<tr data-state="${esc(r.State)}" data-startmode="${esc(r.StartMode)}">${cols.map(c => `<td>${c === stateColName ? stateToBadge(r[c]) : esc(r[c])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
    const anomalyHtml = anomalies.length ? `<div class="d-flex justify-content-between align-items-center alert alert-warning"><span><strong>${anomalies.length}</strong> service(s) automatique(s) non démarré(s).</span><button id="autoStoppedToggle" class="btn btn-sm btn-warning">Afficher uniquement ceux-ci</button></div>` : '';
    return anomalyHtml + tableHtml;
}
function eventsView(data) {
    const list = rows(data);
    if (!list.length) return '<div class="alert alert-info">Aucun événement.</div>';

    let cols = Object.keys(list[0]);
    const levelColName = cols.find(c => c.toLowerCase().includes('level'));

    // Move 'Level' column to 3rd position (index 2) if it exists
    if (levelColName && cols.indexOf(levelColName) !== 2) {
        cols = cols.filter(c => c !== levelColName);
        if (cols.length >= 2) {
            cols.splice(2, 0, levelColName);
        } else {
            cols.push(levelColName);
        }
    }

    const levelToBadge = (level) => {
        const levelStr = String(level || '').toLowerCase();
        if (levelStr.includes('erreur') || levelStr.includes('error')) {
            return `<span class="badge bg-danger">${esc(level)}</span>`;
        }
        if (levelStr.includes('avertissement') || levelStr.includes('warning')) {
            return `<span class="badge bg-warning text-dark">${esc(level)}</span>`;
        }
        return esc(level);
    };

    const tableBody = list.map(r => `<tr>${cols.map(c => {
        const value = r[c];
        if (c === levelColName) {
            return `<td>${levelToBadge(value)}</td>`;
        }
        if (c.toLowerCase().includes('message')) {
            const strValue = String(value ?? '');
            const shortValue = strValue.length > 120 ? strValue.slice(0, 120) + '…' : strValue;
            return `<td title="${esc(strValue)}">${esc(shortValue)}</td>`;
        }
        return `<td>${esc(value)}</td>`;
    }).join('')}</tr>`).join('');

    return `${filterInput('eventSearch','Rechercher dans les événements…')}<div class="table-wrap"><table class="table table-hover table-striped mb-0"><thead class="sticky-top"><tr>${cols.map(c => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${tableBody}</tbody></table></div>`;
}
function portsView(data) { const list = rows(data); return `${filterInput("portSearch", "Rechercher par port, application ou service…")}<div class="table-wrap"><table class="table table-hover table-striped mb-0"><thead class="sticky-top"><tr><th>Port</th><th>Protocole</th><th>Application</th><th>Service</th><th>PID</th></tr></thead><tbody>${list.map(p => `<tr><td><span class="badge bg-secondary">${esc(p.Port)}</span></td><td><span class="badge ${p.Proto === "TCP" ? "bg-primary" : "bg-warning text-dark"}">${esc(p.Proto)}</span></td><td><span class="badge bg-info text-dark">${esc(p.App)}</span></td><td>${esc(p.Service)}</td><td>${esc(p.PID)}</td></tr>`).join("")}</tbody></table></div>`; }
function adView(data) {
    const groups = rows(data.Groups || []);
    const state = data.Status === 'Actif' ? 'bg-success' : 'bg-danger';
    const na = '<span class="text-secondary">N/A</span>'; // Helper for Not Available

    return `
<div class="card shadow-sm">
    <div class="card-header bg-light d-flex justify-content-between flex-wrap gap-2">
        <div>
            <h4 class="mb-0">${esc(data.DisplayName || data.Username)}</h4>
            <div class="text-secondary small">${esc(data.OU || 'OU non disponible')}</div>
        </div>
        <span class="badge ${state} fs-6 align-self-center">${esc(data.Status || 'Inconnu')}</span>
    </div>
    <div class="card-body">
        <div class="row g-4">
            <!-- Left Column: Identity & Contact -->
            <div class="col-lg-6">
                <h5>Identité &amp; Contact</h5>
                <hr class="mt-2">
                <dl class="row mb-0">
                    <dt class="col-sm-5">Identifiant (SamAccountName)</dt>
                    <dd class="col-sm-7">${esc(data.Username || na)}</dd>

                    <dt class="col-sm-5">Département</dt>
                    <dd class="col-sm-7">${esc(data.Department || na)}</dd>

                    <dt class="col-sm-5">Adresse E-mail</dt>
                    <dd class="col-sm-7">${esc(data.Email || na)}</dd>

                    <dt class="col-sm-5">Téléphone</dt>
                    <dd class="col-sm-7">${esc(data.PhoneNumber || na)}</dd>

                    <dt class="col-sm-5">Téléphone IP</dt>
                    <dd class="col-sm-7">${esc(data.IPPhone || na)}</dd>
                </dl>

                <h5 class="mt-4">Office 365</h5>
                <hr class="mt-2">
                <dl class="row mb-0">
                    <dt class="col-sm-5">UPN</dt>
                    <dd class="col-sm-7">${esc(data.UserPrincipalName || na)}</dd>

                    <dt class="col-sm-5">Attribut O365</dt>
                    <dd class="col-sm-7">${esc(data.Office365 || na)}</dd>
                </dl>
            </div>

            <!-- Right Column: Security & Password -->
            <div class="col-lg-6">
                <h5>Sécurité &amp; Statut</h5>
                <hr class="mt-2">
                <dl class="row mb-0">
                    <dt class="col-sm-5">EmployeeID</dt>
                    <dd class="col-sm-7">${esc(data.EmployeeID || na)}</dd>

                    <dt class="col-sm-5">Compte verrouillé</dt>
                    <dd class="col-sm-7">${data.IsLocked ? 'Oui' : 'Non'}</dd>

                    <dt class="col-sm-5">Privilèges Admin</dt>
                    <dd class="col-sm-7">${data.IsAdmin ? 'Oui' : 'Non'}</dd>

                    <dt class="col-sm-5">Dernière connexion</dt>
                    <dd class="col-sm-7">${esc(data.LastLogon || na)}</dd>
                </dl>

                <h5 class="mt-4">Mot de passe</h5>
                <hr class="mt-2">
                <dl class="row mb-0">
                    <dt class="col-sm-5">Dernière modification</dt>
                    <dd class="col-sm-7">${esc(data.PasswordLastSet || na)}</dd>

                    <dt class="col-sm-5">Date d'expiration</dt>
                    <dd class="col-sm-7">${esc(data.PasswordExpires || na)}</dd>

                    <dt class="col-sm-5">N'expire jamais</dt>
                    <dd class="col-sm-7">${data.PasswordNeverExpires ? 'Oui' : 'Non'}</dd>
                </dl>
            </div>
        </div>

        <hr>
        <h5>Groupes d'appartenance (${groups.length})</h5>
        <div class="d-flex gap-2 flex-wrap mt-2">
            ${groups.length ? groups.map(g => `<span class="badge bg-info text-dark">${esc(g)}</span>`).join('') : '<span class="text-secondary">Aucun groupe retourné.</span>'}
        </div>
    </div>
</div>`;
}

function vmwareView(data) {
    const host = data.HostInfo;
    const vms = rows(data.VMs || []);
    const hostMemPct = (host.MemoryUsageGB / host.MemoryTotalGB) * 100 || 0;
    const bar = (value, cls) => `<div class="progress" style="height:22px"><div class="progress-bar ${cls}" style="width:${Math.min(100,value)}%">${value.toFixed(1)}%</div></div>`;

    const hostCard = `
    <div class="card shadow-sm mb-4">
        <div class="card-header bg-light">
            <h4 class="mb-0"><i class="bi bi-server"></i> Hôte : ${esc(host.Name)}</h4>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-6">
                    <p class="mb-1"><strong>Version :</strong> ${esc(host.Version)} (Build ${esc(host.Build)})</p>
                    <p class="mb-1"><strong>CPU :</strong> ${esc(host.CpuModel)} (${esc(host.NumCpuCores)} cœurs)</p>
                </div>
                <div class="col-md-6">
                    <strong>Utilisation Mémoire :</strong>
                    <span>${esc(host.MemoryUsageGB)} Go / ${esc(host.MemoryTotalGB)} Go</span>
                    ${bar(hostMemPct, hostMemPct > 90 ? 'bg-danger' : hostMemPct > 75 ? 'bg-warning text-dark' : 'bg-success')}
                </div>
            </div>
        </div>
    </div>`;

    const vmTable = `
    <h5>Machines Virtuelles (${vms.length})</h5>
    ${filterInput('vmSearch', 'Rechercher une VM...')}
    <div class="table-wrap">
        <table class="table table-hover table-striped mb-0">
            <thead class="sticky-top">
                <tr>
                    <th>Nom</th>
                    <th>État</th>
                    <th>CPU</th>
                    <th>Mémoire (Go)</th>
                    <th>Espace Utilisé (Go)</th>
                    <th>Espace Provisionné (Go)</th>
                </tr>
            </thead>
            <tbody>
                ${vms.map(vm => `
                    <tr>
                        <td><strong>${esc(vm.Name)}</strong></td>
                        <td><span class="badge ${vm.PowerState === 'PoweredOn' ? 'bg-success' : 'bg-danger'}">${esc(vm.PowerState)}</span></td>
                        <td>${esc(vm.NumCpu)}</td>
                        <td>${esc(vm.MemoryGB)}</td>
                        <td>${esc(vm.UsedSpaceGB)}</td>
                        <td>${esc(vm.ProvisionedSpaceGB)}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    </div>`;

    return hostCard + (vms.length > 0 ? vmTable : '<div class="alert alert-info">Aucune machine virtuelle trouvée sur cet hôte.</div>');
}

function linuxHealthView(data) {
    const mem = data.Memory;
    const disks = rows(data.Disks || []);
    const memPct = mem.UsagePct || 0;
    const bar = (value, cls) => `<div class="progress" style="height:22px"><div class="progress-bar ${cls}" style="width:${Math.min(100,value)}%">${value.toFixed(1)}%</div></div>`;

    const healthCards = `
    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="card h-100 shadow-sm">
                <div class="card-body">
                    <h5 class="card-title"><i class="bi bi-cpu"></i> CPU & Load</h5>
                    <p class="card-text mb-1"><strong>Modèle :</strong> ${esc(data.CPU.Model)} (${esc(data.CPU.Cores)} cœurs)</p>
                    <p class="card-text"><strong>Charge (1, 5, 15 min) :</strong> ${esc(data.LoadAverage)}</p>
                </div>
            </div>
        </div>
        <div class="col-md-8">
            <div class="card h-100 shadow-sm">
                <div class="card-body">
                    <h5 class="card-title"><i class="bi bi-memory"></i> Mémoire</h5>
                    <strong>Utilisation :</strong>
                    <span>${esc(mem.UsedMB)} Mo / ${esc(mem.TotalMB)} Mo</span>
                    ${bar(memPct, memPct > 90 ? 'bg-danger' : memPct > 75 ? 'bg-warning text-dark' : 'bg-success')}
                </div>
            </div>
        </div>
    </div>`;

    const diskTable = `
    <h5>Systèmes de fichiers</h5>
    <div class="table-wrap">
        <table class="table table-hover table-striped mb-0">
            <thead class="sticky-top">
                <tr><th>Système de fichiers</th><th>Taille</th><th>Utilisé</th><th>Dispo.</th><th>Util.%</th><th>Monté sur</th></tr>
            </thead>
            <tbody>
                ${disks.map(d => {
                    const usage = parseInt(d.Usage, 10) || 0;
                    const color = usage > 90 ? 'table-danger' : usage > 80 ? 'table-warning' : '';
                    return `<tr class="${color}">
                        <td>${esc(d.Filesystem)}</td>
                        <td>${esc(d.Size)}</td>
                        <td>${esc(d.Used)}</td>
                        <td>${esc(d.Avail)}</td>
                        <td><span class="badge ${usage > 90 ? 'bg-danger' : usage > 80 ? 'bg-warning text-dark' : 'bg-secondary'}">${esc(d.Usage)}</span></td>
                        <td>${esc(d.Mount)}</td>
                    </tr>`
                }).join('')}
            </tbody>
        </table>
    </div>`;
    
    return healthCards + diskTable;
}

function linuxUpdatesView(data) {
    const count = parseInt(data.UpdatesAvailable, 10);
    if (isNaN(count)) {
        return `<div class="alert alert-secondary">Le nombre de mises à jour disponibles n'a pas pu être déterminé pour la famille de distribution : ${esc(data.DistributionFamily)}.</div>`;
    }
    if (count > 0) {
        return `<div class="alert alert-warning"><strong>${esc(count)}</strong> mise(s) à jour disponible(s) pour cette distribution (famille : ${esc(data.DistributionFamily)}).</div>`;
    }
    return `<div class="alert alert-success">Le système est à jour (famille de distribution : ${esc(data.DistributionFamily)}).</div>`;
}

function zabbixSlaView(data) {
    const report = data.sla_report[0];
    if (!report) {
        return failure(`Aucun rapport SLA trouvé pour le service "${esc(data.service_name)}".`);
    }
    const slaValue = parseFloat(report.sla);
    const color = slaValue >= 99.9 ? 'bg-success' : slaValue >= 99 ? 'bg-warning text-dark' : 'bg-danger';
    const bar = `<div class="progress" style="height:28px; font-size: 1rem;">
        <div class="progress-bar ${color}" role="progressbar" style="width: ${slaValue}%;" aria-valuenow="${slaValue}" aria-valuemin="0" aria-valuemax="100">${slaValue.toFixed(3)}%</div>
    </div>`;

    return `
    <div class="card shadow-sm">
        <div class="card-header bg-light">
            <h4 class="mb-0">Rapport SLA sur 30 jours</h4>
        </div>
        <div class="card-body">
            <h5 class="card-title">${esc(data.service_name)}</h5>
            <p class="text-secondary">Disponibilité (SLA)</p>
            ${bar}
            <p class="mt-3"><strong>Période :</strong> du ${new Date(report.from * 1000).toLocaleDateString()} au ${new Date(report.to * 1000).toLocaleDateString()}</p>
        </div>
    </div>`;
}

function zabbixGraphView(data) {
    const item = data.item_info;
    const history = rows(data.history);

    return `
    <div class="card shadow-sm">
        <div class="card-header bg-light">
            <h4 class="mb-0">Graphique : ${esc(item.name)}</h4>
        </div>
        <div class="card-body">
            <p class="text-secondary">Historique des dernières 24 heures. Unité : ${esc(item.units || 'N/A')}</p>
            <div class="alert alert-info">
                <i class="bi bi-info-circle-fill"></i> Pour afficher le graphique, une bibliothèque comme <strong>Chart.js</strong> doit être intégrée au projet.
            </div>
            <canvas id="zabbixChart" width="400" height="200"></canvas>
            <p class="mt-2 small text-secondary">Données brutes récupérées : ${history.length} points.</p>
        </div>
    </div>`;
}

function nasScanView(data) {
    const list = rows(data);
    if (!list.length) return '<div class="alert alert-info">Aucun sous-dossier trouvé ou l\'analyse n\'a retourné aucune donnée.</div>';
    
    const totalSize = list.reduce((sum, item) => sum + (item.SizeGB || 0), 0);

    return `
    <h5>Analyse de l'utilisation des sous-dossiers</h5>
    <p class="text-secondary">Total analysé : ${totalSize.toFixed(2)} Go</p>
    <div class="table-wrap">
        <table class="table table-hover table-striped mb-0">
            <thead class="sticky-top">
                <tr>
                    <th>Dossier</th>
                    <th style="width: 150px;" class="text-end">Taille (Go)</th>
                    <th style="width: 200px;">Visualisation</th>
                </tr>
            </thead>
            <tbody>
                ${list.map(item => {
                    const size = item.SizeGB || 0;
                    const percentage = totalSize > 0 ? (size / totalSize) * 100 : 0;
                    // Gère le fait que LastWrite peut être un objet après sérialisation PS
                    const lastWriteDate = new Date(item.LastWrite.value || item.LastWrite);
                    return `<tr>
                        <td><strong>${esc(item.Name)}</strong><br><small class="text-secondary">Dernière modif.: ${esc(lastWriteDate.toLocaleString())}</small></td>
                        <td class="text-end">${size.toFixed(2)}</td>
                        <td>
                            <div class="progress" style="height: 20px;">
                                <div class="progress-bar bg-info" role="progressbar" style="width: ${percentage}%;" aria-valuenow="${percentage}" aria-valuemin="0" aria-valuemax="100">${percentage > 10 ? percentage.toFixed(0) + '%' : ''}</div>
                            </div>
                        </td>
                    </tr>`
                }).join('')}
            </tbody>
        </table>
    </div>`;
}

async function windows(action) {
    const result = document.querySelector('#result'), host = document.querySelector('#server').value.trim() || 'localhost';
    result.innerHTML = spinner;
    try {
        const data = await request(`/api/windows/${action}/${encodeURIComponent(host)}`);
        const viewMap = { system: systemView, disks: disksView, gpos: gposView, services: servicesView, ports: portsView, events: eventsView, reboots: eventsView };
        const searchId = action === 'reboots' ? 'rebootSearch' : `${action.slice(0, -1)}Search`;
        
        result.innerHTML = viewMap[action] ? viewMapaction : genericTable(data);
        
        if (['services', 'ports', 'events', 'reboots'].includes(action)) attachFilter(searchId);
        if (action === 'services') { const button = document.querySelector('#autoStoppedToggle'); if (button) { let filtered = false; button.onclick = () => { filtered = !filtered; document.querySelectorAll('#result tbody tr').forEach(row => { const isAnomaly = row.dataset.startmode === 'Auto' && row.dataset.state !== 'Running'; row.hidden = filtered && !isAnomaly; }); button.textContent = filtered ? 'Retour à tous les services' : 'Afficher uniquement ceux-ci'; }; } }
    } catch (e) { result.innerHTML = failure(e.message); }
}
async function ad() { const result = document.querySelector('#result'), user = document.querySelector('#account').value.trim(); result.innerHTML = spinner; try { result.innerHTML = adView(await request(`/api/ad/users/${encodeURIComponent(user)}`)); } catch (e) { result.innerHTML = failure(e.message); } }

async function vmware() {
    const result = document.querySelector('#result');
    const host = document.querySelector('#vmware_host').value.trim();
    const user = document.querySelector('#vmware_user').value.trim();
    const password = document.querySelector('#vmware_pass').value;

    if (!host || !user || !password) {
        result.innerHTML = failure('Veuillez remplir tous les champs de connexion.');
        return;
    }
    result.innerHTML = spinner;
    try {
        const data = await request('/api/vmware/info', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ host, user, password })
        });
        result.innerHTML = vmwareView(data);
        attachFilter('vmSearch');
    } catch (e) { result.innerHTML = failure(e.message); }
}

async function exchange(action, params = {}) {
    const result = document.querySelector('#result');
    const user = document.querySelector('#exchange_user').value.trim();
    const password = document.querySelector('#exchange_pass').value;
    const servers = Array.from(document.querySelectorAll('.exchange-server:checked')).map(cb => cb.value);

    if (!servers.length) {
        result.innerHTML = failure('Veuillez sélectionner au moins un serveur Exchange.');
        return;
    }
    if (!user || !password) {
        result.innerHTML = failure('Veuillez saisir un utilisateur et un mot de passe.');
        return;
    }

    result.innerHTML = spinner;
    try {
        const data = await request('/api/exchange/run', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ servers, user, password, action, params })
        });
        result.innerHTML = genericTable(data, 'exchangeResultSearch', 'Rechercher dans les résultats...');
        attachFilter('exchangeResultSearch');
    } catch (e) {
        result.innerHTML = failure(e.message);
    }
}

async function linux(action, params = {}) {
    const result = document.querySelector('#result');
    const host = document.querySelector('#linux_host').value.trim();
    const user = document.querySelector('#linux_user').value.trim();
    const auth_method = document.querySelector('#linux_auth_method').value;
    const password = document.querySelector('#linux_pass').value; // Ne pas trimer le mot de passe
    const private_key = document.querySelector('#linux_key').value;

    if (!host || !user) {
        result.innerHTML = failure('Veuillez saisir un hôte et un utilisateur.');
        return;
    }
    
    const body = { host, user, action, auth_method, ...params };
    if (auth_method === 'password') {
        if (!password) {
            result.innerHTML = failure('Veuillez saisir un mot de passe.');
            return;
        }
        body.password = password;
    } else { // key
        if (!private_key) {
            result.innerHTML = failure('Veuillez coller une clé privée.');
            return;
        }
        body.private_key = private_key;
    }

    result.innerHTML = spinner;
    try {
        const data = await request('/api/linux/run', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (action === 'health') {
            result.innerHTML = linuxHealthView(data);
        } else if (action === 'custom') {
            result.innerHTML = `<div class="card card-body bg-dark text-light font-monospace" style="white-space: pre-wrap; word-wrap: break-word;">${esc(data.output)}</div>`;
        } else if (action === 'updates') {
            result.innerHTML = linuxUpdatesView(data);
        } else { // services, reboots
            result.innerHTML = genericTable(data, 'linuxResultSearch', 'Rechercher dans les résultats...');
            attachFilter('linuxResultSearch');
        }
    } catch (e) {
        result.innerHTML = failure(e.message);
    }
}

async function nas(action, params = {}) {
    const result = document.querySelector('#result');
    const path = document.querySelector('#nas_path').value.trim();
    const user = document.querySelector('#nas_user').value.trim();
    const password = document.querySelector('#nas_pass').value;

    if (!path) {
        result.innerHTML = failure('Veuillez saisir un chemin UNC.');
        return;
    }

    const body = { path, action, params };
    if (user) body.user = user;
    if (password) body.password = password;

    result.innerHTML = spinner;
    try {
        const data = await request('/api/nas/run', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (action === 'scan') {
            result.innerHTML = nasScanView(data);
        } else { // audit
            result.innerHTML = genericTable(data, 'nasResultSearch', 'Rechercher dans les permissions...');
            attachFilter('nasResultSearch');
        }
    } catch (e) {
        result.innerHTML = failure(e.message);
    }
}

async function zabbix(action, params = {}) {
    const result = document.querySelector('#result');
    const url = document.querySelector('#zabbix_url').value.trim();
    const token = document.querySelector('#zabbix_token').value.trim();

    if (!url || !token) {
        result.innerHTML = failure('Veuillez saisir l\'URL de Zabbix et un jeton d\'API.');
        return;
    }

    const body = { url, token, action, params };

    result.innerHTML = spinner;
    try {
        const data = await request('/api/zabbix/run', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (action === 'sla') {
            result.innerHTML = zabbixSlaView(data);
        } else if (action === 'graph') {
            result.innerHTML = zabbixGraphView(data);
        } else {
            result.innerHTML = genericTable(data, 'zabbixResultSearch', 'Rechercher...');
            attachFilter('zabbixResultSearch');
        }
    } catch (e) {
        result.innerHTML = failure(e.message);
    }
}

function render(name) {
    app.innerHTML = modulesname;
    document.querySelectorAll('[data-module]').forEach(b => b.classList.toggle('active', b.dataset.module === name));
    if (name === 'windows') document.querySelectorAll('[data-action]').forEach(b => b.onclick = () => windows(b.dataset.action));
    if (name === 'ad') document.querySelector('#adSearch').onclick = ad;
    if (name === 'vmware') document.querySelector('#vmware_connect').onclick = vmware;
    if (name === 'exchange') {
        document.querySelector('#exchange_track_message').onclick = () => {
            const params = {
                sender: document.querySelector('#track_sender').value.trim(),
                recipient: document.querySelector('#track_recipient').value.trim(),
                subject: document.querySelector('#track_subject').value.trim()
            };
            if (!params.sender && !params.recipient) {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir au moins un expéditeur ou un destinataire pour le message tracking.');
                return;
            }
            exchange('track', params);
        };
        document.querySelector('#exchange_audit_shared').onclick = () => {
            const params = { mailbox: document.querySelector('#exchange_mailbox').value.trim() };
            if (!params.mailbox) {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir le nom de la boîte partagée.');
                return;
            }
            exchange('audit', params);
        };
        document.querySelector('#exchange_check_journal').onclick = () => exchange('journal');
    }
    if (name === 'linux') {
        const authMethodSelect = document.querySelector('#linux_auth_method');
        authMethodSelect.onchange = () => {
            const isPassword = authMethodSelect.value === 'password';
            document.querySelector('#linux_pass').classList.toggle('d-none', !isPassword);
            document.querySelector('#linux_key').classList.toggle('d-none', isPassword);
        };
        document.querySelectorAll('[data-linux-action]').forEach(button => {
            button.onclick = () => linux(button.dataset.linuxAction);
        });
        document.querySelector('#linux_run_custom').onclick = () => {
            const command = document.querySelector('#linux_custom_cmd').value.trim();
            if (command) {
                linux('custom', { command });
            } else {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir une commande à exécuter.');
            }
        };
    }
    if (name === 'nas') {
        document.querySelector('#nas_run_audit').onclick = () => {
            const auditUser = document.querySelector('#nas_audit_user').value.trim();
            if (!auditUser) {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir un nom d\'utilisateur ou de groupe pour l\'audit.');
                return;
            }
            nas('audit', { auditUser });
        };
        document.querySelector('#nas_run_scan').onclick = () => nas('scan');
    }
    if (name === 'zabbix') {
        document.querySelector('#zabbix_run_sla').onclick = () => {
            const service_id = document.querySelector('#zabbix_service_id').value.trim();
            if (!service_id) {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir un ID de Service IT.');
                return;
            }
            zabbix('sla', { service_id });
        };
        document.querySelector('#zabbix_run_graph').onclick = () => {
            const item_id = document.querySelector('#zabbix_item_id').value.trim();
            if (!item_id) {
                document.querySelector('#result').innerHTML = failure('Veuillez saisir un ID d\'élément.');
                return;
            }
            zabbix('graph', { item_id });
        };
    }
}
async function loadStatus() { const target = document.querySelector('#connectorStatus'); try { const data = await request('/api/status'); const ready = Object.values(data.connectors).filter(Boolean).length; target.textContent = `${ready} / ${Object.keys(data.connectors).length} connecteurs prêts`; } catch { target.textContent = 'État des connecteurs indisponible'; target.className = 'small text-warning mb-2'; } }
document.querySelectorAll('[data-module]').forEach(b => b.onclick = () => render(b.dataset.module)); document.querySelector('#themeToggle').onclick = () => { const n = document.documentElement.dataset.bsTheme === 'dark' ? 'light' : 'dark'; document.documentElement.dataset.bsTheme = n; localStorage.setItem('sacc-theme', n); }; loadStatus(); render('windows');