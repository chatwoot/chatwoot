<template>
  <div class="event-registration">
    <div class="event-registration__header">
      <h1 class="event-registration__title">
        {{ value ? 'Editar Evento' : 'Cadastro de Eventos' }}
      </h1>
      <p class="event-registration__description">
        Configure eventos automatizados para envio via WhatsApp
      </p>
    </div>

    <div class="event-registration__content">
      <!-- Formulário de Cadastro -->
      <form @submit.prevent="handleSubmit" class="event-form">
        <div class="event-form__group">
          <label for="eventId" class="event-form__label">ID do Evento</label>
          <select
            id="eventId"
            v-model="eventForm.eventId"
            @change="handleEventIdChange"
            class="event-form__input"
            :class="{ 'event-form__input--error': errors.eventId }"
            required
          >
            <option disabled value="">Selecione um evento</option>
            <option
              v-for="option in eventIdOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
            <option value="__new">Inserir um novo evento</option>
          </select>
          <span v-if="errors.eventId" class="event-form__error">
            {{ errors.eventId }}
          </span>
        </div>

        <div class="event-form__group">
          <label class="event-form__label">Período de evento</label>
          <button type="button" class="btn btn--secondary" @click="showPeriodModal = true">
            Definir período
          </button>
        </div>

        <div
          v-for="day in sortedSelectedDays"
          :key="day"
          class="event-form__group"
        >
          <label :for="`template-${day}`" class="event-form__label">
            Template da mensagem de {{ dayLabel(day) }}
          </label>
          <textarea
            :id="`template-${day}`"
            v-model="eventForm.messageTemplates[day]"
            class="event-form__textarea"
            :placeholder="`Mensagem para ${dayLabel(day)}`"
            rows="4"
            required
          ></textarea>
        </div>

        <div class="event-form__group">
          <label class="event-form__checkbox-container">
            <input
              v-model="eventForm.enabled"
              type="checkbox"
              class="event-form__checkbox"
            />
            <span class="event-form__checkbox-label">Evento Ativo</span>
          </label>
        </div>

        <div class="event-form__group">
          <label for="attachment" class="event-form__label">Anexo</label>
          <input
            id="attachment"
            type="file"
            class="event-form__input"
            @change="handleFileChange"
            required
          />
        </div>

        <div class="event-form__actions">
          <button
            type="submit"
            class="btn btn--primary"
            :disabled="isSubmitting || !isFormValid"
            :class="{ 'btn--loading': isSubmitting }"
          >
            {{ isSubmitting ? 'Salvando...' : 'Salvar Evento' }}
          </button>
        </div>
      </form>

      <!-- Feedback Visual -->
      <div
        v-if="submitStatus.show"
        class="alert"
        :class="submitStatus.type === 'success' ? 'alert--success' : 'alert--error'"
      >
        <div class="alert__content">
          <h3 class="alert__title">
            {{ submitStatus.type === 'success' ? '✓ Sucesso!' : '✗ Erro!' }}
          </h3>
          <p class="alert__message">{{ submitStatus.message }}</p>
        </div>
      </div>
    </div>

    <!-- Modal Novo Evento -->
    <div v-if="showNewEventModal" class="modal">
      <div class="modal__content">
        <h3 class="modal__title">Inserir novo evento</h3>
        <input v-model="newEventId" type="text" class="event-form__input" placeholder="ID do evento" />
        <div class="modal__actions">
          <button type="button" class="btn btn--secondary" @click="closeNewEventModal">Cancelar</button>
          <button type="button" class="btn btn--primary" @click="confirmNewEvent">Adicionar</button>
        </div>
      </div>
    </div>

    <!-- Modal Período de Evento -->
    <div v-if="showPeriodModal" class="modal">
      <div class="modal__content">
        <h3 class="modal__title">Período de evento</h3>
        <div class="event-form__group">
          <label class="event-form__label">Dias da Semana</label>
          <div class="days-selector">
            <label v-for="day in daysOptions" :key="day.value" class="days-selector__item">
              <input
                v-model="eventForm.daysOfWeek"
                type="checkbox"
                :value="day.value"
                class="days-selector__checkbox"
              />
              <span class="days-selector__label">{{ day.label }}</span>
            </label>
          </div>
        </div>
        <div class="event-form__group">
          <label for="time" class="event-form__label">Horário</label>
          <input id="time" v-model="eventForm.time" type="time" class="event-form__input" />
        </div>
        <div class="event-form__group">
          <label for="startDate" class="event-form__label">Início</label>
          <input id="startDate" v-model="eventForm.startDate" type="date" class="event-form__input" />
        </div>
        <div class="event-form__group">
          <label for="endDate" class="event-form__label">Fim</label>
          <input id="endDate" v-model="eventForm.endDate" type="date" class="event-form__input" />
        </div>
        <div class="modal__actions">
          <button type="button" class="btn btn--secondary" @click="closePeriodModal">Cancelar</button>
          <button type="button" class="btn btn--primary" @click="closePeriodModal">Salvar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'EventForm',
  
  props: {
    value: {
      type: Object,
      default: null
    }
  },
  
  data() {
    const today = new Date().toISOString().split('T')[0]
    return {
      // Form data
      eventForm: {
        eventId: '',
        daysOfWeek: [],
        time: '09:00',
        startDate: today,
        endDate: today,
        messageTemplates: {},
        enabled: true,
        attachment: null
      },
      
      // UI State
      isSubmitting: false,
      submitStatus: {
        show: false,
        type: '', // 'success' | 'error'
        message: ''
      },
      errors: {},

      eventIdOptions: [
        { value: 'boas_vindas', label: 'Boas Vindas' },
        { value: 'aniversario', label: 'Aniversário' },
        { value: 'promocao_semana', label: 'Promoção da Semana' },
        { value: 'lembrete_pagamento', label: 'Lembrete de Pagamento' },
        { value: 'aniversarios', label: 'Aniversários' }
      ],
      showNewEventModal: false,
      newEventId: '',
      showPeriodModal: false,

      // Options
      daysOptions: [
        { value: 'MON', label: 'Segunda' },
        { value: 'TUE', label: 'Terça' },
        { value: 'WED', label: 'Quarta' },
        { value: 'THU', label: 'Quinta' },
        { value: 'FRI', label: 'Sexta' },
        { value: 'SAT', label: 'Sábado' },
        { value: 'SUN', label: 'Domingo' }
      ],
      
      // API Configuration
      API_CONFIG: {
        baseURL: 'https://api.example.com/v1',
        authToken: 'token-padrao'
      }
    }
  },

  computed: {
    sortedSelectedDays() {
      return [...this.eventForm.daysOfWeek].sort(
        (a, b) =>
          this.daysOptions.findIndex(d => d.value === a) -
          this.daysOptions.findIndex(d => d.value === b)
      )
    },
    isFormValid() {
      return (
        this.eventForm.eventId &&
        this.eventForm.daysOfWeek.length > 0 &&
        this.eventForm.time &&
        this.eventForm.startDate &&
        this.eventForm.endDate &&
        this.eventForm.attachment &&
        this.eventForm.daysOfWeek.every(
          day =>
            this.eventForm.messageTemplates[day] &&
            this.eventForm.messageTemplates[day].trim()
        )
      )
    }
  },
  
  watch: {
    value: {
      immediate: true,
      handler(newValue) {
        if (newValue) {
          // Modo edição - preenche o formulário com os dados do evento
          this.eventForm = {
            ...this.eventForm,
            ...newValue,
            daysOfWeek: newValue.daysOfWeek || [],
            messageTemplates: newValue.messageTemplates || {},
            attachment: newValue.attachment || null
          }
        }
      }
    },
    'eventForm.daysOfWeek'(newDays) {
      for (const day of Object.keys(this.eventForm.messageTemplates)) {
        if (!newDays.includes(day)) {
          delete this.eventForm.messageTemplates[day]
        }
      }
    }
  },

  methods: {
    // Gerenciamento do ID do evento
    handleEventIdChange() {
      if (this.eventForm.eventId === '__new') {
        this.eventForm.eventId = ''
        this.newEventId = ''
        this.showNewEventModal = true
      }
    },
    closeNewEventModal() {
      this.showNewEventModal = false
      this.eventForm.eventId = ''
    },
    confirmNewEvent() {
      const trimmed = this.newEventId.trim()
      if (trimmed) {
        this.eventIdOptions.push({ value: trimmed, label: trimmed })
        this.eventForm.eventId = trimmed
        this.showNewEventModal = false
      }
    },

    closePeriodModal() {
      this.showPeriodModal = false
    },

    // Validação
    validateForm() {
      this.errors = {}

      if (!this.eventForm.eventId.trim()) {
        this.errors.eventId = 'ID do evento é obrigatório'
      }

      return Object.keys(this.errors).length === 0
    },

    handleFileChange(event) {
      const file = event.target.files[0]
      if (file) {
        const reader = new FileReader()
        reader.onload = () => {
          this.eventForm.attachment = reader.result
        }
        reader.readAsDataURL(file)
      } else {
        this.eventForm.attachment = null
      }
    },

    // Submissão do formulário
    async handleSubmit() {
      if (!this.validateForm()) {
        return
      }

      this.isSubmitting = true
      this.hideAlert()

      try {
        const cleanedData = { ...this.eventForm }

        const response = await this.submitEventToAPI(cleanedData)

        if (response.status === 200) {
          this.showAlert('success', 'Evento cadastrado com sucesso!')
          this.resetForm()
          this.$emit('event-saved', cleanedData)
        }

      } catch (error) {
        console.error('Erro ao cadastrar evento:', error)
        this.showAlert('error', 'Erro ao cadastrar evento. Tente novamente.')
      } finally {
        this.isSubmitting = false
      }
    },

    // Requisição para API
    async submitEventToAPI(eventData) {
      const config = {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.API_CONFIG.authToken}`
        }
      }

      // Se está editando, usa PUT, senão usa POST
      if (this.value && this.value.eventId) {
        return await axios.put(
          `${this.API_CONFIG.baseURL}/events/${encodeURIComponent(eventData.eventId)}`,
          eventData,
          config
        )
      } else {
        return await axios.post(
          `${this.API_CONFIG.baseURL}/events`,
          eventData,
          config
        )
      }
    },

    // Utilitários
    resetForm() {
      const today = new Date().toISOString().split('T')[0]
      this.eventForm = {
        eventId: '',
        daysOfWeek: [],
        time: '09:00',
        startDate: today,
        endDate: today,
        messageTemplates: {},
        enabled: true,
        attachment: null
      }
      this.errors = {}
    },

    showAlert(type, message) {
      this.submitStatus = {
        show: true,
        type,
        message
      }
      
      // Auto-hide após 5 segundos
      setTimeout(() => {
        this.hideAlert()
      }, 5000)
    },

    hideAlert() {
      this.submitStatus.show = false
    },

    dayLabel(value) {
      const match = this.daysOptions.find(d => d.value === value)
      return match ? match.label : value
    }
  }
}
</script>

<style scoped>
.event-registration {
  min-height: 100vh;
  padding: 24px;
  max-width: 800px;
  margin: 0 auto;
  background: #1a1a1a;
  color: #e5e5e5;
}

.event-registration__header {
  margin-bottom: 24px;
  text-align: center;
}

.event-registration__title {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
  color: #ffffff;
}

.event-registration__description {
  color: #a0a0a0;
  font-size: 18px;
}

/* Form Styles */
.event-form {
  background: #2a2a2a;
  padding: 24px;
  border-radius: 14px;
  border: 1px solid #3a3a3a;
  margin-bottom: 24px;
}

.event-form__group {
  margin-bottom: 16px;
}

.event-form__label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #ffffff;
}

.event-form__input,
.event-form__textarea {
  background-color: #1f1f1f;
  color: #e5e5e5;
  width: 100%;
  padding: 12px;
  border: 1px solid #3a3a3a;
  border-radius: 10px;
  font-size: 16px;
}

.event-form__input:focus,
.event-form__textarea:focus {
  outline: none;
  border-color: #4f9cf9;
  box-shadow: 0 0 0 1px #4f9cf9;
}

.event-form__input::placeholder,
.event-form__textarea::placeholder {
  color: #808080;
}

.event-form__input--error {
  border-color: #ef4444;
}

.event-form__error {
  color: #ef4444;
  font-size: 14px;
  margin-top: 8px;
}

.event-form__checkbox-container {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.event-form__checkbox {
  width: 18px;
  height: 18px;
  accent-color: #4f9cf9;
}

.event-form__checkbox-label {
  color: #e5e5e5;
}

/* Days Selector */
.days-selector {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}

.days-selector__item {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  color: #e5e5e5;
}

.days-selector__checkbox {
  width: 16px;
  height: 16px;
  accent-color: #4f9cf9;
}

.event-form__actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 24px;
}

/* Buttons */
.btn {
  padding: 12px 16px;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn--primary {
  background-color: #4f9cf9;
  color: #ffffff;
}

.btn--primary:hover:not(:disabled) {
  background-color: #3b82f6;
}

.btn--secondary {
  background-color: #333333;
  border: 1px solid #3a3a3a;
  color: #e5e5e5;
}

.btn--secondary:hover:not(:disabled) {
  background-color: #3a3a3a;
}

.btn--danger {
  background-color: #ef4444;
  color: #ffffff;
}

.btn--small {
  padding: 6px 12px;
  font-size: 14px;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn--loading {
  opacity: 0.8;
}

/* Alerts */
.alert {
  padding: 16px;
  border-radius: 10px;
  margin-bottom: 24px;
}

.alert--success {
  background-color: #064e3b;
  border: 1px solid #10b981;
  color: #10b981;
}

.alert--error {
  background-color: #7f1d1d;
  border: 1px solid #ef4444;
  color: #ef4444;
}

.alert__title {
  font-weight: 700;
  margin-bottom: 8px;
  margin-top: 0;
}

.alert__message {
  margin: 0;
}

/* Modal */
.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal__content {
  background: #2a2a2a;
  padding: 24px;
  border-radius: 14px;
  border: 1px solid #3a3a3a;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 400px;
}

.modal__title {
  margin-top: 0;
  margin-bottom: 16px;
  font-size: 18px;
  color: #ffffff;
}

.modal__actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
}

/* Responsive design */
@media (max-width: 600px) {
  .event-registration {
    padding: 16px;
  }

  .event-form {
    padding: 16px;
  }

  .modal__content {
    width: 95%;
    max-width: none;
    padding: 16px;
  }

  .modal__actions {
    flex-direction: column;
    gap: 8px;
  }

  .modal__actions .btn {
    width: 100%;
  }

  .event-form__actions {
    flex-direction: column;
  }
  
  .event-form__actions .btn {
    width: 100%;
  }

  .days-selector {
    flex-direction: column;
    gap: 12px;
  }
}

@media (min-width: 1200px) {
  .event-registration {
    max-width: 1200px;
  }

  .event-form {
    max-width: 1200px;
  }
}

/* Scrollbar personalizada para tema escuro */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #2a2a2a;
}

::-webkit-scrollbar-thumb {
  background: #4a4a4a;
  border-radius: 4px;
}


::-webkit-scrollbar-thumb:hover {
  background: #5a5a5a;
}
</style>