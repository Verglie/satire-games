# BOUWPROMPT — Lokale AI-orchestrator voor satirische Unity-games

> Plak dit bestand als eerste opdracht in Claude Code, gestart in een lege map `~/satire-games/`:
> `cd ~/satire-games && claude` → daarna: "Lees BOUWPROMPT.md en voer het uit."
> Claude doet alles wat zonder mens kan. Alles wat een mens moet doen (inloggen, goedkeuren,
> op een knop drukken) schrijft Claude in `HANDLEIDING-EFREN.md` als genummerde stap en stopt
> daar met een duidelijke melding, in plaats van te wachten, te raden of door te gaan.

## 0. Wie je bent en wat je bouwt

Je bent Claude Code en je bouwt een lokaal, gratis systeem waarin drie AI-accounts samenwerken
aan satirische games in Unity en de website waarop ze draaien:

- **ChatGPT-account 1** via Codex CLI, profiel `~/.codex-redactie` — rol: hoofdredacteur,
  gameontwerper en **bouwer** in Unity.
- **ChatGPT-account 2** via Codex CLI, profiel `~/.codex-site` — rol: site-beheer en QA-checklists.
- **Claude-account** via Claude Code (jijzelf, maar dan als agent) — rol: **speltester**,
  code-reviewer en merger.
- **Efren** (de eigenaar) is raad van bestuur: hij pitcht ideeën, keurt het ontwerp goed
  vóór de bouw en speelt de game zelf vóór publicatie. Verder niets.

Onderdelen (allemaal gratis en open source; installeer niets dat geld kost):

| Onderdeel | Rol | Bron |
|---|---|---|
| Paperclip | control plane: rollen, tickets, heartbeats, budgetten, goedkeuringen | `npx paperclipai onboard` — https://github.com/paperclipai/paperclip |
| ai-memory | gedeeld geheugen en handoffs tussen Codex en Claude Code, markdown-wiki in git | https://github.com/akitaonrails/ai-memory |
| Codex CLI | agent-runtime voor de twee ChatGPT-accounts, ingelogd met ChatGPT (geen API-sleutel) | `npm i -g @openai/codex` |
| Claude Code | agent-runtime voor het Claude-account, ingelogd met abonnement (geen API-sleutel) | `npm i -g @anthropic-ai/claude-code` |
| Unity 6 + officiële Unity MCP Server | de game-engine; MCP-brug via de relay in `~/.unity/relay/` (pakket `com.unity.ai.assistant`) | https://docs.unity3d.com/Packages/com.unity.ai.assistant@latest/manual/integration/unity-mcp-get-started.html |
| GitHub + GitHub Pages + Actions | repo, CI (tests + WebGL-build) en gratis hosting van de site | — |
| Ollama (optioneel) | lokaal model voor ai-memory-samenvattingen, zodat de abonnementen vrij blijven | https://ollama.com |

## 1. Harde regels (gelden voor alles wat je doet)

1. **Geen API-sleutels in de shell.** Nooit `ANTHROPIC_API_KEY` of `OPENAI_API_KEY` globaal zetten;
   dan schakelen de CLI's stilletjes van abonnement naar betaalde API. Een sleutel hoort, als hij
   ooit nodig is, alleen in de env van de ene Paperclip-agent die hem gebruikt.
2. **Alleen officiële CLI's.** Nooit de chatwebsites van OpenAI of Anthropic automatiseren; dat is
   tegen de voorwaarden en kost het account.
3. **Eén werkmap:** `~/satire-games/` onder git. Obsidian is alleen een leesvenster op de
   ai-memory-wiki (`~/ai-memory-data/wiki/`), geen opslag voor iets wat agents nodig hebben.
4. **Mens-stappen stop je niet weg.** Alles wat een browser-login, een goedkeuring in Unity of een
   GitHub-instelling vraagt, zet je als genummerde stap in `HANDLEIDING-EFREN.md` en je meldt:
   "STOP — stap N in HANDLEIDING-EFREN.md is aan jou." Daarna ga je door met alles wat niet van
   die stap afhangt.
