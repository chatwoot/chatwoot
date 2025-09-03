<template>
  <div class="events-container">
    <!-- Header da página -->
    <div class="events-header">
      <h1 class="events-title">Eventos Automatizados</h1>
      <div class="events-actions">
        <button class="btn btn--secondary" @click="loadEvents" :disabled="loading">
          <span v-if="loading">Carregando...</span>
          <span v-else>Recarregar</span>
        </button>
        <button class="btn btn--primary" @click="openCreateForm">
          Novo Evento
        </button>
      </div>
    </div>

    <!-- Estado vazio -->
    <div v-if="!loading && !events.length" class="empty-state">
      <div class="empty-state__icon">📅</div>
      <h2 class="empty-state__title">Sem eventos cadastrados</h2>
      <p class="empty-state__description">
        Crie seu primeiro evento para começar os disparos automatizados.
      </p>
      <button class="btn btn--primary btn--large" @click="openCreateForm">
        Criar Primeiro Evento
      </button>
    </div>

    <!-- Lista de eventos -->
    <div v-else-if="!loading" class="events-list">
      <!-- Filtros e busca -->
      <div class="events-filters">
        <div class="search-box">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar eventos..."
            class="search-input"
          />
        </div>
        <div class="legend">
          <span class="legend-item">
            <span class="status-dot status-dot--active"></span>
            Ativo
          </span>
          <span class="legend-item">
            <span class="status-dot status-dot--inactive"></span>
            Inativo
          </span>
        </div>
      </div>

      <!-- Cards dos eventos -->
      <div class="events-grid">
        <div
          v-for="event in filteredEvents"
          :key="event.eventId"
          class="event-card"
          :class="{ 'event-card--inactive': !event.enabled }"
        >
          <!-- Header do card -->
          <div class="event-card__header">
            <div class="event-card__title-section">
              <h3 class="event-card__title">{{ event.eventId }}</h3>
              <span 
                class="event-card__status"
                :class="event.enabled ? 'event-card__status--active' : 'event-card__status--inactive'"
              >
                {{ event.enabled ? 'Ativo' : 'Inativo' }}
              </span>
            </div>
            <div class="event-card__actions">
              <button
                class="btn btn--small btn--ghost"
                @click="toggleEnabled(event)"
                :disabled="togglingId === event.eventId"
                :title="event.enabled ? 'Desativar evento' : 'Ativar evento'"
              >
                <template v-if="event.enabled">
                  <!-- Ícone de pausa -->
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      d="M8 5V19M16 5V19"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    />
                  </svg>
                </template>
                <template v-else>
                  <!-- Ícone de play -->
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      d="M16.6582 9.28638C18.098 10.1862 18.8178 10.6361 19.0647 11.2122C19.2803 11.7152 19.2803 12.2847 19.0647 12.7878C18.8178 13.3638 18.098 13.8137 16.6582 14.7136L9.896 18.94C8.29805 19.9387 7.49907 20.4381 6.83973 20.385C6.26501 20.3388 5.73818 20.0469 5.3944 19.584C5 19.053 5 18.1108 5 16.2264V7.77357C5 5.88919 5 4.94701 5.3944 4.41598C5.73818 3.9531 6.26501 3.66111 6.83973 3.6149C7.49907 3.5619 8.29805 4.06126 9.896 5.05998L16.6582 9.28638Z"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linejoin="round"
                    />
                  </svg>
                </template>
              </button>
              <button
                class="btn btn--small btn--ghost"
                @click="editEvent(event)"
                title="Editar evento"
              >
                <svg width="20px" height="20px" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.2799 6.40005L11.7399 15.94C10.7899 16.89 7.96987 17.33 7.33987 16.7C6.70987 16.07 7.13987 13.25 8.08987 12.3L17.6399 2.75002C17.8754 2.49308 18.1605 2.28654 18.4781 2.14284C18.7956 1.99914 19.139 1.92124 19.4875 1.9139C19.8359 1.90657 20.1823 1.96991 20.5056 2.10012C20.8289 2.23033 21.1225 2.42473 21.3686 2.67153C21.6147 2.91833 21.8083 3.21243 21.9376 3.53609C22.0669 3.85976 22.1294 4.20626 22.1211 4.55471C22.1128 4.90316 22.0339 5.24635 21.8894 5.5635C21.7448 5.88065 21.5375 6.16524 21.2799 6.40005V6.40005Z" stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M11 4H6C4.93913 4 3.92178 4.42142 3.17163 5.17157C2.42149 5.92172 2 6.93913 2 8V18C2 19.0609 2.42149 20.0783 3.17163 20.8284C3.92178 21.5786 4.93913 22 6 22H17C19.21 22 20 20.2 20 18V13" stroke="#000000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
              </button>
              <button
                class="btn btn--small btn--ghost btn--danger"
                @click="confirmDelete(event)"
                title="Excluir evento"
              >
                <svg width="20px" height="20px" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M3 3L21 21M18 6L17.6 12M17.2498 17.2527L17.1991 18.0129C17.129 19.065 17.0939 19.5911 16.8667 19.99C16.6666 20.3412 16.3648 20.6235 16.0011 20.7998C15.588 21 15.0607 21 14.0062 21H9.99377C8.93927 21 8.41202 21 7.99889 20.7998C7.63517 20.6235 7.33339 20.3412 7.13332 19.99C6.90607 19.5911 6.871 19.065 6.80086 18.0129L6 6H4M16 6L15.4559 4.36754C15.1837 3.55086 14.4194 3 13.5585 3H10.4416C9.94243 3 9.47576 3.18519 9.11865 3.5M11.6133 6H20M14 14V17M10 10V17" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
              </button>
            </div>
          </div>

          <!-- Informações do evento -->
          <div class="event-card__content">
            <div class="event-info">
              <div class="event-info__item">
                <label class="event-info__label">Período:</label>
                <span class="event-info__value">{{ formatPeriod(event) }}</span>
              </div>
              <div class="event-info__item">
                <label class="event-info__label">Próxima execução:</label>
                <span class="event-info__value">{{ formatDateTime(event.nextRun) || '-' }}</span>
              </div>
              <div class="event-info__item">
                <label class="event-info__label">Clientes:</label>
                <span class="event-info__value">{{ (event.clients || []).length }} vinculados</span>
              </div>
            </div>

            <!-- Toggle para mostrar clientes -->
            <button
              class="clients-toggle"
              @click="toggleClients(event.eventId)"
              v-if="(event.clients || []).length > 0"
            >
              {{ expandedEvents.includes(event.eventId) ? '▼' : '▶' }}
              {{ expandedEvents.includes(event.eventId) ? 'Ocultar' : 'Ver' }} clientes
            </button>

            <!-- Lista de clientes (expandível) -->
            <div
              v-if="expandedEvents.includes(event.eventId) && (event.clients || []).length > 0"
              class="clients-list"
            >
              <div class="clients-header">
                <span class="clients-search">
                  <input
                    v-model="clientSearchQueries[event.eventId]"
                    type="text"
                    placeholder="Buscar cliente..."
                    class="clients-search-input"
                  />
                </span>
              </div>
              <div class="clients-grid">
                <div
                  v-for="client in getFilteredClients(event)"
                  :key="client.phone"
                  class="client-card"
                >
                  <div class="client-info">
                    <div class="client-name">{{ client.name }}</div>
                    <div class="client-phone">{{ client.phone }}</div>
                    <div class="client-status" :class="client.sent ? 'client-status--sent' : 'client-status--pending'">
                      {{ client.sent ? '✅ Enviado' : '⏳ Pendente' }}
                    </div>
                  </div>
                  <div class="client-actions">
                    <button
                      class="btn btn--tiny btn--ghost"
                      @click="previewMessage(event, client)"
                      title="Pré-visualizar mensagem"
                    >
                      👁️
                    </button>
                    <button
                      class="btn btn--tiny btn--primary"
                      @click="sendNow(event, client)"
                      title="Enviar agora"
                    >
                      📤
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Paginação -->
      <div v-if="totalPages > 1" class="pagination">
        <button
          class="btn btn--small btn--ghost"
          @click="currentPage--"
          :disabled="currentPage <= 1"
        >
          ← Anterior
        </button>
        <span class="pagination-info">
          Página {{ currentPage }} de {{ totalPages }}
        </span>
        <button
          class="btn btn--small btn--ghost"
          @click="currentPage++"
          :disabled="currentPage >= totalPages"
        >
          Próxima →
        </button>
      </div>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="loading-state">
      <div class="loading-spinner"></div>
      <p>Carregando eventos...</p>
    </div>

    <!-- Modal do formulário -->
    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal-content">
        <div class="modal-header">
          <h2 class="modal-title">
            {{ selectedEvent ? 'Editar Evento' : 'Novo Evento' }}
          </h2>
          <button class="btn btn--ghost btn--small modal-close" @click="closeForm">
            ✕
          </button>
        </div>
        <div class="modal-body">
          <EventForm :value="selectedEvent" @event-saved="handleEventSaved" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import EventForm from './EventForm.vue'

