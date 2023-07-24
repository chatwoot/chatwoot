<template>
  <transition-group
    name="wizard-items"
    tag="div"
    class="wizard-box"
    :class="classObject"
  >
    <div
      v-for="item in items"
      :key="item.route"
      class="item"
      :class="{ active: isActive(item), over: isOver(item) }"
    >
      <div class="flex items-center">
        <h3
          class="overflow-hidden whitespace-nowrap text-ellipsis leading-tight"
        >
          {{ item.title }}
        </h3>
        <span v-if="isOver(item)" class="completed">
          <fluent-icon icon="checkmark" />
        </span>
      </div>
      <span class="step">
        {{ items.indexOf(item) + 1 }}
      </span>
      <p>{{ item.body }}</p>
    </div>
  </transition-group>
</template>

<script>
/* eslint no-console: 0 */
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  props: {
    isFullwidth: Boolean,
    items: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    classObject() {
      return 'w-full';
    },
    activeIndex() {
      return this.items.findIndex(i => i.route === this.$route.name);
    },
  },
  methods: {
    isActive(item) {
      return this.items.indexOf(item) === this.activeIndex;
    },
    isOver(item) {
      return this.items.indexOf(item) < this.activeIndex;
    },
  },
};
</script>
<style lang="scss" scoped>
.wizard-box {
  .item {
    @apply cursor-pointer py-4 pr-4 pl-6 relative;

    &::before,
    &::after {
      @apply bg-slate-75 dark:bg-slate-600 content-[''] h-full absolute top-5 w-0.5;
    }

    &::before {
      @apply h-4 top-0;
    }

    &:first-child {
      &::before {
        @apply h-0;
      }
    }

    &:last-child {
      &::after {
        @apply h-0;
      }
    }

    &.active {
      h3 {
        @apply text-woot-500 dark:text-woot-500;
      }

      .step {
        @apply bg-woot-500 dark:bg-woot-500;
      }
    }

    &.over {
      &::after {
        @apply bg-woot-500 dark:bg-woot-500;
      }

      .step {
        @apply bg-woot-500 dark:bg-woot-500;
      }

      & + .item {
        &::before {
          @apply bg-woot-500 dark:bg-woot-500;
        }
      }
    }

    h3 {
      @apply text-slate-800 dark:text-slate-100 text-base pl-6;
    }

    .completed {
      @apply text-green-500 dark:text-green-500 ml-1;
    }

    p {
      @apply text-slate-600 dark:text-slate-300 text-sm m-0 pl-6;
    }

    .step {
      @apply bg-slate-75 dark:bg-slate-600 rounded-2xl font-medium w-4 left-4 leading-4 z-[999] absolute text-center text-white dark:text-white text-xxs top-5;

      i {
        @apply text-xxs;
      }
    }
  }
}
</style>
