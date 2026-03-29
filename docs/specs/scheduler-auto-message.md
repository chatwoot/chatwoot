# Scheduler (예약 자동 메시지) 기능 스펙

## Context

zarada-chat에서 zarada-crm의 예약 데이터를 기반으로 WhatsApp 자동 메시지를 발송하는 기능이 필요하다.
기존 Campaign 기능과 유사한 UX를 제공하되, 오픈소스 라이센스 분쟁을 피하기 위해 DB 엔티티, 코드, UI를 모두 새로 작성한다.
Campaign의 스케줄링 인프라(TriggerScheduledItemsJob, WhatsApp 템플릿 발송 파이프라인)는 그대로 활용한다.

---

## 1. 기능 요약

| 메시지 타입 | 설명 | 발송 시점 |
|---|---|---|
| D-1 리마인드 | 예약 전날 알림 | CRM에서 지정 |
| 방문 안내 | 위치/준비사항 안내 | CRM에서 지정 |
| 해피콜 (당일) | 시술 후 만족도/케어 안내 | CRM에서 지정 |
| 해피콜 (2주) | 경과 확인 및 재방문 유도 | CRM에서 지정 |

- 발송 시점(scheduled_at)은 CRM이 결정하여 전달
- 메시지 타입은 확장 가능 (위 4개가 초기 지원 타입)

---

## 2. 아키텍처 개요

```
zarada-crm ──(API/Mock)──> Scheduler Sync Job
                                │
                                ▼
                      ┌─────────────────────┐
                      │  scheduled_messages  │  (새 DB 테이블)
                      │  schedulers          │  (새 DB 테이블)
                      └─────────────────────┘
                                │
          TriggerScheduledItemsJob (5분 주기)
                                │
                                ▼
                   Dispatch Job (발송 대상 조회)
                                │
                                ▼
              Whatsapp::TemplateProcessorService (기존)
                                │
                                ▼
              Channel::Whatsapp#send_template (기존)
```

---

## 3. DB 스키마

### 3.1 `schedulers` 테이블 (스케줄러 설정)

Campaign과 유사한 역할. 어떤 inbox로, 어떤 템플릿으로, 어떤 타입의 메시지를 보낼지 정의.

```ruby
create_table :schedulers do |t|
  t.bigint   :account_id,    null: false
  t.bigint   :inbox_id,      null: false       # WhatsApp inbox
  t.string   :title,         null: false       # "D-1 리마인드", "방문 안내" 등
  t.string   :message_type,  null: false       # d1_reminder, visit_guidance, happy_call_same_day, happy_call_2weeks
  t.text     :description
  t.integer  :status,        default: 0        # enum: active(0), paused(1)
  t.jsonb    :template_params, default: {}     # WhatsApp 템플릿 설정
  t.integer  :display_id                       # account별 순번
  t.timestamps
end

add_index :schedulers, [:account_id, :message_type], unique: true
add_index :schedulers, :inbox_id
add_index :schedulers, :display_id
```

### 3.2 `scheduled_messages` 테이블 (개별 발송 건)

각 예약에 대해 CRM이 만들어주는 발송 예정 메시지.

```ruby
create_table :scheduled_messages do |t|
  t.bigint   :account_id,        null: false
  t.bigint   :scheduler_id,      null: false   # FK -> schedulers
  t.bigint   :contact_id                       # FK -> contacts (phone 매칭 후)
  t.string   :external_id,       null: false   # CRM 예약 ID
  t.string   :customer_phone,    null: false   # E.164 형식
  t.string   :customer_name
  t.string   :message_type,      null: false   # d1_reminder 등
  t.datetime :scheduled_at,      null: false   # 발송 예정 시각 (CRM이 결정)
  t.string   :status,            default: 'pending'  # pending, sent, failed, skipped, cancelled
  t.datetime :sent_at
  t.string   :whatsapp_message_id              # Meta API 응답 ID
  t.string   :error_message
  t.jsonb    :template_params,   default: {}   # 이 건에 대한 템플릿 파라미터 (고객명, 날짜 등)
  t.jsonb    :metadata,          default: {}   # CRM 추가 데이터 (시술 종류, 위치 등)
  t.timestamps
end

add_index :scheduled_messages, [:external_id, :message_type], unique: true,
          name: 'idx_scheduled_messages_unique'
add_index :scheduled_messages, [:account_id, :status, :scheduled_at],
          name: 'idx_scheduled_messages_dispatch'
add_index :scheduled_messages, :scheduler_id
add_index :scheduled_messages, :contact_id
```

