---
name: roadmap
description: Generate and open the local roadmap dashboard for this template workflow. Trigger on '/roadmap', 'roadmap', 'show roadmap', or dashboard inspection requests.
---

# Roadmap

Use this skill when the user asks for `/roadmap` or wants to inspect the local
roadmap dashboard.

1. Run `bash dashboard/engines/roadmap.sh`.
2. Open `dashboard/roadmap.html` in the browser.
3. If the dashboard looks stale, run `bash dashboard/engines/roadmap-selftest.sh`
   and report any failing group.