5. **Nooit twee agents tegelijk in Unity.** Eén Unity Editor, één project; het Paperclip-ticket
   is het slot. Bouwen en testen gebeuren na elkaar.
6. **Niets geldt als getest tenzij CI het zegt.** De reviewer mag alleen mergen met een groene
   Actions-run én een QA-akkoord-ticket.
7. **Bouwer test niet zelf.** ChatGPT 1 bouwt, Claude test; ChatGPT 2 beheert de site, Claude
   reviewt.
8. **Tokens:** kleine tickets (≤ 1 heartbeat), delta-prompts (alleen wat gewijzigd is),
   gestructureerde resultaten (JSON) in plaats van logs, laag reasoning-niveau voor routine,
   hoog alleen voor ontwerp. Meet tokens per **goedgekeurde** game, nooit los.
9. **Loop-begrenzing:** maximaal 4 bouw-testrondes per ticket, maximaal 2 QA-rondes per site-ticket;
   daarna stopt de loop en krijgt Efren een digest-ticket.
10. **Content:** geen echte personen als personage, geen gelicentieerde assets, geen groepen als
    mikpunt; deze regels staan in `AGENTS.md` en in de QA-checklist.
11. **Secrets:** gitleaks als pre-commit en in CI; `.env`, `~/.codex-*`, `~/.claude` nooit in git;
    ai-memory capture-regels sluiten `.env` en `*.key` uit.
12. **Alles idempotent en herhaalbaar:** `scripts/setup.sh` moet op een schone machine opnieuw het
    hele systeem opzetten met als enige mensenwerk de logins en goedkeuringen uit de handleiding.

## 2. Mapstructuur die je aanmaakt

```
~/satire-games/
├── AGENTS.md                      # spelregels, toon, techstack, contentregels (≤ 40 regels, elk met datum + reden)
├── HANDLEIDING-EFREN.md           # genummerde mens-stappen; jij vult dit terwijl je bouwt
├── BOUWPROMPT.md                  # dit bestand
├── games/
│   └── _template/                 # kopie-bron voor elke nieuwe game
│       ├── design.md              # script, personages, omgevingen, mechaniek, klaar-criteria per scène
│       ├── playtest.json          # speler-scenario's voor de bot-speler
│       ├── unity/                 # Unity 6-project (Assets, Packages, ProjectSettings) met Test Framework + bot-speler
│       └── results/               # playtest-result.json en result.xml per ronde (gitignored behalve laatste)
├── site/                          # statische site; WebGL-builds komen door CI in site/games/<naam>/
├── scripts/
│   ├── setup.sh                   # bootstrap van alles (idempotent)
│   ├── watchdog.sh                # elk uur: logins geldig? laatste geslaagde run < 24 u? anders melding + agent pauzeren
│   ├── controller.py              # tokens/rondes per ticket, loop-begrenzing, weekcijfers, regelhygiëne
│   ├── playtest.sh                # Unity -runTests -batchmode -testPlatform PlayMode → results/result.xml → playtest-result.json
│   ├── cleanup.sh                 # worktrees na merge weg, logs roteren, ai-memory purge-beleid
│   └── digest.py                  # dagelijks digest-ticket: kudos eerst, dan 3 beslissingen, dan incidenten
├── paperclip/                     # export van de bedrijfsconfig (agents, rollen, heartbeats) zodat setup.sh hem kan terugzetten
├── .github/workflows/
│   ├── ci.yml                     # gitleaks, lint, EditMode- en PlayMode-tests via game-ci/unity-test-runner
│   ├── build-webgl.yml            # WebGL-build via game-ci/unity-builder → site/games/<naam>/
│   └── deploy-pages.yml           # site/ → GitHub Pages bij merge naar main
├── .gitignore                     # Unity: Library/ Temp/ Logs/ Build/ UserSettings/; results/*; .env
└── .gitattributes                 # Git LFS voor .png .psd .wav .mp3 .fbx .blend
```

