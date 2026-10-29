# 게시판, 위키 패키지

> 사내 게시판과 위키 솔루션을 Salesforce 2GP 관리형 패키지로 만들고, 패키지 환경과 Experience Cloud 포털에서만 생기는 문제들을 해결했습니다.

| 항목 | 내용 |
|---|---|
| 기간 | 위키 2026.01 – 02, 게시판 2026.04 – 09 |
| 역할 | 패키징, 패키지 환경 버그 수정, 첨부 업로더 개발, 다국어 처리, 권한 정리 |
| 형태 | 회사 프로젝트 (기존 솔루션을 패키지로 전환) |
| 기술 | 2GP Managed Package, LWC, Apex, Visualforce, Experience Cloud, Custom Label |

> 회사 프로젝트를 정리한 문서입니다. 회사 소스 코드는 포함하지 않습니다.

## 게시판

게시글, 댓글 · 답글, 좋아요, 북마크, 태그, 첨부파일, 리치텍스트 편집기, 통계

### 패키지 org에서만 실패하던 첨부 업로드
- 패키지로 설치하면 Visualforce 페이지 경로와 필드 API 이름에 네임스페이스가 붙어, 첨부 업로드가 세션 오류와 필드 오류로 실패했습니다.
- Apex로 현재 네임스페이스를 실행 시점에 확인해 경로와 필드 이름을 만들도록 바꿨습니다.

### 편집기에서 "/"를 누르면 검색창이 열리던 문제
- Salesforce 전역 단축키가 편집기 입력을 가로채고 있었습니다.
- 이벤트 캡처 단계에서 편집기 영역의 키 입력 전파를 막아 해결했습니다.

### 그 밖에
- 첨부파일 업로더 LWC 신규 개발
- 편집기 라벨 70개, 토스트, 접근성 라벨까지 Custom Label로 전환해 전체 한국어화
- 저장 전 확인 창, 댓글 · 답글 UI 개선, PRD 작성

## 위키

트리 구조 문서, Markdown 편집기 · 뷰어, Experience 포털(게스트 포함), 상태별 공개 범위

### 포털 게스트에게 이미지가 보이지 않던 문제
- 게스트 사용자는 일반 파일 URL에 접근할 수 없었습니다.
- 공개 배포 링크(ContentDistribution)의 다운로드 주소를 쓰도록 바꿔 해결했습니다.

### 그 밖에
- 2GP 패키징 준비와 오류 수정, 버전 관리
- 관리자 · 작성자 · 열람자 권한 세트 정리, 한국어 · 영어 번역
- 포털 적용 가이드 작성

## 예제 코드

패키지 환경에서 겪은 문제 세 가지의 해결 방식을 **독립적으로 다시 구현한 예제**입니다. 회사 코드가 아닙니다.

| 파일 | 해결하는 문제 |
|---|---|
| [`PackageNamespace.cls`](force-app/main/default/classes/PackageNamespace.cls) | 패키지 org 에서 필드 · 오브젝트 · Visualforce 경로에 붙는 네임스페이스. 클래스 자신의 이름에서 네임스페이스를 읽어 `Title__c` → `ns__Title__c`, `/apex/Page` → `/apex/ns__Page` 로 바꿔 준다. 표준 이름 · 이미 접두어가 있는 이름 · 관계 경로도 처리 |
| [`PublicImageService.cls`](force-app/main/default/classes/PublicImageService.cls) | 포털 게스트에게 이미지가 안 보이는 문제. 파일마다 공개 배포(ContentDistribution)를 만들고 다운로드 주소를 돌려준다. 이미 있으면 다시 쓴다 |
| [`slashSafeEditor`](force-app/main/default/lwc/slashSafeEditor) | 편집기에서 `/` 를 누르면 Salesforce 검색창이 열리는 문제. 편집 영역에서 생긴 키 입력만 캡처 단계에서 전파를 멈춘다 |
| `*_Test.cls` | 테스트 7개 — 패키지 / 비패키지, 관계 경로, 배포 재사용, 입력 검증 |

```apex
// 패키지 org 에서도, 스크래치 org 에서도 같은 코드로 동작
String field = PackageNamespace.qualify('Board__r.Title__c');   // acme__Board__r.acme__Title__c
String page = PackageNamespace.visualforcePath('FileUpload');    // /apex/acme__FileUpload
```

### 직접 실행

```bash
sf org create scratch -f config/project-scratch-def.json -a board-demo
sf project deploy start -o board-demo -d force-app --test-level RunLocalTests
```

스크래치 org 에서 테스트 7개 통과, 커버리지 96% (2026-10-30 확인).

## 배운 점

- 스크래치 org에서 잘 되던 기능도 **네임스페이스가 붙는 순간** 깨질 수 있어서, 패키지 설치 org 시험을 개발 과정에 넣어야 한다는 것
