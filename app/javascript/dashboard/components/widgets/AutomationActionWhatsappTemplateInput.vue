<script>
import { mapGetters } from 'vuex';

const DEFAULT_CONFIG = () => ({
  inbox_ids: [],
  template_name: '',
  template_language: '',
  template_namespace: null,
  template_category: '',
  template_body: '',
  processed_params: {},
});

// Tokens the user can drop into a variable input. Substitution happens
// server-side; this list drives the in-form hint only.
const PLACEHOLDER_TOKENS = [
  '{{contact.name}}',
  '{{contact.email}}',
  '{{contact.phone_number}}',
  '{{conversation.id}}',
  '{{agent.name}}',
];

const templateKey = template =>
  template ? `${template.name}|||${template.language}` : '';

export default {
  props: {
    value: {
      type: [Object, Array],
      default: () => null,
    },
  },
  data() {
    return {
      config: this.unwrap(this.value),
      placeholderTokens: PLACEHOLDER_TOKENS,
    };
  },
  computed: {
    ...mapGetters({ allInboxes: 'inboxes/getInboxes' }),
    whatsappInboxes() {
      return (this.allInboxes || []).filter(
        inbox => inbox.channel_type === 'Channel::Whatsapp'
      );
    },
    selectedInboxes: {
      get() {
        const ids = this.config.inbox_ids || [];
        return this.whatsappInboxes.filter(i => ids.includes(i.id));
      },
      set(value) {
        this.update({ inbox_ids: (value || []).map(i => i.id) });
      },
    },
    // Templates that exist (by name+language) on every selected inbox. We
    // intersect because the same rule may fire on any of the picked inboxes
    // and the chosen template has to be approved on all of them.
    availableTemplates() {
      const inboxes = this.selectedInboxes;
      if (!inboxes.length) return [];

      const templatesPerInbox = inboxes.map(inbox =>
        this.$store.getters['inboxes/getWhatsAppTemplates'](inbox.id).filter(
          t => (t.status || '').toLowerCase() === 'approved'
        )
      );

      const [first, ...rest] = templatesPerInbox;
      if (!first) return [];

      return first.filter(template =>
        rest.every(list =>
          list.some(
            other =>
              other.name === template.name &&
              other.language === template.language
          )
        )
      );
    },
    templateOptions() {
      return this.availableTemplates.map(t => ({
        ...t,
        key: templateKey(t),
        display_name: `${t.name} · ${t.language}`,
      }));
    },
    selectedTemplate: {
      get() {
        if (!this.config.template_name) return null;
        const key = `${this.config.template_name}|||${this.config.template_language}`;
        return this.templateOptions.find(t => t.key === key) || null;
      },
      set(value) {
        if (!value) {
          this.update({
            template_name: '',
            template_language: '',
            template_namespace: null,
            template_category: '',
            template_body: '',
            processed_params: {},
          });
          return;
        }
        this.update({
          template_name: value.name,
          template_language: value.language,
          template_namespace: value.namespace || null,
          template_category: value.category || '',
          template_body: this.bodyText(value),
          processed_params: this.initialParamsFor(value),
        });
      },
    },
    bodyVariableKeys() {
      const body = this.config.template_body || '';
      const matches = body.match(/{{\s*\d+\s*}}/g) || [];
      return matches.map(token => token.replace(/[^0-9]/g, ''));
    },
    renderedBody() {
      const body = this.config.template_body || '';
      if (!body) return '';
      return body.replace(/{{\s*(\d+)\s*}}/g, (match, key) => {
        const value = (this.config.processed_params || {})[key];
        return value ? value : match;
      });
    },
    placeholdersHint() {
      return this.placeholderTokens.join(', ');
    },
  },
  watch: {
    value: {
      handler(newValue) {
        const next = this.unwrap(newValue);
        if (JSON.stringify(next) !== JSON.stringify(this.config)) {
          this.config = next;
        }
      },
      deep: true,
    },
    // If the user removes an inbox and the previously-selected template is
    // no longer present on all selected inboxes, clear it out so we don't
    // submit a stale template name.
    availableTemplates() {
      if (!this.config.template_name) return;
      const key = `${this.config.template_name}|||${this.config.template_language}`;
      if (!this.templateOptions.some(t => t.key === key)) {
        this.selectedTemplate = null;
      }
    },
  },
  mounted() {
    // Emit the normalised shape on mount so a freshly-added action stores
    // an object rather than the empty array set by resetAction().
    if (Array.isArray(this.value) || !this.value) {
      this.emitConfig();
    }
  },
  methods: {
    unwrap(value) {
      if (!value) return DEFAULT_CONFIG();
      if (Array.isArray(value)) {
        return { ...DEFAULT_CONFIG(), ...(value[0] || {}) };
      }
      return { ...DEFAULT_CONFIG(), ...value };
    },
    update(patch) {
      this.config = { ...this.config, ...patch };
      this.emitConfig();
    },
    updateVariable(key, value) {
      const next = { ...(this.config.processed_params || {}), [key]: value };
      this.update({ processed_params: next });
    },
    emitConfig() {
      this.$emit('input', this.config);
    },
    bodyText(template) {
      const body = (template.components || []).find(c => c.type === 'BODY');
      return body ? body.text || '' : '';
    },
    initialParamsFor(template) {
      const body = this.bodyText(template);
      const matches = body.match(/{{\s*\d+\s*}}/g) || [];
      const params = {};
      matches.forEach(token => {
        const key = token.replace(/[^0-9]/g, '');
        params[key] = '';
      });
      return params;
    },
    insertToken(key, token) {
      const current = (this.config.processed_params || {})[key] || '';
      this.updateVariable(key, `${current}${token}`);
    },
  },
};
</script>

