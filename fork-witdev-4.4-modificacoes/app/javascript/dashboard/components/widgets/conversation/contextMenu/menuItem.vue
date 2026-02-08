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

<template>
  <div
    class="menu text-slate-800 dark:text-slate-100 min-h-7 min-w-0"
    role="button"
  >
    <fluent-icon
      v-if="variant === 'icon' && option.icon"
      :icon="option.icon"
      size="14"
      class="flex-shrink-0"
    />
    <span
      v-if="variant === 'label' && option.color"
      class="label-pill flex-shrink-0"
      :style="{ backgroundColor: option.color }"
    />
    <Thumbnail
      v-if="variant === 'agent'"
      :username="option.label"
      :src="option.thumbnail"
      :status="option.status"
      size="20px"
      class="flex-shrink-0"
    />
    <p class="menu-label truncate min-w-0 flex-1">
      {{ option.label }}
    </p>
  </div>
</template>

<style scoped lang="scss">
.menu {
  width: calc(var(--space-mega) * 2);
  @apply flex items-center flex-nowrap p-1 rounded-md overflow-hidden cursor-pointer;

  .menu-label {
    @apply my-0 mx-2 text-xs flex-shrink-0;
  }

  &:hover {
    @apply bg-n-brand text-white dark:text-slate-50;
  }
}

.agent-thumbnail {
  margin-top: 0 !important;
}

.label-pill {
  @apply w-4 h-4 rounded-full border border-n-strong border-solid flex-shrink-0;
}
</style>
