<template>
  <router-link v-slot="{ href, isActive, navigate }" :to="to" custom>
    <a
      v-tooltip.right="$t(`SIDEBAR.${name}`)"
      :href="href"
      class="button clear button--only-icon menu-item"
      :class="{ 'is-active': isActive || isChildMenuActive }"
      :rel="openInNewPage ? 'noopener noreferrer nofollow' : undefined"
      :target="openInNewPage ? '_blank' : undefined"
      @click="navigate"
    >
      <fluent-icon :icon="icon" />
      <span class="show-for-sr">{{ name }}</span>
      <span v-if="count" class="badge warning">{{ count }}</span>
    </a>
  </router-link>
</template>
<script>
export default {
  props: {
    to: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    count: {
      type: String,
      default: '',
    },
    isChildMenuActive: {
      type: Boolean,
      default: false,
    },
    openInNewPage: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
<style lang="scss" scoped>
.button {
  margin: var(--space-small) 0;
}

.menu-item {
  display: inline-flex;
  position: relative;
  border-radius: var(--border-radius-large);
  border: 1px solid transparent;
  color: var(--s-600);

  &:hover {
    background: var(--w-25);
    color: var(--s-600);
  }

  &:focus {
    border-color: var(--w-500);
  }

  &.is-active {
    background: var(--w-50);
    color: var(--w-500);
  }
}

.icon {
  font-size: var(--font-size-default);
}

.badge {
  position: absolute;
  right: var(--space-minus-smaller);
  top: var(--space-minus-smaller);
}
</style>
