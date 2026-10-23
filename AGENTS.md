# AGENTS.md — spelregels Satire Games

Geldt voor elke agent (Codex-redactie, Codex-site, Claude-tester). Max 40 regels; elke regel heeft datum + reden.
Wijzigen alleen via PR na weekretro en Efrens akkoord.

## Toon en content
1. Satire stoot omhoog: mikpunt is macht, systemen en absurde situaties, nooit een groep mensen. (2026-10-24, bouwprompt §1.10)
2. Geen echte, herkenbare personen als personage; verzonnen namen en uiterlijk. (2026-10-24, bouwprompt §1.10 — juridisch risico)
3. Geen gelicentieerde assets: alleen zelfgemaakt, CC0 of eigen generatie met vastgelegde bron. (2026-10-24, bouwprompt §1.10)
4. Eén grap moet zonder uitleg werken bij een speler die de nieuwsachtergrond niet kent. (2026-10-24, startregel; herzien bij eerste retro)

## Techniek
5. Unity 6 (6000.x) + C#, doelplatform WebGL. (2026-10-24, gemeten: Unity 6000.6.3f1 op de bouwmachine)
6. Eén werkmap `~/satire-games/` onder git; niets wat een agent nodig heeft staat alleen in Obsidian of ai-memory. (2026-10-24, bouwprompt §1.3)
7. Nooit twee agents tegelijk in de Unity Editor; het Paperclip-ticket is het slot. (2026-10-24, bouwprompt §1.5)
8. Resultaten als compacte JSON (`playtest-result.json`), geen logs plakken. (2026-10-24, tokenregel §1.8)

## Rollen
9. Bouwer test niet zelf: Codex-redactie bouwt, Claude test. Codex-site bouwt de site, Claude reviewt. (2026-10-24, bouwprompt §1.7)
10. Mergen alleen bij groene Actions-run én QA-akkoord-ticket. (2026-10-24, bouwprompt §1.6)
11. Max 4 bouw-testrondes per bouwticket, max 2 QA-rondes per siteticket; daarna digest-ticket aan Efren. (2026-10-24, bouwprompt §1.9)
12. Efren beslist alleen: ontwerp-akkoord, release-akkoord, nieuwe agents, strategiewijziging. (2026-10-24, bouwprompt §0)

## Veiligheid
13. Nooit `ANTHROPIC_API_KEY` of `OPENAI_API_KEY` in de shell of in git; Codex-profielen staan op `forced_login_method = "chatgpt"`. (2026-10-24, bouwprompt §1.1 — stil overschakelen naar betaalde API)
14. Alleen officiële CLI's; nooit chatwebsites automatiseren. (2026-10-24, bouwprompt §1.2 — voorwaarden)
15. `.env`, `*.key`, `~/.codex-*`, `~/.claude` nooit in git; gitleaks draait pre-commit en in CI. (2026-10-24, bouwprompt §1.11)

## Bekende risico's (geen regel, wel weten)
- Twee ChatGPT-accounts van één persoon kunnen botsen met de OpenAI-voorwaarde tegen het omzeilen van limieten. Risico ligt bij de eigenaar. (2026-10-24)
