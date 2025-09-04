<template>
  <div class="event-registration">
    <div class="event-registration__header">
      <h1 class="event-registration__title">
        {{ isEdit ? 'Editar Agendamento' : 'Novo Agendamento' }}
      </h1>
      <p class="event-registration__description">
        Configure envio automático por WhatsApp ou Email (SES)
      </p>
    </div>

    <div class="event-registration__content">
      <form @submit.prevent="submit" class="event-form">
        <div class="grid two-cols">
          <div class="event-form__group">
            <label class="event-form__label">Nome (único)</label>
            <input
              class="event-form__input"
              v-model.trim="form.name"
              :disabled="isEdit"
              placeholder="boas-vindas"
              required
            />
          </div>
          <div class="event-form__group">
            <label class="event-form__label">Canal</label>
            <select class="event-form__input" v-model="form.channel">
              <option value="whatsapp">WhatsApp</option>
              <option value="email">Email (SES)</option>
            </select>
          </div>
        </div>

        <!-- Destinatários -->
        <div class="event-form__group">
          <div class="dest-toolbar">
            <label class="event-form__label">Destinatários</label>
            <div class="dest-actions">
              <button type="button" class="btn btn--secondary" @click="addRecipient">Adicionar</button>

              <!-- Importar CSV -->
              <label class="btn btn--secondary" title="Importar CSV">
                Importar CSV
                <input
                  type="file"
                  accept=".csv,text/csv"
                  class="visually-hidden"
                  @change="handleCsvUpload"
                />
              </label>

              <button type="button" class="btn btn--ghost" @click="downloadCsvTemplate">
                Baixar modelo CSV
              </button>
            </div>
          </div>

          <p class="hint">
            CSV com cabeçalho:
            <template v-if="form.channel==='email'">
              <code>name</code>/<code>nome</code>, <code>email</code>/<code>e-mail</code>
            </template>
            <template v-else>
              <code>name</code>/<code>nome</code>, <code>phone</code>/<code>telefone</code>/<code>celular</code>/<code>whatsapp</code>
            </template>
            (delimitador vírgula <code>,</code> ou ponto e vírgula <code>;</code>).
          </p>

          <div class="grid recipients-grid">
            <div v-for="(r, idx) in form.recipients" :key="idx" class="recipient-row">
              <div class="recipient-col">
                <label class="event-form__label">Nome</label>
                <input class="event-form__input" v-model="r.name" placeholder="Ana" />
              </div>
              <div class="recipient-col" v-if="form.channel==='email'">
                <label class="event-form__label">Email</label>
                <input class="event-form__input" v-model="r.email" placeholder="ana@exemplo.com" />
              </div>
              <div class="recipient-col" v-else>
                <label class="event-form__label">Telefone (WhatsApp)</label>
                <input class="event-form__input" v-model="r.phone" placeholder="+5532999999999" />
              </div>

              <button type="button" class="btn btn--ghost" @click="removeRecipient(idx)">Remover</button>
            </div>

            <p v-if="!form.recipients.length" class="event-form__error">
              Adicione manualmente ou importe via CSV.
            </p>

            <p v-if="csvReport" class="csv-report" :class="csvReport.ok ? 'ok' : 'err'">
              {{ csvReport.msg }}
            </p>
          </div>
        </div>

        <!-- Payload (Email ou WhatsApp) -->
        <div class="grid two-cols" v-if="form.channel==='email'">
          <div class="event-form__group">
            <label class="event-form__label">Assunto</label>
            <input class="event-form__input" v-model="form.payload.subject" placeholder="Mensagem" />
          </div>
          <div></div>

          <div class="event-form__group col-span-2">
            <label class="event-form__label">Texto/Corpo</label>
            <textarea
              class="event-form__textarea"
              rows="4"
              v-model="form.payload.text"
              placeholder="Olá {{name}}!"
            ></textarea>
          </div>

          <div class="event-form__group col-span-2">
            <label class="event-form__label">HTML (opcional)</label>
            <textarea
              class="event-form__textarea"
              rows="4"
              v-model="form.payload.html"
              placeholder="<p>Olá {{name}}!</p>"
            ></textarea>
          </div>
        </div>

        <div v-else class="event-form__group">
          <label class="event-form__label">Mensagem padrão (fallback)</label>
          <textarea
            class="event-form__textarea"
            rows="3"
            v-model="form.payload.message"
            placeholder="Olá {{name}}!"
          ></textarea>
          <p class="hint">Para recorrentes, você pode definir uma <b>mensagem por dia</b> abaixo.</p>
        </div>

        <!-- Tipo de agendamento -->
        <div class="event-form__group box">
          <div class="row">
            <input type="checkbox" v-model="oneShot" id="oneshot" />
            <label for="oneshot">Agendar uma única vez (runAt, UTC)</label>
          </div>

          <div v-if="oneShot" class="grid oneshot-grid">
            <div>
              <label class="event-form__label">Executar em (ISO UTC, sufixo Z)</label>
              <input class="event-form__input" v-model="form.runAt" placeholder="2025-09-05T15:00:00Z" />
            </div>
            <div>
              <label class="event-form__label">Timezone</label>
              <input class="event-form__input" value="— não aplicável —" disabled />
            </div>
          </div>

          <div v-else class="grid recurrent-grid">
            <div>
              <label class="event-form__label">Dias da semana</label>
              <div class="dow">
                <label v-for="d in DOW" :key="d.value" class="dow-item">
                  <input type="checkbox" :value="d.value" v-model="form.daysOfWeek" />
                  <span>{{ d.label }}</span>
                </label>
              </div>
            </div>
            <div>
              <label class="event-form__label">Horário (HH:mm)</label>
              <input class="event-form__input" v-model="form.time" placeholder="08:00" />
            </div>
            <div>
              <label class="event-form__label">Timezone</label>
              <input class="event-form__input" v-model="form.timezone" placeholder="America/Sao_Paulo" />
            </div>
          </div>

          <!-- Mensagens por dia (WhatsApp + recorrente) -->
          <div v-if="!oneShot && form.channel==='whatsapp'" class="event-form__group">
            <label class="event-form__label">Mensagens por dia selecionado</label>
            <div class="grid two-cols">
              <div v-for="d in form.daysOfWeek" :key="d" class="event-form__group">
                <label class="event-form__label">{{ labelFor(d) }}</label>
                <textarea
                  class="event-form__textarea"
                  rows="3"
                  v-model="form.payload.messagesByDay[d]"
                  :placeholder="`Mensagem para ${labelFor(d)} (suporta {{name}})`"
                ></textarea>
                <p v-if="!dayHasMessage(d)" class="event-form__error">Obrigatório para {{ labelFor(d) }}</p>
              </div>
            </div>
            <p class="hint">
              Se algum dia não tiver mensagem, o formulário não permitirá salvar.
              O campo "Mensagem padrão" acima será usado como <i>fallback</i> quando não houver mensagem por dia.
            </p>
          </div>

          <!-- Vigência -->
          <div class="event-form__group">
            <label class="event-form__label">Vigência (UTC)</label>
            <div class="grid two-cols">
              <div>
                <label class="event-form__label">Início (startAt, ISO)</label>
                <input class="event-form__input" v-model="form.startAt" placeholder="2025-09-01T00:00:00Z" />
              </div>
              <div>
                <label class="event-form__label">Fim (endAt, ISO)</label>
                <input class="event-form__input" v-model="form.endAt" placeholder="2025-12-31T23:59:59Z" />
              </div>
            </div>
            <p v-if="!validDateRange" class="event-form__error">A data de fim deve ser posterior à data de início.</p>
            <p class="hint">O envio só ocorrerá se o horário atual estiver dentro dessa janela.</p>
          </div>

          <div class="event-form__group" style="margin-top:12px">
            <label class="event-form__checkbox-container">
              <input type="checkbox" v-model="form.enabled" class="event-form__checkbox" />
              <span class="event-form__checkbox-label">Agendamento habilitado</span>
            </label>
          </div>
        </div>

        <div class="event-form__actions">
          <button type="submit" class="btn btn--primary" :disabled="submitting || !isValid">
            {{ submitting ? 'Salvando...' : (isEdit ? 'Salvar alterações' : 'Criar agendamento') }}
          </button>
        </div>
      </form>

      <div v-if="status.show" class="alert" :class="status.ok ? 'alert--success' : 'alert--error'">
        <h3 class="alert__title">{{ status.ok ? '✓ Sucesso' : '✗ Erro' }}</h3>
        <p class="alert__message">{{ status.msg }}</p>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

