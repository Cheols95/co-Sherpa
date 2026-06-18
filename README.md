# co-Sherpa

본 워크플로우 시스템은 Matt Pocock의 기획 워크플로우와 cc-system의 findings-cycles-goals 시스템을 조합한 시스템이다.

co-Sherpa는 한 프로젝트 안에서 `concept → freeze → build` 흐름을 반복하기 위한 Claude Code + Codex 워크플로우
하네스다. `cosherpa`는 플러그인 id이며, Phase 1에서 결정표면을 닫고 계약을 고정한 뒤 Phase 2에서
goal gate가 초록불이 될 때까지 구현한다.

## Runtime support

co-Sherpa targets the same command surface on macOS, Windows, and WSL:

- macOS: system Bash 3.2+ is supported; GNU-only calls have portable fallbacks.
- Windows: run through Git Bash or WSL, not PowerShell/CMD-native shell execution.
- WSL/Linux: run with the distro Bash and core Unix tools.

Required tools: `bash`, `git`, `find`, `awk`, `sed`, `grep`, `sort`, `cp`, `mkdir`, and either
`shasum` or `sha256sum`. Optional tools such as GNU `sort -V` and `timeout` are used when present
but are not required.

## Install

Claude Code:

```bash
claude plugin marketplace add Cheols95/co-Sherpa
claude plugin install cosherpa@cosherpa
```

Then open a fresh Claude Code session from the project root and run:

```text
/cosherpa:init
```

Codex:

```bash
codex plugin marketplace add Cheols95/co-Sherpa --ref main
codex plugin add cosherpa@cosherpa
```

Then open a fresh Codex session from the project root and ask:

```text
Use cosherpa init to install the workflow here.
```

If your Codex host exposes plugin skill selection, choose `cosherpa:init`. After init, Codex also gets daily slash-command shims such as `/concept`, `/freeze`, and `/build`.

`cosherpa init` installs or updates the local harness and syncs the daily global skills for both Claude and Codex.

## Commands

Lifecycle commands are plugin namespaced:

- `/cosherpa:init`
- `/cosherpa:help`
- `/cosherpa:migration`

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
claude plugin update cosherpa
```

Codex:

```bash
codex plugin marketplace upgrade cosherpa
codex plugin add cosherpa@cosherpa
```

After updating the plugin, start a fresh session and run the platform-specific init surface again:

- Claude Code: `/cosherpa:init`
- Codex: `Use cosherpa init to install the workflow here.`

That re-syncs the project harness and the machine-global daily skills.

## License

MIT. See [LICENSE](LICENSE).
