# Kuro prefabs

Server templates (games, web sites, tools) for [Kuro](https://github.com/kuroctl/kuro), the
server management panel. This repository is included in Kuro as a submodule (`prefabs/`): each
Kuro release ships the prefabs of the commit it pins, imported as official prefabs when the API
starts.

A prefab can also be made in the panel's **Prefab Studio** (editor validated as you type, trial on
a test node), then published to the catalog of an installation. To offer it to everyone, add its
folder here through a pull request: see [CONTRIBUTING.md](CONTRIBUTING.md) (rules, checks,
working from Kuro's submodule).

| Prefab | Services | What it shows |
|---|---|---|
| `minecraft-java` | 1 | self-installing image, `server.properties` as `managed-keys`, mods and plugins as `download` (Modrinth, CurseForge, upload), hot backup (`save-off` / `save-all flush` / `save-on`, logs excluded) |
| `wordpress` | 2 (`web`, `db`) | private network between services, shared generated secret, healthcheck, editable PHP files |
| `terraria` | 1 | `download` (pinned sha256) + `extract` (`subdir`, `executable`) + `remove` install, `serverconfig.txt` as `managed-keys` (`ini`), `HOME` on the volume, backup after `save` |
| `ark-survival-ascended` | 1 | `steamcmd` install, free `Game.ini`, `GameUserSettings.ini` as `managed-keys`, CurseForge mods as `reference` (draft: runtime image to choose) |
| `minecraft-bedrock` | 1 | self-installing image, RakNet transport (a single UDP port), settings through environment variables, hot backup (`save hold` / `save query` / `save resume`), CurseForge add-ons as `extract` (packs sorted by their `manifest.json`, registered in `world_*_packs.json`) |
| `valheim` | 1 | `steamcmd`, Pterodactyl image kept with its entrypoint (`STARTUP`, settings through the environment), stop by SIGINT |
| `project-zomboid` | 1 | `steamcmd`, JVM shipped with the game, `kuro.ini` as `managed-keys` (`ini` without sections), Steam Workshop slot as `reference` (`WorkshopItems`), mod ids entered per item (`fields`, `Mods=`), suggested from the item description (`prefill`) |
| `rust` | 1 | `steamcmd` then `script` (Steam library), started from the game folder by `sh -c` with values as separate arguments, internal WebRCON |
| `enshrouded` | 1 | Windows server under Proton GE, log redirected to the console (draft: `steamcmd` must be able to force the Windows platform) |
| `arma-3` | 1 | `steamcmd` with the installation's Steam account (`login: account`), `server.cfg` as `template` rewritten on every start, free `basic.cfg` (draft: not yet tried on a real node) |
| `fivem` | 1 | pinned build as `download` + `extract` of a `.tar.xz` (internal links copied), `tcp+udp` port on one allocation, `kuro.cfg` as `template` loaded by a free `server.cfg`, base resources at a fixed commit (draft: not yet tried with a real license) |
| `redm` | 1 | RedM (Red Dead Redemption 2) variant of the `fivem` prefab, same install, game `rdr3` (draft: not yet tried with a real license) |
| `counter-strike-2` | 1 | `steamcmd` (app 730, anonymous) then `script` (Steam library), `sh -c` start with separate arguments, game mode through `+game_alias`, optional GSLT token (draft: not yet tried) |
| `nextcloud` | 2 (`web`, `db`) | web site, install by the image's entrypoint, PHP `template` with `{{ server.web_host }}`, `occ` actions including a schedulable `cron`, stop by the image's signal (draft) |
| `owncloud-ocis` | 1 | web site, `ocis init` as `script` in the official image (entrypoint cleared), generated config kept on reinstall (draft) |
| `openclaw` | 1 | web site, `openclaw.json` as JSON `managed-keys` (site origin, trusted proxy), device approval actions, ready by healthcheck (starts on a Linux node; public interface not yet tried) |
| `hermes-agent` | 1 | web site, s6-overlay image run without root (`/run` as `writable`), `config.yaml` as YAML `managed-keys`, stop by the image's signal (starts on a Linux node; public HTTPS not yet tried) |

## Layout

```
<folder>/
├── prefab.yaml         manifest (format kuro.prefab/v1)
├── locales/en.json     required (fallback language), then fr.json…
├── templates/          file templates
└── assets/             icon, banner, thumbnail (PNG, JPEG or WebP)
```

The folder name is free; the prefab's identity is the `id` of its manifest. A published prefab is
**immutable** by `id` + `version`: changing its content needs a new version.

For completion and validation in your editor (VS Code, Red Hat YAML extension), at the top of
`prefab.yaml`:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/kuroctl/kuro/main/shared/prefab/schema/prefab.v1.schema.json
```

## Checking

The JSON Schema does not cover everything (template references, paths under volumes, default
value bounds, translation keys). CI loads every folder exactly like Kuro's import, with the
`kuro-prefab` crate; locally, from a Kuro clone:

```bash
cargo run -p kuro-prefab --bin kuro-prefab-check -- prefabs
```

## Images

`assets/`: publisher artwork (Steam for Steam games) or community artwork, to replace if its use
is not allowed for your deployment.

A game sold on Steam declares `steam: { app: <id> }`: the id of **the game** on the store (730 for
Counter-Strike 2, 892970 for Valheim), not the id of its dedicated server. The Studio then imports
its images ("Import from Steam"). Like `assets`, this section is cosmetic: adding it does not need
a new version.
