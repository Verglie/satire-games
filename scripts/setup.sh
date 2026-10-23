#!/usr/bin/env bash
# Zet het Satire Games-systeem op. Idempotent: opnieuw draaien verandert niets wat al goed staat.
# Enige mensenwerk: de stappen in HANDLEIDING-EFREN.md (logins, goedkeuringen).
#
# Gebruik: scripts/setup.sh [repo-map]   (standaard: de map waar dit script in staat, één niveau op)
set -euo pipefail

REPO="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
AIMEM_VERSION="v3.2.2"
AIMEM_DIR="$HOME/Applications/ai-memory"
AIMEM="$AIMEM_DIR/ai-memory"
AIMEM_DATA="$HOME/Library/Application Support/ai-memory"
LFS_VERSION="v3.8.1"

ok()   { printf '  ok    %s\n' "$*"; }
doe()  { printf '  doe   %s\n' "$*"; }
mens() { printf '  MENS  %s\n' "$*"; }

# Harde regel 1: met een API-sleutel in de shell schakelen de CLI's stil naar betaalde API.
for k in ANTHROPIC_API_KEY OPENAI_API_KEY; do
  if [ -n "${!k:-}" ]; then echo "STOP — $k staat in je shell. Haal hem weg (harde regel 1)." >&2; exit 1; fi
done

arch() { case "$(uname -m)" in arm64) echo aarch64 ;; *) echo x86_64 ;; esac; }
sha_ok() { [ "$(shasum -a 256 "$1" | awk '{print $1}')" = "$2" ]; }

echo "== 1. Gereedschap"
for c in node npm git gh brew; do command -v "$c" >/dev/null || { echo "STOP — $c ontbreekt" >&2; exit 1; }; ok "$c"; done
if [ -d "/Applications/Unity Hub.app" ]; then ok "Unity Hub; editors: $(ls /Applications/Unity/Hub/Editor 2>/dev/null | tr '\n' ' ')"; else mens "Unity Hub installeren (handleiding)"; fi

command -v codex >/dev/null || { doe "Codex CLI installeren"; npm i -g @openai/codex >/dev/null; }
ok "codex $(codex --version 2>/dev/null)"
command -v claude >/dev/null || { doe "Claude Code installeren"; npm i -g @anthropic-ai/claude-code >/dev/null; }
ok "claude $(claude --version 2>/dev/null)"
command -v gitleaks >/dev/null || { doe "gitleaks installeren"; brew install gitleaks >/dev/null; }
ok "gitleaks $(gitleaks version)"

# git-lfs via release-binary: brew weigert op deze machine door verouderde Command Line Tools.
if ! git lfs version >/dev/null 2>&1; then
  doe "git-lfs $LFS_VERSION installeren"
  t="$(mktemp -d)"; z="git-lfs-darwin-$( [ "$(arch)" = aarch64 ] && echo arm64 || echo amd64 )-$LFS_VERSION.zip"
  gh release download "$LFS_VERSION" -R git-lfs/git-lfs -p "$z" -p sha256sums.asc -D "$t"
  sha_ok "$t/$z" "$(grep "$z" "$t/sha256sums.asc" | awk '{print $1}')" || { echo "STOP — git-lfs checksum klopt niet" >&2; exit 1; }
  (cd "$t" && unzip -oq "$z")
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$(find "$t" -name git-lfs -type f -perm -u+x | head -1)" "$HOME/.local/bin/git-lfs"
  ln -sf "$HOME/.local/bin/git-lfs" /usr/local/bin/git-lfs
  rm -rf "$t"
fi
ok "$(git lfs version)"

echo "== 2. Codex-profielen"
for p in redactie site; do
  d="$HOME/.codex-$p"; mkdir -p "$d"; chmod 700 "$d"
  if [ ! -f "$d/config.toml" ]; then
    doe "config $d"
    cat > "$d/config.toml" <<EOF
