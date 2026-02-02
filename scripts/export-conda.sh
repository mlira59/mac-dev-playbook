#!/bin/bash
# Export Conda environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_DIR="$REPO_DIR/files/exports/conda-envs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

mkdir -p "$EXPORT_DIR"

# Find conda executable
CONDA_EXE=""
for path in "$HOME/miniforge3/condabin/conda" "$HOME/miniconda3/condabin/conda" "/opt/homebrew/Caskroom/miniconda/base/condabin/conda"; do
    if [ -x "$path" ]; then
        CONDA_EXE="$path"
        break
    fi
done

if [ -z "$CONDA_EXE" ]; then
    echo -e "${YELLOW}Conda not found. Skipping.${NC}"
    exit 0
fi

echo "Using conda at: $CONDA_EXE"
echo "Exporting Conda environments..."

# Get list of environments (excluding base)
ENVS=$("$CONDA_EXE" env list --json | python3 -c "
import sys, json, os
data = json.load(sys.stdin)
for env_path in data.get('envs', []):
    if '/envs/' in env_path:
        print(os.path.basename(env_path))
")

if [ -z "$ENVS" ]; then
    echo -e "${YELLOW}No conda environments found (excluding base).${NC}"
    exit 0
fi

# Export each environment
count=0
for env in $ENVS; do
    echo "  Exporting: $env"

    # Full export with pinned versions
    "$CONDA_EXE" env export -n "$env" > "$EXPORT_DIR/${env}.yml" 2>/dev/null || true

    # Minimal cross-platform export (just explicit packages)
    "$CONDA_EXE" env export -n "$env" --from-history > "$EXPORT_DIR/${env}-minimal.yml" 2>/dev/null || true

    count=$((count + 1))
done

# Create summary
cat > "$EXPORT_DIR/README.md" << EOF
# Conda Environments Export

Generated: $(date +%Y-%m-%d)

## Environments

EOF

for env in $ENVS; do
    echo "- \`$env\`" >> "$EXPORT_DIR/README.md"
done

cat >> "$EXPORT_DIR/README.md" << 'EOF'

## Files

- `<env>.yml` - Full export with pinned versions (platform-specific)
- `<env>-minimal.yml` - Minimal export from history (cross-platform)

## Recreating Environments

```bash
# Full recreation (same platform)
conda env create -f python_3_13.yml

# Cross-platform recreation
conda env create -f python_3_13-minimal.yml
```
EOF

echo ""
echo -e "${GREEN}Conda export complete: $EXPORT_DIR/${NC}"
echo "  $count environments exported"
ls -1 "$EXPORT_DIR"/*.yml 2>/dev/null | head -5
[ $(ls -1 "$EXPORT_DIR"/*.yml 2>/dev/null | wc -l) -gt 5 ] && echo "  ..."
