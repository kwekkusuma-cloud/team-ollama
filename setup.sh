#!/usr/bin/env bash
# Sets up the shared Ollama chat site. Run once: ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

# ponytail: fixed concurrency knobs. Raise these if the machine is bored, lower them if it swaps.
# NUM_PARALLEL = how many people can be answered at the same time.
# MAX_LOADED   = how many different models sit in memory at once.
OLLAMA_NUM_PARALLEL=${OLLAMA_NUM_PARALLEL:-4}
OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS:-2}

say() { printf '\n==> %s\n' "$1"; }
die() { printf '\nSTOPPED: %s\n' "$1" >&2; exit 1; }

command -v docker >/dev/null || die "Docker is not installed. Install it with: curl -fsSL https://get.docker.com | sh"
docker compose version >/dev/null 2>&1 || die "Docker Compose is missing. Reinstall Docker with: curl -fsSL https://get.docker.com | sh"
curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 || die "Ollama is not answering on port 11434. Start it with: sudo systemctl start ollama"

say "Letting Ollama serve $OLLAMA_NUM_PARALLEL people at once"
if systemctl list-unit-files ollama.service >/dev/null 2>&1; then
  sudo mkdir -p /etc/systemd/system/ollama.service.d
  sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<CONF
[Service]
Environment="OLLAMA_NUM_PARALLEL=$OLLAMA_NUM_PARALLEL"
Environment="OLLAMA_MAX_LOADED_MODELS=$OLLAMA_MAX_LOADED_MODELS"
Environment="OLLAMA_HOST=0.0.0.0:11434"
CONF
  sudo systemctl daemon-reload && sudo systemctl restart ollama
else
  echo "   Ollama is not run by systemd here, skipping. Set OLLAMA_NUM_PARALLEL yourself if it feels slow."
fi

if [ ! -f .env ]; then
  say "Cloudflare tunnel token"
  echo "   Get it from step 2 of the README, then paste it here."
  read -rp "   Token: " token
  [ -n "$token" ] || die "No token entered. Run ./setup.sh again when you have it."
  printf 'TUNNEL_TOKEN=%s\n' "$token" > .env
fi

say "Starting the website"
docker compose up -d

say "Checking it came up"
for _ in $(seq 30); do
  if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
    say "Done. Open your Cloudflare address in a browser and create the first account."
    echo "   The first account to sign up is the admin. That should be you."
    exit 0
  fi
  sleep 2
done
die "The website did not start. See what went wrong with: docker compose logs open-webui"