const tz = 'America/Sao_Paulo'
const fmtDate = (d) => {
  if (!d) return ''
  try {
    const asISO = typeof d === 'string' && d.includes(' ') ? d.replace(' ', 'T') : d
    const date = new Date(asISO)
    if (isNaN(date.getTime())) return d
    return date.toLocaleDateString('pt-BR', { timeZone: tz })
  } catch { return d }
}
const fmtDateTime = (d) => {
  if (!d) return ''
  try {
    const asISO = typeof d === 'string' && d.includes(' ') ? d.replace(' ', 'T') : d
    const date = new Date(asISO)
    if (isNaN(date.getTime())) return d
    return date.toLocaleString('pt-BR', {
      timeZone: tz,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit'
    })
  } catch { return d }
}

export default {
  name: 'EventRegistration',
  components: {
    EventForm
  },
  data() {
    return {
      loading: false,
      showForm: false,
      events: [],
      selectedEvent: null,
      togglingId: null,
      deletingId: null,
      searchQuery: '',
      expandedEvents: [],
      clientSearchQueries: {},
      currentPage: 1,
      pageSize: 6,
      API_CONFIG: {
        baseURL: 'https://api.example.com/v1',
        authToken: 'token-padrao',
      },
      api: null,
    }
  },
  computed: {
    filteredEvents() {
      let filtered = this.events
      
      if (this.searchQuery.trim()) {
        const query = this.searchQuery.toLowerCase()
        filtered = filtered.filter(event =>
          event.eventId.toLowerCase().includes(query)
        )
      }
      
      // Paginação
      const start = (this.currentPage - 1) * this.pageSize
      const end = start + this.pageSize
      return filtered.slice(start, end)
    },
    totalPages() {
      return Math.ceil(this.events.length / this.pageSize)
    }
  },
  created() {
    this.api = axios.create({
      baseURL: this.API_CONFIG.baseURL,
      headers: { Authorization: `Bearer ${this.API_CONFIG.authToken}` },
    })
  },
  mounted() {
    this.loadEvents()
    window.addEventListener('keydown', this.onKeydown)
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this.onKeydown)
  },
  methods: {
    onKeydown(e) {
      if (e.key === 'Escape' && this.showForm) this.closeForm()
    },
    
    openCreateForm() {
      this.selectedEvent = null
      this.showForm = true
    },
    
    closeForm() {
      this.showForm = false
      this.selectedEvent = null
    },
    
    async loadEvents() {
      this.loading = true
      try {
        const { status, data } = await this.api.get('/events')
        if (status === 200 && Array.isArray(data)) {
          this.events = data.map(ev => ({
            ...ev,
            startDate: ev.startDate || null,
            endDate: ev.endDate || null,
            nextRun: ev.nextRun || null,
            enabled: !!ev.enabled,
            clients: Array.isArray(ev.clients) ? ev.clients : [],
          }))
        } else {
          this.events = []
        }
      } catch (err) {
        console.error('Erro ao carregar eventos:', err)
        if (!this.events.length) this.events = this.getSampleEvents()
      } finally {
        this.loading = false
      }
    },
    
    editEvent(event) {
      this.selectedEvent = { ...event }
      this.showForm = true
    },
    
    async toggleEnabled(event) {
      if (!event?.eventId) return
      this.togglingId = event.eventId
      try {
        const updated = { ...event, enabled: !event.enabled }
        await this.api.put(`/events/${encodeURIComponent(event.eventId)}`, updated)
        const idx = this.events.findIndex(e => e.eventId === event.eventId)
        if (idx >= 0) this.events.splice(idx, 1, updated)
      } catch (err) {
        console.error('Erro ao alternar ativo:', err)
        alert('Não foi possível atualizar o status do evento.')
      } finally {
        this.togglingId = null
      }
    },
    
    async confirmDelete(event) {
      if (!event?.eventId || this.deletingId) return
      const ok = confirm(`Excluir o evento "${event.eventId}"? Esta ação não pode ser desfeita.`)
      if (!ok) return
      this.deletingId = event.eventId
      try {
        await this.api.delete(`/events/${encodeURIComponent(event.eventId)}`)
        this.events = this.events.filter(e => e.eventId !== event.eventId)
      } catch (err) {
        console.error('Erro ao excluir:', err)
        alert('Não foi possível excluir o evento.')
      } finally {
        this.deletingId = null
      }
    },
    
    handleEventSaved() {
      this.showForm = false
      this.selectedEvent = null
      this.loadEvents()
    },
    
    formatPeriod(event) {
      const s = event.startDate ? fmtDate(event.startDate) : null
      const e = event.endDate ? fmtDate(event.endDate) : null
      if (s && e) {
        return s === e ? s : `${s} — ${e}`
      }
      return s || e || '-'
    },
    
    formatDateTime(val) {
      return fmtDateTime(val)
    },
    
    toggleClients(eventId) {
      const index = this.expandedEvents.indexOf(eventId)
      if (index > -1) {
        this.expandedEvents.splice(index, 1)
      } else {
        this.expandedEvents.push(eventId)
      }
    },
    
    getFilteredClients(event) {
      const clients = event.clients || []
      const query = this.clientSearchQueries[event.eventId]
      if (!query || !query.trim()) return clients
      
      const searchTerm = query.toLowerCase()
      return clients.filter(client =>
        client.name.toLowerCase().includes(searchTerm) ||
        client.phone.toLowerCase().includes(searchTerm)
      )
    },
    
    previewMessage(event, client) {
      alert(`Prévia:\nEvento: ${event?.eventId}\nCliente: ${client?.name}\nNúmero: ${client?.phone}`)
    },
    
    async sendNow(event, client) {
      try {
        await this.api.post(`/events/${encodeURIComponent(event.eventId)}/send`, {
          phone: client.phone
        })
        alert('Mensagem enviada (solicitada).')
      } catch (err) {
        console.error('Erro ao enviar agora:', err)
        alert('Falha ao solicitar envio.')
      }
    },
    
    getSampleEvents() {
      return [
        {
          eventId: 'boas_vindas',
          startDate: '2024-01-01',
          endDate: '2024-12-31',
          nextRun: '2024-05-25 09:00',
          enabled: true,
          clients: [
            { name: 'João', phone: '+5531999999999', sent: true },
            { name: 'Maria', phone: '+5532888888888', sent: false }
          ]
        },
        {
          eventId: 'aniversarios',
          startDate: '2024-05-01',
          endDate: '2024-07-31',
          nextRun: '2024-05-30 10:00',
          enabled: false,
          clients: [
            { name: 'Carlos', phone: '+5532777777777', sent: false }
          ]
        },
        {
          eventId: 'lembrete_pagamento',
          startDate: '2024-06-01',
          endDate: '2024-06-30',
          nextRun: '2024-06-15 14:30',
          enabled: true,
          clients: [
            { name: 'Ana', phone: '+5532666666666', sent: false },
            { name: 'Pedro', phone: '+5532555555555', sent: true }
          ]
        }
      ]
    }
  }
}
</script>

