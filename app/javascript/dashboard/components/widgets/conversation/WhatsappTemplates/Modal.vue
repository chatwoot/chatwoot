<script>
import { useAdmin } from 'dashboard/composables/useAdmin';
import TemplatesPicker from './TemplatesPicker.vue';
import TemplateCreator from './TemplateCreator.vue';
import WhatsAppTemplateReply from './WhatsAppTemplateReply.vue';
export default {
  components: {
    TemplatesPicker,
    TemplateCreator,
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
  },
  emits: ['onSend', 'cancel', 'update:show'],
  setup() {
    const { isAdmin } = useAdmin();
    return { isAdmin };
  },
  data() {
    return {
      selectedWaTemplate: null,
      currentView: 'picker', // 'picker' | 'reply' | 'create'
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
      return this.$t('WHATSAPP_TEMPLATES.MODAL.TITLE');
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
    onClose() {
      this.currentView = 'picker';
      this.selectedWaTemplate = null;
      this.$emit('cancel');
    },
    showCreateView() {
      this.currentView = 'create';
    },
    onTemplateCreated() {
      this.currentView = 'picker';
    },
    onBackFromCreate() {
      this.currentView = 'picker';
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="modalTitle"
      :header-content="modalHeaderContent"
    />
    <!-- Create Template button — shown only on picker view for admins -->
    <div
      v-if="currentView === 'picker' && isAdmin"
      class="flex justify-end px-8 -mt-2 mb-1"
    >
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg text-n-brand hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 transition-colors"
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
    </div>
  </woot-modal>
</template>

<style scoped>
.modal-content {
  padding: 1.5625rem 2rem;
}
</style>