# Satire Games — profiel $p (beheerd door ~/satire-games/scripts/setup.sh)
# Alleen ChatGPT-login: voorkomt stil overschakelen naar betaalde API (harde regel 1).
forced_login_method = "chatgpt"
# Inlog per profiel in een eigen bestand, zodat de twee accounts elkaar niet overschrijven.
cli_auth_credentials_store = "file"
model_reasoning_effort = "low"
sandbox_mode = "workspace-write"
EOF
  fi
  s="$(CODEX_HOME="$d" codex login status 2>&1 | head -1 || true)"
  case "$s" in *"Logged in"*) ok "codex-$p: $s" ;; *) mens "codex-$p: $s → handleiding stap 'Codex-login'" ;; esac
done

echo "== 3. ai-memory (native, LaunchAgent op 127.0.0.1:49374)"
if [ ! -x "$AIMEM" ] || ! "$AIMEM" --version | grep -q "${AIMEM_VERSION#v}"; then
  doe "ai-memory $AIMEM_VERSION installeren"
  mkdir -p "$AIMEM_DIR"; tgz="ai-memory-macos-$(arch).tar.gz"
  gh release download "$AIMEM_VERSION" -R akitaonrails/ai-memory -p "$tgz" -p "$tgz.sha256" -D "$AIMEM_DIR" --clobber
  sha_ok "$AIMEM_DIR/$tgz" "$(awk 'NR==1{print $1}' "$AIMEM_DIR/$tgz.sha256")" || { echo "STOP — ai-memory checksum klopt niet" >&2; exit 1; }
  tar -xzf "$AIMEM_DIR/$tgz" -C "$AIMEM_DIR"
fi
ok "$("$AIMEM" --version)"
[ -f "$AIMEM_DATA/config.toml" ] || { doe "ai-memory init"; "$AIMEM" init >/dev/null 2>&1; }
plist="$HOME/Library/LaunchAgents/com.github.akitaonrails.ai-memory.plist"
if [ ! -f "$plist" ]; then
  doe "LaunchAgent installeren"
  mkdir -p "$HOME/Library/Logs/ai-memory" "$HOME/Library/LaunchAgents"
  sed -e "s|__AI_MEMORY_BIN__|$AIMEM|" -e "s|__HOME__|$HOME|" \
    "$AIMEM_DIR/packaging/launchd/com.github.akitaonrails.ai-memory.plist" > "$plist"
  launchctl bootstrap "gui/$(id -u)" "$plist"
fi
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -fsS http://127.0.0.1:49374/healthz >/dev/null 2>&1 && break; sleep 1; done
curl -fsS http://127.0.0.1:49374/healthz >/dev/null || { echo "STOP — ai-memory reageert niet op /healthz" >&2; exit 1; }
ok "ai-memory server gezond"
[ -L "$HOME/ai-memory-data" ] || ln -sfn "$AIMEM_DATA" "$HOME/ai-memory-data"
ok "~/ai-memory-data → $AIMEM_DATA (Obsidian: open ~/ai-memory-data/wiki)"

echo "== 4. Repo"
cd "$REPO"
[ -d .git ] || { doe "git init"; git init -q -b main; }
git lfs install --local >/dev/null
git config core.hooksPath scripts/hooks
chmod +x scripts/hooks/* scripts/*.sh
ok "hooks via scripts/hooks (gitleaks pre-commit)"

echo "== 5. ai-memory koppelen aan de agents"
# Claude Code: alleen dit project (.claude/settings.local.json), zodat andere projecten niet worden opgenomen.
"$AIMEM" install-hooks --agent claude-code --scope project --apply >/dev/null
ok "hooks claude-code (project)"
# Niet via install-mcp: die registreert op user-niveau (alle projecten). Hier scope local = alleen deze map.
claude mcp get ai-memory >/dev/null 2>&1 || claude mcp add --scope local --transport stdio ai-memory -- \
  "$AIMEM" mcp-bridge --server-url http://127.0.0.1:49374/mcp >/dev/null
ok "mcp claude-code (alleen deze map)"
for p in redactie site; do
  CODEX_HOME="$HOME/.codex-$p" "$AIMEM" install-mcp --client codex --apply >/dev/null
  CODEX_HOME="$HOME/.codex-$p" "$AIMEM" install-hooks --agent codex --apply >/dev/null
  ok "mcp + hooks codex-$p"
done

echo "== 6. Basispagina's in de wiki"
"$REPO/scripts/wiki-basis.sh"

echo
echo "Klaar. Open stappen staan in HANDLEIDING-EFREN.md."
