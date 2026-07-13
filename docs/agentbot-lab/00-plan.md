# Chatwoot AgentBot 독립 서버 진행 기록

## 목표

Chatwoot core와 분리된 TypeScript 서버가 Website Widget의 메시지를 AgentBot Webhook으로 받고, Chatwoot REST API로 답변하며, 이후 OpenAI Agents SDK와 mock 도구를 사용하도록 발전시키고 브라우저에서 검증한다.

## 완료 조건

| 단계 | 산출물 | 검증 증거 |
| --- | --- | --- |
| 1–4 | 격리된 Compose, Website Inbox, Widget, Webhook 수신 서버, AgentBot | 컨테이너 상태, bootstrap 결과, 구조화 로그 |
| 5 | Widget 첫 메시지 수신 | 브라우저 메시지와 `webhook_received` 로그 |
| 6–7 | Create Message API 응답 | API 성공 로그와 Widget 답변 |
| 8–9 | 후속 메시지 지속 응답 및 상담원 소유권 보호 | self-assignment, 후속 답변, 사람 할당 시 ignore 로그 |
| 10–11 | Agents SDK와 사례별 mock 도구 | 무도구·읽기·읽기쓰기 각 시나리오의 도구 호출 로그와 Widget 답변 |

## 설계 결정

- `agent-server/`는 자체 `package.json`, lockfile, Dockerfile을 가진 독립 애플리케이션이다.
- Chatwoot에는 변경을 넣지 않고 AgentBot Webhook과 `/api/v1/accounts/...` API만 사용한다.
- Compose project 이름과 volume을 `chatwoot-agentbot-lab`로 격리하여 기존 Chatwoot 데이터에 영향을 주지 않는다.
- Webhook HTTP 응답 본문으로 고객에게 답하지 않는다. AgentBot access token으로 Create Message API를 호출한다.
- 수신 시 Chatwoot HMAC 서명을 검증하고, 전화번호는 존재 여부와 끝 4자리만 로그에 남긴다.
- 초기 대화는 AgentBot이 먼저 자신에게 할당하고, 이후에는 자신에게 할당된 대화만 처리한다.
- `message.id` 멱등성과 `conversation.id` 단위 직렬화로 재전송 및 동시 응답을 막는다.
- 운영 전환 전까지 RPLS 읽기/쓰기 도구는 mock 데이터만 사용한다.

## 커밋 계획

1. 수신 서버·Compose·Widget 데모·계획 문서
2. Chatwoot API 응답·self-assignment·멱등성 및 연속 대화
3. OpenAI Agents SDK·선정 사례·mock 도구
4. 브라우저 E2E 증거와 최종 실행 문서
