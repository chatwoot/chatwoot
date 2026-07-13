# 1. 격리 환경 초기화 결과

검증일: 2026-07-13

## 구성

- Compose project: `chatwoot-agentbot-lab`
- Chatwoot image: `chatwoot/chatwoot:v4.15.1`
- Chatwoot URL: `http://localhost:3300`
- Widget demo URL: `http://localhost:3401`
- Agent server health: `http://localhost:3401/healthz`
- Postgres와 Redis는 host port를 노출하지 않는다.
- Chatwoot, Postgres, Redis storage는 project 전용 named volume을 사용한다.

호스트 `3400`은 현재 OrbStack 포워딩에서 연결이 reset되는 로컬 충돌이 있었다. 동일 이미지와 컨테이너 내부 통신은 정상임을 확인한 후 host port만 `3401`로 변경했다.

## 실행 명령

```bash
docker compose -f docker-compose.agentbot.yaml up -d --build
docker compose -f docker-compose.agentbot.yaml exec -T rails \
  bundle exec rails runner /opt/agentbot-lab/scripts/bootstrap-chatwoot.rb
docker compose -f docker-compose.agentbot.yaml up -d --force-recreate agent-server
```

## bootstrap 결과

민감한 token과 secret은 출력하거나 문서에 기록하지 않고 `.env.agent.local`에 mode `600`으로 저장했다.

```json
{
  "account_id": 1,
  "inbox_id": 1,
  "agent_bot_id": 1,
  "website_token_configured": true,
  "webhook_secret_configured": true
}
```

DB 상태 조회 결과:

```json
{
  "accounts": 1,
  "website_inboxes": 1,
  "active_agent_bot_inboxes": 1,
  "agent_bot_tokens": 1
}
```

## 통과한 검증

- `chatwoot-init` container exit code `0`
- Postgres와 Redis healthcheck 통과
- Rails `/app/login` 응답 `302`
- Agent server `/healthz` 응답 `{"status":"ok"}`
- Widget demo HTML에서 `demo-customer-001`과 `phone_number` 설정 확인
- `OPENAI_API_KEY`, Chatwoot bot token, Widget token, Webhook secret이 모두 비어 있지 않으며 Git에서 제외됨
