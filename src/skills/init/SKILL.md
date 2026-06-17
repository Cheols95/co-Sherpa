---
name: init
description: Initialize or update the ironman workflow harness in the current project. Use when the user invokes '/ironman:init', asks to install ironman into a repo, or wants to sync/update the workflow after a plugin update.
---

# init — install or sync ironman

Run the bundled `ironman-init` executable from the current project root.

```bash
ironman-init
```

If `ironman-init` is not on PATH, say that the plugin bin was not exposed by the host and ask the user
to reinstall or restart the host after installing the plugin. Do not hand-copy files.

`ironman-init` is both the first-time initializer and the update sync. It copies the harness assets
into the current working directory, installs/updates the machine-global daily skills for Claude and
Codex, regenerates Codex slash shims, and reports the next command:

- greenfield project: `/concept`
- existing codebase without ironman context: `/ironman:migration`
- existing ironman project: continue with `/concept`, `/freeze`, or `/build` as appropriate
