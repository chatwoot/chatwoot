<template>
  <div class="menu">
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
      size="20px"
      class="agent-thumbnail"
    />
    <p class="menu-label">{{ option.label }}</p>
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
  display: flex;
  align-items: center;
  width: 100%;
  padding: var(--space-smaller);
  border-radius: var(--border-radius-small);
  min-width: calc(var(--space-mega) * 2);

  .menu-label {
    margin: 0;
    font-size: var(--font-size-mini);
  }

  .menu-icon {
    margin-right: var(--space-small);
  }

  &:hover {
    background-color: var(--w-500);
    color: var(--white);
  }
}

.agent-thumbnail {
  margin-top: 0 !important;
  margin-right: var(--space-small);
}

.label-pill {
  width: var(--space-normal);
  height: var(--space-normal);
  border-radius: var(--border-radius-rounded);
  border: 1px solid var(--s-50);
  flex-shrink: 0;
  margin-right: var(--space-small);
}
</style>
