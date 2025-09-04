<template>
  <div class="events-container">
    <div class="events-header">
      <h1 class="events-title">Agendamentos</h1>
      <div class="events-actions">
        <button class="btn btn--secondary" @click="loadSchedules" :disabled="loading">
          <span v-if="loading">Carregando...</span>
          <span v-else>Recarregar</span>
        </button>
        <button class="btn btn--primary" @click="openCreateForm">Novo Agendamento</button>
      </div>
    </div>

    <!-- Estado vazio -->
    <div v-if="!loading && !schedules.length" class="empty-state">
      <div class="empty-state__icon">⏱️</div>
      <h2 class="empty-state__title">Sem agendamentos</h2>
      <p class="empty-state__description">Crie seu primeiro agendamento.</p>
      <button class="btn btn--primary btn--large" @click="openCreateForm">Criar</button>
    </div>

    <!-- Lista -->
    <div v-else-if="!loading" class="events-list">
      <div class="events-filters">
        <div class="search-box">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar por nome, canal ou expressão..."
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

      <div class="events-grid">
        <div
          v-for="it in filteredSchedules"
          :key="it.eventId"
          class="event-card"
          :class="{ 'event-card--inactive': !it.enabled }"
        >
          <!-- Header do card -->
          <div class="event-card__header">
            <div class="event-card__title-section">
              <h3 class="event-card__title">{{ it.eventId }}</h3>
              <div class="flex gap-2 items-center">
                <span
                  class="event-card__status"
                  :class="it.enabled ? 'event-card__status--active' : 'event-card__status--inactive'"
                >
                  {{ it.enabled ? 'Habilitado' : 'Desabilitado' }}
                </span>
                <span class="pill" :title="it.channel">
                  {{ it.channel === 'email' ? 'Email' : 'WhatsApp' }}
                </span>
              </div>
            </div>

            <div class="event-card__actions">
              <button
                class="btn btn--small btn--ghost"
                @click="toggleEnabled(it)"
                :disabled="togglingId === it.eventId"
                :title="it.enabled ? 'Desabilitar' : 'Habilitar'"
              >
                <template v-if="it.enabled">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                       xmlns="http://www.w3.org/2000/svg">
                    <path d="M8 5V19M16 5V19"
                          stroke="currentColor" stroke-width="2"
                          stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                </template>
                <template v-else>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                       xmlns="http://www.w3.org/2000/svg">
                    <path d="M16.6582 9.28638C18.098 10.1862 18.8178 10.6361 19.0647 11.2122C19.2803 11.7152 19.2803 12.2847 19.0647 12.7878C18.8178 13.3638 18.098 13.8137 16.6582 14.7136L9.896 18.94C8.29805 19.9387 7.49907 20.4381 6.83973 20.385C6.26501 20.3388 5.73818 20.0469 5.3944 19.584C5 19.053 5 18.1108 5 16.2264V7.77357C5 5.88919 5 4.94701 5.3944 4.41598C5.73818 3.9531 6.26501 3.66111 6.83973 3.6149C7.49907 3.5619 8.29805 4.06126 9.896 5.05998L16.6582 9.28638Z"
                          stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
                  </svg>
                </template>
              </button>

              <button class="btn btn--small btn--ghost" @click="editSchedule(it)" title="Editar">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                     xmlns="http://www.w3.org/2000/svg">
                  <path d="M21.2799 6.40005L11.7399 15.94C10.7899 16.89 7.96987 17.33 7.33987 16.7C6.70987 16.07 7.13987 13.25 8.08987 12.3L17.6399 2.75002C17.8754 2.49308 18.1605 2.28654 18.4781 2.14284C18.7956 1.99914 19.139 1.92124 19.4875 1.9139C19.8359 1.90657 20.1823 1.96991 20.5056 2.10012C20.8289 2.23033 21.1225 2.42473 21.3686 2.67153C21.6147 2.91833 21.8083 3.21243 21.9376 3.53609C22.0669 3.85976 22.1294 4.20626 22.1211 4.55471C22.1128 4.90316 22.0339 5.24635 21.8894 5.5635C21.7448 5.88065 21.5375 6.16524 21.2799 6.40005V6.40005Z"
                        stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M11 4H6C4.93913 4 3.92178 4.42142 3.17163 5.17157C2.42149 5.92172 2 6.93913 2 8V18C2 19.0609 2.42149 20.0783 3.17163 20.8284C3.92178 21.5786 4.93913 22 6 22H17C19.21 22 20 20.2 20 18V13"
                        stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>

              <button class="btn btn--small btn--ghost btn--danger" @click="confirmDelete(it)" title="Excluir">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                     xmlns="http://www.w3.org/2000/svg">
                  <path d="M3 3L21 21M18 6L17.6 12M17.2498 17.2527L17.1991 18.0129C17.129 19.065 17.0939 19.5911 16.8667 19.99C16.6666 20.3412 16.3648 20.6235 16.0011 20.7998C15.588 21 15.0607 21 14.0062 21H9.99377C8.93927 21 8.41202 21 7.99889 20.7998C7.63517 20.6235 7.33339 20.3412 7.13332 19.99C6.90607 19.5911 6.871 19.065 6.80086 18.0129L6 6H4M16 6L15.4559 4.36754C15.1837 3.55086 14.4194 3 13.5585 3H10.4416C9.94243 3 9.47576 3.18519 9.11865 3.5M11.6133 6H20M14 14V17M10 10V17"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
            </div>
          </div>

          <!-- Conteúdo -->
          <div class="event-card__content">
            <div class="event-info">
              <div class="event-info__item">
                <label class="event-info__label">Modelo:</label>
                <span class="event-info__value">{{ it.runAt ? 'Pontual (at)' : 'Recorrente (cron)' }}</span>
              </div>
              <div class="event-info__item" v-if="!it.runAt">
                <label class="event-info__label">Quando:</label>
                <span class="event-info__value">{{ humanRecurring(it) }}</span>
              </div>
              <div class="event-info__item" v-else>
                <label class="event-info__label">Executar em:</label>
                <span class="event-info__value">{{ formatDateTime(it.runAt) }}</span>
              </div>
              <div class="event-info__item">
                <label class="event-info__label">Expressão:</label>
                <span class="event-info__value font-mono">{{ it.scheduleExpression }}</span>
              </div>

              <div class="event-info__item">
                <label class="event-info__label">Vigência:</label>
                <span class="event-info__value">
                  <template v-if="it.startAt || it.endAt">
                    {{ it.startAt ? formatDateTime(it.startAt) : '—' }} — {{ it.endAt ? formatDateTime(it.endAt) : '—' }}
                  </template>
                  <template v-else>—</template>
                </span>
              </div>

              <div class="event-info__item">
                <label class="event-info__label">Destinatários:</label>
                <span class="event-info__value">{{ it.recipients.length }}</span>
              </div>
            </div>

            <button
              class="clients-toggle"
              @click="toggleRecipients(it.eventId)"
              v-if="it.recipients.length"
            >
              {{ expanded.includes(it.eventId) ? '▼ Ocultar' : '▶ Ver' }} destinatários
            </button>

            <div v-if="expanded.includes(it.eventId)" class="clients-list">
              <div class="clients-grid">
                <div v-for="(r, idx) in it.recipients" :key="idx" class="client-card">
                  <div class="client-info">
                    <div class="client-name">{{ r.name || '(sem nome)' }}</div>
                    <div class="client-phone">
                      <template v-if="it.channel === 'email'">{{ r.email }}</template>
                      <template v-else>{{ r.phone }}</template>
                    </div>
                  </div>
                  <div class="client-actions">
                    <button class="btn btn--tiny btn--ghost" @click="previewMessage(it, r)">Prévia</button>
                  </div>
                </div>
              </div>
            </div>
          </div> <!-- /content -->
        </div>
      </div>

      <!-- Paginação -->
      <div v-if="totalPages > 1" class="pagination">
        <button class="btn btn--small btn--ghost" @click="currentPage--" :disabled="currentPage <= 1">← Anterior</button>
        <span class="pagination-info">Página {{ currentPage }} de {{ totalPages }}</span>
        <button class="btn btn--small btn--ghost" @click="currentPage++" :disabled="currentPage >= totalPages">Próxima →</button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading-state">
      <div class="loading-spinner"></div>
      <p>Carregando agendamentos...</p>
    </div>

    <!-- Modal -->
    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal-content">
        <div class="modal-header">
          <h2 class="modal-title">{{ selected ? 'Editar Agendamento' : 'Novo Agendamento' }}</h2>
          <button class="btn btn--ghost btn--small modal-close" @click="closeForm">✕</button>
        </div>
        <div class="modal-body">
          <EventForm :value="selected" @saved="handleSaved" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import EventForm from './EventForm.vue'