const API_BASE = 'https://f4wzfjousg.execute-api.us-east-1.amazonaws.com/schedules'
const DOW_LABEL = { SUN: 'Dom', MON: 'Seg', TUE: 'Ter', WED: 'Qua', THU: 'Qui', FRI: 'Sex', SAT: 'Sáb' }

export default {
  name: 'EventForm',
  props: { value: { type: Object, default: null } },
  data() {
    return {
      api: axios.create({ baseURL: API_BASE, headers: { 'Content-Type': 'application/json' } }),
      DOW: [
        { value: 'MON', label: 'Seg' }, { value: 'TUE', label: 'Ter' }, { value: 'WED', label: 'Qua' },
        { value: 'THU', label: 'Qui' }, { value: 'FRI', label: 'Sex' }, { value: 'SAT', label: 'Sáb' }, { value: 'SUN', label: 'Dom' }
      ],
      form: {
        name: '',
        channel: 'whatsapp',
        recipients: [],
        payload: { message: 'Olá {{name}}!', messagesByDay: {} },
        enabled: true,
        // recorrente
        daysOfWeek: ['MON'],
        time: '08:00',
        timezone: 'America/Sao_Paulo',
        // pontual
        runAt: '',
        // vigência
        startAt: '',
        endAt: ''
      },
      oneShot: false,
      submitting: false,
      status: { show: false, ok: true, msg: '' },
      csvReport: null
    }
  },
  computed: {
    isEdit() { return !!this.value?.Name },
    validDateRange() {
      const s = this.form.startAt?.trim(), e = this.form.endAt?.trim()
      if (!s || !e) return true
      const sd = new Date(s), ed = new Date(e)
      if (isNaN(sd.getTime()) || isNaN(ed.getTime())) return true
      return ed > sd
    },
    isValid() {
      if (!this.form.name) return false
      if (!this.form.recipients.length) return false

      if (this.form.channel === 'email') {
        if (!this.form.recipients.every(r => !!r.email)) return false
      } else {
        if (!this.form.recipients.every(r => !!r.phone)) return false
      }

      if (!this.validDateRange) return false

      if (this.oneShot) {
        return !!this.form.runAt
      } else {
        const baseOk = this.form.daysOfWeek.length > 0 && !!this.form.time && !!this.form.timezone
        if (!baseOk) return false
        // Exigir mensagem por dia para WhatsApp (recorrente)
        if (this.form.channel === 'whatsapp') {
          return this.form.daysOfWeek.every(d => !!(this.form.payload?.messagesByDay?.[d] || '').trim())
        }
        return true
      }
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(v) {
        if (!v) return
        // Mapear Schedule -> form
        this.form.name = v.Name || ''
        this.form.channel = v.Channel || 'whatsapp'
        this.form.recipients = Array.isArray(v.Recipients) ? JSON.parse(JSON.stringify(v.Recipients)) : []
        const defaultPayload = this.form.channel === 'email'
          ? { subject: '', text: '', html: '' }
          : { message: 'Olá {{name}}!', messagesByDay: {} }
        const fromPayload = JSON.parse(JSON.stringify(v.Payload || defaultPayload))
        if (this.form.channel === 'whatsapp' && !fromPayload.messagesByDay) fromPayload.messagesByDay = {}
        this.form.payload = fromPayload
        this.form.enabled = !!v.Enabled

        // Vigência
        this.form.startAt = v.StartAt || ''
        this.form.endAt = v.EndAt || ''

        if (v.RunAt) {
          this.oneShot = true
          this.form.runAt = v.RunAt
          this.form.daysOfWeek = []
          this.form.time = ''
          this.form.timezone = ''
        } else {
          this.oneShot = false
          this.form.daysOfWeek = v.DaysOfWeek || ['MON']
          this.form.time = v.Time || '08:00'
          this.form.timezone = v.Timezone || 'America/Sao_Paulo'
          this.form.runAt = ''
        }
      }
    },
    'form.channel'(ch) {
      // Ajusta estrutura dos recipients ao trocar canal
      this.form.recipients = (this.form.recipients || []).map(r => ({
        name: r.name || '',
        email: ch === 'email' ? (r.email || '') : undefined,
        phone: ch === 'whatsapp' ? (r.phone || '') : undefined
      }))
      // Ajusta payload mínimo por canal
      if (ch === 'email') {
        this.form.payload = {
          subject: this.form.payload.subject || '',
          text: this.form.payload.text || '',
          html: this.form.payload.html || ''
        }
      } else {
        this.form.payload = {
          message: this.form.payload.message || 'Olá {{name}}!',
          messagesByDay: this.form.payload.messagesByDay || {}
        }
      }
    },
    // Sempre que marcar um dia, garante a chave no messagesByDay
    'form.daysOfWeek': {
      deep: true,
      handler(days) {
        if (this.form.channel !== 'whatsapp') return
        this.form.payload.messagesByDay = this.form.payload.messagesByDay || {}
        days.forEach(d => {
          if (!this.form.payload.messagesByDay[d]) this.$set(this.form.payload.messagesByDay, d, '')
        })
        // limpa chaves de dias desmarcados
        Object.keys(this.form.payload.messagesByDay).forEach(k => {
          if (!days.includes(k)) this.$delete(this.form.payload.messagesByDay, k)
        })
      }
    }
  },
  methods: {
    labelFor(d) { return DOW_LABEL[d] || d },
    dayHasMessage(d) { return !!(this.form.payload?.messagesByDay?.[d] || '').trim() },

    addRecipient() {
      this.form.recipients.push({
        name: '',
        phone: this.form.channel === 'whatsapp' ? '' : undefined,
        email: this.form.channel === 'email' ? '' : undefined
      })
    },
    removeRecipient(i) { this.form.recipients.splice(i, 1) },

    // ===== CSV =====
    normalizeHeader(s) {
      return (s || '')
        .toString()
        .trim()
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9_ -]/g, '')
    },
    detectDelimiter(firstLine) {
      const commas = (firstLine.match(/,/g) || []).length
      const semis = (firstLine.match(/;/g) || []).length
      return semis > commas ? ';' : ','
    },
    parseCsvText(text) {
      const lines = text.split(/\r?\n/).filter(l => l.trim() !== '')
      if (!lines.length) return { headers: [], rows: [] }
      const delimiter = this.detectDelimiter(lines[0])
      const split = (line) => {
        const out = []
        let cur = '', inQuotes = false
        for (let i = 0; i < line.length; i++) {
          const ch = line[i]
          if (ch === '"') {
            if (line[i + 1] === '"') { cur += '"'; i++; continue }
            inQuotes = !inQuotes
          } else if (ch === delimiter && !inQuotes) {
            out.push(cur); cur = ''
          } else {
            cur += ch
          }
        }
        out.push(cur)
        return out.map(s => s.trim())
      }
      const headers = split(lines[0]).map(this.normalizeHeader)
      const rows = lines.slice(1).map(split)
      return { headers, rows }
    },
    handleCsvUpload(e) {
      const file = e.target.files && e.target.files[0]
      if (!file) return
      const reader = new FileReader()
      reader.onload = () => {
        try {
          const text = reader.result?.toString() || ''
          const { headers, rows } = this.parseCsvText(text)
          if (!headers.length || !rows.length) {
            this.csvReport = { ok: false, msg: 'CSV vazio ou sem cabeçalho.' }
            return
          }
          const hset = new Map(headers.map((h, i) => [h, i]))
          const nameKey = ['name', 'nome'].find(k => hset.has(k))
          const emailKey = ['email', 'e-mail', 'e_mail'].find(k => hset.has(k))
          const phoneKey = ['phone', 'telefone', 'celular', 'whatsapp'].find(k => hset.has(k))
          const needsEmail = this.form.channel === 'email'
          const okHeaders = needsEmail ? (nameKey && emailKey) : (nameKey && phoneKey)
          if (!okHeaders) {
            this.csvReport = {
              ok: false,
              msg: needsEmail
                ? 'Cabeçalho inválido. Esperado: name/nome, email/e-mail.'
                : 'Cabeçalho inválido. Esperado: name/nome, phone/telefone/celular/whatsapp.'
            }
            return
          }
          const existingKeySet = new Set(
            (this.form.recipients || [])
              .map(r => (needsEmail ? (r.email || '').toLowerCase() : (r.phone || '')))
              .filter(Boolean)
          )
          let imported = 0, skipped = 0
          const newRecipients = []
          for (const row of rows) {
            const name = row[hset.get(nameKey)]?.trim()
            const email = emailKey ? (row[hset.get(emailKey)] || '').trim() : ''
            const phone = phoneKey ? (row[hset.get(phoneKey)] || '').trim() : ''
            if (!name && !email && !phone) { skipped++; continue }
            if (needsEmail) {
              if (!email || !this.isValidEmail(email)) { skipped++; continue }
              const k = email.toLowerCase()
              if (existingKeySet.has(k)) { skipped++; continue }
              existingKeySet.add(k)
              newRecipients.push({ name, email }); imported++
            } else {
              if (!phone || !this.isLikelyPhone(phone)) { skipped++; continue }
              const normalizedPhone = phone.replace(/\s+/g, '')
              if (existingKeySet.has(normalizedPhone)) { skipped++; continue }
              existingKeySet.add(normalizedPhone)
              newRecipients.push({ name, phone: normalizedPhone }); imported++
            }
          }
          this.form.recipients = [...this.form.recipients, ...newRecipients]
          this.csvReport = { ok: true, msg: `Importados ${imported}. Ignorados ${skipped}. Total agora: ${this.form.recipients.length}.` }
          e.target.value = ''
        } catch (err) {
          console.error(err); this.csvReport = { ok: false, msg: 'Erro ao processar o CSV.' }
        }
      }
      reader.readAsText(file, 'utf-8')
    },
    downloadCsvTemplate() {
      const needsEmail = this.form.channel === 'email'
      const headers = needsEmail ? ['name', 'email'] : ['name', 'phone']
      const sample = needsEmail
        ? [['Ana', 'ana@exemplo.com'], ['Bruno', 'bruno@exemplo.com']]
        : [['Ana', '+5532987654321'], ['Bruno', '+5531999999999']]
      const csvLines = [ headers.join(','), ...sample.map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')) ]
      const csv = csvLines.join('\n')
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a'); a.href = url
      a.download = needsEmail ? 'recipients_email_template.csv' : 'recipients_whatsapp_template.csv'
      document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url)
    },

    isValidEmail(email) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) },
    isLikelyPhone(phone) { const digits = phone.replace(/\D/g, ''); return digits.length >= 10 && digits.length <= 15 },

    // ===== Submit =====
    buildBackendBody() {
      const base = {
        name: this.form.name,
        channel: this.form.channel,
        recipients: this.form.recipients,
        payload: this.form.channel === 'email'
          ? {
              subject: this.form.payload?.subject || 'Mensagem',
              text: this.form.payload?.text || '',
              html: this.form.payload?.html || ''
            }
          : {
              message: this.form.payload?.message || 'Olá {{name}}!',
              messagesByDay: (!this.oneShot && this.form.channel === 'whatsapp')
                ? this.form.daysOfWeek.reduce((acc, d) => {
                    const v = (this.form.payload?.messagesByDay?.[d] || '').trim()
                    if (v) acc[d] = v
                    return acc
                  }, {})
                : undefined
            },
        enabled: !!this.form.enabled,
        startAt: (this.form.startAt || '').trim() || undefined,
        endAt: (this.form.endAt || '').trim() || undefined
      }

      if (this.oneShot) {
        return { ...base, runAt: this.form.runAt }
      }
      return {
        ...base,
        daysOfWeek: this.form.daysOfWeek,
        time: this.form.time,
        timezone: this.form.timezone || 'America/Sao_Paulo'
      }
    },

    async submit() {
      if (!this.isValid) return
      this.submitting = true
      this.status.show = false
      try {
        const body = this.buildBackendBody()
        if (this.isEdit) {
          await this.api.put(`/${encodeURIComponent(this.form.name)}`, body)
          this.ok('Agendamento atualizado com sucesso.')
        } else {
          const res = await this.api.post('', body)
          if (res.status === 200) this.ok('Agendamento criado com sucesso.')
        }
        this.$emit('saved')
      } catch (e) {
        console.error('Falha ao salvar:', e.response?.data || e)
        const msg = e?.response?.data?.error || 'Falha ao salvar. Verifique CORS do POST e os campos obrigatórios.'
        this.err(msg)
      } finally { this.submitting = false }
    },

    ok(msg) { this.status = { show: true, ok: true, msg } },
    err(msg) { this.status = { show: true, ok: false, msg } }
  }
}
</script>

