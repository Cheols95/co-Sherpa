---
name: init
description: Initialize or update the co-Sherpa workflow harness in the current project. Use when the user invokes '/cosherpa:init', asks to install co-Sherpa into a repo, or wants to sync/update the workflow after a plugin update.
disable-model-invocation: true
allowed-tools: Bash
---

# init — install or sync co-Sherpa

Run the bundled `cosherpa-init` executable from the current project root.

```bash
cosherpa-init
```

If `cosherpa-init` is not on PATH, say that the plugin bin was not exposed by the host and ask the user
to reinstall or restart the host after installing the plugin. Do not hand-copy files.

`cosherpa-init` is both the first-time initializer and the update sync. It copies the harness assets
into the current working directory, installs/updates the machine-global daily skills for Claude and
Codex, regenerates Codex slash shims, and reports the next command:

- greenfield project: `/concept`
- existing codebase without co-Sherpa context: `/cosherpa:migration`
- existing co-Sherpa project: continue with `/concept`, `/freeze`, or `/build` as appropriate
