#!/usr/bin/env bash
# Instala el entorno de desarrollo en Ubuntu (WSL2) desde cero:
#   curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/install.sh | bash
# Para probar otra rama: ... | DOTFILES_REF=<rama> bash
set -euo pipefail

DOTFILES_REF="${DOTFILES_REF:-main}"
DOTFILES_TARBALL="https://github.com/AMiguelNavarro/dotfiles/archive/refs/heads/${DOTFILES_REF}.tar.gz"
JAVA_ID="21.0.13.0+9-tem"
APT_PAQUETES=(
  zsh tmux fzf ripgrep zsh-autosuggestions zsh-syntax-highlighting
  zoxide starship lazygit neovim build-essential zip unzip curl git
)

PASO=""
TMP=""
NVIM_OK=1
AVISOS=()

paso() {
  PASO="$1"
  printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

info() { printf '  %s\n' "$1"; }

aviso() {
  printf '  \033[1;33mAviso:\033[0m %s\n' "$1"
  AVISOS+=("$1")
}

al_salir() {
  local estado=$?
  [ -n "$TMP" ] && rm -rf "$TMP"
  if [ "$estado" -ne 0 ]; then
    printf '\n\033[1;31mError en el paso: %s\033[0m\n' "$PASO" >&2
  fi
}

# Copia origen a destino. Si el destino existe y es distinto, lo guarda en <destino>.bak.
copiar() {
  local origen="$1" destino="$2"
  mkdir -p "$(dirname "$destino")"
  if [ -e "$destino" ] || [ -L "$destino" ]; then
    if [ ! -L "$destino" ] && diff -rq "$origen" "$destino" >/dev/null 2>&1; then
      info "$destino ya está al día"
      return
    fi
    rm -rf "$destino.bak"
    mv "$destino" "$destino.bak"
    info "Copia de seguridad: $destino.bak"
  fi
  cp -r "$origen" "$destino"
  info "Copiado $destino"
}

comprobar_requisitos() {
  paso "Comprobando requisitos"
  if [ "$EUID" -eq 0 ]; then
    echo "No ejecutes este script como root ni con sudo: lánzalo con tu usuario." >&2
    exit 1
  fi
  if ! command -v apt-get >/dev/null; then
    echo "Este script necesita apt (Ubuntu o Debian)." >&2
    exit 1
  fi
  info "Se pedirá la contraseña de sudo (solo para apt y chsh)"
  sudo -v
}

instalar_apt() {
  paso "Instalando paquetes con apt"
  sudo apt-get update </dev/null
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PAQUETES[@]}" </dev/null
}

cambiar_shell() {
  paso "Configurando zsh como shell por defecto"
  local zsh_path actual
  zsh_path="$(command -v zsh)"
  actual="$(getent passwd "$USER" | cut -d: -f7)"
  if [ "$actual" = "$zsh_path" ]; then
    info "zsh ya es la shell por defecto"
    return
  fi
  sudo chsh -s "$zsh_path" "$USER"
}

descargar_config() {
  paso "Descargando la configuración (rama $DOTFILES_REF)"
  TMP="$(mktemp -d)"
  mkdir -p "$TMP/repo"
  curl -fsSL "$DOTFILES_TARBALL" | tar -xz -C "$TMP/repo" --strip-components=1
}

instalar_node() {
  paso "Instalando fnm, Node LTS y tree-sitter-cli"
  if [ ! -x "$HOME/.local/share/fnm/fnm" ]; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/share/fnm"
  else
    info "fnm ya está instalado"
  fi
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  fnm use default

  if [ ! -x "$(npm prefix -g)/bin/tree-sitter" ]; then
    npm install -g tree-sitter-cli </dev/null
  else
    info "tree-sitter-cli ya está instalado"
  fi
}

