<template>
  <div
    class="menu text-slate-800 dark:text-slate-100"
    role="button"
    @click.stop="$emit('click')"
  >
    <fluent-icon
      v-if="variant === 'icon' && option.icon"
      :icon="option.icon"
      size="14"
      class="menu-icon"
    />
    <span
      v-if="variant === 'label' && option.color"
      class="label-pill"
      :style="{ backgroundColor: option.color }"
    />
    <thumbnail
      v-if="variant === 'agent'"
      :username="option.label"
      :src="option.thumbnail"
      :status="option.status"
      size="20px"
      class="agent-thumbnail"
    />
    <p class="menu-label overflow-hidden whitespace-nowrap text-ellipsis">
      {{ option.label }}
    </p>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
export default {
  components: {
    Thumbnail,
  },
  props: {
    option: {
      type: Object,
      default: () => {},
    },
    variant: {
      type: String,
      default: 'default',
    },
  },
};
</script>

<style scoped lang="scss">
.menu {
  width: calc(var(--space-mega) * 2);
  @apply flex items-center flex-nowrap p-1 rounded-sm overflow-hidden cursor-pointer;

  .menu-label {
    @apply my-0 mx-2 text-xs flex-shrink-0;
  }

  &:hover {
    @apply bg-woot-500 dark:bg-woot-500 text-white dark:text-slate-50;
  }
}

.agent-thumbnail {
  margin-top: 0 !important;
}

.label-pill {
  @apply w-4 h-4 rounded-full border border-slate-50 border-solid dark:border-slate-900 flex-shrink-0;
}
</style>
