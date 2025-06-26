<script>
// TODO: Remove this when we support all formats
const formatsToRemove = ['DOCUMENT', 'IMAGE', 'VIDEO'];

export default {
  props: {
    inboxId: {
      type: Number,
      default: undefined,
    },
  },
  emits: ['onSelect'],
  data() {
    return {
      query: '',
    };
  },
  computed: {
    whatsAppTemplateMessages() {
      // TODO: Remove the last filter when we support all formats
      return this.$store.getters['inboxes/getWhatsAppTemplates'](this.inboxId)
        .filter(template => template.status.toLowerCase() === 'approved')
        .filter(template => {
          return template.components.every(component => {
            return !formatsToRemove.includes(component.format);
          });
        });
    },
    filteredTemplateMessages() {
      return this.whatsAppTemplateMessages.filter(template =>
        template.name.toLowerCase().includes(this.query.toLowerCase())
      );
    },
  },
  methods: {
    getTemplatebody(template) {
      return template.components.find(component => component.type === 'BODY')
        .text;
    },
  },
};
</script>

<template>
  <div class="w-full">
    <div
      class="gap-1 bg-n-alpha-black2 items-center flex mb-2.5 py-0 px-2.5 rounded-lg outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
    >
      <fluent-icon icon="search" class="text-n-slate-12" size="16" />
      <input
        v-model="query"
        type="search"
        :placeholder="$t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
        class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
      />
    </div>
    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          class="rounded-lg cursor-pointer block p-2.5 text-left w-full hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
          @click="$emit('onSelect', template)"
        >
          <div>
            <div class="flex items-center justify-between mb-2.5">
              <p class="text-sm">
                {{ template.name }}
              </p>
              <span
                class="inline-block px-2 py-1 text-xs leading-none bg-n-slate-3 rounded-lg cursor-default text-n-slate-12"
              >
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE') }} :
                {{ template.language }}
              </span>
            </div>
            <div>
              <p class="font-medium">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.TEMPLATE_BODY') }}
              </p>
              <p class="label-body">{{ getTemplatebody(template) }}</p>
            </div>
            <div class="mt-5">
              <p class="font-medium">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.CATEGORY') }}
              </p>
              <p>{{ template.category }}</p>
            </div>
          </div>
        </button>
        <hr
          v-if="i != filteredTemplateMessages.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredTemplateMessages.length">
        <p>
          {{ $t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
          <strong>{{ query }}</strong>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
