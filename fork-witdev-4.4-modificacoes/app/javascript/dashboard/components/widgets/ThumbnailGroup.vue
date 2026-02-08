<script>
import Thumbnail from './Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  props: {
    usersList: {
      type: Array,
      default: () => [],
    },
    size: {
      type: String,
      default: '24px',
    },
    showMoreThumbnailsCount: {
      type: Boolean,
      default: false,
    },
    moreThumbnailsText: {
      type: String,
      default: '',
    },
    gap: {
      type: String,
      default: 'normal',
      validator(value) {
        // The value must match one of these strings
        return ['normal', '', 'tight'].includes(value);
      },
    },
  },
};
</script>

<template>
  <div class="overlapping-thumbnails">
    <Thumbnail
      v-for="user in usersList"
      :key="user.id"
      v-tooltip="user.name"
      :title="user.name"
      :src="user.thumbnail"
      :username="user.name"
      has-border
      :size="size"
      :class="`overlapping-thumbnail gap-${gap}`"
    />
    <span v-if="showMoreThumbnailsCount" class="thumbnail-more-text">
      {{ moreThumbnailsText }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.overlapping-thumbnails {
  display: flex;
}

.overlapping-thumbnail {
  position: relative;
  box-shadow: var(--shadow-small);

  &:not(:first-child) {
    margin-left: var(--space-minus-smaller);
  }

  .gap-tight {
    margin-left: var(--space-minus-small);
  }
}

.thumbnail-more-text {
  display: inline-flex;
  align-items: center;
  position: relative;

  margin-left: var(--space-minus-small);
  padding: 0 var(--space-small);
  box-shadow: var(--shadow-small);
  background: var(--color-background);
  border-radius: var(--space-giga);
  border: 1px solid var(--white);

  color: var(--s-600);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