## 3. Fasen — voer ze in deze volgorde uit, vink af in een takenlijst

### Fase A — Basis (geen mens nodig behalve logins)
1. Controleer `node`, `git`, `docker`, Unity Hub; installeer wat ontbreekt via de package manager
   van het OS. Meld de Unity-versie die je aantreft.
2. `npm i -g @openai/codex @anthropic-ai/claude-code`. Maak `~/.codex-redactie` en `~/.codex-site`
   aan met elk een `config.toml` (model_reasoning_effort standaard `low`, sandbox `workspace-write`,
   MCP-blok voor Unity alleen in het redactie-profiel). Schrijf in `HANDLEIDING-EFREN.md`:
   - stap: `CODEX_HOME=~/.codex-redactie codex login` → inloggen met ChatGPT-account 1
   - stap: `CODEX_HOME=~/.codex-site codex login` → inloggen met ChatGPT-account 2
   - stap: `claude` → inloggen met het Claude-abonnement; controleren met `/status` dat er "subscription" staat
3. ai-memory: start als Docker-container op loopback (`127.0.0.1:49374`, `--restart unless-stopped`,
   volume `~/ai-memory-data`), zonder LLM-sleutel. Daarna `install-mcp` en `install-hooks` voor
   `claude-code` en voor beide Codex-profielen. Zet `[capture]`-regels die `.env`, `*.key` en
   `results/` uitsluiten. Maak drie wiki-pagina's aan: `stijlgids.md`, `besluiten.md`
   (met kolommen datum/status geldig|herroepen), `afgewezen-ideeen.md`, en twee lege mappen:
   `incidenten/`, `kudos/`. Als Ollama aanwezig is: koppel het als LLM-provider voor samenvattingen.
4. Git-repo met de mapstructuur uit §2, `AGENTS.md` (eerste versie: toon, techstack Unity 6 + C#,
   WebGL als doelplatform, contentregels, "bouwer test niet zelf", loop-grenzen), `.gitignore`,
   `.gitattributes` (LFS), gitleaks pre-commit. Eerste commit.
5. GitHub: maak de repo aan met `gh` als die ingelogd is; anders handleidingstap. Schrijf hoe dan
   ook deze handleidingstappen: fine-grained token met alleen `contents:write` + `pull_requests:write`
   op deze repo → repository-secret `AGENT_GITHUB_TOKEN`; branch protection op `main` (PR verplicht,
   checks verplicht, geen force-push); Pages aan op de `gh-pages`-branch of `site/`.

### Fase B — Unity-project en speltest-infrastructuur
6. Maak `games/_template/unity/` als Unity 6-project (via Unity Hub CLI of een kaal project dat je
   committed) met: Unity Test Framework, Input System, een `BotPlayer`-MonoBehaviour die
   `playtest.json` leest en scenario's uitvoert met gesimuleerde input, en per stap een regel
   schrijft naar `results/playtest-result.json` (`{step, expected, observed, pass, screenshot?}`).
   Screenshot alleen bij `pass: false`.
7. `scripts/playtest.sh`: vindt de Unity-installatie, draait
   `-runTests -batchmode -projectPath … -testPlatform PlayMode -testResults results/result.xml`,
   parseert de NUnit-XML en voegt samen met de bot-resultaten tot één compact JSON.
