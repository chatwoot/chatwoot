# Chatwoot Agent Server

Chatwoot와 별도 프로세스 및 Docker 이미지로 실행되는 TypeScript AgentBot 서버입니다. Chatwoot core 코드를 수정하지 않고 AgentBot Webhook과 REST API만 사용합니다.

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