<style scoped>
/* Container principal */
.events-container {
  min-height: 100vh;
  max-width: 1200px; /* antes era width fixa */
  width: 100%;
  margin: 0 auto;
  padding: 20px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #1a1a1a;
  color: #e5e5e5;
}

html, body, #app {
  min-height: 100%;
  overflow-y: auto;
}

/* Header */
.events-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.events-title {
  font-size: 24px;
  font-weight: 700;
  margin: 0;
  color: #ffffff;
}

.events-actions {
  display: flex;
  gap: 12px;
}

/* Estado vazio */
.empty-state {
  text-align: center;
  padding: 64px 24px;
  background: #2a2a2a;
  border-radius: 12px;
  border: 1px solid #3a3a3a;
}

.empty-state__icon {
  font-size: 64px;
  margin-bottom: 24px;
}

.empty-state__title {
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 12px 0;
  color: #ffffff;
}

.empty-state__description {
  font-size: 16px;
  color: #a0a0a0;
  margin: 0 0 32px 0;
}

/* Filtros */
.events-filters {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  gap: 16px;
  flex-wrap: wrap;
}

.search-box {
  flex: 1;
  max-width: 400px;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #3a3a3a;
  border-radius: 8px;
  font-size: 14px;
  background: #2a2a2a;
  color: #e5e5e5;
}

