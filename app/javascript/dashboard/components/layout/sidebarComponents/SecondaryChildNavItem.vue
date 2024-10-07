<script>
export default {
  props: {
    to: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
    labelColor: {
      type: String,
      default: '',
    },
    shouldTruncate: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: '',
    },
    warningIcon: {
      type: String,
      default: '',
    },
    showChildCount: {
      type: Boolean,
      default: false,
    },
    childItemCount: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    showIcon() {
      return {
        'overflow-hidden whitespace-nowrap text-ellipsis': this.shouldTruncate,
      };
    },
    isCountZero() {
      return this.childItemCount === 0;
    },
    menuTitle() {
      return this.shouldTruncate ? this.label : '';
    },
  },
};
</script>

<template>
  <router-link
    v-slot="{ href, isActive, navigate }"
    :to="to"
    custom
    active-class="active"
  >
    <li
      class="h-7 my-1 hover:bg-slate-25 hover:text-bg-50 flex items-center px-2 rounded-md dark:hover:bg-slate-800"
      :class="{
        'bg-woot-25 dark:bg-slate-800': isActive,
        'text-ellipsis overflow-hidden whitespace-nowrap max-w-full':
          shouldTruncate,
      }"
      @click="navigate"
    >
      <a
        :href="href"
        class="inline-flex text-left max-w-full w-full items-center"
      >
        <span
          v-if="icon"
          class="inline-flex items-center justify-center w-4 rounded-sm bg-slate-100 dark:bg-slate-700 p-0.5 mr-1.5 rtl:mr-0 rtl:ml-1.5"
        >
          <fluent-icon
            class="text-xxs text-slate-700 dark:text-slate-200"
            :class="{
              'text-woot-500 dark:text-woot-500': isActive,
            }"
            :icon="icon"
            size="12"
          />
        </span>

        <span
          v-if="labelColor"
          class="inline-flex rounded-sm bg-slate-100 h-3 w-3.5 mr-1.5 rtl:mr-0 rtl:ml-1.5 border border-slate-50 dark:border-slate-900"
          :style="{ backgroundColor: labelColor }"
        />
        <div
          class="items-center flex overflow-hidden whitespace-nowrap text-ellipsis w-full justify-between"
        >
          <span
            :title="menuTitle"
            class="text-sm text-slate-700 dark:text-slate-100"
            :class="{
              'text-woot-500 dark:text-woot-500': isActive,
              'text-ellipsis overflow-hidden whitespace-nowrap max-w-full':
                shouldTruncate,
            }"
          >
            {{ label }}
          </span>
          <span
            v-if="showChildCount"
            class="bg-slate-50 dark:bg-slate-700 rounded-full min-w-[18px] justify-center items-center flex text-xxs mx-1 py-0 px-1"
            :class="
              isCountZero
                ? `text-slate-300 dark:text-slate-500`
                : `text-slate-700 dark:text-slate-50`
            "
          >
            {{ childItemCount }}
          </span>
        </div>
        <span
          v-if="warningIcon"
          class="inline-flex mr-1 bg-red-50 dark:bg-red-900 p-0.5 rounded-sm"
        >
          <fluent-icon
            v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
            class="text-xxs text-red-500 dark:text-red-300"
            :icon="warningIcon"
            size="12"
          />
        </span>
      </a>
    </li>
  </router-link>
</template>
