# Python 템플릿 — LLM 에이전트용 프로젝트 스캐폴딩

[English README](./README.md)

> LLM 코딩 에이전트(Claude Code / Cursor)가 빈 디렉토리에서 시작해
> GitHub Actions CI green까지 도달하도록 설계된 Python 3.13 프로젝트 템플릿.
> 세팅 도중 사람 개입 없이 완주합니다.

**실측 검증 완료**: SETUP.md 하나로 Claude Code가 35분 만에 CI green 달성
([증거 run](https://github.com/KWONSEOK02/llm-setup-e2e17-python/actions/runs/24566234342)).

---

## 이 템플릿이 존재하는 이유

Python 프로젝트를 처음 세팅할 때마다 같은 결정을 반복하게 됩니다. 타입 체커(type checker)는 무엇을, 테스트 러너는 무엇을, import 경계 검사는 어떤 도구로, 포맷터(formatter)는 어느 것으로, src 레이아웃은 어떤 구조로. 이 템플릿은 각 항목마다 **근거 있는 선택지 하나**를 골라 고정하고, 에이전트가 바로 실행할 수 있는 SETUP.md로 묶습니다.

**고정된 선택지** (선택 이유 포함):

| 레이어 | 선택 | 이유 (기각한 대안) |
|---|---|---|
| 타입 체커 | basedpyright (strict, CI) + ty (IDE) | mypy는 느림; plain pyright는 strict 없이 너무 많이 통과시킴 |
| 린터 + 포맷터 | Ruff (E,F,I,UP,B,S,PERF,PD,NPY,RUF) | black + isort + flake8 = 도구 3개, 잘못 설정할 경우의 수 3배 |
| import 린터 | import-linter (include_external_packages) | `services/`가 `sqlalchemy`를 직접 import하는 사고 방지 |
| 런타임 / 패키지 관리 | uv (pip 아님) | lockfile, 재현성, 속도 |
| 레이아웃 | `src/my_project/` | in-tree 코드의 암묵적 import 방지 — 실제 버그 원인 |
| 아키타입 | FastAPI / Library-CLI / Data-science | 프로젝트 용도에 맞게 선택; 아래 참조 |

---

## 이런 분에게 맞습니다

**유형 1 — 새 Python 서비스를 시작하는 개인 개발자 또는 소규모 팀**
- 해결하는 문제: "버전은 뭘 고정하지? CI는 어떻게 구성하지? 아키텍처 경계는 어떻게 강제하지?"
- 해결하지 않는 문제: 도메인 모델링 결정, 인프라 선택 (DB, 메시지 브로커)

**유형 2 — LLM 보조 개발 (Claude Code, Cursor)**
- 해결하는 문제: 에이전트가 fail-fast SETUP.md, 재시도 예산, 검증 루프를 갖추게 되며 "어떤 포맷터를 쓰지?"라는 모호함이 사라짐
- 해결하지 않는 문제: 에이전트도 아키타입, 프로젝트 이름, 비즈니스 도메인은 사람이 정해줘야 함

**유형 3 — 엄격한 타입과 모듈 경계를 도입하려는 팀**
- 해결하는 문제: CI의 basedpyright strict + Import Linter 계약이 구체적인 실패 지점을 알려줌
- 해결하지 않는 문제: 리팩토링 자체; 이 템플릿은 목표 상태를 정의할 뿐 마이그레이션 경로는 제공하지 않음

**유형 4 — 재현 가능한 Python 수업 프로젝트를 세팅하는 강사 또는 학생**
- 해결하는 문제: 모든 학생이 동일한 툴링을 가져가며 "내 환경에서만 됨" 문제를 최소화
- 해결하지 않는 문제: 커리큘럼 설계나 과제 채점

---

## 이런 분에게는 추천하지 않습니다

- Python 3.10 이하를 지원해야 하는 경우 → 이 템플릿은 3.13을 요구합니다
- Poetry나 PDM을 선호하는 경우 → uv를 교체하면 SETUP의 약 40%를 건드려야 합니다
- Django같은 풀스택 MVC 프레임워크가 필요한 경우 → FastAPI / 라이브러리 / 데이터사이언스 아키타입 전용이며 Django는 대상 외입니다
- Windows 네이티브 빌드가 핵심인 경우 → CI와 Docker 경로는 Linux 러너를 기준으로 합니다

---

## 30초 자가 진단

세 가지 질문에 답해보세요:

1. **Python 버전이 3.13 이상인가요?** 아니오 → 이 템플릿은 건너뛰세요.
2. **basedpyright strict를 처음부터 사용할 의향이 있나요?** (익숙하지 않은 패턴에서 오류가 발생합니다. 익히는 비용이 있습니다.) 아니오 → 다른 템플릿을 사용하세요.
3. **uv를 유일한 패키지 관리자로 사용할 수 있나요?** (pip, conda와 혼용하지 않는 조건입니다.) 아니오 → 포크해서 uv를 교체하거나 다른 템플릿을 선택하세요.

세 개 모두 예 → [SETUP.md](./SETUP.md)를 읽고 시작하세요.

---

## 아키타입 선택

SETUP.md Phase 1에서 하나를 고릅니다:

| 프로젝트 성격 | 선택할 아키타입 | 이유 |
|---|---|---|
| DTO, 데이터베이스, 비즈니스 로직이 있는 HTTP API | **FastAPI Service** | routers/services/repositories + AppException 계층 + Loguru + ErrorResponse 스키마 포함 |
| 다른 프로젝트가 `pip install`할 패키지 (SDK, CLI 도구, 유틸 라이브러리) | **Library / CLI** | `__all__` public API + typer CLI 진입점 + `[project.scripts]` 포함 |
| numpy, pandas, scipy를 쓰는 과학/분석 작업 | **Data-science** | 스텁 미비 구간에서 basedpyright strict 완화; syrupy 대신 numpy.testing 사용 |

확신이 없다면 **Library / CLI**로 시작하세요. 가장 단순합니다. 아키타입은 나중에 마이그레이션할 수 있지만, 처음에 맞게 고르면 한 시간을 아낄 수 있습니다.

---

## 구성 파일 안내

- 세팅 흐름: [SETUP.md](./SETUP.md) — LLM 에이전트가 위에서 아래로 실행하는 문서 (14단계)
- AI 에이전트 규칙: [CLAUDE.md](./CLAUDE.md) — 기술 스택, 주요 명령어, 검증 체크리스트
- 아키텍처 경계: [.claude/rules/architecture.md](./.claude/rules/architecture.md) — src 레이아웃, import 방향, 예외 계층
- 검증 루프: [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md) — 6단계 fail-fast 시퀀스
- 테스트 수정 규칙: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md) — 테스트를 언제, 어떻게 수정하는가
- 문서화 모듈: [.claude/rules/documentation.md](./.claude/rules/documentation.md) — FR / RTM / ADR / RFC / 리포트

---

## 관련 템플릿

- [typescript-template](https://github.com/llm-setup-templates/typescript-template) — Next.js 15 + FSD 5계층
- [spring-template](https://github.com/llm-setup-templates/spring-template) — Spring Boot 3 + 레이어드 아키텍처

---

## 라이선스

MIT.
