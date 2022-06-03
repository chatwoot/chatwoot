<template>
  <woot-modal :show.sync="show" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('WHATSAPP_TEMPLATES.MODAL.TITLE')"
      :header-content="modalHeaderContent"
    />
    <div class="row modal-content">
      <templates-picker
        v-if="!selectedWaTemplate"
        :inbox-id="inboxId"
        @onSelect="pickTemplate"
      />
      <template-parser
        v-else
        :template="selectedWaTemplate"
        @resetTemplate="onResetTemplate"
        @sendMessage="onSendMessage"
      />
    </div>
  </woot-modal>
</template>

<script>
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
    show: {
      type: Boolean,
      default: true,
    },
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
      this.$emit('on-send', message);
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>

<style scoped>
.modal-content {
  padding: 2.5rem 3.2rem;
}
</style>
