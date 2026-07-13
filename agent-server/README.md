# Chatwoot Agent Server

Chatwoot와 별도 프로세스 및 Docker 이미지로 실행되는 TypeScript AgentBot 서버입니다. Chatwoot core 코드를 수정하지 않고 AgentBot Webhook과 REST API만 사용합니다.

`OPENAI_API_KEY`가 있으면 OpenAI Agents SDK와 RPLS 계약 기반 mock 도구를 사용하고, 없으면 Webhook/API 연결 확인용 echo 응답으로 동작합니다. Agents SDK 대화 이력은 Chatwoot conversation ID별로 Redis에 7일간 저장합니다.

## 로컬 실행

저장소 루트의 `.env.agent.local`에 `OPENAI_API_KEY`를 설정한 뒤 실행합니다.

```bash
docker compose -f docker-compose.agentbot.yaml up -d --build
docker compose -f docker-compose.agentbot.yaml exec rails \
  bundle exec rails runner /opt/agentbot-lab/scripts/bootstrap-chatwoot.rb
docker compose -f docker-compose.agentbot.yaml up -d --force-recreate agent-server
```

- Chatwoot: <http://localhost:3300>
- Widget 데모: <http://localhost:3401>
- Agent server health: <http://localhost:3401/healthz>
- Webhook 로그: `docker compose -f docker-compose.agentbot.yaml logs -f agent-server`

`bootstrap-chatwoot.rb`는 Account, 관리자, Website Inbox, Widget token, AgentBot 및 access token을 로컬 DB에 생성하고 민감한 값은 Git에서 제외된 `.env.agent.local`에 기록합니다.

## 검증 메시지

Widget에서 아래 메시지를 순서대로 보내면 도구 없는 답변, 주문 조회, 주문 조회 후 취소 mock을 검증할 수 있습니다.

```text
CASE_NO_TOOL: Can I change the saved delivery address?
CASE_READ: When will my order be delivered?
CASE_WRITE: Please cancel the cancellable order you found for me.
```

실행 기록과 기대 로그는 `docs/agentbot-lab/`에 단계별로 정리되어 있습니다.
