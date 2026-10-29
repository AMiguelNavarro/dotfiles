Repositorio de configuración para WSL2 (Ubuntu), pensado para reproducirse en un equipo nuevo con un solo script.

# Shell

- zsh: shell principal.

# Tools CLI
- starship: prompt claro e informativo.
- tmux: sesiones, ventanas y paneles.
- fzf: búsqueda difusa de historial, ficheros y directorios.
- zoxide: saltar a directorios frecuentes sin escribir rutas largas.
- ripgrep: búsqueda rápida de texto en el código.

# Git

- lazygit: interfaz de git en terminal, sin salir de la consola.

# Editor

- Neovim con LazyVim

# Desarrollo

- SDKMAN: gestiona Java y Maven.
- fnm: gestiona Node.

# IA

- Claude Code
- OpenCode

# IDEs

- VS Code
- IntelliJ IDEA

# Docker
- Rancher Desktop

# Emulador de terminal
- Alacritty

# Donde reside cada cosa

| Windows | WSL (Ubuntu) |
|---|---|
| WSL2 y Ubuntu | zsh |
| Rancher Desktop (motor Moby) | starship |
| Alacritty | tmux |
| JetBrainsMono Nerd Font | fzf |
| VS Code | zoxide |
| IntelliJ IDEA Community | ripgrep |
|  | lazygit |
|  | Neovim con LazyVim |
|  | SDKMAN (Temurin 21 y Maven) |
|  | fnm (Node LTS) |
|  | tree-sitter-cli |
|  | Claude Code |
|  | OpenCode |

# Enlaces de interes

- Montar entorno de desarrollo: [setup.md](docs/setup.md)