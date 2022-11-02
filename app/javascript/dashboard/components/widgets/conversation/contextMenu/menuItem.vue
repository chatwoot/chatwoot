<template>
  <div class="menu" @click.stop="$emit('click')">
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
    <p class="menu-label text-truncate">{{ option.label }}</p>
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
  flex-wrap: nowrap;
  width: calc(var(--space-mega) * 2);
  padding: var(--space-smaller);
  border-radius: var(--border-radius-small);
  overflow: hidden;
  .menu-label {
    margin: 0;
    font-size: var(--font-size-mini);
    flex-shrink: 0;
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
