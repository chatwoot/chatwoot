<template>
  <div
    class="ml-0 mr-0 flex pt-0 pr-4 pb-4 pl-0"
    :class="{
      'pt-4 border-b border-solid border-slate-50 dark:border-slate-700/30':
        showBorder,
    }"
  >
    <div class="w-[30%] min-w-0 max-w-[30%] pr-12">
      <p
        v-if="title"
        class="text-base text-woot-500 dark:text-woot-500 mb-0 font-medium"
      >
        {{ title }}
      </p>
      <p class="text-sm mb-2">
        <slot v-if="subTitle" name="subTitle">
          {{ subTitle }}
        </slot>
      </p>
      <p v-if="note">
        <span class="font-semibold">{{ $t('INBOX_MGMT.NOTE') }}</span>
        {{ note }}
      </p>
    </div>
    <div class="w-[50%] min-w-0 max-w-[50%]">
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
    showBorder: {
      type: Boolean,
      default: true,
    },
    note: {
      type: String,
      default: '',
    },
  },
};
</script>
