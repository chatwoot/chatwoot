<template>
  <div
    class="flex w-full pl-4 pr-2 py-2 h-14 justify-between items-center border-b border-slate-50 dark:border-slate-800/50"
  >
    <div class="flex items-center gap-1.5">
      <h1 class="font-medium text-slate-900 dark:text-slate-25 text-xl">
        Inbox
      </h1>
      <div
        role="button"
        class="flex gap-1 items-center py-1 px-2 border border-slate-100 dark:border-slate-700/50 rounded-md"
        @click="openInboxDisplayMenu"
      >
        <span
          class="text-slate-600 relative -top-px dark:text-slate-200 text-xs text-center font-medium"
        >
          Display
        </span>
        <fluent-icon
          icon="chevron-down"
          size="12"
          class="text-slate-600 dark:text-slate-200"
        />
      </div>
    </div>
    <div class="flex gap-1 items-center">
      <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="filter"
        @click="openInboxFilter"
      />
      <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="mail-inbox"
        @click="openInboxOptionsMenu"
      />
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    openInboxDisplayMenu() {
      this.$emit('open-display-menu');
    },
    openInboxFilter() {
      this.$emit('open-filter');
    },
    openInboxOptionsMenu() {
      this.$emit('open-options-menu');
    },
  },
};
</script>

<style></style>
