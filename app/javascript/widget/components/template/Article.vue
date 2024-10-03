<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { useDarkMode } from 'widget/composables/useDarkMode';

export default {
  components: {
    FluentIcon,
  },
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },
  setup() {
    const { truncateMessage } = useMessageFormatter();
    const { getThemeClass } = useDarkMode();
    return { getThemeClass, truncateMessage };
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="!!items.length"
    class="chat-bubble agent"
    :class="getThemeClass('bg-white', 'dark:bg-slate-700')"
  >
    <div v-for="item in items" :key="item.link" class="article-item">
      <a :href="item.link" target="_blank" rel="noopener noreferrer nofollow">
        <span class="title flex items-center text-black-900 font-medium">
          <FluentIcon
            icon="link"
            class="mr-1"
            :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
          />
          <span :class="getThemeClass('text-slate-900', 'dark:text-slate-50')">
            {{ item.title }}
          </span>
        </span>
        <span
          class="description"
          :class="getThemeClass('text-slate-700', 'dark:text-slate-200')"
        >
          {{ truncateMessage(item.description) }}
        </span>
      </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import 'widget/assets/scss/variables.scss';

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
