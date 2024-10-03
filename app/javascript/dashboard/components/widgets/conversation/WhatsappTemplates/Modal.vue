<script>
import { defineModel } from 'vue';
import TemplatesPicker from './TemplatesPicker.vue';
import TemplateParser from './TemplateParser.vue';
export default {
  components: {
    TemplatesPicker,
    TemplateParser,
  },
  props: {
    inboxId: {
      type: Number,
      default: undefined,
    },
  },
  emits: ['onSend', 'cancel'],
  setup() {
    const show = defineModel('show', { type: Boolean, default: false });

    return { show };
  },
  data() {
    return {
      selectedWaTemplate: null,
    };
  },
  computed: {
    modalHeaderContent() {
      return this.selectedWaTemplate
        ? this.$t('WHATSAPP_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
            templateName: this.selectedWaTemplate.name,
          })
        : this.$t('WHATSAPP_TEMPLATES.MODAL.SUBTITLE');
    },
  },
  methods: {
    pickTemplate(template) {
      this.selectedWaTemplate = template;
    },
    onResetTemplate() {
      this.selectedWaTemplate = null;
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
  <woot-modal v-model:show="show" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('WHATSAPP_TEMPLATES.MODAL.TITLE')"
      :header-content="modalHeaderContent"
    />
    <div class="row modal-content">
      <TemplatesPicker
        v-if="!selectedWaTemplate"
        :inbox-id="inboxId"
        @on-select="pickTemplate"
      />
      <TemplateParser
        v-else
        :template="selectedWaTemplate"
        @reset-template="onResetTemplate"
        @send-message="onSendMessage"
      />
    </div>
  </woot-modal>
</template>

<style scoped>
.modal-content {
  padding: 1.5625rem 2rem;
}
</style>
