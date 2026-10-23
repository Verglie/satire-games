# Handleiding voor Efren — alleen wat jij zelf moet doen

Stand: Fase A (basis) gebouwd op 2026-10-24. Fase B–E volgen; hun stappen komen hier bij zodra ze gebouwd zijn.
Controleer alles in één keer met `~/satire-games/scripts/setup.sh`: elke regel `MENS` is een stap hieronder.

## Eenmalig (installatie)

1. [ ] **Codex-login redactie** — Waarom: de hoofdredacteur-bouwer draait op ChatGPT-account 1, via het abonnement, niet via betaalde API. — Waar: Terminal:
   `CODEX_HOME=~/.codex-redactie codex login` → er opent een browser → log in met **ChatGPT-account 1**. — Klaar als: `CODEX_HOME=~/.codex-redactie codex login status` toont "Logged in using ChatGPT".

2. [ ] **Codex-login site** — Waarom: site-beheer en QA draaien op ChatGPT-account 2. — Waar: Terminal:
   `CODEX_HOME=~/.codex-site codex login` → log in met **ChatGPT-account 2** (niet hetzelfde als stap 1). — Klaar als: `CODEX_HOME=~/.codex-site codex login status` toont "Logged in using ChatGPT".

3. [ ] **Claude-abonnement controleren** — Waarom: de speltester mag nooit via een API-sleutel lopen. — Waar: Terminal: `claude`, typ daarna `/status`. — Klaar als: er staat een abonnement (Pro/Max), geen "API key".

4. [ ] **GitHub-token voor de agents** — Waarom: agents mogen alleen in deze ene repo pushen en PR's openen, niet in je andere repo's. — Waar: github.com → Settings → Developer settings → Fine-grained tokens → Generate. Repository access: alleen `Verglie/satire-games`. Permissions: **Contents: Read and write**, **Pull requests: Read and write**. Plak het token daarna als secret: repo → Settings → Secrets and variables → Actions → New secret, naam `AGENT_GITHUB_TOKEN`. — Klaar als: de secret staat in de lijst. (Claude mag tokens niet zelf aanmaken of invoeren.)

5. [ ] **(Later, na Fase B) Branch protection op `main`** — Waarom: niemand, ook geen agent, merget zonder groene CI. — Waar: repo → Settings → Branches → Add rule `main`: PR verplicht, status checks verplicht (`ci`), force-push uit. — Klaar als: een directe push naar `main` geweigerd wordt. Dit kan pas als de CI-checks bestaan; Claude meldt wanneer.

6. [ ] **(Later, na Fase B) GitHub Pages aanzetten** — Waarom: gratis hosting van de site. — Waar: repo → Settings → Pages → Source: "GitHub Actions". — Klaar als: Pages toont een URL.

7. [ ] **(Optioneel) Command Line Tools bijwerken** — Waarom: Homebrew weigert nu nieuwe pakketten ("Your Command Line Tools are too outdated"). Git-lfs is daarom buiten brew om geïnstalleerd; voor latere onderdelen kan brew nodig zijn. — Waar: Terminal: `softwareupdate --list`; staat er een "Command Line Tools"-regel, installeer die met `softwareupdate -i "<die naam>"` (vraagt je wachtwoord). — Klaar als: `brew install hello` zonder die fout werkt.

8. [ ] **(Optioneel) Obsidian als leesvenster** — Waarom: het gedeelde geheugen van de agents meelezen. — Waar: Obsidian → Open folder as vault → `~/ai-memory-data/wiki`. Let op: mappen hebben ID-namen; het project staat in de map met `besluiten.md` erin. Alleen lezen, niet bewerken. — Klaar als: je `besluiten.md` ziet.

## Per game (terugkerend)
Volgt na Fase C (Paperclip).

## Wekelijks (5 minuten)
Volgt na Fase D.
