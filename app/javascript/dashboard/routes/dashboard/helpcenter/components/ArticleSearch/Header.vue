<template>
  <div class="chatwoot-search">
    <div class="flex-container align-middle align-justify">
      <h3 class="sub-block-title¯">{{ title }}</h3>
      <woot-button
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>

    <div class="search-wrap">
      <div class="search-icon-container">
        <fluent-icon icon="search" class="search-icon" />
      </div>
      <input
        type="text"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class="contact-search"
        :value="searchQuery"
        @input="onInput"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'ChatwootSearch',
  props: {
    title: {
      type: String,
      default: 'Chatwoot',
    },
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  methods: {
    onInput() {
      this.$emit('search-input', this.searchQuery);
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.chatwoot-search {
  display: flex;
  flex-direction: column;
  padding: var(--space-small);
}

.title {
  margin-bottom: 10px;
}

.search-wrap {
  position: relative;
  display: flex;
  align-items: center;

  .search-icon-container {
    display: flex;
    align-items: center;
    position: absolute;
    height: 100%;
    left: var(--space-small);

    .search-icon {
      height: var(--space-normal);
      font-size: var(--font-size-small);
      color: var(--b-700);
    }
  }
  .contact-search {
    height: var(--space-large);
    margin: 0;
    width: 100%;
    font-size: var(--font-size-small);
    padding-left: calc(var(--space-large) + var(--space-smaller));
    border-color: var(--s-100);
    background: var(--s-25);
  }
}
</style>
