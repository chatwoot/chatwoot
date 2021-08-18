<template>
  <div>
    <div class="contact_info" @click="$emit('click')">
      <span class="item-name text-block-title">
        {{ headerTitle }}
      </span>
      <i v-if="showItem" class="ion-chevron-down icon"></i>
      <i v-else class="ion-chevron-right icon"></i>
    </div>
    <slot></slot>
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    showItem: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.contact_info {
  display: flex;
  justify-content: space-between;
  width: 100%;
  cursor: pointer;
  user-select: none;
  padding: var(--space-smaller) 0;
  background: var(--color-background);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  margin-bottom: var(--space-small);
}

.item-name {
  font-weight: var(--font-weight-medium);
  color: var(--color---color-heading);
  padding: 0 var(--space-small);
}

.icon {
  margin-right: var(--space-small);
}
</style>
