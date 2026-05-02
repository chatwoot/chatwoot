<script>
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import TemplatesPicker from './TemplatesPicker.vue';
import TemplateCreator from './TemplateCreator.vue';
import InteractiveMessageCreator from './InteractiveMessageCreator.vue';
import WhatsAppTemplateReply from './WhatsAppTemplateReply.vue';
export default {
  components: {
    TemplatesPicker,
    TemplateCreator,
    InteractiveMessageCreator,
    WhatsAppTemplateReply,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
    conversationId: {
      type: Number,
      default: undefined,
    },
  },
  emits: ['onSend', 'cancel', 'update:show'],
  setup() {
    const { isAdmin } = useAdmin();
    return { isAdmin, showAlert: useAlert };
  },
  data() {
    return {
      selectedWaTemplate: null,
      currentView: 'picker',
    };
  },
  computed: {
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    modalHeaderContent() {
      if (this.currentView === 'create') {
        return this.$t('WHATSAPP_TEMPLATES.CREATOR.SUBTITLE');
      }
      if (this.currentView === 'interactive') {
        return this.$t('WHATSAPP_TEMPLATES.INTERACTIVE.SUBTITLE');
      }
      return this.selectedWaTemplate
        ? this.$t('WHATSAPP_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
            templateName: this.selectedWaTemplate.name,
          })
        : this.$t('WHATSAPP_TEMPLATES.MODAL.SUBTITLE');
    },
    modalTitle() {
      if (this.currentView === 'create') {
        return this.$t('WHATSAPP_TEMPLATES.CREATOR.TITLE');
      }
      if (this.currentView === 'interactive') {
        return this.$t('WHATSAPP_TEMPLATES.INTERACTIVE.TITLE');
      }
      return this.$t('WHATSAPP_TEMPLATES.MODAL.TITLE');
    },
    modalSize() {
      return ['create', 'interactive'].includes(this.currentView)
        ? 'modal-bigger'
        : 'modal-big';
    },
  },
  methods: {
    pickTemplate(template) {
      this.selectedWaTemplate = template;
      this.currentView = 'reply';
    },
    onResetTemplate() {
      this.selectedWaTemplate = null;
      this.currentView = 'picker';
    },
    onSendMessage(message) {
      this.$emit('onSend', message);
    },
    async onSendInteractiveTemplate(template) {
      if (!this.conversationId) {
        this.showAlert(
          this.$t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_NO_CONVERSATION')
        );
        return;
      }

      try {
        await this.$store.dispatch('whatsappInteractiveTemplates/dispatch', {
          templateId: template.id,
          conversationId: this.conversationId,
        });
        this.showAlert(this.$t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_SUCCESS'));
        this.onClose();
        this.localShow = false;
      } catch (error) {
        const message =
          error?.response?.data?.error ||
          this.$t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_ERROR');
        this.showAlert(message);
      }
    },
    onClose() {
      this.currentView = 'picker';
      this.selectedWaTemplate = null;
      this.$emit('cancel');
    },
    showCreateView() {
      this.currentView = 'create';
    },
    showInteractiveView() {
      this.currentView = 'interactive';
    },
    onTemplateCreated() {
      this.currentView = 'picker';
    },
    onTemplateSent() {
      this.onClose();
      this.localShow = false;
    },
    onBackFromCreate() {
      this.currentView = 'picker';
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" :size="modalSize">
    <!-- Header with optional back arrow -->
    <div class="px-8 pt-6 pb-2">
      <div class="flex items-center gap-3">
        <button
          v-if="['create', 'interactive'].includes(currentView)"
          class="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12 transition-colors cursor-pointer shrink-0"
          :title="$t('WHATSAPP_TEMPLATES.CREATOR.BACK')"
          @click="onBackFromCreate"
        >
          <span class="i-lucide-arrow-left size-5" />
        </button>
        <div class="flex-1 min-w-0">
          <h2 class="text-xl font-medium text-n-slate-12">
            {{ modalTitle }}
          </h2>
          <p class="text-sm text-n-slate-10 mt-0.5">
            {{ modalHeaderContent }}
          </p>
        </div>
      </div>
    </div>
    <!-- Create Template button — shown only on picker view for admins -->
    <div
      v-if="currentView === 'picker' && isAdmin"
      class="flex justify-end gap-2 px-8 -mt-2 mb-1"
    >
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg text-n-brand hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 transition-colors cursor-pointer"
        @click="showInteractiveView"
      >
        <span class="i-lucide-message-square-plus size-4" />
        {{ $t('WHATSAPP_TEMPLATES.INTERACTIVE.CREATE_BUTTON') }}
      </button>
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg text-n-brand hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 transition-colors cursor-pointer"
        @click="showCreateView"
      >
        <span class="i-lucide-plus size-4" />
        {{ $t('WHATSAPP_TEMPLATES.CREATOR.CREATE_BUTTON') }}
      </button>
    </div>
    <div class="row modal-content">
      <TemplatesPicker
        v-if="currentView === 'picker'"
        :inbox-id="inboxId"
        @on-select="pickTemplate"
        @on-select-interactive="onSendInteractiveTemplate"
      />
      <WhatsAppTemplateReply
        v-else-if="currentView === 'reply'"
        :template="selectedWaTemplate"
        @reset-template="onResetTemplate"
        @send-message="onSendMessage"
      />
      <TemplateCreator
        v-else-if="currentView === 'create'"
        :inbox-id="inboxId"
        @template-created="onTemplateCreated"
        @back="onBackFromCreate"
      />
      <InteractiveMessageCreator
        v-else-if="currentView === 'interactive'"
        :conversation-id="conversationId"
        @template-created="onTemplateCreated"
        @template-sent="onTemplateSent"
        @back="onBackFromCreate"
      />
    </div>
  </woot-modal>
</template>

<style scoped>
.modal-content {
  padding: 1.5625rem 2rem;
}
</style>