**핵심 설계:**
- `[external_id, message_type]` unique index -> 같은 예약에 같은 타입 메시지 중복 발송 방지
- `status + scheduled_at` composite index -> 발송 대상 빠른 조회
- `contact_id` nullable -> phone 매칭 실패해도 레코드 생성 가능

---

## 4. 백엔드 파일 구조

```
app/
  models/
    scheduler.rb
    scheduled_message.rb

  controllers/api/v1/accounts/
    schedulers_controller.rb

  services/
    schedulers/
      sync_service.rb                    # CRM -> DB 동기화 (현재는 mock)
      dispatch_service.rb                # pending 메시지 발송
      message_builder_service.rb         # 템플릿 파라미터 조립

  jobs/
    schedulers/
      sync_scheduled_messages_job.rb     # CRM 동기화 job
      dispatch_scheduled_messages_job.rb # 발송 job

  policies/
    scheduler_policy.rb

  views/api/v1/accounts/schedulers/
    index.json.jbuilder
    show.json.jbuilder
    create.json.jbuilder
    update.json.jbuilder
  views/api/v1/models/
    _scheduler.json.jbuilder

config/
  features.yml                          # + scheduler feature flag

db/migrate/
  YYYYMMDD_create_schedulers.rb
  YYYYMMDD_create_scheduled_messages.rb
```

---

## 5. 프론트엔드 파일 구조

```
app/javascript/dashboard/
  routes/dashboard/schedulers/
    schedulers.routes.js
    pages/
      SchedulersPageRouteView.vue       # 루트 페이지
      SchedulersPage.vue                # 스케줄러 목록 + 생성

  components-next/Schedulers/
    SchedulerLayout.vue                 # 헤더 + "New Scheduler" 버튼
    SchedulerCard/
      SchedulerCard.vue                 # 개별 스케줄러 카드
      SchedulerStats.vue                # 발송 통계 (sent/pending/failed)
    Pages/SchedulerPage/
      SchedulerList.vue                 # 카드 목록
      SchedulerDialog.vue               # 생성 다이얼로그
      SchedulerForm.vue                 # 생성 폼
      SchedulerDetailDialog.vue         # 상세 (발송 내역 리스트)
      ConfirmDeleteSchedulerDialog.vue
    EmptyState/
      SchedulerEmptyState.vue

  store/modules/
    schedulers.js                       # Vuex store

  api/
    schedulers.js                       # API client
```

---

## 6. API 설계

### 6.1 Schedulers CRUD

| Method | Path | 설명 |
|---|---|---|
| GET | `/api/v1/accounts/:id/schedulers` | 스케줄러 목록 |
| POST | `/api/v1/accounts/:id/schedulers` | 스케줄러 생성 |
| GET | `/api/v1/accounts/:id/schedulers/:id` | 스케줄러 상세 (+ 발송 내역) |
| PATCH | `/api/v1/accounts/:id/schedulers/:id` | 스케줄러 수정 |
| DELETE | `/api/v1/accounts/:id/schedulers/:id` | 스케줄러 삭제 |

### 6.2 Scheduler 생성 파라미터

```json
{
  "scheduler": {
    "title": "D-1 예약 리마인드",
    "message_type": "d1_reminder",
    "inbox_id": 42,
    "description": "예약 전날 오전에 리마인드 메시지를 발송합니다",
    "template_params": {
      "name": "appointment_reminder_d1",
      "namespace": "...",
      "language": "ko",
      "processed_params": {
        "body": { "1": "{{customer_name}}", "2": "{{appointment_date}}" }
      }
    }
  }
}
```

