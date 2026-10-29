# Probar install.sh en un WSL aislado

Cómo probar `install.sh` en una distro de Ubuntu nueva y desechable, sin tocar la distro de trabajo.

## Qué se aísla y qué no

- La distro de pruebas tiene su propio disco, sus usuarios, su `$HOME` y sus paquetes. No afecta a tu Ubuntu de trabajo ni a Rancher Desktop.
- Comparte con Windows el disco `C:` (en `/mnt/c`) y, por defecto, el PATH de Windows. El script no toca ninguno de los dos.

Los bloques `powershell` se ejecutan en Windows. Los bloques `bash` se ejecutan dentro de la distro de pruebas.

## 1. Crear la distro de pruebas

`--name` permite tener otra Ubuntu 26.04 con un nombre distinto del de la distro de trabajo:

```powershell
wsl --install -d Ubuntu-26.04 --name dotfiles-test
```

Pide un usuario y una contraseña. Cuando aparezca el prompt, sal con `exit`.

## 2. Guardar una copia limpia

Permite repetir la prueba desde cero sin volver a instalar Ubuntu:

```powershell
mkdir C:\WSL -Force
wsl --export dotfiles-test C:\WSL\dotfiles-test-limpia.tar
```

## 3. Primera ejecución

```powershell
wsl -d dotfiles-test
```

```bash
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/install.sh | bash
```

La URL tiene que ser la **raw**. La de `github.com/.../blob/...` devuelve HTML y bash falla con `syntax error near unexpected token 'newline'`.

Para probar una rama sin fusionarla en `main`, haz push de la rama y cambia la rama en la URL y en `DOTFILES_REF`:

```bash
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/<rama>/install.sh | DOTFILES_REF=<rama> bash
```

Al terminar debe mostrar "Instalación terminada". Si algo falla, muestra `Error en el paso: …`.

## 4. Entrar en la shell nueva

```powershell
wsl --terminate dotfiles-test
wsl -d dotfiles-test
```

Debe arrancar directamente en zsh, con el prompt de starship.

## 5. Comprobaciones

```bash
echo $SHELL                 # /usr/bin/zsh
which zsh starship zoxide fzf rg lazygit nvim fnm node java mvn claude opencode tree-sitter
which java                  # ~/.sdkman/candidates/java/...
java -version 2>&1 | head -1
ls -l ~/.config/secrets/env.sh   # -rw-------
grep -c sdkman-init ~/.zshrc     # 1
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/zsh/.zshrc | diff - ~/.zshrc && echo ".zshrc igual que el repo"
```

En `nvim`, comprueba también:

- `:Lazy` no tiene nada pendiente.
- `:checkhealth nvim-treesitter` no muestra errores, salvo el falso positivo de `runtimepath`.

## 6. Segunda ejecución (idempotencia)

```bash
curl -fsSL https://raw.githubusercontent.com/AMiguelNavarro/dotfiles/main/install.sh | bash
ls -d ~/.*.bak ~/.config/*.bak 2>/dev/null   # no debe salir nada
grep -c sdkman-init ~/.zshrc                 # sigue en 1
```

En la salida no debe aparecer "Copia de seguridad". Todo debe decir "ya está instalado" o "ya está al día".

## 7. Repetir desde cero

```powershell
wsl --unregister dotfiles-test
wsl --import dotfiles-test C:\WSL\dotfiles-test C:\WSL\dotfiles-test-limpia.tar
wsl -d dotfiles-test -u <tu_usuario>
```

Una distro importada entra como root por defecto, y el script se niega a ejecutarse como root. Para entrar con tu usuario, usa `-u <tu_usuario>`. Para dejarlo fijo, añade esto a `/etc/wsl.conf` dentro de la distro:

```ini
[user]
default=<tu_usuario>
```

## 8. Limpieza

```powershell
wsl --unregister dotfiles-test      # borra la distro de pruebas para siempre
Remove-Item C:\WSL\dotfiles-test-limpia.tar
Remove-Item C:\WSL\dotfiles-test -Recurse   # solo si usaste --import
```
