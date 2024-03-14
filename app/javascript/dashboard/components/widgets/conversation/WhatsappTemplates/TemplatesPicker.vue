<template>
  <div class="w-full">
    <div class="templates__list-search gap-1">
      <fluent-icon icon="search" class="search-icon" size="16" />
      <input
        ref="search"
        v-model="query"
        type="search"
        :placeholder="$t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
        class="templates__search-input"
      />
    </div>
    <div class="template__list-container">
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          class="template__list-item"
          @click="$emit('onSelect', template)"
        >
          <div>
            <div class="flex items-center justify-between mb-2.5">
              <p class="label-title">
                {{ template.name }}
              </p>
              <span
                class="inline-block py-1 px-2 rounded-sm text-xs leading-none cursor-default bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100"
              >
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE') }} :
                {{ template.language }}
              </span>
            </div>
            <div>
              <p class="strong">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.TEMPLATE_BODY') }}
              </p>
              <p class="label-body">{{ getTemplatebody(template) }}</p>
            </div>
            <div class="label-category">
              <p class="strong">
                {{ $t('WHATSAPP_TEMPLATES.PICKER.LABELS.CATEGORY') }}
              </p>
              <p>{{ template.category }}</p>
            </div>
          </div>
        </button>
        <hr v-if="i != filteredTemplateMessages.length - 1" :key="`hr-${i}`" />
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

<style scoped lang="scss">
.templates__list-search {
  @apply items-center flex bg-slate-25 dark:bg-slate-900 mb-2.5 py-0 px-2.5 rounded-md border border-solid border-slate-100 dark:border-slate-700;

  .search-icon {
    @apply text-slate-400 dark:text-slate-300;
  }

  .templates__search-input {
    @apply bg-transparent border-0 text-xs h-9 m-0;
  }
}
.template__list-container {
  @apply bg-slate-25 dark:bg-slate-900 rounded-md max-h-[18.75rem] overflow-y-auto p-2.5;

  .template__list-item {
    @apply rounded-lg cursor-pointer block p-2.5 text-left w-full hover:bg-woot-50 dark:hover:bg-slate-800;

    .label-title {
      @apply text-sm;
    }

    .label-category {
      @apply mt-5;

      span {
        @apply text-sm font-semibold;
      }
    }

    .label-body {
      font-family: monospace;
    }
  }
}

.strong {
  @apply text-xs font-semibold;
}

hr {
  @apply border-b border-solid border-slate-100 dark:border-slate-700 my-2.5 mx-auto max-w-[95%];
}
</style>
