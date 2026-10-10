# skills

tkhwang 의 개인 [agent skills](https://docs.claude.com/en/docs/claude-code/skills) 모음입니다. Claude Code, Codex 등 skill 을 지원하는 agent 에서 씁니다. 중심은 **tk workflow** 로, 하나의 변경을 의도에서 signoff 까지 agent 하나로 끌고 가는 문서 기반 단계 워크플로우입니다.

[English](README.md) | **한글**

<p align="center">
  <img src="./assets/readme/tk-workflow.ko.svg" width="100%" alt="tk workflow: intent, plan, implement, verify, signoff 다섯 단계가 왼쪽에서 오른쪽으로 진행되고, 단계 사이마다 사람이 승인한다. intent 는 영구 문서, tasks 는 작업 단위 문서, specs 는 현재 동작을 기술한다">
</p>

## 무엇인가

- **파일이 곧 상태.** 각 단계는 문서를 읽고 문서를 씁니다. 어디까지 왔는지는 대화 기억이 아니라 `docs/` 에서 유도하므로, 어떤 세션에서든 이어서 할 수 있습니다.
- **단계마다 사람의 승인.** 단계는 산출물을 저장하고 요약을 출력한 뒤 턴을 끝냅니다. 다음 단계는 명시적인 "다음"에만 시작합니다.
- **agent 는 commit 하지 않음.** git 은 읽기만 합니다. commit, push, branch 는 사람이 합니다.

## Skill 목록

| Skill | 단계 | 하는 일 |
|-------|------|---------|
| [`tk-setup`](tk-setup/) | repo 당 1회 | repo 를 탐색해 `docs/agents/tk-workflow.md` 를 씁니다: 레이아웃, 문서 경로, 모듈 코드, 검증 커맨드. |
| [`tk-workflow`](tk-workflow/) | 허브 | 파일에서 현재 단계를 유도하고 다음 skill 로 라우팅합니다. `다음` / `수정:` / `auto` 로 흐름을 몹니다. |
| [`tk-intent`](tk-intent/) | [0] | 사람이 intent 초안(`AGENT001-slug.md`)을 쓰면, 코드와 대조해 읽고 중요한 공백만 묻고, 요구사항에 `R1`, `R2`, … 번호를 붙입니다. |
| [`tk-plan`](tk-plan/) | [1] | intent 를 `docs/tasks/plan.md` + `todo.md` 로 바꿉니다. 세로 슬라이스, 슬라이스 안은 Backend → Frontend, R-id 커버리지 매트릭스, 미결 결정 0. |
| [`tk-implement`](tk-implement/) | [2] | `todo.md` 를 순서대로 구현합니다. Backend / Frontend 소단계마다 멈추고(`auto` 면 끝까지), 증거와 함께 체크합니다. |
| [`tk-verify`](tk-verify/) | [3] | repo 의 typecheck, lint(warning 도 실패), format 검사, 테스트, plan 의 동작 검증을 실행하고 결과를 R-id 별로 `plan.md` 에 기록합니다. |
| [`tk-signoff`](tk-signoff/) | [4] | 모든 R-id 를 plan, diff, 검증 결과로 추적합니다. Go / No-Go. Go 면 intent 에 Outcome 추가, 모듈 spec 갱신, `docs/tasks/` 비움. |
| [`tk-grill`](tk-grill/) | 보조 | 미결 결정을 추천안과 함께 한 번에 하나씩 묻고, 답을 문서에 반영합니다. `tk-intent` 와 `tk-plan` 이 사용합니다. |

## 변경 하나의 흐름

```text
/tk-setup                       repo 당 1회
(docs/intents/AGENT001-tenant-export.md 를 직접 작성)
/tk-intent AGENT001             인터뷰 → 요구사항 R1…Rn
다음                            → /tk-plan: 슬라이스, 결정, 커버리지
다음                            → /tk-implement: Slice 1 Backend … 멈춤
다음                            → Slice 1 Frontend … 멈춤 … (또는 `auto`)
다음                            → /tk-verify: tsc · eslint · prettier · tests
다음                            → /tk-signoff: Go → spec 갱신, tasks 비움
git commit                      사람이
```

세션에서 `/tk-workflow` 나 단계 커맨드를 한 번 실행한 뒤에는 `다음`, `수정: …`, `auto`, `상태`, `중단` 만으로 흐름이 이어집니다. "괜찮은 듯" 같은 애매한 답은 승인으로 치지 않고 다시 묻습니다.

## 문서

| 경로 | 수명 | 내용 |
|------|------|------|
| `docs/intents/<MODULE><NNN>-<slug>.md` | 영구, 변경당 1개 | 배경, 목표, 비목표, 성공 기준, `R` 번호 요구사항, 결정 로그, 결과(Outcome) |
| `docs/tasks/plan.md` | 현재 작업 동안만 | 결정, 범위, 슬라이스, 검증 계획, R-id 커버리지, 검증 결과 |
| `docs/tasks/todo.md` | 현재 작업 동안만 | `## Slice N` → `### Backend` / `### Frontend` → 증거가 붙은 체크박스 task |
| `docs/specs/<module>/` | 영구 | 각 모듈이 지금 어떻게 동작하는지, 시제 없는 문장으로 |
| `docs/agents/tk-workflow.md` | repo 당 | `tk-setup` 이 쓰는 설정 |

`plan.md` 와 `todo.md` 는 작업마다 덮어쓰고 signoff 때 비웁니다. 이력은 git 이 보관합니다. 이미 다른 문서 레이아웃을 쓰는 repo 는 `tk-setup` 으로 그 레이아웃을 그대로 씁니다.

## 설치

```bash
# 전체 skill, 사용자 레벨, 지원하는 모든 agent
npx skills add tkhwang/skills -g

# tk workflow 만
npx skills add tkhwang/skills -s tk-setup,tk-workflow,tk-intent,tk-grill,tk-plan,tk-implement,tk-verify,tk-signoff -g

# 이후 갱신
npx skills update
```

프로젝트에서는 `/tk-setup` 을 돌리고, 첫 intent 를 직접 쓴 뒤 `/tk-intent` 를 실행합니다.

`tk-grill` 은 단독으로 동작합니다. [`mattpocock/skills`](https://github.com/mattpocock/skills) 가 설치되어 있으면 그쪽 `grilling` 의 질문 순서 규율을 따릅니다.

## 단독 skill

| Skill | 설명 |
|-------|------|
| [`plan-decision-grill`](plan-decision-grill/) | 코딩 전에 plan, 설계, PRD 의 중요한 결정 게이트만 골라 점검합니다. 워크플로우 안에서는 `tk-grill` 이 같은 역할을 합니다. |

## 개발

이 repo 를 clone 하고 `npx skills add` 대신 [`link.sh`](link.sh) 를 실행하면 수정이 바로 git 작업 트리에 반영됩니다:

```bash
./link.sh                 # 모든 skill 연결
./link.sh tk-plan         # 하나만
```

`~/.agents/skills/<name>` → 이 repo, `~/.claude/skills/<name>`, `~/.codex/skills/<name>` → 그 허브로 심링크를 만듭니다. skill 폴더를 추가하면 다시 실행하면 되고, 여러 번 실행해도 안전합니다.

## 참고한 것

[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 에서 `tasks/plan.md` + `todo.md` 규약, 단계 게이트, clean-baseline 검사를, [mattpocock/skills](https://github.com/mattpocock/skills) 에서 design tree 인터뷰로서의 grilling, repo 별 `docs/agents/` 설정, agent 를 위한 문서 작성법을 가져왔습니다.
