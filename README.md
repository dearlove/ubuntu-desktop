# ubuntu-desktop
Ubuntu based desktop for use in a docker container, built for [Kasm Workspaces](https://kasmweb.com/).

Includes: Vivaldi, Anytype, RustDesk, Visual Studio Code, Claude Desktop (beta), MusicBrainz Picard
and [Herdr](https://herdr.dev/) (herdr-app with herdr-core).

## Image

```
ghcr.io/dearlove/ubuntu-desktop:latest
```

Also tagged with the build date (`YYYYMMDD`) and short commit SHA.

GitHub Actions rebuilds and pushes the image on every push to `main`, every Monday,
and on demand (Actions → Build image → Run workflow). Builds never use the layer cache,
so each build picks up the newest base image and app versions.

## Base image

The image is built `FROM` Kasm's core image (`kasmweb/core-ubuntu-noble`, Ubuntu 24.04 LTS),
which supplies KasmVNC, the XFCE desktop and the startup scripts Kasm needs.
Kasm's Ubuntu 26.04 base (`kasmweb/core-ubuntu-resolute`) currently only has `develop` tags;
to build on it anyway:

```
docker build --build-arg BASE_IMAGE=core-ubuntu-resolute --build-arg BASE_TAG=develop .
```

## Adding to Kasm

Admin → Workspaces → Add Workspace:

- **Docker Image:** `ghcr.io/dearlove/ubuntu-desktop:latest`
- **Docker Registry:** `https://ghcr.io` (the package must be public, or add GHCR credentials)
- **Cores / Memory:** 2+ cores, 4096 MB+ recommended

## Notes

- Vivaldi, VS Code, Anytype and Claude are launched with `--no-sandbox`, since Chromium's
  sandbox can't run in an unprivileged container.
- Claude's Cowork feature needs KVM and won't work inside Kasm; Chat and Claude Code do.
- Herdr connects to other machines (such as a Mac) over SSH, offering the hosts in
  `~/.ssh/config`. The Mac needs Remote Login turned on. Use a persistent profile, or
  re-add your key and config each session, since a fresh session's home starts empty.
- Herdr and herdr-core update themselves inside the session; each rebuild also ships
  the latest release.
- Herdr renders with Mesa's software Vulkan driver unless the agent passes a GPU through.
- Only `linux/amd64` is built.
