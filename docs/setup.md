# Montar el entorno de desarrollo

Guía para preparar un equipo Windows 11 desde cero. Los pasos 1 a 3 son manuales en Windows. El paso 4 lo hace `install.sh` dentro de Ubuntu. Los pasos 5 y 6 son manuales después del script.

## Resumen del orden

1. Windows: instalar WSL.
2. Windows: instalar Ubuntu 26.04 en WSL.
3. Windows: Rancher Desktop, Nerd Font, Alacritty, VS Code e IntelliJ IDEA.
4. Ubuntu: ejecutar `install.sh`.
5. Ubuntu: pasos manuales después del script.
6. Comprobaciones finales.

## Paso 1: instalar WSL

Abre **PowerShell como administrador** (clic derecho en PowerShell, *Ejecutar como administrador*):

```powershell
wsl --install --no-distribution
```

Reinicia Windows cuando termine.

## Paso 2: instalar Ubuntu 26.04

En PowerShell (no hace falta que sea como administrador):

```powershell
wsl --install -d Ubuntu-26.04
```

Al terminar, se abre Ubuntu y pide un usuario y una contraseña de Linux. Esa contraseña es la que pedirá `sudo` más adelante.

Tiene que ser **26.04** o posterior: `install.sh` instala `neovim`, `starship` y `lazygit` con apt, y en versiones anteriores no están disponibles o son demasiado antiguos.

## Paso 3: aplicaciones de Windows

Se pueden instalar desde su web o con `winget` desde PowerShell.

### Rancher Desktop

```powershell
winget install SUSE.RancherDesktop
```

- Motor de contenedores: **dockerd (moby)**.
- En *Preferences > WSL > Integrations*, activa la distro de Ubuntu para tener `docker` dentro de WSL.

### JetBrainsMono Nerd Font

1. Descarga `JetBrainsMono.zip` desde https://www.nerdfonts.com/font-downloads.
2. Descomprímelo, selecciona los `.ttf`, clic derecho y *Instalar para todos los usuarios*.

### Alacritty

```powershell
winget install Alacritty.Alacritty
```

Crea `%APPDATA%\alacritty\alacritty.toml` (normalmente `C:\Users\<usuario>\AppData\Roaming\alacritty\alacritty.toml`), guardado en **UTF-8**:

```toml
[terminal.shell]
program = "wsl.exe"
args = ["--distribution", "Ubuntu-26.04", "--cd", "~"]

[font.normal]
family = "JetBrainsMono Nerd Font"
```

- `--distribution` es la distro que se abre. Tiene que coincidir con el nombre que muestra `wsl -l -v` (al instalar con `wsl --install -d Ubuntu-26.04` se llama `Ubuntu-26.04`).
- `--cd ~` hace que arranque en el `$HOME` de Linux y no en la carpeta de Windows desde la que se lanzó Alacritty.
- Se abre con la shell por defecto del usuario, que después de `install.sh` es zsh.

Desde PowerShell se puede crear así:

```powershell
New-Item -ItemType Directory -Force "$env:APPDATA\alacritty" | Out-Null
$config = @'
[terminal.shell]
program = "wsl.exe"
args = ["--distribution", "Ubuntu-26.04", "--cd", "~"]

[font.normal]
family = "JetBrainsMono Nerd Font"
'@
# WriteAllText guarda en UTF-8 sin BOM en cualquier versión de PowerShell
[System.IO.File]::WriteAllText("$env:APPDATA\alacritty\alacritty.toml", $config)
```

### VS Code

```powershell
winget install Microsoft.VisualStudioCode
code --install-extension ms-vscode-remote.remote-wsl
```

Con la extensión WSL, `code .` desde Ubuntu abre VS Code conectado a WSL.

### IntelliJ IDEA Community

```powershell
winget install JetBrains.IntelliJIDEA.Community
```

## Paso 4: ejecutar install.sh

Dentro de Ubuntu, con tu usuario (no como root):

```bash
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/install.sh | bash
```

La URL tiene que ser la **raw** (`raw.githubusercontent.com`). La de `github.com/.../blob/...` es la página web y bash fallaría con `syntax error near unexpected token 'newline'`.

Qué hace el script:

- Instala los paquetes con apt.
- Pone zsh como shell por defecto.
- Instala fnm con Node LTS y tree-sitter-cli.
- Instala SDKMAN con Temurin 21 y Maven.
- Instala Claude Code y OpenCode.
- Copia la configuración del repo (`.zshrc`, `.tmux.conf`, `starship.toml` y `nvim`).
- Crea `~/.config/secrets/env.sh`.
- Instala los plugins y parsers de Neovim.

Pide la contraseña de sudo una vez al principio y tarda varios minutos. Se puede volver a ejecutar sin problema: lo que ya está instalado se salta, y si un fichero de configuración local es distinto del repo, guarda una copia en `<fichero>.bak`.

Si falla, muestra `Error en el paso: …` con el paso concreto.

## Paso 5: pasos manuales después del script

1. **Abrir una terminal nueva** para entrar en zsh. Desde PowerShell: `wsl --terminate Ubuntu-26.04` y vuelve a abrirla.
2. **Claude Code:** ejecuta `claude` e inicia sesión.
3. **OpenCode:** `opencode auth login`.
4. **Claves de API:** rellénalas en `~/.config/secrets/env.sh` (permisos 600, fuera del repo):

   ```bash
   export ANTHROPIC_API_KEY="..."
   ```

5. **Identidad de git**, con el email `noreply` de GitHub (*Settings > Emails*):

   ```bash
   git config --global user.name "Tu nombre"
   git config --global user.email "<id>+<usuario>@users.noreply.github.com"
   ```

6. **Clave SSH para GitHub:**

   ```bash
   ssh-keygen -t ed25519 -C "<id>+<usuario>@users.noreply.github.com"
   cat ~/.ssh/id_ed25519.pub
   ```

   Pega la clave pública en GitHub (*Settings > SSH and GPG keys > New SSH key*) y compruébala con `ssh -T git@github.com`.

7. **Opcional: clonar el repo para editar la configuración.** El script copia los ficheros, no los enlaza, así que un cambio en `~/.zshrc` no llega al repo. Para versionar cambios, clona el repo, edítalo ahí y haz push:

   ```bash
   git clone git@github.com:AMiguelNavarro/dotfiles.git ~/dotfiles
   ```

## Paso 6: comprobaciones finales

En una terminal nueva:

```bash
echo $SHELL                 # /usr/bin/zsh
which zsh starship zoxide fzf rg lazygit nvim fnm node java mvn claude opencode tree-sitter
which java                  # ~/.sdkman/candidates/java/...
java -version               # Temurin 21
```

Todas las herramientas deben devolver una ruta.

En Neovim (`nvim`):

- `:Lazy` no debe tener nada pendiente.
- `:checkhealth nvim-treesitter` no debe mostrar errores. La única excepción es un falso positivo conocido: dice que `~/.local/share/nvim/site/` "is not in runtimepath", pero sí lo está y los parsers cargan. No hay que corregirlo.

Para probar cambios en el script sin tocar tu entorno, consulta [how-to-perform-isolated-test.md](how-to-perform-isolated-test.md).
