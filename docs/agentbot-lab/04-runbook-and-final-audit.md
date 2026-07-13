# 4. 재현 Runbook과 최종 감사

검증일: 2026-07-13

## 0. 사전 조건

- Docker와 Docker Compose
- Node.js 24 이상 및 Corepack
- OpenAI API key
- host port `3300`, `3401` 사용 가능

저장소 루트에 Git에서 제외되는 secret 파일을 준비한다.

```bash
touch .env.agent.local
chmod 600 .env.agent.local
```

다음 한 줄만 먼저 입력한다. 값은 문서나 커밋에 기록하지 않는다.

```text
OPENAI_API_KEY=...
```

필요하면 `OPENAI_MODEL`도 지정할 수 있고, 기본값은 `gpt-5.6-luna`다.

## 1. 격리 환경 기동과 Chatwoot 초기화

저장소 루트에서 실행한다.

```bash
docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml \
  up -d --build

docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml \
  exec -T rails bundle exec rails runner \
  /opt/agentbot-lab/scripts/bootstrap-chatwoot.rb

docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml \
  up -d --force-recreate agent-server
```

bootstrap은 Account, Website Inbox, Widget token, AgentBot, access token, Webhook secret을 생성하고 `.env.agent.local`에 기록한다.

## 2. 서비스 확인

```bash
docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml ps

curl -fsS http://localhost:3401/healthz
```

기대 결과:

- Postgres와 Redis: healthy
- Rails, Sidekiq, agent-server: running
- health: `{"status":"ok"}`

접속 주소:

- Chatwoot: `http://localhost:3300`
- Widget demo: `http://localhost:3401`

## 3. 터미널 로그를 열어둔 브라우저 검증

별도 터미널에서 다음 로그를 관찰한다.

```bash
docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml \
  logs -f agent-server
```

Widget을 열고 아래 메시지를 순서대로 보낸다.

### Webhook과 고객 식별정보

```text
webhook-receive-test-001
```

기대 로그:

- `event=webhook_received`
- `messageType=incoming`
- `senderIdentifierPresent=true`
- `senderPhonePresent=true`
- 전화번호 원문은 없고 끝 4자리만 표시

### Agents SDK 도구 없는 사례

```text
CASE_NO_TOOL: Can I change the saved delivery address?
```

기대 결과:

- Widget에 새 배송지 추가 경로 안내
- `agent_run_completed toolUsed=false`
- 해당 run에 `agent_tool_call` 없음

### 읽기 도구 사례

```text
CASE_READ: When will my order be delivered?
```

기대 결과:

- Widget에 mock 상품, 배송 상태, 출고 예정일, 택배 정보 표시
- `tool=get_orders_by_customer_phone mode=mock status=success`

### 읽기 및 쓰기 도구 사례

```text
CASE_WRITE: Please cancel the cancellable order you found for me.
```

기대 결과:

- 조회 로그 다음에 취소 로그가 순서대로 표시
- `tool=create_order_cancel_ticket mode=mock status=success`
- Widget에 취소 접수 완료 표시

### 지속 응답과 소유권

- 같은 대화에서 메시지를 추가해 `decision=reply reason=assigned_to_self` 확인
- agent-server를 재시작한 뒤 다시 메시지를 보내도 응답하는지 확인
- 사람 상담원에게 할당한 뒤에는 `decision=ignore reason=assigned_to_user`이며 새 bot 메시지가 없어야 함

## 4. 자동 검증

```bash
cd agent-server
corepack pnpm typecheck
corepack pnpm test
corepack pnpm build

cd ..
docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml \
  config --quiet
```

최종 실행 결과:

```text
TypeScript typecheck: passed
Vitest: 4 files, 14 tests passed
TypeScript build: passed
Docker Compose config: passed
Docker image build: passed
Browser E2E: passed
```

## 5. 요청 단계별 완료표

| 요청 단계 | 완료 증거 |
| ---: | --- |
| 1 | 격리된 Compose project와 전용 volume으로 Chatwoot 4.15.1 초기화 |
| 2 | Website Inbox token을 사용한 Widget demo 페이지 |
| 3 | 서명 검증과 개인정보 마스킹을 포함한 Webhook 수신 서버 |
| 4 | Website Inbox에 활성 AgentBot 연결 |
| 5 | Widget 발신과 `webhook_received` 터미널 로그 |
| 6 | AgentBot token의 Create Message API 응답 |
| 7 | Widget에 API 응답 표시 |
| 8 | self-assignment, `open` 후속 메시지, Redis 대화 session |
| 9 | 재시작 후 같은 대화 브라우저 응답 |
| 10 | OpenAI Agents SDK, 시트 3개 사례, RPLS 계약 기반 mock 도구 |
| 11 | 무도구·읽기·읽기쓰기 Widget 및 도구 로그 검증 |

## 6. 커밋 발자취

시간순 커밋 제목:

1. `✨ feat(agent-server): AgentBot 검증 환경을 구축했습니다`
2. `📝 docs(agent-server): 초기화 검증 결과를 기록했습니다`
3. `✨ feat(agent-server): 대화 소유권 기반 응답을 구현했습니다`
4. `✨ feat(agent-server): Agents SDK 상담 도구를 구현했습니다`
5. `📝 docs(agent-server): 최종 검증 Runbook을 기록했습니다`

## 7. 운영 전환 전에 남은 항목

- 로컬 private network 허용을 제거하고 공개 HTTPS Webhook 사용
- RPLS API key를 secret manager에 저장하고 mock adapter를 실제 HTTP adapter로 교체
- RPLS 조회 응답의 `orderLineId`와 취소 요청의 `orderItemId` 매핑 확인
- 실제 쓰기 도구에 고객 재확인 또는 사람 승인 단계 추가
- Webhook 제한시간과 LLM 지연을 분리하기 위한 durable queue/worker 도입
- Redis session의 개인정보 보관 기간, 암호화, 삭제 정책 확정
- OpenAI trace 정책과 조직의 개인정보 처리 기준에 맞춘 재활성화 여부 결정
- rate limit, retry, dead-letter queue, 지표와 alert 구성

## 8. 종료와 완전 초기화

컨테이너만 중지:

```bash
docker compose \
  --project-name chatwoot-agentbot-lab \
  --env-file .env.agent.local \
  -f docker-compose.agentbot.yaml down
```

실험 데이터 volume까지 삭제하려면 명시적으로 `down -v`를 사용한다. 이 명령은 복구할 수 없으므로 필요한 검증 기록을 확인한 뒤 실행한다.
