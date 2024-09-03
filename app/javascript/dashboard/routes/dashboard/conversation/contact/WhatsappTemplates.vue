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
      this.$emit('onSend', message);
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <div class="flex flex-wrap mx-0">
    <TemplatesPicker
      v-if="!selectedWaTemplate"
      :inbox-id="inboxId"
      @onSelect="pickTemplate"
    />
    <TemplateParser
      v-else
      :template="selectedWaTemplate"
      @resetTemplate="onResetTemplate"
      @sendMessage="onSendMessage"
    />
  </div>
</template>
