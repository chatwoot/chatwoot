# 3. OpenAI Agents SDK와 RPLS mock 도구 검증

검증일: 2026-07-13

## 사례 선정 근거

Google Sheet `[라포랩스-퀸잇] AI 응대 매뉴얼 (25년)`의 `응대 매뉴얼 전달본!A1:D833`에서 다음 행을 선정했다.

| 도구 분류 | 시트 행 | 문의 유형 | 실험 메시지 |
| --- | ---: | --- | --- |
| 없음 | 2 | 단순 문의 예시: 등록 배송지 변경 | `CASE_NO_TOOL: Can I change the saved delivery address?` |
| 읽기 | 39 | 배송 일정 및 현황 | `CASE_READ: When will my order be delivered?` |
| 읽기 + 쓰기 | 60 | 주문 취소 요청 | `CASE_WRITE: Please cancel the cancellable order you found for me.` |

세 사례의 문의와 답변 규칙은 `src/agent/prompt.ts`에 명시했다. 영문 `CASE_*` 문장은 브라우저 자동 입력을 안정적으로 재현하기 위한 실험 별칭이며 고객 답변은 한국어로 생성한다.

## RPLS API 계약

기준 문서: `https://api.rpls.work/generativelab-api/latest`

- 인증: 전달받은 API key를 base64 인코딩한 Basic 인증
- 주문 조회: `GET /generativelab/orders-by-phone`
  - query: `ordererPhoneNumber`, `pageNumber`, `pageSize`
  - response: `OrderForGenerativelabPageDto`
- 주문 취소: `PUT /generativelab/orders/lines/cancel-tickets`
  - body: `orderId`, `partials[{orderItemId, quantity}]`, `reason`, `isCustomerNegligence`

현재 구현은 외부 API를 호출하지 않는 mock이다. Widget Webhook의 `sender.phone_number`를 모델 입력 파라미터로 노출하지 않고 실행 컨텍스트에서 조회 도구에 주입한다. 취소 도구는 동일 실행에서 조회 도구가 먼저 성공해야 하고, mock 조회 결과의 취소 가능 주문만 처리한다.

API 명세의 주문 조회 응답에는 취소 요청에 필요한 `orderItemId`가 직접 보이지 않는다. mock에는 쓰기 계약 검증을 위해 이 값을 포함했으며, 실제 API 전환 전에 `orderLineId`와 `orderItemId`의 운영 데이터 매핑을 RPLS 담당자와 확인해야 한다.

## Agents SDK 구성

- package: `@openai/agents@0.13.2`
- model: `gpt-5.6-luna` (`OPENAI_MODEL`로 변경 가능)
- agent: `Agent<SupportAgentContext>`와 `run()` 사용
- tools: Zod 입력 스키마를 가진 `tool()` 두 개
- session: Chatwoot conversation ID별 Redis session, TTL 7일
- tracing: 테스트 고객정보가 외부 trace에 남지 않도록 비활성화
- max turns: 6

`OPENAI_API_KEY`가 없으면 기존 echo generator로 폴백하므로 Chatwoot 연결만 별도로 검증할 수 있다.

## 브라우저 검증 결과

### 도구 없는 사례

Widget 답변:

```text
네, 배송지는 변경할 수 있습니다. 기존 배송지 삭제는 지원되지 않으므로,
구매하기 > 배송지 변경 > 새로운 배송지 추가 경로에서 등록해 주세요.
```

로그에서 `agent_run_completed toolUsed=false`를 확인했고 `agent_tool_call`은 없었다.

### 읽기 도구 사례

Widget 답변에 mock의 다음 정보가 표시됐다.

```text
여성 진주 포인트 블랙 헤어핀
배송 준비 중
2026년 7월 15일 출고 예정
CJ대한통운 / 599200954313
```

로그:

```text
tool=get_orders_by_customer_phone mode=mock status=success customerPhonePresent=true
```

전화번호 원문은 로그에 남지 않았다.

### 읽기 및 쓰기 도구 사례

동일 Agent run에서 다음 순서가 확인됐다.

```text
tool=get_orders_by_customer_phone mode=mock status=success
tool=create_order_cancel_ticket mode=mock status=success
```

Widget 답변:

```text
여성 진주 포인트 블랙 헤어핀 1개에 대한 취소 접수가 완료되었습니다.
```

## open 대화와 재시작 검증

AgentBot 할당 후 Chatwoot이 대화 상태를 `pending`에서 `open`으로 변경하는 동작을 추가 검증에서 발견했다. 최초 구현은 `pending`만 허용해 다음 후속 메시지를 무시했다.

수정 후 규칙은 다음과 같다.

- 미할당 `pending`: 현재 AgentBot이 claim 후 응답
- 현재 AgentBot 할당 `pending` 또는 `open`: 계속 응답
- 미할당 `open`: claim하지 않음
- 사람 또는 다른 AgentBot 할당: 응답하지 않음
- resolved/snoozed 등 비활성 상태: 응답하지 않음

컨테이너를 재빌드·재시작한 뒤 이미 `open`이고 현재 AgentBot에 할당된 같은 대화에 후속 메시지를 보냈다. 로그의 `decision=reply reason=assigned_to_self`와 Widget 답변을 확인했다. 재시작 전 Redis에는 12개 session item이 있었고, 재시작 후에도 기존 이력을 사용해 응답했다.

최종 DB 상태:

```json
{
  "conversation_id": 1,
  "status": "open",
  "user_assignee_id": null,
  "agent_bot_assignee_id": 1,
  "assignee_type": "AgentBot",
  "incoming_messages": 10,
  "outgoing_messages": 6
}
```

## 자동 검증

```text
TypeScript typecheck: passed
Vitest: 4 files, 14 tests passed
TypeScript build: passed
Docker Compose config: passed
Docker image build: passed
Agent server /healthz: passed
```
