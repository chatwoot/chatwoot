<script>
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
// TODO: Remove this when we support all formats
const formatsToRemove = ['DOCUMENT', 'IMAGE', 'VIDEO'];

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
