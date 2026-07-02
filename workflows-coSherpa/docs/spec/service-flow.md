---
spec: service-flow
---
# service-flow.md — 서비스 흐름 (IT 지원 에이전트 BPMN 데모)

대시보드 「서비스 흐름」 탭이 이 문서를 파싱한다. 표 형식의 권위는
`workflows-coSherpa/dashboard/engines/roadmap.sh`의 서비스 파서 주석이다.

- `Components`의 `group` 칸 예약어: `gateway` = 분기 마름모(◇), `event` = 시작·종료 원(◯).
  둘 다 배포 그룹에 속하지 않는 논리 노드다.
- `## Flow`가 있으면 화살표의 원천(방향 `from→to`, `label`은 화살표 위 조건, `kind`=`normal|conditional`).
  없으면 `Components`의 `depends_on`으로 폴백한다.
- `col/row`는 정수 격자 좌표. 분기가 갈라지는 만큼 행을 벌려 배치한다.

## Components
| id | name | group | col | row | depends_on | phase | desc |
| --- | --- | --- | --- | --- | --- | --- | --- |
| start | 요청 수신 | event | 0 | 3 | — | — | 사용자 문의 유입(시작 이벤트) |
| agent | IT Support Agent | — | 1 | 3 | — | 1 | 1차 응대 에이전트 |
| gw_intent | 의도 판단 | gateway | 2 | 3 | — | — | 문의 유형에 따른 분기 |
| onb1 | EmployeeOnboarding_Agent 호출 | — | 3 | 0 | — | 1 | 온보딩 처리 에이전트 |
| onb2 | Slack 온보딩 알림 받음 | — | 4 | 0 | — | 1 | 담당자 온보딩 알림 |
| gw_crit | CRITICAL 여부 판단 | gateway | 3 | 2 | — | — | 심각도 분기 |
| crit1 | Slack CRITICAL 알림·Jira 자동 생성 | — | 4 | 1 | — | 1 | 긴급 티켓 자동 발행 |
| crit2 | Slack 티켓 번호 안내 받음 | — | 5 | 1 | — | 1 | 티켓 번호 회신 |
| gen1 | 비밀번호 초기화·Slack 안내 받음 | — | 4 | 2 | — | 1 | 일반 처리 안내 |
| gen2 | PasswordReset_RPA 호출 | — | 5 | 2 | — | 1 | 비밀번호 초기화 RPA |
| gen3 | Slack 비밀번호 초기화 완료 알림 | — | 6 | 2 | — | 1 | 완료 통보 |
| kb | KB 검색 / Web Search | — | 3 | 4 | — | 1 | 지식베이스·웹 조회 |
| gw_res | 해결 여부 | gateway | 4 | 4 | — | — | 자동 해결 여부 분기 |
| res1 | Slack 해결 안내 받음 | — | 5 | 4 | — | 1 | 해결 안내 회신 |
| nr1 | Slack Action Center 알림 받음 | — | 5 | 5 | — | 1 | 상담 채널 알림 |
| nr2 | Escalation_ITSupport 호출 | — | 6 | 5 | — | 1 | 상위 담당 이관 |
| gw_appr | 승인 여부 | gateway | 7 | 5 | — | — | 상위 승인 분기 |
| appr1 | Jira 티켓 생성·Slack 티켓 알림 | — | 8 | 5 | — | 1 | 정식 티켓 발행 |
| appr2 | Jira 티켓 생성 완료 알림 | — | 9 | 5 | — | 1 | 완료 통보 |
| end | 완료 | event | 10 | 3 | — | — | 처리 종료(종료 이벤트) |

## Flow
| from | to | label | kind |
| --- | --- | --- | --- |
| start | agent | — | normal |
| agent | gw_intent | — | normal |
| gw_intent | onb1 | Onboarding | conditional |
| gw_intent | gw_crit | Password | conditional |
| gw_intent | kb | IT-Issue | conditional |
| onb1 | onb2 | — | normal |
| onb2 | end | — | normal |
| gw_crit | crit1 | Critical | conditional |
| gw_crit | gen1 | General | conditional |
| crit1 | crit2 | — | normal |
| crit2 | end | — | normal |
| gen1 | gen2 | — | normal |
| gen2 | gen3 | — | normal |
| gen3 | end | — | normal |
| kb | gw_res | — | normal |
| gw_res | res1 | Resolved | conditional |
| gw_res | nr1 | NotResolved | conditional |
| res1 | end | — | normal |
| nr1 | nr2 | — | normal |
| nr2 | gw_appr | — | normal |
| gw_appr | appr1 | Approve | conditional |
| gw_appr | end | Reject | conditional |
| appr1 | appr2 | — | normal |
| appr2 | end | — | normal |

## Use-cases
| uc | name | trigger | step | component | action | kind |
| --- | --- | --- | --- | --- | --- | --- |
| pwd | 비밀번호 재설정 | 비밀번호 문의 | 1 | agent | 의도 파악 | main |
| pwd | 비밀번호 재설정 | — | 2 | gw_intent | Password 분기 | main |
| pwd | 비밀번호 재설정 | — | 3 | gw_crit | General 판단 | main |
| pwd | 비밀번호 재설정 | — | 4 | gen1 | 초기화 안내 | main |
| pwd | 비밀번호 재설정 | — | 5 | gen2 | RPA 실행 | main |
| pwd | 비밀번호 재설정 | 심각 이슈 | 3 | crit1 | 긴급 티켓 발행 | edge |
| esc | 장애 에스컬레이션 | 장애 문의 | 1 | agent | 의도 파악 | main |
| esc | 장애 에스컬레이션 | — | 2 | gw_intent | IT-Issue 분기 | main |
| esc | 장애 에스컬레이션 | — | 3 | kb | KB 검색 | main |
| esc | 장애 에스컬레이션 | — | 4 | gw_res | 미해결 분기 | main |
| esc | 장애 에스컬레이션 | — | 5 | nr1 | 상담 알림 | main |
| esc | 장애 에스컬레이션 | — | 6 | nr2 | 상위 이관 | main |
| esc | 장애 에스컬레이션 | — | 7 | gw_appr | 승인 요청 | main |
