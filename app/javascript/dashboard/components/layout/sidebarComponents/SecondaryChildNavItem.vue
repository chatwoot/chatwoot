<template>
  <router-link
    v-slot="{ href, isActive, navigate }"
    :to="to"
    custom
    active-class="active"
  >
    <li
      class="text-slate-600 dark:text-slate-50 font-medium h-6 my-1 hover:bg-slate-25 hover:text-bg-50 flex items-center px-2 rounded-sm"
      :class="{
        'bg-woot-25 text-woot-500 dark:bg-slate-800 dark:text-slate-300': isActive,
        'text-truncate': shouldTruncate,
      }"
    >
      <a
        :href="href"
        class="inline-flex text-left max-w-full items-center"
        @click="navigate"
      >
        <span
          v-if="icon"
          class="inline-flex items-center justify-center w-4 rounded-sm bg-slate-100 p-0.5 mr-1.5"
        >
          <fluent-icon class="text-xxs" :icon="icon" size="12" />
        </span>

        <span
          v-if="labelColor"
          class="inline-flex rounded-sm bg-slate-100 h-3 w-3 ml-0.5 mr-2.5"
          :style="{ backgroundColor: labelColor }"
        />
        <span
          :title="menuTitle"
          class="text-sm "
          :class="{
            'text-ellipsis overflow-hidden whitespace-nowrap max-w-full': shouldTruncate,
          }"
        >
          {{ label }}
          <span
            v-if="showChildCount"
            class="bg-slate-50 rounded-xl text-slate-600 text-xxs font-medium mx-1 py-0 px-1"
          >
            {{ childItemCount }}
          </span>
        </span>
        <span
          v-if="warningIcon"
          class="inline-flex rounded-sm mr-1 bg-slate-100"
        >
          <fluent-icon
            v-tooltip.top-end="$t('SIDEBAR.FACEBOOK_REAUTHORIZE')"
            class="text-xxs"
            :icon="warningIcon"
            size="12"
          />
        </span>
      </a>
    </li>
  </router-link>
</template>
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
      return { 'text-truncate': this.shouldTruncate };
    },
    menuTitle() {
      return this.shouldTruncate ? this.label : '';
    },
  },
};
</script>
