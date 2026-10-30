# Contributing to Kuro prefabs

A prefab describes a server (game, web site, tool) that Kuro can deploy: its containers, settings,
files and install. This repository is included in [Kuro](https://github.com/kuroctl/kuro) as a
submodule (`prefabs/`): what is merged here ships with the next Kuro release as an official
prefab.

The format is defined by Kuro's JSON Schema (`shared/prefab/schema/prefab.v1.schema.json`); this
guide says how to write a prefab that will be accepted, and what gets it refused.

## The easy way: the Prefab Studio

The panel's Studio (Prefabs › Studio) validates as you type, shows the settings form as an admin
will see it, imports a `docker-compose.yml` or a Pterodactyl egg, sets the images (Steam's for a
game declaring `steam.app`), and **tries the prefab on a test node**. Once happy, copy its files
into a folder of this repository, add the images, and open a pull request.

An AI agent can do all of this through Kuro's MCP server (create, validate, try, read the
console); publishing stays a human action.

## Prefab layout

```
<folder>/
├── prefab.yaml         manifest (format kuro.prefab/v1)
├── locales/en.json     required (fallback language)
├── locales/fr.json     expected
├── templates/          file templates, if the manifest declares any
└── assets/             icon, banner, thumbnail
```

- The folder name is free; the prefab's identity is `id` + `version` of its manifest.
- At the top of `prefab.yaml`, for completion and validation in your editor (VS Code, Red Hat
  YAML extension):

  ```yaml
  # yaml-language-server: $schema=https://raw.githubusercontent.com/kuroctl/kuro/main/shared/prefab/schema/prefab.v1.schema.json
  ```

- Start from a similar prefab rather than a blank page (see the table in the
  [README](README.md)), then change **right away** `id`, `version: 1.0.0`, `tags` and the names
  in the translations.

## Rules

### Identity and versions
- A published prefab is **immutable** by `id` + `version`: changing its content needs a new
  version (`1.0.0` → `1.0.1` for a fix, `1.1.0` for an addition). Existing servers stay on their
  version.
- Two folders with the same `id@version` are refused: they would conflict when the catalog
  reloads.
- Cosmetic exceptions: images (`assets`) and the Steam game (`steam`) can be added to a published
  version without changing its number.

### Docker images and install
- **Pinned** images: by digest (`@sha256:…`) or by a dated tag, never `latest` nor a moving tag.
  Say in a comment which version the digest points to.
- Explicit registry (`docker.io/library/…`, `ghcr.io/…`).
- Every install download has its `sha256`.
- Prefer typed steps (`download`, `extract`, `steamcmd`, `copy`, `remove`) over `script`.

### Security (not negotiable)
Kuro refuses, whatever the manifest says: root, privileged containers, host network, host
folder mounts, added capabilities. Every service runs:
- as a non-root user (`user: "uid:gid"`);
- on a **read-only** root: everything to write goes in a volume, or in `writable` (in memory,
  owned by the service user);
- with no port published on the host except those marked `public: true`.

A game that writes to `~` crashes when its home folder is not a volume:
`env: { HOME: /data }`.

### Ports
- Name them (`game`, `query`, `rcon`…); `public: true` only for what players reach. An RCON or an
  admin API stays internal.
- A web site declares **one** `web: true` port: served over HTTPS by the node proxy at
  `{{ server.web_url }}` (host name only: `{{ server.web_host }}`), never published on the host.

### Settings
- Password typed by the admin: `type: password`; secret generated at deployment (RCON, admin):
  `type: secret` with `generate: { length: 24 }`.
- Bound everything that ends up in a file or a command line (`pattern`, `min`, `max`,
  `max_length`); a value must never be able to break the syntax of the file receiving it.
- `restart: true` if the value is only read at start; `editable: deploy` if it only makes sense
  at creation (world size, seed).

### Files
- `managed-keys`: Kuro rewrites a few keys on every start and leaves the rest (`ini`,
  `properties`, `json`, `yaml`); for a file the application edits itself.
- `template`: file fully rewritten on every start from `templates/`.
- `user`: free file, editable by the admin (a `template` gives its initial content).
- Nothing concatenated into a shell line: pass values as separate arguments
  (`sh -c '… "$@"' name arg1 arg2`) or through a configuration file.

### Lifecycle, backup, actions
- `ready`: a console line **actually printed** when the server accepts players (checked on a
  trial), or `healthcheck: true`. Never make one up: leave it out rather than wrong.
- `stop`: a clean console command, otherwise a signal (`SIGTERM`, `SIGINT`, `SIGWINCH`, `SIGHUP`,
  or `image` for the signal declared by the image).
- `backup.before`: the `wait` targets the line printed **at the end** of the save.
- `actions`: maintenance commands run in a running service (argument list, never a shell line;
  typed and bounded parameters). `schedulable: true` for those meant to be scheduled.

### Translations
`locales/en.json` and `locales/fr.json` complete and symmetric: `prefab.name` and `description`,
a title per group, a `label` (and useful help) per field, the `options` of each `enum`, a
description per file, a `label` per action and per parameter. A missing key is a validation
error.

### Images
- `assets/`: PNG, JPEG or WebP, 2 MiB at most each; **never SVG** (the whole prefab would be
  refused). The paths declared in `assets:` must exist.
- Agreed sizes: icon 64×64, banner 1600×600, thumbnail 600×800 (portrait). Kuro crops and
  shrinks them itself ("Optimize images"), never enlarging.
- A game sold on Steam declares `steam: { app: <id> }`: the id of **the game** on the store
  (Valheim 892970), not the id of its dedicated server (896660).
- Only add images you are allowed to use (publisher artwork, or community artwork whose author
  allows it).

### Drafts
Until a prefab has run on a real node, mark it:

```yaml
x-status: "draft: <what is left to check>"
```

It can then only be deployed on a test node. Remove the mark (new version) once tried, and say in
the pull request what it was tried on.

## Checking before the pull request

CI loads every folder exactly like Kuro's import: manifest, translations, templates, images,
duplicate `id@version`. Locally, from a Kuro clone:

```bash
cargo run -p kuro-prefab --bin kuro-prefab-check -- prefabs
```

The JSON Schema is not enough: it sees neither template references, nor paths outside volumes,
nor missing translation keys.

## Proposing the prefab

1. A branch, a folder (or a new version of an existing folder).
2. Its row in the [README](README.md) table: what it shows, and "draft" if not yet tried.
3. A commit in the Conventional Commits format: `feat(valheim): ...`, `fix(rust): ...`.
4. In the pull request: where the game-specific values come from (dedicated server docs, egg,
   image), and what was tried.

## From the Kuro repository (maintainers)

`kuro/prefabs/` is a full clone of this repository: the dev API reads it directly.

- `git submodule update` puts the submodule on the commit pinned by Kuro, **as a detached
  HEAD**: before editing, go back to the branch (`git -C prefabs switch main`), otherwise your
  commits are on no branch.
- Commit and push **in the submodule** first, then commit the new pointer in Kuro
  (`git add prefabs`) so that this Kuro version ships these prefabs.
- This repository's CI validates with Kuro's main branch: a format change is pushed to Kuro
  before the prefabs that use it.