### 6.3 CRM Webhook/Sync API (Phase 2)

CRM이 발송 건을 푸시하는 엔드포인트 (mock 단계에서는 sync job이 대체):

```
POST /api/v1/accounts/:id/schedulers/messages
{
  "messages": [
    {
      "external_id": "reservation-001",
      "message_type": "d1_reminder",
      "customer_phone": "+821012345678",
      "customer_name": "홍길동",
      "scheduled_at": "2026-03-30T09:00:00+09:00",
      "metadata": {
        "appointment_type": "피부 레이저",
        "location": "강남점 3층",
        "doctor": "김원장"
      }
    }
  ]
}
```

---

## 7. 핵심 서비스 로직

### 7.1 Sync Service (`Schedulers::SyncService`)

```
1. CRM에서 예약 기반 발송 대상 수신 (현재는 mock data)
2. 각 건에 대해 ScheduledMessage upsert (external_id + message_type unique)
3. customer_phone으로 Contact 매칭 -> contact_id 설정
4. 해당 message_type의 Scheduler가 active인지 확인 -> 아니면 skip
```

### 7.2 Dispatch Service (`Schedulers::DispatchService`)

```
1. ScheduledMessage.where(status: 'pending', scheduled_at <= now) 조회
2. 각 건에 대해:
   a. contact 존재 확인 (없으면 skip)
   b. scheduler의 template_params + message의 metadata 합쳐서 최종 파라미터 생성
   c. Whatsapp::TemplateProcessorService로 템플릿 처리
   d. channel.send_template() 호출
   e. 성공 -> status: 'sent', sent_at 기록
   f. 실패 -> status: 'failed', error_message 기록
3. 개별 건 실패가 다른 건에 영향 없음 (rescue per message)
```

### 7.3 Message Builder Service (`Schedulers::MessageBuilderService`)

```
1. Scheduler의 template_params (기본 템플릿 설정) 로드
2. ScheduledMessage의 metadata에서 동적 값 추출
3. 플레이스홀더 치환:
   {{customer_name}} -> scheduled_message.customer_name
   {{appointment_date}} -> scheduled_message.metadata['appointment_date']
   {{location}} -> scheduled_message.metadata['location']
   등
4. 최종 template_params 반환
```

---

## 8. Job 스케줄링

### TriggerScheduledItemsJob 확장

`app/jobs/trigger_scheduled_items_job.rb`의 `perform` 메서드에 추가:

```ruby
# 기존 코드 끝에 추가
Schedulers::SyncScheduledMessagesJob.perform_later
Schedulers::DispatchScheduledMessagesJob.perform_later
```

-> 5분 주기로 동기화 + 발송 실행

---

## 9. 프론트엔드 UI 설계

### 9.1 사이드바

Campaign 아래에 별도 메뉴로 "Scheduler" 추가:

```javascript
{
  name: 'Scheduler',
  label: t('SIDEBAR.SCHEDULER'),
  icon: 'i-lucide-calendar-clock',
  to: accountScopedRoute('schedulers_index'),
}
```

### 9.2 스케줄러 목록 페이지

- 카드 형태로 스케줄러 표시 (Campaign 카드와 유사하지만 다른 디자인)
- 각 카드에 표시: title, message_type 뱃지, inbox, 상태(active/paused), 발송 통계
- "New Scheduler" 버튼으로 생성 다이얼로그 오픈

### 9.3 스케줄러 생성 폼

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| Title | text input | O | 스케줄러 이름 |
| Message Type | select | O | d1_reminder, visit_guidance, happy_call_same_day, happy_call_2weeks |
| Inbox | select | O | WhatsApp inbox만 필터 |
| Template | select | O | 선택한 inbox의 승인된 템플릿 목록 |
| Description | textarea | X | 설명 |

### 9.4 스케줄러 상세 (발송 내역)

