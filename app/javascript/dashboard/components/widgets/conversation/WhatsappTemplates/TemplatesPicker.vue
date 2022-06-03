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
      <button
        v-for="template in filteredTemplates"
        :key="template.id"
        class="template__list-item"
        @click="$emit('onSelect', template)"
      >
        <p>
          {{ template.name }}
        </p>
        <p>Category: {{ template.category }}</p>
        <p>Lang: {{ template.language }}</p>
        <p>Body: {{ getTemplatebody(template) }}</p>
      </button>
      <div v-if="!filteredTemplates.length">
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
    alltemplates() {
      return this.$store.getters['inboxes/getWhatsappTempaltes'](this.inboxId);
    },
    filteredTemplates() {
      return this.alltemplates.filter(template =>
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
  display: flex;
  align-items: center;
  padding: 0 var(--space-one);
  border: 1px solid var(--s-100);
  border-radius: var(--border-radius-medium);
  background-color: var(--s-25);
  margin-bottom: var(--space-one);
  .search-icon {
    color: var(--s-400);
  }
  .templates__search-input {
    border: 0;
    font-size: var(--font-size-mini);
    margin: 0;
    background-color: transparent;
    height: unset;
  }
}
.template__list-container {
  background-color: var(--s-25);
  max-height: 16rem;
  padding: var(--space-one);
  overflow-y: auto;
  border-radius: var(--border-radius-medium);
  .template__list-item {
    width: 100%;
    display: block;
    text-align: left;
    padding: var(--space-one);
    cursor: pointer;
    border-radius: var(--border-radius-medium);
    &:hover {
      background-color: var(--w-50);
    }
  }
}
</style>