const API_BASE = 'https://f4wzfjousg.execute-api.us-east-1.amazonaws.com/schedules'
const tz = 'America/Sao_Paulo'
const DOW_LABEL = { SUN: 'Dom', MON: 'Seg', TUE: 'Ter', WED: 'Qua', THU: 'Qui', FRI: 'Sex', SAT: 'Sáb' }
const DOW_KEYS = ['MON','TUE','WED','THU','FRI','SAT','SUN']

function fmtDateTime(d) {
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
  name: 'SchedulesIndex',
  components: { EventForm },
  data() {
    return {
      api: axios.create({ baseURL: API_BASE }),
      loading: false,
      showForm: false,
      schedules: [],
      selected: null,
      togglingId: null,
      deletingId: null,
      searchQuery: '',
      expanded: [],
      currentPage: 1,
      pageSize: 6,
    }
  },
  computed: {
    filteredSchedules() {
      let list = this.schedules
      const q = this.searchQuery.trim().toLowerCase()
      if (q) {
        list = list.filter(it =>
          it.eventId.toLowerCase().includes(q) ||
          (it.channel || '').toLowerCase().includes(q) ||
          (it.scheduleExpression || '').toLowerCase().includes(q)
        )
      }
      const start = (this.currentPage - 1) * this.pageSize
      const end = start + this.pageSize
      return list.slice(start, end)
    },
    totalPages() { return Math.ceil(this.schedules.length / this.pageSize) || 1 }
  },
  mounted() {
    this.loadSchedules()
    window.addEventListener('keydown', this.onKeydown)
  },
  beforeUnmount() { window.removeEventListener('keydown', this.onKeydown) },
  methods: {
    onKeydown(e) { if (e.key === 'Escape' && this.showForm) this.closeForm() },
    openCreateForm() { this.selected = null; this.showForm = true },
    closeForm() { this.showForm = false; this.selected = null },
    formatDateTime: fmtDateTime,
    humanRecurring(it) {
      const days = (it.daysOfWeek || []).map(d => DOW_LABEL[d] || d).join(', ')
      const time = it.time || '—'
      const tzs = it.timezone || 'America/Sao_Paulo'
      return days ? `${days} às ${time} (${tzs})` : '—'
    },
    toggleRecipients(id) {
      const i = this.expanded.indexOf(id)
      if (i > -1) this.expanded.splice(i, 1); else this.expanded.push(id)
    },
    dayKeyFor(date, timezone) {
      try {
        // usa o fuso para aproximar o dia corrente do envio
        const now = new Date()
        const fmt = new Intl.DateTimeFormat('en-US', { timeZone: timezone || 'UTC', weekday: 'short' })
        const k = fmt.format(now).toUpperCase().slice(0,3) // MON/TUE...
        return k === 'THU' ? 'THU' : k // manter igual
      } catch { return 'MON' }
    },
    previewMessage(it, r) {
      const chan = it.channel
      let preview = ''
      if (chan === 'email') {
        const subj = (it.payload?.subject || 'Mensagem').replace(/\{\{(name|nome)\}\}/g, r.name || '')
        const text = (it.payload?.text || it.payload?.html || '').replace(/\{\{(name|nome)\}\}/g, r.name || '')
        preview = `Assunto: ${subj}\n\n${text}`
      } else {
        const k = this.dayKeyFor(new Date(), it.timezone)
        const byDay = it.payload?.messagesByDay || {}
        const base = it.payload?.message || ''
        const chosen = byDay[k] || base
        const msg = (chosen || '').replace(/\{\{(name|nome)\}\}/g, r.name || '')
        preview = msg
      }
      alert(preview || '(sem conteúdo)')
    },

    async loadSchedules() {
      this.loading = true
      try {
        const { data } = await this.api.get('') // GET /schedules
        const items = Array.isArray(data?.items)
          ? data.items
          : Array.isArray(data) ? data
          : []
        this.schedules = items.map(row => ({
          eventId: row.Name,
          channel: row.Channel,
          recipients: row.Recipients || [],
          payload: row.Payload || {},
          enabled: !!row.Enabled,
          scheduleExpression: row.ScheduleExpression || '',
          timezone: row.Timezone || null,
          daysOfWeek: row.DaysOfWeek || [],
          time: row.Time || null,
          runAt: row.RunAt || null,
          // vigência
          startAt: row.StartAt || null,
          endAt: row.EndAt || null,
        }))
      } catch (e) {
        console.error('Falha ao carregar:', e)
        this.schedules = []
      } finally { this.loading = false }
    },

    editSchedule(it) {
      this.selected = {
        Name: it.eventId,
        Channel: it.channel,
        Recipients: JSON.parse(JSON.stringify(it.recipients || [])),
        Payload: JSON.parse(JSON.stringify(it.payload || {})),
        Enabled: it.enabled,
        ScheduleExpression: it.scheduleExpression,
        Timezone: it.timezone,
        DaysOfWeek: it.daysOfWeek,
        Time: it.time,
        RunAt: it.runAt,
        StartAt: it.startAt,
        EndAt: it.endAt,
      }
      this.showForm = true
    },

    async toggleEnabled(it) {
      if (!it?.eventId) return
      this.togglingId = it.eventId
      try {
        await this.api.patch(`/${encodeURIComponent(it.eventId)}`, { enabled: !it.enabled })
        it.enabled = !it.enabled
      } catch (e) {
        console.error('Erro ao alternar enabled:', e)
        alert('Não foi possível atualizar o status.')
      } finally { this.togglingId = null }
    },

    async confirmDelete(it) {
      if (!it?.eventId || this.deletingId) return
      const ok = confirm(`Excluir o agendamento "${it.eventId}"?`)
      if (!ok) return
      this.deletingId = it.eventId
      try {
        await this.api.delete(`/${encodeURIComponent(it.eventId)}`)
        this.schedules = this.schedules.filter(x => x.eventId !== it.eventId)
      } catch (e) {
        console.error('Erro ao excluir:', e)
        alert('Falha ao excluir.')
      } finally { this.deletingId = null }
    },

    handleSaved() {
      this.showForm = false
      this.selected = null
      this.loadSchedules()
    }
  }
}
</script>

