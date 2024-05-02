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
        <span
          class="text-ellipsis overflow-hidden whitespace-nowrap search-placeholder"
        >
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
  @apply p-2;
}
.search--icon {
  @apply flex-shrink-0 text-slate-500 dark:text-slate-300;
}
.search-placeholder {
  @apply text-slate-500 dark:text-slate-300;
}

.search-input {
  @apply flex justify-center items-center gap-1;
}
</style>