.search-input:focus {
  outline: none;
  border-color: #4f9cf9;
  box-shadow: 0 0 0 1px #4f9cf9;
}

.search-input::placeholder {
  color: #808080;
}

.legend {
  display: flex;
  gap: 16px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #a0a0a0;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot--active {
  background: #10b981;
}

.status-dot--inactive {
  background: #6b7280;
}

/* Grid de eventos - Corrigindo o scroll */
.events-list {
  width: 100%;
  max-height: calc(100dvh - 160px); /* altura visível, deixa espaço para header/filtros */
  overflow-y: auto; /* ativa scroll vertical */
  padding-right: 4px; /* dá espaço para o scrollbar */
}

.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
  overflow: visible; /* mantém conteúdo expandindo normalmente */
}

/* Cards de eventos */
.event-card {
  background: #2a2a2a;
  border: 1px solid #3a3a3a;
  border-radius: 12px;
  overflow: visible; /* Permite conteúdo expandir */
  transition: all 0.2s ease;
}

.event-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  border-color: #4a4a4a;
}

.event-card--inactive {
  opacity: 0.75;
}

.event-card__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 20px;
  border-bottom: 1px solid #3a3a3a;
  background: #333333;
}

.event-card__title-section {
  flex: 1;
}

.event-card__title {
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 8px 0;
  color: #ffffff;
}

