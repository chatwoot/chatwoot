<script>
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    Icon,
  },
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
      isRefreshing: false,
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

        // Filter out interactive templates (LIST, PRODUCT, CATALOG) and location templates
        const hasUnsupportedComponents = template.components.some(
          component =>
            ['LIST', 'PRODUCT', 'CATALOG'].includes(component.type) ||
            (component.type === 'HEADER' && component.format === 'LOCATION')
        );

        if (hasUnsupportedComponents) {
          return false;
        }

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
    getTemplateBody(template) {
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
    async refreshTemplates() {
      this.isRefreshing = true;
      try {
        await this.$store.dispatch('inboxes/syncTemplates', this.inboxId);
        useAlert(this.$t('WHATSAPP_TEMPLATES.PICKER.REFRESH_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('WHATSAPP_TEMPLATES.PICKER.REFRESH_ERROR'));
      } finally {
        this.isRefreshing = false;
      }
    },
  },
};
</script>

<template>
  <div class="w-full">
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="$t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
        />
      </div>
      <button
        :disabled="isRefreshing"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed"
        :title="$t('WHATSAPP_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-n-slate-12 size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
      </button>
    </div>
    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          class="block p-2.5 w-full text-left rounded-lg cursor-pointer hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
          @click="$emit('onSelect', template)"
        >
          <div>
            <div class="flex justify-between items-center mb-2.5">
              <p class="text-sm">
                {{ template.name }}
              </p>
              <span
                class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
              >
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE') }}:
                {{ template.language }}
              </span>
            </div>
            <!-- Header -->
            <div v-if="getTemplateHeader(template)" class="mb-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.HEADER') || 'HEADER' }}
              </p>
              <div
                v-if="getTemplateHeader(template).format === 'TEXT'"
                class="text-sm label-body"
              >
                {{ getTemplateHeader(template).text }}
              </div>
              <div
                v-else-if="hasMediaContent(template)"
                class="text-sm italic text-n-slate-11"
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
              <p class="text-xs font-medium text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.BODY') || 'BODY' }}
              </p>
              <p class="text-sm label-body">{{ getTemplateBody(template) }}</p>
            </div>

            <!-- Footer -->
            <div v-if="getTemplateFooter(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.FOOTER') || 'FOOTER' }}
              </p>
              <p class="text-sm label-body">
                {{ getTemplateFooter(template).text }}
              </p>
            </div>

            <!-- Buttons -->
            <div v-if="getTemplateButtons(template)" class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.BUTTONS') || 'BUTTONS' }}
              </p>
              <div class="flex flex-wrap gap-1 mt-1">
                <span
                  v-for="button in getTemplateButtons(template).buttons"
                  :key="button.text"
                  class="px-2 py-1 text-xs rounded bg-n-slate-3 text-n-slate-12"
                >
                  {{ button.text }}
                </span>
              </div>
            </div>

            <div class="mt-3">
              <p class="text-xs font-medium text-n-slate-11">
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
      <div v-if="!filteredTemplateMessages.length" class="py-8 text-center">
        <div v-if="query && whatsAppTemplateMessages.length">
          <p>
            {{ $t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <div v-else-if="!whatsAppTemplateMessages.length" class="space-y-4">
          <p class="text-n-slate-11">
            {{ $t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
