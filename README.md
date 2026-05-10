<img width="1500" height="500" alt="debuntubootlogo" src="https://github.com/user-attachments/assets/4a1f288a-11ec-4cd7-a607-3ddec18e7822" />

# Ubuntu Customizer / Hijacker / DeBloater
ngl this a project i managed to make in a night.
pretty simple app. does a lot though.

- removes the snaps nobody asked for
- swaps the boot logo to something cleaner
- verbose boot mode so you actually see whats happening on startup
- live USB boot — plug one in and it sets it as the next boot target automatically
- installs stuff ubuntu should've shipped (codecs, ffmpeg, vlc, etc)
- distro hijack — pulls in Nix, Flatpak/Flathub, Homebrew, Cargo, pipx on top of ubuntu

you'll figure the rest out.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sup3rt00ls/DeBuntu/main/install.sh | sudo bash
```

then just run `debuntu`.

## Notes
- Ubuntu 20.04 or higher only
- runs as root automatically
- revert option undoes everything if you break something
