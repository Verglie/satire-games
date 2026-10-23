#!/usr/bin/env bash
# Legt de basispagina's van de gedeelde wiki aan (project satire-games). Bestaande pagina's blijven onaangeroerd.
set -euo pipefail
AIMEM="$HOME/Applications/ai-memory/ai-memory"
PROJ=satire-games

pagina() { # pad, body
  if "$AIMEM" read-page --project "$PROJ" --path "$1" >/dev/null 2>&1; then
    printf '  ok    wiki %s\n' "$1"
  else
    printf '%s\n' "$2" | "$AIMEM" write-page --project "$PROJ" --path "$1" --body - >/dev/null 2>&1
    printf '  doe   wiki %s\n' "$1"
  fi
}

pagina stijlgids.md "# Stijlgids

Toon, humor en vormgeving van Satire Games. De regels staan in AGENTS.md; hier komen voorbeelden en uitwerkingen.

## Toon
- (nog leeg — eerste game vult dit)"

pagina besluiten.md "# Besluiten

| datum | besluit | reden | status |
|---|---|---|---|
| 2026-10-24 | ai-memory draait native (LaunchAgent), niet in Docker | het project raadt native aan op macOS; scheelt schijf en geeft token-auth | geldig |
| 2026-10-24 | Claude Code-hooks alleen op projectniveau | andere projecten op deze machine mogen niet in deze wiki | geldig |
| 2026-10-24 | Repo publiek op GitHub (Verglie/satire-games) | GitHub Pages en Actions gratis | geldig |"

pagina afgewezen-ideeen.md "# Afgewezen ideeën

| datum | idee | waarom niet |
|---|---|---|"

pagina incidenten/_sjabloon.md "# Incident: <korte titel>

- datum:
- symptoom:
- commando dat het toont:
- oorzaak (alleen als vastgesteld):
- regel of checklist die het had moeten vangen:"

pagina kudos/_sjabloon.md "# Kudos: <korte titel>

- datum:
- wie (agent of mens):
- wat ging goed:
- welk patroon hergebruiken we:"
