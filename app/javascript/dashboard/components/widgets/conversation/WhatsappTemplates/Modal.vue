<template>
  <div>
    <woot-modal-header
      header-title="Whatsapp Templates"
      :header-content="modalHeaderContent"
    />
    <div class="row modal-content">
      <templates-picker v-if="!selectedWaTemplate" @onSelect="pickTemplate" />
      <template-parser
        v-else
        :template="selectedWaTemplate"
        @resetTemplate="onResetTemplate"
      />
    </div>
  </div>
</template>

<script>
import TemplatesPicker from './TemplatesPicker.vue';
import TemplateParser from './TemplateParser.vue';
export default {
  components: {
    TemplatesPicker,
    TemplateParser,
  },
  data() {
    return {
      selectedWaTemplate: null,
    };
  },
  computed: {
    modalHeaderContent() {
      return this.selectedWaTemplate
        ? `Compile ${this.selectedWaTemplate.name}`
        : 'Select the whatsapp template you want to send';
    },
  },
  methods: {
    pickTemplate(template) {
      this.selectedWaTemplate = template;
    },
    onResetTemplate() {
      this.selectedWaTemplate = null;
    },
  },
};
</script>

<style scoped>
.modal-content {
  padding: 2.5rem 3.2rem;
}
</style>
