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
      :show-message-button="showMessageButton"
      :options="eventOptions"
      :selected-params="this.computedTemplate.processed_params"
      :selected-event-params="this.computedTemplate.processed_events"
      @resetTemplate="onResetTemplate"
      @sendMessage="onSendMessage"
      @changeVariable="onChangeVariable"
      @changeEventVariable="onChangeEventVariable"
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
    show: {
      type: Boolean,
      default: true,
    },
    showMessageButton: {
      type: Boolean,
      default: true,
    },
    eventOptions: {
      type: Array,
      default: () => [],
    },
    template: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      selectedWaTemplate: null,
      eventOptions: null,
    };
  },

  computed: {
    computedTemplate() {
      return this.template ?? {};
    },
  },

  mounted() {
    if (this.template?.id) {
      const {
        inbox_id,
        processed_events,
        processed_params,
        ...filteredTemplate
      } = this.template;
      this.selectedWaTemplate = filteredTemplate;
    }
  },
  methods: {
    pickTemplate(template) {
      this.$emit('pickTemplate', true);
      this.$emit('select-template', template);
      this.selectedWaTemplate = template;
    },
    onResetTemplate() {
      this.$emit('pickTemplate', false);
      this.$emit('select-template', null);
      this.selectedWaTemplate = null;
      this.$emit('change-variable', null);
    },
    onSendMessage(message) {
      this.$emit('on-send', message);
    },
    onChangeVariable(params) {
      this.$emit('change-variable', params);
    },
    onChangeEventVariable(params) {
      this.$emit('change-event-variable', params);
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>

<style></style>