instalar_java() {
  paso "Instalando SDKMAN, Java (Temurin 21) y Maven"
  if [ ! -d "$HOME/.sdkman" ]; then
    curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
  else
    info "SDKMAN ya está instalado"
  fi

  # SDKMAN usa variables sin definir, así que se desactiva -u mientras se usa
  set +u
  # shellcheck disable=SC1091
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdkman_auto_answer=true

  local java_id="$JAVA_ID"
  if [ ! -d "$HOME/.sdkman/candidates/java/$java_id" ]; then
    if ! sdk list java </dev/null | grep -F "$java_id" >/dev/null; then
      java_id="$(sdk list java </dev/null | grep -oE '21\.[0-9.+]+-tem' | sort -V | tail -1)"
      if [ -z "$java_id" ]; then
        set -u
        echo "No se encuentra ninguna Temurin 21 en SDKMAN." >&2
        return 1
      fi
      aviso "Temurin $JAVA_ID no está disponible; se instala $java_id"
    fi
    sdk install java "$java_id" </dev/null
  else
    info "Java $java_id ya está instalado"
  fi
  sdk default java "$java_id" </dev/null

  if [ ! -d "$HOME/.sdkman/candidates/maven/current" ]; then
    sdk install maven </dev/null
  else
    info "Maven ya está instalado"
  fi
  set -u

  case "$(command -v java)" in
    "$HOME/.sdkman/candidates/java/"*) info "java: $(command -v java)" ;;
    *) aviso "java no apunta a SDKMAN: $(command -v java)" ;;
  esac
}

instalar_ia() {
  paso "Instalando Claude Code y OpenCode"
  if [ ! -x "$HOME/.local/bin/claude" ]; then
    curl -fsSL https://claude.ai/install.sh | bash
  else
    info "Claude Code ya está instalado"
  fi
  if [ ! -x "$HOME/.opencode/bin/opencode" ]; then
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
  else
    info "OpenCode ya está instalado"
  fi
}

copiar_config() {
  paso "Copiando la configuración"
  copiar "$TMP/repo/zsh/.zshrc" "$HOME/.zshrc"
  copiar "$TMP/repo/tmux/.tmux.conf" "$HOME/.tmux.conf"
  copiar "$TMP/repo/starship/starship.toml" "$HOME/.config/starship.toml"
  copiar "$TMP/repo/nvim" "$HOME/.config/nvim"
}

crear_secretos() {
  paso "Preparando ~/.config/secrets/env.sh"
  local fichero="$HOME/.config/secrets/env.sh"
  mkdir -p "$HOME/.config/secrets"
  chmod 700 "$HOME/.config/secrets"
  if [ ! -f "$fichero" ]; then
    printf '# Claves de API. Este fichero no se versiona.\n# export ANTHROPIC_API_KEY="..."\n' >"$fichero"
    info "Creado $fichero"
  else
    info "$fichero ya existe"
  fi
  chmod 600 "$fichero"
}

preparar_neovim() {
  paso "Instalando plugins y parsers de Neovim"
  # En una instalación limpia el primer restore deja algunos plugins en una versión
  # más nueva y reescribe lazy-lock.json: se repone el lock y se repite el restore.
  if ! { nvim --headless "+Lazy! restore" +qa </dev/null &&
    cp "$TMP/repo/nvim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json" &&
    nvim --headless "+Lazy! restore" +qa </dev/null; }; then
    NVIM_OK=0
    aviso "Falló la instalación de plugins de Neovim"
    return
  fi
  if ! nvim --headless \
    -c 'lua require("nvim-treesitter").install(LazyVim.opts("nvim-treesitter").ensure_installed):wait(600000)' \
    -c qa </dev/null; then
    NVIM_OK=0
    aviso "Falló la instalación de parsers de treesitter"
  fi
  echo
}

resumen() {
  paso "Instalación terminada"
  if [ "${#AVISOS[@]}" -gt 0 ]; then
    echo "Avisos:"
    printf '  - %s\n' "${AVISOS[@]}"
    echo
  fi
  cat <<EOF
Pasos manuales pendientes:
  1. Cierra la terminal y abre una nueva para entrar en zsh
     (o desde Windows: wsl --terminate <distro>).
  2. Inicia sesión en Claude Code: claude
  3. Inicia sesión en OpenCode: opencode auth login
  4. Rellena tus claves en ~/.config/secrets/env.sh
  5. Configura tu identidad de git (email noreply de GitHub):
       git config --global user.name "..."
       git config --global user.email "...@users.noreply.github.com"
  6. Crea una clave SSH y añádela a GitHub.
EOF
  if [ "$NVIM_OK" -eq 0 ]; then
    echo "  7. Abre nvim para terminar de instalar plugins y parsers."
  fi
}

main() {
  trap al_salir EXIT
  comprobar_requisitos
  instalar_apt
  cambiar_shell
  descargar_config
  export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
  instalar_node
  instalar_java
  instalar_ia
  copiar_config
  crear_secretos
  preparar_neovim
  resumen
}

main "$@"
