<template>
  <router-link v-slot="{ href, isActive, navigate }" :to="to" custom>
    <a
      v-tooltip.right="$t(`SIDEBAR.${name}`)"
      :href="href"
      class="text-slate-600 dark:text-woot-50 w-10 h-10 my-2 flex items-center justify-center rounded-lg hover:bg-woot-25 dark:hover:bg-slate-800 hover:text-woot-500"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500':
          isActive || isChildMenuActive,
      }"
      :rel="openInNewPage ? 'noopener noreferrer nofollow' : undefined"
      :target="openInNewPage ? '_blank' : undefined"
      @click="navigate"
    >
      <fluent-icon :icon="icon" />
      <span class="sr-only">{{ name }}</span>
      <span
        v-if="count"
        class="text-black-900 bg-yellow-500 absolute -top-1 -right-1"
      >
        {{ count }}
      </span>
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
