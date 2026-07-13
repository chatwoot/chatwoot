# 2. Webhook 응답과 대화 소유권 검증

검증일: 2026-07-13

## 구현

- AgentBot access token을 사용하는 Chatwoot client를 추가했다.
- 미할당 `pending` 대화는 Assignment API로 현재 AgentBot에 먼저 할당한다.
- 현재 AgentBot에 할당된 `pending` 대화의 후속 incoming 메시지는 재할당 없이 처리한다.
- 사람 상담원 또는 다른 AgentBot에 할당된 메시지는 답하지 않는다.
- outgoing, private, `message_created`가 아닌 이벤트는 답하지 않는다.
- Redis의 message key로 24시간 멱등성을 유지하고 conversation lock으로 같은 대화의 동시 처리를 직렬화한다.
- 처리 실패 시 message claim을 해제하고 HTTP 500을 반환하여 Chatwoot AgentBot retry를 사용할 수 있게 한다.

## Docker 내부 Webhook 진단

첫 브라우저 메시지는 Chatwoot DB에 저장됐지만 `SafeFetch`가 `agent-server`의 private IP를 차단했다.

```text
Invalid webhook URL http://agent-server:3400/webhooks/chatwoot:
Hostname 'agent-server' has no public ip addresses
```

격리된 local Compose에만 `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true`를 적용한 뒤 같은 내부 URL로 정상 전달됐다. 운영 배포에서는 이 옵션 대신 공개 HTTPS Webhook URL을 사용해야 한다.

## 브라우저 및 로그 검증

### Webhook 수신과 고객 식별정보

Widget 메시지 `webhook-receive-test-002` 전송 후:

```json
{
  "event": "webhook_received",
  "chatwootEvent": "message_created",
  "conversationId": 1,
  "messageId": 3,
  "messageType": "incoming",
  "private": false,
  "assigneeType": null,
  "senderIdentifierPresent": true,
  "senderPhonePresent": true,
  "senderPhoneLast4": "5678"
}
```

### 첫 API 응답과 self-assignment

Widget 메시지 `echo-test-001`에 대해 다음 순서가 확인됐다.

```text
decision=claim reason=unassigned conversationId=1 messageId=4
action=assign_agent_bot status=success conversationId=1
action=create_message status=success conversationId=1 outgoingMessageId=5
```

Widget에 표시된 답변:

```text
확인했습니다. 다음 메시지를 수신했습니다: echo-test-001
```

DB 상태:

```json
{
  "status": "pending",
  "assignee_type": "AgentBot",
  "assignee_id": 1
}
```

### 같은 대화의 후속 메시지

Widget 메시지 `echo-test-002`에 대해 재할당 없이 다음 로그와 답변이 확인됐다.

```text
decision=reply reason=assigned_to_self conversationId=1 messageId=6
action=create_message status=success conversationId=1 outgoingMessageId=7
```

```text
확인했습니다. 다음 메시지를 수신했습니다: echo-test-002
```

AgentBot이 만든 outgoing message의 Webhook은 `reason=not_incoming`으로 무시됐다.

### 사람 상담원 소유권 보호

대화를 `AgentBot Lab Admin` 사용자에게 할당한 뒤 `human-owner-test-001`을 전송했다.

```text
decision=ignore reason=assigned_to_user conversationId=1 messageId=8
```

- AgentBot assignment가 제거되고 `assignee_type=User`로 변경됨
- outgoing message count가 `2`에서 증가하지 않음
- Widget에도 새로운 bot 답변이 표시되지 않음

## 자동 검증

```text
TypeScript typecheck: passed
Vitest: 3 files, 10 tests passed
TypeScript build: passed
Docker agent-server build: passed
```
