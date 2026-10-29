# Montar el entorno de desarrollo

Pasos para un Windows 11 nuevo. Los pasos 1 a 3 se hacen en Windows y el 4 es `install.sh` dentro de Ubuntu. Los pasos 5 y 6 se hacen a mano después.

## 1. Instalar WSL

En **PowerShell como administrador**:

```powershell
wsl --install --no-distribution
```

- `--install`: activa las características de Windows que necesita WSL e instala su kernel. Por eso hace falta ser administrador.
- `--no-distribution`: instala solo WSL. Sin este parámetro instalaría también la Ubuntu por defecto, y la versión la queremos elegir en el paso 2.

Reinicia Windows.

## 2. Instalar Ubuntu 26.04

En PowerShell normal:

```powershell
wsl --install -d Ubuntu-26.04
```

- `-d` (abreviatura de `--distribution`): elige qué distribución instalar. Sin él se instala la `Ubuntu` genérica, sin versión fija. Con `wsl --list --online` ves los nombres disponibles.
- Tiene que ser la 26.04 o posterior porque `install.sh` instala `neovim`, `starship` y `lazygit` con apt, y en versiones anteriores no están o son demasiado antiguos.

Al terminar pide un usuario y una contraseña de Linux. Esa contraseña es la que pedirá `sudo`.

## 3. Aplicaciones de Windows

Todas se descargan de su web oficial.

| Aplicación | Web | Notas |
| --- | --- | --- |
| Rancher Desktop | https://rancherdesktop.io | Motor **dockerd (moby)**. En *Preferences > WSL*, activa la integración con `Ubuntu-26.04` para tener `docker` en WSL. |
| JetBrainsMono Nerd Font | https://www.nerdfonts.com/font-downloads | Descomprime el zip, selecciona los `.ttf` y elige *Instalar para todos los usuarios*. |
| Alacritty | https://alacritty.org | Configuración en el apartado siguiente. |
| VS Code | https://code.visualstudio.com | Instala la extensión **WSL** (`ms-vscode-remote.remote-wsl`). Así `code .` desde Ubuntu abre VS Code conectado a WSL. |
| IntelliJ IDEA Community | https://www.jetbrains.com/idea/download | |

### Configuración de Alacritty

Alacritty lee su configuración de `%APPDATA%\alacritty\alacritty.toml`.

1. Escribe `%APPDATA%` en la barra de direcciones del Explorador y crea la carpeta `alacritty`.
2. Abre el Bloc de notas y pega:

   ```toml
   [terminal.shell]
   program = "wsl.exe"
   args = ["--distribution", "Ubuntu-26.04", "--cd", "~"]

   [font.normal]
   family = "JetBrainsMono Nerd Font"
   ```

3. Elige *Guardar como* dentro de la carpeta `alacritty`:
   - **Nombre:** `alacritty.toml`
   - **Tipo:** *Todos los archivos (\*.\*)*. Si no lo cambias, el Bloc de notas lo guarda como `alacritty.toml.txt` y Alacritty no lo encuentra.
   - **Codificación:** *UTF-8*. No uses *UTF-8 con BOM* ni *UTF-16*, porque Alacritty no lee bien el fichero con esas codificaciones.

Qué hace cada opción:

- `program = "wsl.exe"`: Alacritty abre WSL en lugar de PowerShell.
- `--distribution Ubuntu-26.04`: elige qué distro abrir. Tiene que coincidir con el nombre que muestra `wsl -l -v`.
- `--cd ~`: arranca en el `$HOME` de Linux, no en la carpeta de Windows desde la que se lanzó Alacritty.
- `family`: usa la Nerd Font, que incluye los iconos que usan starship y Neovim.

## 4. Ejecutar install.sh

Dentro de Ubuntu, con tu usuario (no como root):

```bash
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/install.sh | bash
```

