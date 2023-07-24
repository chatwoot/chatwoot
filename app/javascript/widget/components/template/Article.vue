<template>
  <div
    v-if="!!items.length"
    class="chat-bubble agent"
    :class="$dm('bg-white', 'dark:bg-slate-700')"
  >
    <div v-for="item in items" :key="item.link" class="article-item">
      <a :href="item.link" target="_blank" rel="noopener noreferrer nofollow">
        <span class="title flex items-center text-black-900 font-medium">
          <fluent-icon
            icon="link"
            class="mr-1"
            :class="$dm('text-black-900', 'dark:text-slate-50')"
          />
          <span :class="$dm('text-slate-900', 'dark:text-slate-50')">{{
            item.title
          }}</span>
        </span>
        <span
          class="description"
          :class="$dm('text-slate-700', 'dark:text-slate-200')"
        >
          {{ truncateMessage(item.description) }}
        </span>
      </a>
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  components: {
    FluentIcon,
  },
  mixins: [messageFormatterMixin, darkModeMixin],
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.article-item {
  border-bottom: 1px solid $color-border;
  font-size: $font-size-default;
  padding: $space-small 0;

  a {
    color: $color-body;
    text-decoration: none;
  }

  .description {
    display: block;
    margin-top: $space-smaller;
  }

  &:last-child {
    border-bottom: 0;
  }
}
</style>
