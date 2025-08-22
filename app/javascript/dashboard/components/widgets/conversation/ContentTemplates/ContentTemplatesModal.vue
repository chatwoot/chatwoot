<script>
import TemplatesPicker from './ContentTemplatesPicker.vue';
import TemplateParser from '../../../../components-next/content-templates/ContentTemplateParser.vue';

export default {
  components: {
    TemplatesPicker,
    TemplateParser,
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
  data() {
    return {
      selectedTwilioTemplate: null,
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
      return this.selectedTwilioTemplate
        ? this.$t('CONTENT_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
            templateName: this.selectedTwilioTemplate.friendly_name,
          })
        : this.$t('CONTENT_TEMPLATES.MODAL.SUBTITLE');
    },
  },
  methods: {
    pickTemplate(template) {
      this.selectedTwilioTemplate = template;
    },
    onResetTemplate() {
      this.selectedTwilioTemplate = null;
    },
    onSendMessage(message) {
      this.$emit('onSend', message);
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('CONTENT_TEMPLATES.MODAL.TITLE')"
      :header-content="modalHeaderContent"
    />
    <div class="row modal-content">
      <TemplatesPicker
        v-if="!selectedTwilioTemplate"
        :inbox-id="inboxId"
        @on-select="pickTemplate"
      />
      <TemplateParser
        v-else
        :template="selectedTwilioTemplate"
        @reset-template="onResetTemplate"
        @send-message="onSendMessage"
      >
        <template #actions="{ sendMessage, resetTemplate, disabled }">
          <div class="flex gap-2 mt-6">
            <button
              class="flex-1 px-4 py-2 text-sm font-medium rounded-lg border text-n-slate-12 bg-n-alpha-black2 border-n-weak hover:bg-n-alpha-2 disabled:opacity-50 disabled:cursor-not-allowed"
              @click="resetTemplate"
            >
              {{ $t('CONTENT_TEMPLATES.PARSER.GO_BACK_LABEL') }}
            </button>
            <button
              :disabled="disabled"
              class="flex-1 px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-brand hover:bg-n-brand-darker disabled:opacity-50 disabled:cursor-not-allowed"
              @click="sendMessage"
            >
              {{ $t('CONTENT_TEMPLATES.PARSER.SEND_MESSAGE_LABEL') }}
            </button>
          </div>
        </template>
      </TemplateParser>
    </div>
  </woot-modal>
</template>

<style scoped>
.modal-content {
  padding: 1.5625rem 2rem;
}
</style>