- `curl -fsSL` descarga el script:
  - `-f`: falla si GitHub responde con un error (por ejemplo, un 404), en lugar de pasarle a bash la página de error.
  - `-s`: no muestra la barra de progreso.
  - `-S`: aun así, muestra los errores.
  - `-L`: sigue las redirecciones.
- `| bash`: ejecuta el script descargado sin guardarlo en disco.
- La URL tiene que ser la **raw** (`raw.githubusercontent.com`). La de `github.com/.../blob/...` es la página web y bash falla con `syntax error near unexpected token 'newline'`.

Qué hace el script:

- Instala paquetes con apt y pone zsh como shell por defecto.
- Instala fnm con Node LTS y tree-sitter-cli.
- Instala SDKMAN con Temurin 21 y Maven.
- Instala Claude Code y OpenCode.
- Copia la configuración del repo (`.zshrc`, `.tmux.conf`, `starship.toml` y `nvim`).
- Crea `~/.config/secrets/env.sh`.
- Instala los plugins y parsers de Neovim.

Pide la contraseña de sudo una vez. Se puede repetir sin problema: si un fichero de configuración local es distinto del repo, lo guarda como `.bak`. Si falla, indica el paso con `Error en el paso: …`.

## 5. Pasos manuales

1. **Entrar en zsh.** En PowerShell, ejecuta `wsl --terminate Ubuntu-26.04` y vuelve a abrir Alacritty. `--terminate` para la distro, y así la siguiente sesión arranca con la nueva shell por defecto.
2. **Claude Code:** ejecuta `claude` e inicia sesión.
3. **OpenCode:** `opencode auth login`.
4. **Claves de API:** escríbelas en `~/.config/secrets/env.sh` (fuera del repo, con permisos 600), con este formato:

   ```bash
   export ANTHROPIC_API_KEY="..."
   ```

5. **Identidad de git:**

   ```bash
   git config --global user.name "Tu nombre"
   git config --global user.email "<id>+<usuario>@users.noreply.github.com"
   ```

   - `--global`: guarda la identidad para todos los repos de este usuario, en `~/.gitconfig`.
   - El email `noreply` de GitHub (*Settings > Emails*) evita publicar tu correo real en los commits.

6. **Clave SSH para GitHub:**

   ```bash
   ssh-keygen -t ed25519 -C "<id>+<usuario>@users.noreply.github.com"
   cat ~/.ssh/id_ed25519.pub
   ```

   - `-t ed25519`: el tipo de clave. Es el que recomienda GitHub: moderno, seguro y corto.
   - `-C`: un comentario para reconocer la clave en GitHub.
   - `cat`: muestra la clave pública para copiarla en *GitHub > Settings > SSH and GPG keys*.

   Para comprobarla, ejecuta `ssh -T git@github.com`. `-T` no pide una terminal, porque GitHub no da shell: solo responde con tu usuario.

7. **Opcional: clonar el repo para editar la configuración.** El script copia los ficheros, no los enlaza, así que un cambio en `~/.zshrc` no llega al repo. Para versionar cambios, edítalos en el clon y haz push:

   ```bash
   git clone git@github.com:AMiguelNavarro/dotfiles.git ~/dotfiles
   ```

## 6. Comprobaciones

```bash
echo $SHELL     # /usr/bin/zsh
which zsh starship zoxide fzf rg lazygit nvim fnm node java mvn claude opencode tree-sitter
which java      # ~/.sdkman/candidates/java/...
```

`which` debe devolver una ruta para cada herramienta.

En `nvim`:

- `:Lazy` no debe tener nada pendiente.
- `:checkhealth nvim-treesitter` no debe mostrar errores. La única excepción es el aviso de que `~/.local/share/nvim/site/` "is not in runtimepath": es un falso positivo y no hay que corregirlo.

Para probar cambios en el script sin tocar tu entorno: [how-to-perform-isolated-test.md](how-to-perform-isolated-test.md).
