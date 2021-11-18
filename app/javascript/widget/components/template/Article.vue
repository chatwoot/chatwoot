<template>
  <div v-if="!!items.length" class="chat-bubble agent">
    <div v-for="item in items" :key="item.link" class="article-item">
      <a :href="item.link" target="_blank" rel="noopener noreferrer nofollow">
        <span class="title flex items-center text-black-900 font-medium">
          <fluent-icon icon="link" class="mr-1" />
          <span>{{ item.title }}</span>
        </span>
        <span class="description">
          {{ truncateMessage(item.description) }}
        </span>
      </a>
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: {
    FluentIcon,
  },
  mixins: [messageFormatterMixin],
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
