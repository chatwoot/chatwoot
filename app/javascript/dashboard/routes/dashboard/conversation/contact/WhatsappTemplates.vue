<template>
  <div class="mx-0 flex flex-wrap">
    <templates-picker
      v-if="!selectedWaTemplate"
      :inbox-id="inboxId"
      @onSelect="pickTemplate"
    />
    <template-parser
      v-else
      :template="selectedWaTemplate"
      :remove-overflow="removeOverflow"
      :is-compose-mode="isComposeMode"
      @resetTemplate="onResetTemplate"
      @sendMessage="onSendMessage"
    />
  </div>
</template>

<script>
import TemplatesPicker from 'dashboard/components/widgets/conversation/WhatsappTemplates/TemplatesPicker.vue';
import TemplateParser from 'dashboard/components/widgets/conversation/WhatsappTemplates/TemplateParser.vue';
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
    isComposeMode: {
      type: Boolean,
      default: false,
    },
    show: {
      type: Boolean,
      default: true,
    },
    removeOverflow: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedWaTemplate: null,
    };
  },
  methods: {
    pickTemplate(template) {
      this.$emit('pickTemplate', true);
      this.selectedWaTemplate = template;
    },
    onResetTemplate() {
      this.$emit('pickTemplate', false);
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

<style></style>