<style scoped>
/* (estilos iguais aos seus, mantidos) */
.events-container { min-height: 100vh; max-width: 1200px; width: 100%; margin: 0 auto; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #1a1a1a; color: #e5e5e5; }
.events-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
.events-title { font-size: 24px; font-weight: 700; margin: 0; color: #ffffff; }
.events-actions { display: flex; gap: 12px; }
.empty-state { text-align: center; padding: 64px 24px; background: #2a2a2a; border-radius: 12px; border: 1px solid #3a3a3a; }
.empty-state__icon { font-size: 64px; margin-bottom: 24px; }
.empty-state__title { font-size: 24px; font-weight: 600; margin: 0 0 12px 0; color: #fff; }
.empty-state__description { font-size: 16px; color: #a0a0a0; margin: 0 0 32px 0; }
.events-filters { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; gap: 16px; flex-wrap: wrap; }
.search-box { flex: 1; max-width: 400px; }
.search-input { width: 100%; padding: 12px 16px; border: 1px solid #3a3a3a; border-radius: 8px; font-size: 14px; background: #2a2a2a; color: #e5e5e5; }
.search-input:focus { outline: none; border-color: #4f9cf9; box-shadow: 0 0 0 1px #4f9cf9; }
.search-input::placeholder { color: #808080; }
.legend { display: flex; gap: 16px; }
.legend-item { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #a0a0a0; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-dot--active { background: #10b981; }
.status-dot--inactive { background: #6b7280; }
.pill { padding: 2px 8px; border-radius: 999px; border: 1px solid #3a3a3a; font-size: 12px; }
.events-list { width: 100%; max-height: calc(100dvh - 160px); overflow-y: auto; padding-right: 4px; }
.events-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; margin-bottom: 32px; }
.event-card { background: #2a2a2a; border: 1px solid #3a3a3a; border-radius: 12px; transition: all .2s; }
.event-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,.3); border-color: #4a4a4a; }
.event-card--inactive { opacity: .75; }
.event-card__header { display: flex; justify-content: space-between; align-items: flex-start; padding: 20px; border-bottom: 1px solid #3a3a3a; background: #333; }
.event-card__title { font-size: 18px; font-weight: 600; margin: 0 0 8px 0; color: #fff; }
.event-card__status { font-size: 12px; font-weight: 500; padding: 4px 8px; border-radius: 999px; }
.event-card__status--active { background: #064e3b; color: #10b981; }
.event-card__status--inactive { background: #374151; color: #9ca3af; }
.event-card__actions { display: flex; gap: 8px; }
.event-card__content { padding: 20px; }
.event-info { margin-bottom: 16px; }
.event-info__item { display: flex; margin-bottom: 8px; align-items: baseline; }
.event-info__label { font-weight: 500; color: #a0a0a0; min-width: 120px; font-size: 14px; }
.event-info__value { color: #e5e5e5; font-size: 14px; }
.clients-toggle { display: flex; align-items: center; gap: 8px; background: #333; border: 1px solid #3a3a3a; border-radius: 6px; padding: 8px 12px; font-size: 12px; color: #a0a0a0; cursor: pointer; width: 100%; }
.clients-toggle:hover { background: #3a3a3a; color: #e5e5e5; }
.clients-list { margin-top: 16px; border-top: 1px solid #3a3a3a; padding-top: 16px; }
.clients-grid { display: flex; flex-direction: column; gap: 8px; }
.client-card { display: flex; justify-content: space-between; align-items: center; padding: 12px; background: #1f1f1f; border: 1px solid #3a3a3a; border-radius: 8px; }
.client-name { font-weight: 500; color: #fff; font-size: 14px; }
.client-phone { color: #a0a0a0; font-size: 12px; }
.pagination { display: flex; justify-content: center; align-items: center; gap: 16px; margin-top: 32px; }
.pagination-info { font-size: 14px; color: #a0a0a0; }
.loading-state { text-align: center; padding: 64px; color: #a0a0a0; }
.loading-spinner { width: 32px; height: 32px; border: 3px solid #3a3a3a; border-top-color: #4f9cf9; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 16px; }
@keyframes spin { to { transform: rotate(360deg); } }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,.7); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 20px; }
.modal-content { background: #2a2a2a; border-radius: 12px; border: 1px solid #3a3a3a; box-shadow: 0 20px 25px -5px rgba(0,0,0,.3); width: 100%; max-width: 900px; max-height: 90vh; overflow: hidden; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 20px 24px; border-bottom: 1px solid #3a3a3a; background: #333; }
.modal-title { font-size: 20px; font-weight: 600; margin: 0; color: #fff; }
.modal-body { max-height: calc(90vh - 80px); overflow-y: auto; padding: 16px; }
.btn { display: inline-flex; align-items: center; justify-content: center; padding: 8px 16px; font-size: 14px; font-weight: 500; border-radius: 6px; border: none; cursor: pointer; transition: all .2s; text-decoration: none; white-space: nowrap; }
.btn:disabled { opacity: .6; cursor: not-allowed; }
.btn--primary { background: #4f9cf9; color: #fff; }
.btn--primary:hover:not(:disabled) { background: #3b82f6; }
.btn--secondary { background: #333; color: #e5e5e5; border: 1px solid #3a3a3a; }
.btn--secondary:hover:not(:disabled) { background: #3a3a3a; }
.btn--ghost { background: transparent; color: #a0a0a0; border: 1px solid transparent; }
.btn--ghost:hover:not(:disabled) { background: #333; color: #e5e5e5; }
.btn--danger:hover:not(:disabled) { color: #ef4444; }
.btn--small { padding: 6px 12px; font-size: 12px; }
.btn--tiny { padding: 4px 8px; font-size: 11px; }
.btn--large { padding: 12px 24px; font-size: 16px; }
@media (max-width: 768px) {
  .events-container { padding: 16px; }
  .events-header { flex-direction: column; align-items: stretch; }
  .events-actions { width: 100%; }
  .events-actions .btn { flex: 1; }
  .events-filters { flex-direction: column; align-items: stretch; }
  .legend { justify-content: center; }
  .events-grid { grid-template-columns: 1fr; }
  .event-card__header { flex-direction: column; gap: 12px; align-items: stretch; }
  .event-card__actions { justify-content: stretch; }
  .event-card__actions .btn { flex: 1; }
}
</style>
