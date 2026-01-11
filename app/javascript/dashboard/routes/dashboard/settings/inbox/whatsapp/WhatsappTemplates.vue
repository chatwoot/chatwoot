<script>
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import WhatsappTemplatesAPI from 'dashboard/api/whatsappTemplates';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import Modal from 'dashboard/components/Modal.vue';
import TemplateBuilder from './templates/TemplateBuilder.vue';

export default {
  components: {
    SettingsSection,
    NextButton,
    Spinner,
    Modal,
    TemplateBuilder,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
      isSyncing: false,
      templates: [],
      showCreateModal: false,
      isCreating: false,
      isDeleting: false,
      templateToDelete: null,
    };
  },
  computed: {
    safeTemplates() {
      const templateList = Array.isArray(this.templates) ? this.templates : [];
      return templateList.filter(t => t !== null && t !== undefined);
    },
    approvedTemplates() {
      return this.safeTemplates.filter(t => t.status === 'APPROVED');
    },
    pendingTemplates() {
      return this.safeTemplates.filter(t => t.status === 'PENDING');
    },
    rejectedTemplates() {
      return this.safeTemplates.filter(t => t.status === 'REJECTED');
    },
  },
  mounted() {
    this.loadTemplates();
  },
  methods: {
    loadTemplates() {
      this.isLoading = true;
      try {
        const inboxData = this.$store.getters['inboxes/getInbox'](this.inbox.id);
        this.templates = inboxData?.message_templates || [];
      } finally {
        this.isLoading = false;
      }
    },
    async syncTemplates() {
      this.isSyncing = true;
      try {
        await InboxesAPI.syncTemplates(this.inbox.id);
        await this.$store.dispatch('inboxes/get', { inboxId: this.inbox.id });
        const inboxData = this.$store.getters['inboxes/getInbox'](this.inbox.id);
        this.templates = inboxData?.message_templates || [];
        useAlert(this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_SUCCESS'));
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_ERROR')
        );
      } finally {
        this.isSyncing = false;
      }
    },
    openCreateModal() {
      this.showCreateModal = true;
    },
    closeCreateModal() {
      this.showCreateModal = false;
    },
    async createTemplate(payload) {
      this.isCreating = true;
      try {
        await WhatsappTemplatesAPI.createTemplate(this.inbox.id, payload);
        useAlert(this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_SUCCESS'));
        this.closeCreateModal();
        await new Promise(resolve => setTimeout(resolve, 4000));
        await this.syncTemplates();
      } catch (error) {
        console.error('Template creation error:', error);
        let errorMessage;
        if (error.response?.data?.details?.error?.message) {
          errorMessage = error.response.data.details.error.message;
        } else if (error.response?.data?.error) {
          errorMessage = error.response.data.error;
        } else if (error.message) {
          errorMessage = error.message;
        } else {
          errorMessage = this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_ERROR');
        }
        useAlert(errorMessage);
      } finally {
        this.isCreating = false;
      }
    },
    confirmDelete(template) {
      this.templateToDelete = template;
    },
    cancelDelete() {
      this.templateToDelete = null;
    },
    async deleteTemplate() {
      if (!this.templateToDelete) return;
      this.isDeleting = true;
      try {
        await WhatsappTemplatesAPI.deleteTemplate(
          this.inbox.id,
          this.templateToDelete.name
        );
        useAlert(this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_SUCCESS'));
        this.templateToDelete = null;
        await this.syncTemplates();
      } catch (error) {
        useAlert(
          error.response?.data?.error ||
            this.$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_ERROR')
        );
      } finally {
        this.isDeleting = false;
      }
    },
    getStatusClass(status) {
      switch (status) {
        case 'APPROVED':
          return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400';
        case 'PENDING':
          return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400';
        case 'REJECTED':
          return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400';
        default:
          return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400';
      }
    },
    getCategoryClass(category) {
      switch (category) {
        case 'MARKETING':
          return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400';
        case 'UTILITY':
          return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400';
        case 'AUTHENTICATION':
          return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400';
        default:
          return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400';
      }
    },
    getTemplateBody(template) {
      const bodyComponent = template.components?.find(c => c.type === 'BODY');
      return bodyComponent?.text || '';
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <Spinner v-if="isLoading" />
    <template v-else>
      <SettingsSection
        :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.TITLE')"
        :sub-title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DESCRIPTION')"
        :show-border="false"
      >
        <div class="mb-4 flex gap-2">
          <NextButton
            :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_BUTTON')"
            @click="openCreateModal"
          />
          <NextButton
            ghost
            icon="i-lucide-refresh-cw"
            :is-loading="isSyncing"
            :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_BUTTON')"
            @click="syncTemplates"
          />
        </div>
        <div v-if="templates.length > 0" class="flex items-center gap-4 mb-6 text-sm text-n-slate-11">
          <span class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-green-500"></span>
            <span class="font-medium text-n-slate-12">{{ approvedTemplates.length }}</span>
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.APPROVED') }}
          </span>
          <span class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-yellow-500"></span>
            <span class="font-medium text-n-slate-12">{{ pendingTemplates.length }}</span>
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.PENDING') }}
          </span>
          <span class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-red-500"></span>
            <span class="font-medium text-n-slate-12">{{ rejectedTemplates.length }}</span>
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.REJECTED') }}
          </span>
        </div>
        <div v-if="templates.length === 0" class="text-center py-8 text-n-slate-11">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.EMPTY') }}
        </div>
        <div v-else class="space-y-4">
          <div
            v-for="template in safeTemplates"
            :key="template.id || template.name"
            class="p-4 border border-n-weak rounded-lg"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-2">
                  <h3 class="text-base font-medium text-n-slate-12">{{ template.name }}</h3>
                  <span class="px-2 py-0.5 text-xs rounded-full" :class="getStatusClass(template.status)">{{ $t(`INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.${template.status}`) }}</span>
                  <span class="px-2 py-0.5 text-xs rounded-full" :class="getCategoryClass(template.category)">{{ $t(`INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.${template.category}`) }}</span>
                </div>
                <p class="text-sm text-n-slate-11 mb-2">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LANGUAGE') }}: {{ template.language }}</p>
                <p class="text-sm text-n-slate-12 whitespace-pre-wrap">{{ getTemplateBody(template) }}</p>
              </div>
              <NextButton ghost color-scheme="alert" size="sm" icon="i-lucide-trash-2" :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_BUTTON')" @click="confirmDelete(template)" />
            </div>
          </div>
        </div>
      </SettingsSection>
    </template>
    <Modal v-model:show="showCreateModal" :on-close="closeCreateModal" size="large">
      <TemplateBuilder :inbox-id="inbox.id" :is-creating="isCreating" @create="createTemplate" @cancel="closeCreateModal" />
    </Modal>
    <Modal v-if="templateToDelete" :show="!!templateToDelete" :on-close="cancelDelete" size="small">
      <div class="p-6">
        <h2 class="text-lg font-medium text-n-slate-12 mb-2">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_CONFIRM_TITLE') }}</h2>
        <p class="text-sm text-n-slate-11 mb-4">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_CONFIRM_MESSAGE', { name: templateToDelete.name }) }}</p>
        <div class="flex justify-end gap-2">
          <NextButton ghost :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CANCEL')" @click="cancelDelete" />
          <NextButton color-scheme="alert" :is-loading="isDeleting" :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_BUTTON')" @click="deleteTemplate" />
        </div>
      </div>
    </Modal>
  </div>
</template>
