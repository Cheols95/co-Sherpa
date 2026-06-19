# Dashboard

This directory contains the generated roadmap dashboard and the engines that
build and test it.

Run:

```bash
bash workflows-coSherpa/dashboard/engines/roadmap.sh
```

The command writes `workflows-coSherpa/dashboard/roadmap.html`. The file is generated output and is
ignored by git. The generator reads issue markdown, the active goal pointer, and
goal contracts from the current worktree, then emits a self-contained HTML file.

Before using the dashboard as a coordination aid, run:

```bash
bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh
bash workflows-coSherpa/scripts/completion-check.sh
```

That keeps the dashboard aligned with the FCG goal chain and avoids treating a
dirty worktree or a stale generated file as proof of completion.
