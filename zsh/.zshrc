# Created by newuser for 5.9
eval "$(starship init zsh)"

# fzf: Ctrl+R historial, Ctrl+T ficheros, Alt+C directorios
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# zoxide: cd que aprende (usa z <nombre> para saltar a una carpeta)
eval "$(zoxide init zsh)"

# fnm: gestor de versiones de Node
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd --shell zsh)"

# Plugins de zsh
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-syntax-highlighting debe ir siempre el último
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