<template>
  <div class="wa-template-input">
    <div class="form-row">
      <label class="form-row__label">
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_LABEL') }}
      </label>
      <div class="multiselect-wrap--small">
        <multiselect
          v-model="selectedInboxes"
          track-by="id"
          label="name"
          :placeholder="
            $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.INBOX_PLACEHOLDER')
          "
          multiple
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :max-height="160"
          :options="whatsappInboxes"
          :allow-empty="true"
          :option-height="40"
        />
      </div>
      <p
        v-if="!whatsappInboxes.length"
        class="form-row__hint form-row__hint--warn"
      >
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.NO_WA_INBOXES') }}
      </p>
    </div>

    <div v-if="selectedInboxes.length" class="form-row">
      <label class="form-row__label">
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_LABEL') }}
      </label>
      <div class="multiselect-wrap--small">
        <multiselect
          v-model="selectedTemplate"
          track-by="key"
          label="display_name"
          :placeholder="
            $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.TEMPLATE_PLACEHOLDER')
          "
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :max-height="200"
          :options="templateOptions"
          :allow-empty="true"
          :option-height="40"
        />
      </div>
      <p
        v-if="selectedInboxes.length && !templateOptions.length"
        class="form-row__hint form-row__hint--warn"
      >
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.NO_COMMON_TEMPLATES') }}
      </p>
    </div>

    <div v-if="selectedTemplate" class="wa-template-preview">
      <p class="wa-template-preview__label">
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.BODY_LABEL') }}
      </p>
      <p class="wa-template-preview__body">{{ renderedBody }}</p>
    </div>

    <div v-if="selectedTemplate && bodyVariableKeys.length" class="form-row">
      <label class="form-row__label">
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLES_LABEL') }}
      </label>
      <p class="form-row__hint">
        {{ $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLES_HINT') }}
        <code class="wa-template-tokens">{{ placeholdersHint }}</code>
      </p>
      <div
        v-for="key in bodyVariableKeys"
        :key="key"
        class="wa-template-variable"
      >
        <span class="wa-template-variable__key">{{ `{{${key}}}` }}</span>
        <input
          type="text"
          :value="(config.processed_params || {})[key] || ''"
          class="wa-template-variable__input"
          :placeholder="
            $t('AUTOMATION.ACTION.WHATSAPP_TEMPLATE.VARIABLE_PLACEHOLDER')
          "
          @input="updateVariable(key, $event.target.value)"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.wa-template-input {
  @apply mt-2;
}

.form-row {
  @apply mb-3;

  &__label {
    @apply block text-sm font-medium text-slate-700 dark:text-slate-100 mb-1;
  }

  &__hint {
    @apply text-xs text-slate-500 dark:text-slate-300 mt-1;

    &--warn {
      @apply text-yellow-700 dark:text-yellow-400;
    }
  }
}

.wa-template-tokens {
  @apply block mt-1 px-2 py-1 rounded text-xs bg-slate-50 dark:bg-slate-900 text-slate-700 dark:text-slate-200;
  font-family: monospace;
}

.wa-template-preview {
  @apply rounded-md p-3 my-3 bg-white dark:bg-slate-900 border border-solid border-slate-100 dark:border-slate-700;

  &__label {
    @apply text-xs font-semibold text-slate-500 dark:text-slate-300 mb-1;
  }

  &__body {
    @apply text-sm whitespace-pre-wrap text-slate-800 dark:text-slate-50 mb-0;
    font-family: monospace;
  }
}

.wa-template-variable {
  @apply flex items-center gap-2 mb-2;

  &__key {
    @apply text-xs font-mono px-2 py-1 rounded bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-100;
  }

  &__input {
    @apply flex-grow mb-0;
  }
}

.multiselect {
  @apply mb-0;
}
</style>
