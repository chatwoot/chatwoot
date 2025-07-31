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
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);

  &:not(:first-child) {
    margin-left: -0.25rem;
  }

  .gap-tight {
    margin-left: -0.5rem;
  }
}

.thumbnail-more-text {
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  @apply text-n-slate-11 bg-n-slate-4 border border-n-weak text-xs font-medium rounded-full px-2 ltr:-ml-2 rtl:-mr-2 inline-flex items-center relative;
}
</style>
