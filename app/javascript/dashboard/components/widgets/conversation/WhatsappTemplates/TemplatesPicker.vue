<script>
// Support all template formats including media headers

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
      const templates = this.$store.getters['inboxes/getWhatsAppTemplates'](
        this.inboxId
      );

      if (!templates || !Array.isArray(templates)) {
        return [];
      }

      return templates.filter(template => {
        // Ensure template has required properties
        if (!template || !template.status || !template.components) {
          return false;
        }

        // Only show approved templates
        if (template.status.toLowerCase() !== 'approved') {
          return false;
        }

        // Since we support all formats now, include all approved templates
        // This includes templates with media headers (IMAGE, VIDEO, DOCUMENT)
        return true;
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
      return (
        template.components.find(component => component.type === 'BODY')
          ?.text || ''
      );
    },
    getTemplateHeader(template) {
      return template.components.find(component => component.type === 'HEADER');
    },
    getTemplateFooter(template) {
      return template.components.find(component => component.type === 'FOOTER');
    },
    getTemplateButtons(template) {
      return template.components.find(
        component => component.type === 'BUTTONS'
      );
    },
    hasMediaContent(template) {
      const header = this.getTemplateHeader(template);
      return (
        header &&
        (header.format === 'IMAGE' ||
          header.format === 'VIDEO' ||
          header.format === 'DOCUMENT')
      );
    },
    debugTemplate(template) {
      // Debug helper method - can be used in dev tools console
      return {
        name: template.name,
        status: template.status,
        hasHeader: !!this.getTemplateHeader(template),
        headerFormat: this.getTemplateHeader(template)?.format,
        hasMediaContent: this.hasMediaContent(template),
        components: template.components.map(c => ({
          type: c.type,
          format: c.format,
        })),
      };
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
            <!-- Header -->
            <div v-if="getTemplateHeader(template)" class="mb-3">
              <p class="font-medium text-xs text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.HEADER') || 'HEADER' }}
              </p>
              <div
                v-if="getTemplateHeader(template).format === 'TEXT'"
                class="label-body text-sm"
              >
                {{ getTemplateHeader(template).text }}
              </div>
              <div
                v-else-if="hasMediaContent(template)"
                class="text-sm text-n-slate-11 italic"
              >
                {{
                  $t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT', {
                    format: getTemplateHeader(template).format,
                  }) || `${getTemplateHeader(template).format} media content`
                }}
              </div>
            </div>

            <!-- Body -->
            <div>
              <p class="font-medium text-xs text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.BODY') || 'BODY' }}
              </p>
              <p class="label-body text-sm">{{ getTemplatebody(template) }}</p>
            </div>

            <!-- Footer -->
            <div v-if="getTemplateFooter(template)" class="mt-3">
              <p class="font-medium text-xs text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.FOOTER') || 'FOOTER' }}
              </p>
              <p class="label-body text-sm">
                {{ getTemplateFooter(template).text }}
              </p>
            </div>

            <!-- Buttons -->
            <div v-if="getTemplateButtons(template)" class="mt-3">
              <p class="font-medium text-xs text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.BUTTONS') || 'BUTTONS' }}
              </p>
              <div class="flex flex-wrap gap-1 mt-1">
                <span
                  v-for="button in getTemplateButtons(template).buttons"
                  :key="button.text"
                  class="px-2 py-1 text-xs bg-n-slate-3 rounded text-n-slate-12"
                >
                  {{ button.text }}
                </span>
              </div>
            </div>

            <div class="mt-3">
              <p class="font-medium text-xs text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.CATEGORY') || 'CATEGORY' }}
              </p>
              <p class="text-sm">{{ template.category }}</p>
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
