---
name: roadmap
description: Generate and open the local roadmap dashboard for the co-Sherpa harness. Trigger on '/roadmap', 'roadmap', 'show roadmap', or dashboard inspection requests.
---

# Roadmap

Use this skill when the user asks for `/roadmap` or wants to inspect the local roadmap dashboard.
The project-local skill lives under `.agents/skills/roadmap` and `.claude/skills/roadmap`; it is not
installed under the machine-global `workflows-coSherpa/skills` daily-skill backup.

1. Run `bash workflows-coSherpa/dashboard/engines/roadmap.sh` in installed projects.
   In this template source repo, run `bash workflows-coSherpa/dashboard/engines/roadmap.sh`.
2. Open `workflows-coSherpa/dashboard/roadmap.html` in installed projects.
   In this template source repo, open `workflows-coSherpa/dashboard/roadmap.html`.
3. If the dashboard looks stale, run `bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh`
   in installed projects, or `bash workflows-coSherpa/dashboard/engines/roadmap-selftest.sh` in this template source repo,
   and report any failing group.