- 해당 스케줄러의 ScheduledMessage 목록 표시
- 필터: status (pending/sent/failed/skipped)
- 각 행: 고객명, 전화번호, 예정시각, 발송시각, 상태

---

## 10. Mock 데이터 전략

CRM API가 준비될 때까지 `Schedulers::SyncService`에서 mock 데이터 사용:

```ruby
class Schedulers::SyncService
  def perform
    return sync_from_crm if crm_configured?
    sync_from_mock if Rails.env.development?
  end

  private

  def sync_from_mock
    # seed 데이터 또는 faker로 mock 예약 생성
    mock_messages = generate_mock_appointments
    process_messages(mock_messages)
  end

  def sync_from_crm
    # Phase 2: 실제 CRM API 호출
    client = Crm::Zarada::Api::AppointmentClient.new(...)
    messages = client.fetch_scheduled_messages(...)
    process_messages(messages)
  end
end
```

---

## 11. Feature Flag

`config/features.yml`에 추가:

```yaml
- name: scheduler
  display_name: Scheduler
  enabled: false
```

---

## 12. 기존 코드 재사용 목록

| 기존 코드 | 용도 | 파일 경로 |
|---|---|---|
| `Whatsapp::TemplateProcessorService` | 템플릿 파라미터 -> API 포맷 변환 | `app/services/whatsapp/template_processor_service.rb` |
| `Channel::Whatsapp#send_template` | WhatsApp 템플릿 메시지 발송 | `app/models/channel/whatsapp.rb` |
| `WhatsappCloudService#send_template` | Meta Graph API 호출 | `app/services/whatsapp/providers/whatsapp_cloud_service.rb` |
| `TriggerScheduledItemsJob` | 5분 주기 스케줄러 진입점 | `app/jobs/trigger_scheduled_items_job.rb` |
| `CampaignPolicy` 패턴 | 인가 정책 참조 | `app/policies/campaign_policy.rb` |
| `WhatsAppCampaignForm.vue` 패턴 | 템플릿 선택 UI 참조 | `components-next/Campaigns/.../WhatsAppCampaignForm.vue` |
| Sidebar 구조 | 메뉴 추가 패턴 | `components-next/sidebar/Sidebar.vue` |
| Vuex store 패턴 | 상태 관리 참조 | `store/modules/campaigns.js` |

---

## 13. 구현 단계

### Phase 1: Backend Foundation
1. DB 마이그레이션 (schedulers, scheduled_messages)
2. Model 생성 (Scheduler, ScheduledMessage)
3. Feature flag 추가
4. Controller + Routes + Policy
5. Jbuilder views

### Phase 2: Services & Jobs
1. `Schedulers::MessageBuilderService`
2. `Schedulers::DispatchService`
3. `Schedulers::SyncService` (mock 모드)
4. Jobs 생성 및 TriggerScheduledItemsJob 연결

### Phase 3: Frontend
1. API client + Vuex store
2. Routes 정의
3. Sidebar 메뉴 추가
4. SchedulersPage (목록)
5. SchedulerForm (생성/수정)
6. SchedulerCard (카드 컴포넌트)
7. SchedulerDetailDialog (발송 내역)

### Phase 4: CRM Integration
1. `Crm::Zarada::Api::BaseClient`
2. `Crm::Zarada::Api::AppointmentClient`
3. SyncService에 실제 CRM 연동

---

## 14. 검증 방법

1. **Unit**: `bundle exec rspec spec/models/scheduler_spec.rb`, `spec/models/scheduled_message_spec.rb`
2. **Service**: `spec/services/schedulers/dispatch_service_spec.rb`
3. **API**: `spec/controllers/api/v1/accounts/schedulers_controller_spec.rb`
4. **E2E**: 개발 환경에서 feature flag 활성화 -> Scheduler 생성 -> mock sync -> 5분 후 발송 확인
5. **WhatsApp 발송**: 테스트 번호로 실제 템플릿 메시지 수신 확인
