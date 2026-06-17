# ironman

본 워크플로우 시스템은 Matt Pocock의 기획 워크플로우와 cc-system의 findings-cycles-goals 시스템을 조합한 시스템이다.

ironman은 한 프로젝트 안에서 `concept → freeze → build` 흐름을 반복하기 위한 Claude Code + Codex 워크플로우
하네스다. Phase 1에서 결정표면을 닫고 계약을 고정한 뒤, Phase 2에서 goal gate가 초록불이 될 때까지 구현한다.

## Install

Claude Code:

```bash
claude plugin marketplace add Cheols95/project_template_mpfcg
claude plugin install ironman@ironman
```

Codex:

```bash
codex plugin marketplace add Cheols95/project_template_mpfcg --ref main
codex plugin add ironman@ironman
```

Then run this from the project root:

```text
/ironman:init
```

`/ironman:init` installs or updates the local harness and syncs the daily global skills for both Claude and Codex.

## Commands

Lifecycle commands are plugin namespaced:

- `/ironman:init`
- `/ironman:help`
- `/ironman:migration`

Daily workflow commands stay short after init:

- `/concept`
- `/freeze`
- `/build`
- `/finding`
- `/cycle`
- `/handoff`
- `/roadmap`
- `/prototype`
- `/spec-sync`
- `/improve-codebase-architecture`

## Update

Claude Code:

```bash
claude plugin update ironman
```

Codex:

```bash
codex plugin marketplace upgrade ironman
codex plugin add ironman@ironman
```

After updating the plugin, start a fresh session and run:

```text
/ironman:init
```

That re-syncs the project harness and the machine-global daily skills.
