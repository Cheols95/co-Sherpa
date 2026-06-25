# co-Sherpa Release Verification Report

- generated_at: 2026-06-25T02:10:04Z
- branch: main
- commit: de72881f008bb051f96158d566cb20d1e9219a38
- plugin_id: cosherpa
- display_name: co-Sherpa
- harness_root: workflows-coSherpa/
- verdict: PASS

## Workspace Status Before Release

```text
clean
```

## Command Results

### quick regression profile

- command: `bash dev/release-verification/verify.sh quick`
- exit_code: `0`
- status: `PASS`

### rebuild release package dist

- command: `bash workflows-coSherpa/plugin/build/build.sh`
- exit_code: `0`
- status: `PASS`

### release package cleanliness audit

- command: `verify dist has no runtime/report/E2E/project artifacts`
- exit_code: `0`
- status: `PASS`

### release-check

- command: `bash workflows-coSherpa/plugin/build/release-check.sh`
- exit_code: `0`
- status: `PASS`

### post-release package cleanliness audit

- command: `verify dist remains clean after release-check`
- exit_code: `0`
- status: `PASS`

### plugin dist idempotence check

- command: `re-run build.sh and compare dist snapshot`
- exit_code: `0`
- status: `PASS`

### plugin dist tracked-clean check

- command: `git status --porcelain on workflows-coSherpa/plugin/dist after rebuilds`
- exit_code: `0`
- status: `PASS`

## Workspace Status After Release

```text
 M dev/release-verification/release-report.md
```

## Final Verdict

PASS
