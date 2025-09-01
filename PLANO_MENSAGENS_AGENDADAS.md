# 🚀 Plano Completo de Implementação - Sistema de Mensagens Agendadas

## 📋 Índice
1. [Visão Geral do Projeto](#visao-geral)
2. [Análise de Riscos](#analise-de-riscos)
3. [Estratégia de Implementação](#estrategia-implementacao)
4. [Fases de Desenvolvimento](#fases-desenvolvimento)
5. [Detalhamento Técnico](#detalhamento-tecnico)
6. [Plano de Testes](#plano-testes)
7. [Estratégias de Rollback](#estrategias-rollback)
8. [Monitoramento e Alertas](#monitoramento)
9. [Cronograma e Marcos](#cronograma)
10. [Checklist de Deploy](#checklist-deploy)

---

## 🎯 Visão Geral do Projeto

### **Objetivo:**
Implementar sistema de mensagens agendadas individuais dentro da interface de conversa, permitindo que agentes agendem mensagens específicas para serem enviadas automaticamente em horários definidos.

### **Escopo:**
- ✅ **Agendamento**: Interface para definir data/hora de envio
- ✅ **Gerenciamento**: Visualizar, editar e cancelar mensagens agendadas
- ✅ **Execução**: Processamento automático no horário definido
- ✅ **Monitoramento**: Logs, status e notificações de erro
- ✅ **Integração**: Funciona com todos os canais existentes

### **Não Escopo (Fase 1):**
- ❌ Mensagens recorrentes/repetitivas
- ❌ Agendamento em massa
- ❌ Templates específicos para agendamento
- ❌ Integração com calendário externo

---

## ⚠️ Análise de Riscos

### **Riscos Técnicos:**

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| **Conflito com sistema de mensagens atual** | Alto | Baixo | Testes extensivos, feature flag |
| **Performance do scheduler** | Médio | Médio | Monitoramento, otimização de queries |
| **Falha na entrega agendada** | Alto | Baixo | Retry mechanism, alertas |
| **Inconsistência de timezone** | Médio | Médio | UTC storage, validação de timezone |
| **Migração de dados** | Baixo | Baixo | Migration reversível, backup |

### **Riscos de Negócio:**

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| **Confusão na UX** | Médio | Baixo | UI intuitiva, tooltips, feedback |
| **Mensagens duplicadas** | Alto | Baixo | Validação, idempotência |
| **Fuso horário incorreto** | Médio | Médio | Display claro, validação |

---

## 🛠️ Estratégia de Implementação

### **Abordagem: Expansão Incremental**
Aproveitaremos 90% da infraestrutura existente, expandindo componentes atuais em vez de criar sistemas paralelos.

### **Vantagens:**
- ✅ **Menor risco**: Usa patterns já testados
- ✅ **Consistência**: Mantém padrões existentes
- ✅ **Rapidez**: Reaproveita código existente
- ✅ **Manutenibilidade**: Uma base de código

### **Principais Modificações:**
1. **Model Message**: Adicionar campo `scheduled_at`
2. **MessageBuilder**: Suportar agendamento
3. **TriggerScheduledItemsJob**: Incluir mensagens agendadas
4. **ReplyBox**: Interface de agendamento
5. **MessageAPI**: Aceitar `scheduled_at`

---

## 📅 Fases de Desenvolvimento

### **FASE 1: Backend Foundation (3-4 dias)**
- Migration para adicionar `scheduled_at` ao model Message
- Modificar MessageBuilder para suportar agendamento
- Criar ScheduledMessagesJob
- Integrar no TriggerScheduledItemsJob
- Testes unitários backend

### **FASE 2: API & Integration (2-3 dias)**
- Expandir MessagesController para aceitar `scheduled_at`
- Atualizar MessageApi frontend
- Modificar store actions do Vuex
- Validações e error handling
- Testes de integração API

### **FASE 3: Frontend Interface (3-4 dias)**
- Adicionar datetime picker no ReplyBox
- Toggle entre envio imediato/agendado
- Validações de timezone e data futura
- Estados de loading e feedback
- Testes frontend

### **FASE 4: Management Interface (4-5 dias)**
- Lista de mensagens agendadas
- Funcionalidades de editar/cancelar
- Filtros e busca
- Status e logs
- Testes E2E

### **FASE 5: Polimento & Deploy (2-3 dias)**
- Feature flags
- Monitoramento
- Documentação
- Deploy gradual
- Rollback testing

---

## 🔧 Detalhamento Técnico

### **1. Database Migration**
```ruby
# db/migrate/add_scheduled_at_to_messages.rb
class AddScheduledAtToMessages < ActiveRecord::Migration[7.0]
  def up
    add_column :messages, :scheduled_at, :datetime
    add_index :messages, [:scheduled_at, :account_id], 
              where: "scheduled_at IS NOT NULL", 
              name: "index_messages_on_scheduled_at_and_account"
    
    # Trigger para notificação de mudanças
    execute <<-SQL
      CREATE OR REPLACE FUNCTION notify_scheduled_message_changes()
      RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'INSERT' AND NEW.scheduled_at IS NOT NULL THEN
          PERFORM pg_notify('scheduled_messages', NEW.id::text);
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      
      DROP TRIGGER IF EXISTS scheduled_message_trigger ON messages;
      CREATE TRIGGER scheduled_message_trigger
        AFTER INSERT ON messages
        FOR EACH ROW
        EXECUTE FUNCTION notify_scheduled_message_changes();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS scheduled_message_trigger ON messages;"
    execute "DROP FUNCTION IF EXISTS notify_scheduled_message_changes();"
    
    remove_index :messages, name: "index_messages_on_scheduled_at_and_account"
    remove_column :messages, :scheduled_at
  end
end
```

### **2. Message Model Update**
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  # ... código existente ...
  
  # Scopes para mensagens agendadas
  scope :scheduled, -> { where.not(scheduled_at: nil) }
  scope :ready_to_send, -> { scheduled.where('scheduled_at <= ?', Time.current) }
  scope :pending_scheduled, -> { scheduled.where('scheduled_at > ?', Time.current) }
  
  # Validações para agendamento
  validates :scheduled_at, presence: true, if: :scheduled?
  validate :scheduled_at_must_be_future, if: :scheduled?
  
  # Status computed
  def scheduled?
    scheduled_at.present?
  end
  
  def ready_to_send?
    scheduled? && scheduled_at <= Time.current
  end
  
  def pending_scheduled?
    scheduled? && scheduled_at > Time.current
  end

  private

  def scheduled_at_must_be_future
    if scheduled_at.present? && scheduled_at <= 5.minutes.from_now
      errors.add(:scheduled_at, 'deve ser pelo menos 5 minutos no futuro')
    end
  end
end
```

### **3. Enhanced MessageBuilder**
```ruby
# app/builders/messages/message_builder.rb
class Messages::MessageBuilder
  # ... código existente ...

  def perform
    if scheduled?
      create_scheduled_message
    else
      create_and_send_message
    end
  end

  private

  def scheduled?
    @params[:scheduled_at].present?
  end

  def create_scheduled_message
    @message = @conversation.messages.build(message_params)
    process_attachments
    process_emails
    @message.save!
    
    # Log agendamento
    Rails.logger.info "Scheduled message created: #{@message.id} for #{@message.scheduled_at}"
    
    @message
  end

  def create_and_send_message
    @message = @conversation.messages.build(message_params)
    process_attachments
    process_emails
    @message.save!
    
    # Envia imediatamente
    ::SendReplyJob.perform_later(@message.id) unless @message.private
    
    @message
  end

  def message_params
    {
      content: @params[:content],
      message_type: @message_type,
      private: @private,
      sender: @user,
      content_attributes: content_attributes,
      scheduled_at: parsed_scheduled_at,
      # ... outros params
    }
  end

  def parsed_scheduled_at
    return nil unless @params[:scheduled_at].present?
    
    # Garantir que é UTC
    Time.zone.parse(@params[:scheduled_at]).utc
  rescue ArgumentError => e
    Rails.logger.error "Invalid scheduled_at format: #{@params[:scheduled_at]} - #{e}"
    nil
  end
end
```

### **4. ScheduledMessages Job**
```ruby
# app/jobs/scheduled_messages_job.rb
class ScheduledMessagesJob < ApplicationJob
  queue_as :scheduled_jobs
  
  def perform
    Rails.logger.info "Processing scheduled messages..."
    
    messages_processed = 0
    
    Message.ready_to_send.includes(:conversation, :sender).find_each do |message|
      begin
        process_scheduled_message(message)
        messages_processed += 1
      rescue => e
        Rails.logger.error "Failed to process scheduled message #{message.id}: #{e}"
        # Opcionalmente, criar um retry ou notificação
      end
    end
    
    Rails.logger.info "Processed #{messages_processed} scheduled messages"
  end

  private

  def process_scheduled_message(message)
    # Remover da agenda
    message.update!(scheduled_at: nil)
    
    # Enviar via job existente
    ::SendReplyJob.perform_later(message.id) unless message.private
    
    # Log sucesso
    Rails.logger.info "Scheduled message #{message.id} sent successfully"
  end
end
```

### **5. Integration with TriggerScheduledItemsJob**
```ruby
# app/jobs/trigger_scheduled_items_job.rb
class TriggerScheduledItemsJob < ApplicationJob
  def perform
    # ... código existente ...
    
    # Adicionar processamento de mensagens agendadas
    ScheduledMessagesJob.perform_later
  end
end
```

### **6. Messages Controller Update**
```ruby
# app/controllers/api/v1/accounts/conversations/messages_controller.rb
class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  
  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, message_params)
    @message = mb.perform
    
    if @message.scheduled?
      render json: { 
        message: 'Message scheduled successfully',
        scheduled_at: @message.scheduled_at,
        data: @message 
      }
    else
      # Resposta normal
    end
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end
  
  def index
    @messages = message_finder.perform
    @scheduled_messages = @conversation.messages.pending_scheduled if params[:include_scheduled]
  end

  private

  def message_params
    params.permit(:content, :private, :scheduled_at, content_attributes: {})
  end
end
```

### **7. Frontend MessageApi Update**
```javascript
// app/javascript/dashboard/api/inbox/message.js
export const buildCreatePayload = ({
  message,
  isPrivate,
  contentAttributes,
  scheduledAt,  // ⭐ Novo campo
  echoId,
  files,
  ccEmails = '',
  bccEmails = '',
  templateParams,
}) => {
  // ... código existente ...
  
  if (scheduledAt) {
    payload.scheduled_at = scheduledAt;
  }
  
  return payload;
};

class MessageApi extends ApiClient {
  create({
    conversationId,
    message,
    private: isPrivate,
    contentAttributes,
    scheduledAt,  // ⭐ Novo parâmetro
    echo_id: echoId,
    files,
    ccEmails = '',
    bccEmails = '',
    templateParams,
  }) {
    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: buildCreatePayload({
        message,
        isPrivate,
        contentAttributes,
        scheduledAt,  // ⭐ Incluir no payload
        echoId,
        files,
        ccEmails,
        bccEmails,
        templateParams,
      }),
    });
  }
  
  // Novo método para listar mensagens agendadas
  getScheduledMessages(conversationId) {
    return axios.get(`${this.url}/${conversationId}/messages?include_scheduled=true`);
  }
  
  // Cancelar mensagem agendada
  cancelScheduledMessage(conversationId, messageId) {
    return axios.delete(`${this.url}/${conversationId}/messages/${messageId}/schedule`);
  }
}
```

### **8. ReplyBox Component Enhancement**
```vue
<!-- app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue -->
<template>
  <div class="reply-box">
    <!-- Editor existente -->
    <WootMessageEditor 
      v-model="message"
      enable-variables
      :variables="messageVariables"
    />
    
    <!-- ⭐ Nova seção de agendamento -->
    <div v-if="message.trim()" class="schedule-section">
      <div class="schedule-toggle">
        <input 
          id="schedule-toggle"
          v-model="isScheduled" 
          type="checkbox"
          class="toggle-checkbox"
        >
        <label for="schedule-toggle" class="toggle-label">
          📅 Agendar mensagem
        </label>
      </div>
      
      <div v-if="isScheduled" class="schedule-datetime">
        <input
          v-model="scheduledDateTime"
          type="datetime-local"
          :min="minDateTime"
          class="datetime-input"
          @change="validateScheduledTime"
        >
        <p v-if="scheduleError" class="error-message">
          {{ scheduleError }}
        </p>
        <p v-else-if="scheduledDateTime" class="schedule-info">
          📤 Mensagem será enviada em {{ formatScheduledTime }}
        </p>
      </div>
    </div>

    <!-- Botão de envio existente com texto dinâmico -->
    <ReplyBottomPanel 
      :on-send="onSendReply"
      :send-button-text="dynamicSendButtonText"
      :is-disabled="isScheduled && !isValidScheduledTime"
    />
  </div>
</template>

<script>
export default {
  data() {
    return {
      isScheduled: false,
      scheduledDateTime: '',
      scheduleError: '',
    };
  },

  computed: {
    minDateTime() {
      // 5 minutos no futuro
      const now = new Date();
      now.setMinutes(now.getMinutes() + 5);
      return now.toISOString().slice(0, 16);
    },

    formatScheduledTime() {
      if (!this.scheduledDateTime) return '';
      
      return new Date(this.scheduledDateTime).toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    },

    isValidScheduledTime() {
      if (!this.isScheduled) return true;
      return this.scheduledDateTime && !this.scheduleError;
    },

    dynamicSendButtonText() {
      if (this.isScheduled) {
        return `📅 Agendar (${this.keyLabel})`;
      }
      return this.replyButtonLabel; // Texto original
    },
  },

  methods: {
    validateScheduledTime() {
      this.scheduleError = '';
      
      if (!this.scheduledDateTime) {
        this.scheduleError = 'Selecione data e hora para agendamento';
        return;
      }

      const scheduledDate = new Date(this.scheduledDateTime);
      const minDate = new Date();
      minDate.setMinutes(minDate.getMinutes() + 5);

      if (scheduledDate <= minDate) {
        this.scheduleError = 'Agendamento deve ser pelo menos 5 minutos no futuro';
        return;
      }

      // Validar se não é muito distante (ex: 1 ano)
      const maxDate = new Date();
      maxDate.setFullYear(maxDate.getFullYear() + 1);
      
      if (scheduledDate > maxDate) {
        this.scheduleError = 'Agendamento não pode ser mais de 1 ano no futuro';
        return;
      }
    },

    async onSendReply() {
      // Validação existente...
      
      if (this.isScheduled) {
        if (!this.isValidScheduledTime) {
          useAlert('Por favor, corrija os problemas de agendamento');
          return;
        }
        
        // Confirmar agendamento
        const confirmed = await this.$refs.confirmDialog?.showConfirmation();
        if (!confirmed) return;
      }

      const messagePayload = this.getMessagePayload(this.message);
      
      // ⭐ Adicionar scheduled_at se agendado
      if (this.isScheduled) {
        messagePayload.scheduledAt = new Date(this.scheduledDateTime).toISOString();
      }

      await this.sendMessage(messagePayload);
    },

    async sendMessage(messagePayload) {
      try {
        await this.$store.dispatch('createPendingMessageAndSend', messagePayload);
        
        if (messagePayload.scheduledAt) {
          useAlert(`Mensagem agendada para ${this.formatScheduledTime}`, 'success');
        }
        
        this.clearMessage();
        this.resetSchedule();
      } catch (error) {
        const errorMessage = error?.response?.data?.error || 'Erro ao enviar mensagem';
        useAlert(errorMessage);
      }
    },

    resetSchedule() {
      this.isScheduled = false;
      this.scheduledDateTime = '';
      this.scheduleError = '';
    },
  },
};
</script>

<style scoped>
.schedule-section {
  @apply border-t border-gray-200 pt-3 mt-3;
}

.schedule-toggle {
  @apply flex items-center gap-2 mb-2;
}

.toggle-checkbox {
  @apply w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500;
}

.toggle-label {
  @apply text-sm font-medium text-gray-700 cursor-pointer;
}

.schedule-datetime {
  @apply ml-6;
}

.datetime-input {
  @apply w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500;
}

.error-message {
  @apply text-sm text-red-600 mt-1;
}

.schedule-info {
  @apply text-sm text-green-600 mt-1 flex items-center gap-1;
}
</style>
```

---

## 🧪 Plano de Testes

### **1. Testes Unitários Backend**
```ruby
# spec/models/message_spec.rb
RSpec.describe Message, type: :model do
  describe 'scheduled messages' do
    it 'validates scheduled_at is in the future' do
      message = build(:message, scheduled_at: 1.minute.ago)
      expect(message).not_to be_valid
      expect(message.errors[:scheduled_at]).to include('deve ser pelo menos 5 minutos no futuro')
    end

    it 'allows scheduling 10 minutes in the future' do
      message = build(:message, scheduled_at: 10.minutes.from_now)
      expect(message).to be_valid
    end
  end

  describe 'scopes' do
    let!(:immediate_message) { create(:message) }
    let!(:scheduled_future) { create(:message, scheduled_at: 1.hour.from_now) }
    let!(:scheduled_ready) { create(:message, scheduled_at: 1.minute.ago) }

    it 'finds ready to send messages' do
      expect(Message.ready_to_send).to contain_exactly(scheduled_ready)
    end

    it 'finds pending scheduled messages' do
      expect(Message.pending_scheduled).to contain_exactly(scheduled_future)
    end
  end
end

# spec/jobs/scheduled_messages_job_spec.rb
RSpec.describe ScheduledMessagesJob, type: :job do
  describe '#perform' do
    let!(:ready_message) { create(:message, scheduled_at: 1.minute.ago) }
    let!(:future_message) { create(:message, scheduled_at: 1.hour.from_now) }

    it 'processes ready messages and enqueues SendReplyJob' do
      expect(SendReplyJob).to receive(:perform_later).with(ready_message.id)
      
      described_class.new.perform
      
      ready_message.reload
      expect(ready_message.scheduled_at).to be_nil
    end

    it 'does not process future messages' do
      expect(SendReplyJob).not_to receive(:perform_later).with(future_message.id)
      
      described_class.new.perform
      
      future_message.reload
      expect(future_message.scheduled_at).to be_present
    end
  end
end
```

### **2. Testes de Integração API**
```ruby
# spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb
RSpec.describe Api::V1::Accounts::Conversations::MessagesController, type: :controller do
  describe 'POST #create with scheduled_at' do
    let(:scheduled_time) { 1.hour.from_now }
    
    let(:params) do
      {
        content: 'Test scheduled message',
        scheduled_at: scheduled_time.iso8601
      }
    end

    it 'creates scheduled message' do
      post :create, params: params

      expect(response).to have_http_status(:success)
      
      message = conversation.messages.last
      expect(message.content).to eq('Test scheduled message')
      expect(message.scheduled_at).to be_within(1.second).of(scheduled_time)
    end

    it 'returns error for past scheduled_at' do
      params[:scheduled_at] = 1.hour.ago.iso8601
      
      post :create, params: params
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### **3. Testes Frontend**
```javascript
// spec/javascript/dashboard/components/widgets/conversation/ReplyBox.spec.js
import { mount } from '@vue/test-utils';
import ReplyBox from '@/components/widgets/conversation/ReplyBox.vue';

describe('ReplyBox', () => {
  describe('scheduled messages', () => {
    it('shows schedule toggle when message is not empty', async () => {
      const wrapper = mount(ReplyBox);
      
      await wrapper.setData({ message: 'Test message' });
      
      expect(wrapper.find('.schedule-toggle').exists()).toBe(true);
    });

    it('validates scheduled time is in the future', async () => {
      const wrapper = mount(ReplyBox);
      
      await wrapper.setData({ 
        message: 'Test message',
        isScheduled: true,
        scheduledDateTime: '2023-01-01T10:00'
      });

      wrapper.vm.validateScheduledTime();
      
      expect(wrapper.vm.scheduleError).toContain('futuro');
    });

    it('calls sendMessage with scheduledAt when scheduled', async () => {
      const wrapper = mount(ReplyBox);
      const sendMessageSpy = jest.spyOn(wrapper.vm, 'sendMessage');
      
      const futureDate = new Date();
      futureDate.setHours(futureDate.getHours() + 1);
      
      await wrapper.setData({
        message: 'Test message',
        isScheduled: true,
        scheduledDateTime: futureDate.toISOString().slice(0, 16)
      });

      await wrapper.vm.onSendReply();
      
      expect(sendMessageSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          scheduledAt: expect.any(String)
        })
      );
    });
  });
});
```

### **4. Testes E2E**
```javascript
// cypress/integration/scheduled_messages.spec.js
describe('Scheduled Messages', () => {
  beforeEach(() => {
    cy.login();
    cy.visit('/app/accounts/1/conversations/1');
  });

  it('allows scheduling a message', () => {
    const futureDate = new Date();
    futureDate.setHours(futureDate.getHours() + 1);
    
    // Digitar mensagem
    cy.get('[data-testid="message-input"]')
      .type('This is a scheduled message');
    
    // Habilitar agendamento
    cy.get('[data-testid="schedule-toggle"]').click();
    
    // Selecionar data/hora
    cy.get('[data-testid="schedule-datetime"]')
      .type(futureDate.toISOString().slice(0, 16));
    
    // Enviar
    cy.get('[data-testid="send-button"]').click();
    
    // Verificar confirmação
    cy.get('[data-testid="success-alert"]')
      .should('contain', 'Mensagem agendada');
  });
});
```

---

## 🔄 Estratégias de Rollback

### **1. Feature Flags**
```ruby
# config/features.yml
scheduled_messages:
  enabled: false
  rollout_percentage: 0
  accounts: []

# Usage no código
if Features.enabled?(:scheduled_messages, account: current_account)
  # Nova funcionalidade
else
  # Comportamento original
end
```

### **2. Database Rollback**
```ruby
# Migration reversível já implementada
rails db:rollback STEP=1

# Se dados existirem, migração de limpeza
class CleanupScheduledMessages < ActiveRecord::Migration[7.0]
  def up
    Message.where.not(scheduled_at: nil).find_each do |message|
      # Converter para mensagem imediata ou deletar
      message.update!(scheduled_at: nil)
    end
  end
end
```

### **3. Job Disabling**
```ruby
# Pausar processamento sem afetar sistema
class TriggerScheduledItemsJob < ApplicationJob
  def perform
    return if Features.disabled?(:scheduled_messages_processing)
    
    # ... código normal
    ScheduledMessagesJob.perform_later if Features.enabled?(:scheduled_messages)
  end
end
```

### **4. Frontend Rollback**
```javascript
// Conditional rendering
<div v-if="$features.enabled('scheduled_messages')" class="schedule-section">
  <!-- Nova interface -->
</div>
```

### **5. API Versioning**
```ruby
# Suporte a versão antiga da API
class MessagesController < ApplicationController
  def create
    if api_version >= '1.1' && Features.enabled?(:scheduled_messages)
      # Nova lógica com scheduled_at
    else
      # Lógica original
    end
  end
end
```

---

## 📊 Monitoramento e Alertas

### **1. Métricas Key**
```ruby
# config/initializers/metrics.rb
SCHEDULED_MESSAGES_CREATED = Prometheus::Counter.new(
  name: :scheduled_messages_created_total,
  docstring: 'Total scheduled messages created'
)

SCHEDULED_MESSAGES_SENT = Prometheus::Counter.new(
  name: :scheduled_messages_sent_total,
  docstring: 'Total scheduled messages sent successfully'
)

SCHEDULED_MESSAGES_FAILED = Prometheus::Counter.new(
  name: :scheduled_messages_failed_total,
  docstring: 'Total scheduled messages failed'
)

# Usage nos jobs
def process_scheduled_message(message)
  message.update!(scheduled_at: nil)
  SendReplyJob.perform_later(message.id)
  
  SCHEDULED_MESSAGES_SENT.increment
rescue => e
  SCHEDULED_MESSAGES_FAILED.increment
  raise e
end
```

### **2. Health Checks**
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def scheduled_messages
    checks = {
      pending_count: Message.pending_scheduled.count,
      overdue_count: Message.where('scheduled_at < ?', 1.hour.ago).count,
      job_queue_size: Sidekiq::Queue.new('scheduled_jobs').size,
      last_job_run: last_scheduled_job_run
    }
    
    status = checks[:overdue_count] > 0 ? :warning : :ok
    
    render json: { status: status, checks: checks }
  end
end
```

### **3. Alertas Automatic**
```ruby
# config/initializers/alerts.rb
if Rails.env.production?
  # Alert para mensagens overdue
  Sidekiq.cron.add('overdue_messages_alert', '0 */1 * * *') do
    overdue_count = Message.where('scheduled_at < ?', 1.hour.ago).count
    
    if overdue_count > 0
      Slack.notify(
        channel: '#alerts',
        message: "⚠️ #{overdue_count} mensagens agendadas atrasadas!"
      )
    end
  end
end
```

### **4. Dashboard Monitoring**
```sql
-- Queries para dashboard
-- Mensagens agendadas por período
SELECT 
  DATE_TRUNC('hour', scheduled_at) as hour,
  COUNT(*) as scheduled_count
FROM messages 
WHERE scheduled_at IS NOT NULL 
  AND scheduled_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour;

-- Performance do scheduler
SELECT 
  DATE_TRUNC('minute', created_at) as minute,
  AVG(EXTRACT(EPOCH FROM (updated_at - scheduled_at))) as avg_delay_seconds
FROM messages 
WHERE scheduled_at IS NOT NULL 
  AND updated_at > scheduled_at
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY minute
ORDER BY minute;
```

---

## 📈 Cronograma e Marcos

### **Sprint 1 (Semana 1): Backend Foundation**
- [ ] **Dia 1-2**: Database migration + Message model
- [ ] **Dia 3**: MessageBuilder enhancements
- [ ] **Dia 4**: ScheduledMessagesJob implementation
- [ ] **Dia 5**: Backend testing + integration

**Marco**: Backend capaz de criar e processar mensagens agendadas

### **Sprint 2 (Semana 2): API & Integration**
- [ ] **Dia 1-2**: API controller updates
- [ ] **Dia 3**: Frontend MessageApi updates
- [ ] **Dia 4**: Vuex store modifications
- [ ] **Dia 5**: API testing + documentation

**Marco**: API completa funcionando end-to-end

### **Sprint 3 (Semana 3): Frontend Interface**
- [ ] **Dia 1-2**: ReplyBox UI components
- [ ] **Dia 3**: Validation and error handling
- [ ] **Dia 4**: UX polishing + accessibility
- [ ] **Dia 5**: Frontend testing

**Marco**: Interface de usuário completa e funcional

### **Sprint 4 (Semana 4): Management Features**
- [ ] **Dia 1-2**: Scheduled messages list page
- [ ] **Dia 3**: Edit/cancel functionality
- [ ] **Dia 4**: Search and filtering
- [ ] **Dia 5**: E2E testing

**Marco**: Sistema completo de gerenciamento

### **Sprint 5 (Semana 5): Production Ready**
- [ ] **Dia 1**: Feature flags + rollback mechanisms
- [ ] **Dia 2**: Monitoring + alerting
- [ ] **Dia 3**: Performance optimization
- [ ] **Dia 4**: Documentation + training
- [ ] **Dia 5**: Soft launch preparation

**Marco**: Sistema pronto para produção

---

## ✅ Checklist de Deploy

### **Pre-Deploy Checklist**
- [ ] **Database Migration testada** em staging
- [ ] **Feature flags** configuradas (disabled)
- [ ] **Rollback plan** testado
- [ ] **Monitoring** configurado
- [ ] **Documentation** atualizada
- [ ] **Team training** realizado
- [ ] **Performance tests** passando
- [ ] **Security review** aprovado

### **Deploy Steps**
1. [ ] **Deploy backend** com feature flag OFF
2. [ ] **Run database migration**
3. [ ] **Deploy frontend** com feature flag OFF
4. [ ] **Smoke tests** em produção
5. [ ] **Enable feature flag** para beta accounts (10%)
6. [ ] **Monitor metrics** por 24h
7. [ ] **Gradual rollout** (25% → 50% → 100%)
8. [ ] **Full monitoring** por 1 semana

### **Post-Deploy Checklist**
- [ ] **All metrics** normal
- [ ] **No errors** em logs
- [ ] **User feedback** positivo
- [ ] **Performance impact** acceptable
- [ ] **Documentation** atualizada
- [ ] **Team retrospective** realizado

### **Success Criteria**
- ✅ **0 critical bugs** após 48h
- ✅ **<1% error rate** em scheduled messages
- ✅ **<5s response time** para agendamento
- ✅ **>95% delivery rate** de mensagens agendadas
- ✅ **Positive user feedback** (>4.0/5.0)

---

## 🚨 Emergency Procedures

### **Se algo der errado:**

**1. Immediate Response (0-15min)**
```bash
# Disable feature flag
rails console
Features.disable!(:scheduled_messages)

# Stop scheduled job processing
redis-cli
> FLUSHDB 5  # Clear scheduled jobs queue
```

**2. Assessment (15-30min)**
- Check error logs and metrics
- Assess impact scope
- Determine root cause

**3. Resolution Options**
- **Minor issue**: Hotfix + quick deploy
- **Major issue**: Full rollback
- **Data issue**: Database cleanup script

**4. Communication**
- Notify stakeholders immediately
- Update status page if user-facing
- Post-mortem within 24h

---

Este plano fornece uma estratégia completa, segura e bem estruturada para implementar mensagens agendadas, aproveitando ao máximo a infraestrutura existente do Chatwoot e minimizando riscos através de testes abrangentes e procedimentos de rollback robustos.