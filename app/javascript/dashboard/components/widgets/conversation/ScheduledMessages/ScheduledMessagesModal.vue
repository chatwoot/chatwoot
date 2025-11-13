<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Spinner from 'shared/components/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CannedResponse from 'dashboard/components/widgets/conversation/CannedResponse.vue';
import VariableList from 'dashboard/components/widgets/conversation/VariableList.vue';

export default {
  components: {
    Spinner,
    NextButton,
    CannedResponse,
    VariableList,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  emits: ['close', 'update:show'],
  data() {
    return {
      formData: {
        content: '',
        date: '',
        hour: '09',
        minute: '00',
      },
      editingId: null,
      showCannedMenu: false,
      showVariableMenu: false,
      cannedSearchKey: '',
      variableSearchKey: '',
      cursorPosition: 0,
      statusFilter: 'all',
      showFilterMenu: false,
    };
  },
  computed: {
    ...mapGetters({
      scheduledMessagesGetter: 'scheduledMessages/getScheduledMessages',
      uiFlags: 'scheduledMessages/getUIFlags',
    }),
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    scheduledMessages() {
      return this.scheduledMessagesGetter(this.conversationId);
    },
    filteredScheduledMessages() {
      if (this.statusFilter === 'all') {
        return this.scheduledMessages;
      }
      return this.scheduledMessages.filter(msg => msg.status === this.statusFilter);
    },
    isEditMode() {
      return this.editingId !== null;
    },
    isSubmitting() {
      return this.uiFlags.isCreating || this.uiFlags.isUpdating;
    },
  },
  watch: {
    localShow(newVal) {
      if (newVal) {
        this.fetchMessages();
        this.resetForm();
      }
    },
  },
  mounted() {
    if (this.show) {
      this.fetchMessages();
    }
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async fetchMessages() {
      try {
        await this.$store.dispatch(
          'scheduledMessages/get',
          this.conversationId
        );
      } catch (error) {
        console.error('Erro ao buscar mensagens:', error);
      }
    },
    resetForm() {
      this.formData = {
        content: '',
        date: '',
        hour: '09',
        minute: '00',
      };
      this.editingId = null;
    },
    async handleSubmit() {
      if (!this.formData.content || !this.formData.date || !this.formData.hour || !this.formData.minute) {
        useAlert('Preencha todos os campos obrigatórios');
        return;
      }

      try {
        const scheduledDateTime = `${this.formData.date}T${this.formData.hour}:${this.formData.minute}:00`;

        if (this.isEditMode) {
          // No update, não enviamos conversation_id pois a mensagem já está vinculada
          const updateData = {
            id: this.editingId,
            content: this.formData.content,
            scheduled_at: new Date(scheduledDateTime).toISOString(),
            private: false,
          };
          await this.$store.dispatch('scheduledMessages/update', updateData);
          useAlert('Mensagem atualizada!');
        } else {
          // No create, enviamos conversation_id
          const createData = {
            conversation_id: this.conversationId,
            content: this.formData.content,
            scheduled_at: new Date(scheduledDateTime).toISOString(),
            private: false,
          };
          await this.$store.dispatch('scheduledMessages/create', createData);
          useAlert('Mensagem agendada!');
        }

        this.resetForm();
        await this.fetchMessages();
      } catch (error) {
        const errorMessage = error.response?.data?.errors?.join(', ') || error.message || 'Erro ao agendar mensagem';
        useAlert(errorMessage);
      }
    },
    handleEdit(message) {
      const date = new Date(message.scheduled_at * 1000);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hour = String(date.getHours()).padStart(2, '0');
      const minute = String(date.getMinutes()).padStart(2, '0');

      this.formData = {
        content: message.content,
        date: `${year}-${month}-${day}`,
        hour: hour,
        minute: minute,
      };
      this.editingId = message.id;
    },
    async handleDelete(message) {
      if (!confirm('Excluir esta mensagem agendada?')) return;

      try {
        await this.$store.dispatch('scheduledMessages/delete', message.id);
        useAlert('Mensagem excluída!');
        await this.fetchMessages();
      } catch (error) {
        useAlert(error.message || 'Erro ao excluir');
      }
    },
    formatDate(dateInput) {
      // Aceita tanto timestamp Unix (number) quanto string ISO
      const date = typeof dateInput === 'number'
        ? new Date(dateInput * 1000)
        : new Date(dateInput);

      return date.toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    },
    getStatusBadge(status) {
      const badges = {
        pending: { text: 'Pendente', class: 'warning' },
        sent: { text: 'Enviada', class: 'success' },
        failed: { text: 'Falhou', class: 'alert' },
        cancelled: { text: 'Cancelada', class: 'secondary' },
      };
      return badges[status] || badges.pending;
    },
    getStatusBadgeStyle(status) {
      const styles = {
        pending: {
          backgroundColor: 'rgba(245, 158, 11, 0.1)',
          color: '#f59e0b',
        },
        sent: {
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          color: '#10b981',
        },
        failed: {
          backgroundColor: 'rgba(239, 68, 68, 0.1)',
          color: '#ef4444',
        },
        cancelled: {
          backgroundColor: 'rgba(100, 116, 139, 0.1)',
          color: '#64748b',
        },
      };
      return styles[status] || styles.pending;
    },
    handleInput(e) {
      const textarea = e.target;
      this.cursorPosition = textarea.selectionStart;
      const textBeforeCursor = this.formData.content.substring(0, this.cursorPosition);

      // Check for canned response trigger "/"
      const cannedMatch = textBeforeCursor.match(/\/(\w*)$/);
      if (cannedMatch) {
        this.cannedSearchKey = cannedMatch[1];
        this.showCannedMenu = true;
        this.showVariableMenu = false;
        return;
      }

      // Check for variable trigger "{{"
      const variableMatch = textBeforeCursor.match(/\{\{([^}]*)$/);
      if (variableMatch) {
        this.variableSearchKey = variableMatch[1];
        this.showVariableMenu = true;
        this.showCannedMenu = false;
        return;
      }

      // Close both menus if no trigger found
      this.showCannedMenu = false;
      this.showVariableMenu = false;
    },
    handleCannedSelect(cannedContent) {
      const textarea = this.$refs.messageInput;
      const textBeforeCursor = this.formData.content.substring(0, this.cursorPosition);
      const textAfterCursor = this.formData.content.substring(this.cursorPosition);

      // Find and replace the "/" trigger
      const beforeTrigger = textBeforeCursor.replace(/\/\w*$/, '');
      this.formData.content = beforeTrigger + cannedContent + textAfterCursor;

      this.showCannedMenu = false;
      this.cannedSearchKey = '';

      this.$nextTick(() => {
        const newPosition = beforeTrigger.length + cannedContent.length;
        textarea.setSelectionRange(newPosition, newPosition);
        textarea.focus();
      });
    },
    handleVariableSelect(variableKey) {
      const textarea = this.$refs.messageInput;
      const textBeforeCursor = this.formData.content.substring(0, this.cursorPosition);
      const textAfterCursor = this.formData.content.substring(this.cursorPosition);

      // Find and replace the "{{" trigger with the complete variable format
      const beforeTrigger = textBeforeCursor.replace(/\{\{[^}]*$/, '');
      const variableText = `{{${variableKey}}}`;
      this.formData.content = beforeTrigger + variableText + textAfterCursor;

      this.showVariableMenu = false;
      this.variableSearchKey = '';

      this.$nextTick(() => {
        const newPosition = beforeTrigger.length + variableText.length;
        textarea.setSelectionRange(newPosition, newPosition);
        textarea.focus();
      });
    },
    handleKeydown(e) {
      // Close menus on Escape
      if (e.key === 'Escape') {
        this.showCannedMenu = false;
        this.showVariableMenu = false;
      }
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="!w-[72vw] !max-w-[1280px] !h-[92vh]">
    <div class="flex flex-col overflow-hidden h-full">
      <woot-modal-header
        header-title="Mensagens Agendadas"
        class="!py-4 !px-6"
      />

      <div class="flex flex-1 overflow-hidden min-w-0 border-t border-n-slate-6">
        <!-- COLUNA ESQUERDA: Formulário -->
        <div class="flex-shrink-0 p-6 overflow-y-auto overflow-x-hidden border-r w-[480px] min-w-0 border-n-slate-4">
          <h3 class="mb-4 text-base font-medium text-n-slate-12">
            {{ isEditMode ? 'Editar Mensagem' : 'Nova Mensagem' }}
          </h3>

          <form @submit.prevent="handleSubmit" class="space-y-4 min-w-0">
            <div class="w-full relative">
              <label class="block mb-2 text-sm font-medium text-n-slate-11">
                Conteúdo<span class="text-n-red-9">*</span>
              </label>
              <textarea
                ref="messageInput"
                v-model="formData.content"
                required
                rows="6"
                placeholder="Digite / para respostas prontas ou {{ para variáveis..."
                class="w-full px-3 py-2 text-sm border rounded-md resize-none border-n-slate-6 focus:border-woot-500 focus:ring-1 focus:ring-woot-500"
                @input="handleInput"
                @keydown="handleKeydown"
              />
              <span class="block mt-1 text-xs text-n-slate-8">
                {{ formData.content.length }} caracteres
              </span>

              <!-- Canned Response Menu -->
              <div
                v-if="showCannedMenu"
                class="absolute left-0 right-0 z-50"
                style="top: calc(100% - 24px)"
              >
                <CannedResponse
                  :search-key="cannedSearchKey"
                  @replace="handleCannedSelect"
                />
              </div>

              <!-- Variable Menu -->
              <div
                v-if="showVariableMenu"
                class="absolute left-0 right-0 z-50"
                style="top: calc(100% - 24px)"
              >
                <VariableList
                  :search-key="variableSearchKey"
                  @selectVariable="handleVariableSelect"
                />
              </div>
            </div>

            <div class="w-full">
              <label class="block mb-2 text-sm font-medium text-n-slate-11">
                Data <span class="text-n-red-9">*</span>
              </label>
              <input
                v-model="formData.date"
                type="date"
                required
                class="w-full"
              />
            </div>

            <div class="flex gap-2 w-full">
              <div class="flex-1">
                <label class="block mb-2 text-sm font-medium text-n-slate-11">
                  Hora <span class="text-n-red-9">*</span>
                </label>
                <select
                  v-model="formData.hour"
                  required
                  class="w-full"
                >
                  <option v-for="h in 24" :key="h-1" :value="String(h-1).padStart(2, '0')">
                    {{ String(h-1).padStart(2, '0') }}
                  </option>
                </select>
              </div>
              <div class="flex-1">
                <label class="block mb-2 text-sm font-medium text-n-slate-11">
                  Minuto <span class="text-n-red-9">*</span>
                </label>
                <select
                  v-model="formData.minute"
                  required
                  class="w-full"
                >
                  <option value="00">00</option>
                  <option value="05">05</option>
                  <option value="10">10</option>
                  <option value="15">15</option>
                  <option value="20">20</option>
                  <option value="25">25</option>
                  <option value="30">30</option>
                  <option value="35">35</option>
                  <option value="40">40</option>
                  <option value="45">45</option>
                  <option value="50">50</option>
                  <option value="55">55</option>
                </select>
              </div>
            </div>

            <div class="flex gap-2 pt-2">
              <NextButton
                faded
                slate
                type="button"
                label="Cancelar"
                @click="isEditMode ? resetForm() : onClose()"
              />
              <NextButton
                type="submit"
                :label="isEditMode ? 'Atualizar' : 'Agendar Mensagem'"
                :is-loading="isSubmitting"
              />
            </div>
          </form>
        </div>

        <!-- COLUNA DIREITA: Lista -->
        <div class="flex-1 p-6 overflow-y-auto overflow-x-hidden bg-n-slate-1 min-w-0">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-base font-medium text-n-slate-12">
              Programadas ({{ filteredScheduledMessages.length }})
            </h3>
            <div class="relative">
              <button
                type="button"
                @click="showFilterMenu = !showFilterMenu"
                class="p-2 rounded-md hover:bg-n-slate-3 transition-colors"
                :class="{ 'bg-n-slate-3': showFilterMenu }"
              >
                <fluent-icon
                  icon="filter"
                  size="16"
                  class="text-n-slate-10"
                />
              </button>

              <!-- Dropdown Menu -->
              <div
                v-if="showFilterMenu"
                v-click-outside="() => showFilterMenu = false"
                class="absolute right-0 mt-1 w-48 bg-white border rounded-lg shadow-lg border-n-slate-6 z-50"
              >
                <button
                  v-for="option in [
                    { value: 'all', label: 'Todos' },
                    { value: 'pending', label: 'Pendentes' },
                    { value: 'sent', label: 'Enviadas' },
                    { value: 'failed', label: 'Falhas' },
                    { value: 'cancelled', label: 'Canceladas' },
                  ]"
                  :key="option.value"
                  type="button"
                  @click="statusFilter = option.value; showFilterMenu = false"
                  class="w-full px-3 py-2 text-left text-sm transition-colors hover:bg-n-slate-2"
                  :class="{ 'bg-n-slate-2 font-medium': statusFilter === option.value }"
                >
                  {{ option.label }}
                </button>
              </div>
            </div>
          </div>

          <!-- Loading -->
          <div v-if="uiFlags.isFetching" class="flex items-center justify-center py-12">
            <Spinner size="small" />
          </div>

          <!-- Empty -->
          <div
            v-else-if="filteredScheduledMessages.length === 0"
            class="flex flex-col items-center justify-center py-12 text-center"
          >
            <p class="text-sm text-n-slate-9">
              {{ statusFilter === 'all' ? 'Nenhuma mensagem agendada' : 'Nenhuma mensagem com este status' }}
            </p>
            <p class="mt-1 text-xs text-n-slate-7">
              {{ statusFilter === 'all' ? 'Preencha o formulário ao lado para agendar' : 'Tente outro filtro' }}
            </p>
          </div>

          <!-- Lista -->
          <div v-else class="space-y-3">
            <div
              v-for="message in filteredScheduledMessages"
              :key="message.id"
              class="p-4 border rounded-lg border-n-slate-6 hover:border-n-slate-7 transition-colors bg-n-slate-1"
            >
              <!-- Header -->
              <div class="flex items-center justify-between gap-3 mb-3">
                <div class="flex items-center gap-3 text-xs text-n-slate-10">
                  <span class="flex items-center gap-1">
                    <fluent-icon icon="calendar" size="14" class="text-woot-500" />
                    {{ formatDate(message.scheduled_at) }}
                  </span>
                  <span v-if="message.sender" class="flex items-center gap-1">
                    <fluent-icon icon="person" size="14" class="text-woot-500" />
                    {{ message.sender.name }}
                  </span>
                </div>
                <span
                  class="px-2 py-1 text-xs font-medium rounded-md"
                  :style="getStatusBadgeStyle(message.status)"
                >
                  {{ getStatusBadge(message.status).text }}
                </span>
              </div>

              <!-- Body -->
              <p class="mb-3 text-sm text-n-slate-11 line-clamp-2">
                {{ message.content }}
              </p>

              <!-- Footer Actions -->
              <div v-if="message.status === 'pending'" class="flex gap-4 pt-3 border-t border-n-slate-4">
                <button
                  @click="handleEdit(message)"
                  class="flex items-center gap-1 px-0 text-xs font-medium transition-all hover:scale-105"
                  style="color: #3b82f6"
                >
                  <fluent-icon icon="edit" size="14" style="color: #3b82f6" />
                  <span>Editar</span>
                </button>
                <button
                  @click="handleDelete(message)"
                  class="flex items-center gap-1 px-0 text-xs font-medium transition-all hover:scale-105"
                  style="color: #ef4444"
                >
                  <fluent-icon icon="delete" size="14" style="color: #ef4444" />
                  <span>Excluir</span>
                </button>
              </div>

              <!-- Error Message -->
              <div
                v-if="message.error_message"
                class="p-2 mt-3 text-xs border-l-2 border-n-red-9 bg-n-red-2 text-n-red-11"
              >
                <strong>Erro:</strong> {{ message.error_message }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