.event-card__status {
  font-size: 12px;
  font-weight: 500;
  padding: 4px 8px;
  border-radius: 999px;
}

.event-card__status--active {
  background: #064e3b;
  color: #10b981;
}

.event-card__status--inactive {
  background: #374151;
  color: #9ca3af;
}

.event-card__actions {
  display: flex;
  gap: 8px;
}

.event-card__content {
  padding: 20px;
}

/* Informações do evento */
.event-info {
  margin-bottom: 16px;
}

.event-info__item {
  display: flex;
  margin-bottom: 8px;
  align-items: baseline;
}

.event-info__label {
  font-weight: 500;
  color: #a0a0a0;
  min-width: 120px;
  font-size: 14px;
}

.event-info__value {
  color: #e5e5e5;
  font-size: 14px;
}

/* Toggle de clientes */
.clients-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #333333;
  border: 1px solid #3a3a3a;
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 12px;
  color: #a0a0a0;
  cursor: pointer;
  width: 100%;
  transition: all 0.2s;
}

.clients-toggle:hover {
  background: #3a3a3a;
  color: #e5e5e5;
}

/* Lista de clientes */
.clients-list {
  margin-top: 16px;
  border-top: 1px solid #3a3a3a;
  padding-top: 16px;
}

.clients-header {
  margin-bottom: 12px;
}