8. Officiële Unity MCP Server: schrijf de MCP-config voor Claude Code (`claude mcp add unity-mcp --
   ~/.unity/relay/<platform-binary> --mcp`) en de `[mcp_servers.unity-mcp]`-regel in
   `~/.codex-redactie/config.toml` met hetzelfde commando. Handleidingstappen:
   - Unity 6 openen met het template-project; Package Manager → `com.unity.ai.assistant` installeren
     (Unity AI-trial of -abonnement aanzetten als Unity daarom vraagt; Unity AI-credits worden
     niet verbruikt door MCP)
   - Edit > Project Settings > AI > Unity MCP Server → Unity Bridge moet "Running" zijn
   - bij de eerste verbinding van Claude Code én van Codex: "Pending Connections" → Approve (twee keer)
   Als het officiële pakket een betaald Unity-plan blijkt te vereisen dat Efren niet heeft: schakel
   over op MCP for Unity (https://github.com/CoplayDev/unity-mcp, MIT) en pas de config aan;
   meld dit expliciet.
9. CI: `ci.yml` (gitleaks, EditMode/PlayMode via `game-ci/unity-test-runner`), `build-webgl.yml`
   (`game-ci/unity-builder`, output naar `site/games/<naam>/`), `deploy-pages.yml`. Handleidingstap:
   Unity-licentie voor CI activeren volgens de GameCI-docs (`UNITY_LICENSE`-secret). Zolang die
   secret ontbreekt, draait de PlayMode-test lokaal via `scripts/playtest.sh` in een pre-merge-hook
   en markeert CI de stap als "skipped, lokaal gedraaid" in plaats van te falen.

### Fase C — Paperclip: het bedrijf
10. `npx paperclipai onboard --yes`, embedded Postgres, loopback-only. Maak één bedrijf
    "Satire Games" en deze agents (exporteer de config naar `paperclip/`):

    | Agent | Adapter | Env | Heartbeat | Model/effort |
    |---|---|---|---|---|
    | Hoofdredacteur-bouwer (CEO) | `codex_local` | `CODEX_HOME=~/.codex-redactie` | elke 4 u + bij toewijzing | effort `medium`; `high` alleen bij tickettype `ontwerp` |
    | Site-beheer & QA | `codex_local` | `CODEX_HOME=~/.codex-site` | elke 8 u + bij toewijzing | effort `low` |
    | Speltester-reviewer | `claude_local` | geen API-key in env | bij toewijzing | Sonnet standaard; Opus alleen bij tickettype `review-ontwerp` |
    | Controller | `process` | — | elk uur | `scripts/controller.py` (geen LLM) |
    | Archivaris | `process` | — | dagelijks | `scripts/cleanup.sh` + ai-memory-onderhoud (geen LLM) |

    Governance: alleen het aannemen van agents, een strategiewijziging en het tickettype
    `release` vereisen Efrens goedkeuring. Budget per agent: $0 (abonnement) met een laag
    vangnet, zodat Paperclip pauzeert bij onverwachte kosten. Timeout per heartbeat 20 min.
11. Tickettypen en sjablonen in Paperclip: `pitch`, `ontwerp`, `bouw`, `speeltest`, `site`,
    `review`, `release`, `digest`, `wildcard`, `weekretro`. Elk sjabloon verwijst naar
    `design.md`/`playtest.json` in plaats van inhoud te herhalen.
12. De game-flow als keten van tickets (wie maakt wat aan):
    - `pitch` (Efren) → redacteur stelt ≤ 5 vragen in één beurt → antwoorden in `design.md`
    - `ontwerp` → redacteur schrijft `design.md` + `playtest.json` → ticket `goedkeuring-ontwerp`
      aan Efren (handleiding: in het dashboard lezen, goedkeuren of terugsturen)
    - `bouw` → redacteur bouwt via Unity MCP, commit per scène, maakt `speeltest`-ticket met
      alleen de gewijzigde scènes/stappen
    - `speeltest` → Claude draait `scripts/playtest.sh`, beoordeelt tegen `design.md`, levert
      `playtest-result.json` + max. 5 zinnen oordeel; mislukt → terug naar `bouw` (ronde + 1)
    - alles groen + WebGL-build groen → ticket `release` aan Efren (handleiding: spelen, feedback
      als één nieuw `bouw`-ticket, of goedkeuren → merge → deploy)
    - `site`-tickets lopen apart: ChatGPT 2 bouwt, Claude reviewt, max 2 rondes.

### Fase D — Autonomie, bewaking en leren
13. Diensten: Paperclip en ai-memory als launchd/systemd-dienst (of Docker restart-beleid), zodat
    alles na een herstart meeloopt. Handleidingstap: slaapstand van de machine uitzetten of een
    altijd-aan apparaat kiezen.
14. `scripts/watchdog.sh` (elk uur via Paperclip's controller-heartbeat): `codex login status` in
    beide profielen, Claude-auth, laatste geslaagde run per agent < 24 u, schijfruimte > 10 GB,
    Unity Bridge bereikbaar. Bij een fout: agent pauzeren in Paperclip, incidentpagina in ai-memory,
    melding in het digest én, als een webhook-URL in `.env` staat, naar Efrens chat-app.
15. `scripts/controller.py`: per ticket rondes en tokens tellen (uit Paperclip's run-records),
    loop-grenzen afdwingen, zware tickets plannen aan het begin van een vers 5-uursvenster,
    weekcijfers schrijven naar ai-memory (`cijfers/<week>.md`): tokens per goedgekeurde game,
    rework-ratio, limiet-hits, herhaalde incidenten, hergebruikte patronen, aantal regels in
    `AGENTS.md`.
16. Leerkring: incident- en kudospagina's (sjablonen in ai-memory), wekelijks `weekretro`-ticket
    voor de redacteur (effort `low`): leest `incidenten/` en `kudos/` van de week, stelt ≤ 3
    wijzigingen voor aan `AGENTS.md`/rolprompts/checklists, elk met het incident of de kudos als
    reden; Efren keurt goed in het dashboard; wijzigingen gaan via PR. Regelhygiëne: ≤ 40 regels,
    regels zonder incident in 90 dagen worden ter herbevestiging voorgelegd. Wekelijks één
    `wildcard`-ticket. Het digest opent met kudos.
17. Spelersfeedback: een feedbackknop op de site die (via een GitHub-issue of een gratis
    formulier-naar-issue-Action) een Paperclip-ticket wordt; privacyvriendelijke speelduur-teller
    zonder cookies.

### Fase E — Oplevering en controle
18. Draai `scripts/setup.sh` opnieuw in een tijdelijke map om te bewijzen dat hij idempotent is.
19. Voer een complete droogloop uit met een mini-game ("één scène, één keuze, één grap"): pitch →
    ontwerp → bouw → speeltest → release, met Efren alleen op de goedkeur-momenten. Log de tokens
    per stap in `cijfers/week-0.md`.
20. Lever op: `HANDLEIDING-EFREN.md` compleet en in volgorde, met per stap: waarom, waar
    (welk scherm/commando), hoe je ziet dat het gelukt is. Daarna een samenvatting van wat draait,
    wat nog open staat en welke eerste beslissing alleen Efren kan nemen.

## 4. Formaat van `HANDLEIDING-EFREN.md`

```
# Handleiding voor Efren — alleen wat jij zelf moet doen

## Eenmalig (installatie)
1. [ ] <stap> — Waarom: … — Waar: <commando of scherm> — Klaar als: …
...

## Per game (terugkerend)
1. [ ] Pitch als ticket in Paperclip (http://localhost:<poort>) — Klaar als: redacteur stelt vragen
2. [ ] design.md goedkeuren of terugsturen — Klaar als: ticket `bouw` verschijnt
3. [ ] Release-ticket: WebGL-build spelen, feedback als één ticket, of goedkeuren — Klaar als: site bijgewerkt

## Wekelijks (5 minuten)
1. [ ] Weekretro-voorstellen goedkeuren
2. [ ] Digest lezen; kudos staan bovenaan
```

Alles wat niet in deze handleiding staat, doe jij.