<style scoped>
.event-registration { min-height: 100%; color: #e5e5e5; }
.event-registration__header { margin-bottom: 24px; text-align: center; }
.event-registration__title { font-size: 26px; font-weight: 700; margin-bottom: 8px; color: #fff; }
.event-registration__description { color: #a0a0a0; font-size: 16px; }

/* Form */
.event-form { background: #2a2a2a; padding: 24px; border-radius: 14px; border: 1px solid #3a3a3a; margin-bottom: 24px; }
.event-form__group { margin-bottom: 16px; }
.event-form__label { display: block; margin-bottom: 8px; font-weight: 600; color: #fff; }
.event-form__input, .event-form__textarea { background-color: #1f1f1f; color: #e5e5e5; width: 100%; padding: 12px; border: 1px solid #3a3a3a; border-radius: 10px; font-size: 16px; }
.event-form__textarea { min-height: 96px; }
.event-form__input:focus, .event-form__textarea:focus { outline: none; border-color: #4f9cf9; box-shadow: 0 0 0 1px #4f9cf9; }
.event-form__input::placeholder, .event-form__textarea::placeholder { color: #808080; }
.event-form__error { color: #ef4444; font-size: 14px; margin-top: 8px; }
.grid.two-cols { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.col-span-2 { grid-column: 1 / 3; }
.dest-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.dest-actions { display: flex; gap: 8px; align-items: center; }
.visually-hidden { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0; }
.recipients-grid { display: grid; gap: 8px; }
.recipient-row { display: grid; grid-template-columns: 1fr 1fr auto; gap: 8px; align-items: end; }
.recipient-col { display: flex; flex-direction: column; gap: 6px; }
.hint { color: #a0a0a0; font-size: 13px; margin-top: 4px; }
.csv-report { font-size: 13px; margin-top: 8px; }
.csv-report.ok { color: #10b981; }
.csv-report.err { color: #ef4444; }
/* Box de agendamento */
.box { border: 1px solid #3a3a3a; border-radius: 10px; padding: 16px; }
.row { display: flex; gap: 12px; align-items: center; margin-bottom: 12px; }
.oneshot-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 16px; }
.recurrent-grid { display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 16px; }
.dow { display: flex; gap: 8px; flex-wrap: wrap; }
.dow-item { display: flex; align-items: center; gap: 6px; }
.event-form__checkbox { width: 18px; height: 18px; accent-color: #4f9cf9; }
.event-form__checkbox-container { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.event-form__checkbox-label { color: #e5e5e5; }
.event-form__actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 24px; }
/* Buttons */
.btn { padding: 12px 16px; border: none; border-radius: 10px; font-weight: 600; cursor: pointer; transition: all .2s; }
.btn--primary { background: #4f9cf9; color: #fff; }
.btn--primary:hover:not(:disabled) { background: #3b82f6; }
.btn--secondary { background: #333; border: 1px solid #3a3a3a; color: #e5e5e5; }
.btn--secondary:hover:not(:disabled) { background: #3a3a3a; }
.btn--ghost { background: transparent; border: 1px solid #3a3a3a; color: #e5e5e5; }
.btn:disabled { opacity: .6; cursor: not-allowed; }
/* Alerts */
.alert { padding: 16px; border-radius: 10px; margin-bottom: 24px; }
.alert--success { background: #064e3b; border: 1px solid #10b981; color: #10b981; }
.alert--error { background: #7f1d1d; border: 1px solid #ef4444; color: #ef4444; }
.alert__title { font-weight: 700; margin: 0 0 8px 0; }
.alert__message { margin: 0; }
/* Responsivo */
@media (max-width: 768px) {
  .grid.two-cols { grid-template-columns: 1fr; }
  .col-span-2 { grid-column: 1 / 2; }
  .recipient-row { grid-template-columns: 1fr; }
  .oneshot-grid, .recurrent-grid { grid-template-columns: 1fr; }
}
</style>
