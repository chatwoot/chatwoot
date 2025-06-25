<template>
  <div class="search-input-box">
    <woot-button
      class="hollow"
      size="small"
      color-scheme="secondary"
      is-expanded
    >
      <div class="search-input">
        <fluent-icon icon="search" size="14px" class="search--icon" />
        <span class="text-ellipsis search-placeholder">
          {{ $t('CONVERSATION.SEARCH_MESSAGES') }}
        </span>
      </div>
    </woot-button>
  </div>
</template>

<script>
export default {
  props: {
    tabs: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {};
  },
  methods: {},
};
</script>
<style lang="scss" scoped>
.search-input-box {
  padding: var(--space-small);
}
.search--icon {
  flex-shrink: 0;
  color: var(--s-500);
}
.search-placeholder {
  color: var(--s-500);
}

.search-input {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: var(--space-smaller);
}
</style>
