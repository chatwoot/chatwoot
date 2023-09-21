<template>
  <div class="flex items-center h-[2.375rem] min-w-0 py-0 px-1">
    <span
      class="inline-flex rounded mr-1 rtl:ml-1 rtl:mr-0 bg-slate-25 dark:bg-slate-700 p-0.5 items-center flex-shrink-0 justify-center w-6 h-6"
    >
      <fluent-icon
        :icon="computedInboxIcon"
        size="14"
        class="text-slate-800 dark:text-slate-200"
      />
    </span>
    <div class="flex flex-col w-full min-w-0 ml-1 mr-1">
      <h5 class="option__title">
        {{ name }}
      </h5>
      <p
        class="option__body overflow-hidden whitespace-nowrap text-ellipsis"
        :title="inboxIdentifier"
      >
        {{ inboxIdentifier || computedInboxType }}
      </p>
    </div>
  </div>
</template>

<script>
import {
  getInboxClassByType,
  getReadableInboxByType,
} from 'dashboard/helper/inbox';

export default {
  components: {},
  props: {
    name: {
      type: String,
      default: '',
    },
    inboxIdentifier: {
      type: String,
      default: '',
    },
    channelType: {
      type: String,
      default: '',
    },
  },
  computed: {
    computedInboxIcon() {
      if (!this.channelType) return 'chat';
      const classByType = getInboxClassByType(
        this.channelType,
        this.inboxIdentifier
      );
      return classByType;
    },
    computedInboxType() {
      if (!this.channelType) return 'chat';
      const classByType = getReadableInboxByType(
        this.channelType,
        this.inboxIdentifier
      );
      return classByType;
    },
  },
};
</script>

<style lang="scss" scoped>
.option__body {
  @apply inline-block text-slate-600 dark:text-slate-200 leading-[1.3] min-w-0 m-0;
}
.option__title {
  @apply leading-[1.1] text-xs m-0 text-slate-800 dark:text-slate-100;
}
</style>