.clients-search-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #3a3a3a;
  border-radius: 6px;
  font-size: 12px;
  background: #2a2a2a;
  color: #e5e5e5;
}

.clients-search-input::placeholder {
  color: #808080;
}

.clients-grid {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.client-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #1f1f1f;
  border: 1px solid #3a3a3a;
  border-radius: 8px;
}

.client-info {
  flex: 1;
}

.client-name {
  font-weight: 500;
  color: #ffffff;
  font-size: 14px;
}

.client-phone {
  color: #a0a0a0;
  font-size: 12px;
  font-family: 'SF Mono', monospace;
}

.client-status {
  font-size: 11px;
  font-weight: 500;
  margin-top: 4px;
}

.client-status--sent {
  color: #10b981;
}

.client-status--pending {
  color: #f59e0b;
}

.client-actions {
  display: flex;
  gap: 6px;
}

/* Paginação */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 16px;
  margin-top: 32px;
}

.pagination-info {
  font-size: 14px;
  color: #a0a0a0;
}

/* Loading state */
.loading-state {
  text-align: center;
  padding: 64px;
  color: #a0a0a0;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #3a3a3a;
  border-top-color: #4f9cf9;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: #2a2a2a;
  border-radius: 12px;
  border: 1px solid #3a3a3a;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3);
  width: 100%;
  max-width: 800px;
  max-height: 90vh;
  overflow: hidden;
  animation: modalIn 0.2s ease-out;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #3a3a3a;
  background: #333333;
}

.modal-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0;
  color: #ffffff;
}

.modal-close {
  font-size: 18px;
  font-weight: 600;
}

.modal-body {
  overflow-y: auto;
  max-height: calc(90vh - 80px);
}

@keyframes modalIn {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(-10px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* Botões */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  white-space: nowrap;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn--primary {
  background: #4f9cf9;
  color: #ffffff;
}

.btn--primary:hover:not(:disabled) {
  background: #3b82f6;
}

.btn--secondary {
  background: #333333;
  color: #e5e5e5;
  border: 1px solid #3a3a3a;
}

.btn--secondary:hover:not(:disabled) {
  background: #3a3a3a;
}

.btn--ghost {
  background: transparent;
  color: #a0a0a0;
  border: 1px solid transparent;
}

.btn--ghost:hover:not(:disabled) {
  background: #333333;
  color: #e5e5e5;
}

.btn--danger:hover:not(:disabled) {
  color: #ef4444;
}

.btn--small {
  padding: 6px 12px;
  font-size: 12px;
}

.btn--tiny {
  padding: 4px 8px;
  font-size: 11px;
}

.btn--large {
  padding: 12px 24px;
  font-size: 16px;
}

/* Responsive */
@media (max-width: 768px) {
  .events-container {
    padding: 16px;
  }
  
  .events-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .events-actions {
    width: 100%;
    justify-content: stretch;
  }
  
  .events-actions .btn {
    flex: 1;
  }
  
  .events-filters {
    flex-direction: column;
    align-items: stretch;
  }
  
  .legend {
    justify-content: center;
  }
  
  .events-grid {
    grid-template-columns: 1fr;
  }
  
  .event-card__header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
  
  .event-card__actions {
    justify-content: stretch;
  }
  
  .event-card__actions .btn {
    flex: 1;
  }
}
</style>