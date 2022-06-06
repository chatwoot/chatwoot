<template>
  <div class="medium-12 columns">
    <div class="templates__list-search">
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
            <div class="flex-between">
              <p class="label-title">
                {{ template.name }}
              </p>
              <span class="label-lang label">
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
      return this.$store.getters['inboxes/getWhatsAppTemplates'](this.inboxId);
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
.flex-between {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-one);
}

.templates__list-search {
  align-items: center;
  background-color: var(--s-25);
  border-radius: var(--border-radius-medium);
  border: 1px solid var(--s-100);
  display: flex;
  margin-bottom: var(--space-one);
  padding: 0 var(--space-one);

  .search-icon {
    color: var(--s-400);
  }

  .templates__search-input {
    background-color: transparent;
    border: var(--space-large);
    font-size: var(--font-size-mini);
    height: unset;
    margin: var(--space-zero);
  }
}
.template__list-container {
  background-color: var(--s-25);
  border-radius: var(--border-radius-medium);
  max-height: 30rem;
  overflow-y: auto;
  padding: var(--space-one);

  .template__list-item {
    border-radius: var(--border-radius-medium);
    cursor: pointer;
    display: block;
    padding: var(--space-one);
    text-align: left;
    width: 100%;

    &:hover {
      background-color: var(--w-50);
    }

    .label-title {
      font-size: var(--font-size-small);
    }

    .label-category {
      margin-top: var(--space-two);

      span {
        font-size: var(--font-size-small);
        font-weight: var(--font-weight-bold);
      }
    }

    .label-body {
      font-family: monospace;
    }
  }
}

.strong {
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
}

hr {
  border-bottom: 1px solid var(--s-100);
  margin: var(--space-one) auto;
  max-width: 95%;
}
</style>
