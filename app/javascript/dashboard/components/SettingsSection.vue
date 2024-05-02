<template>
  <div
    class="ml-0 mr-0 flex py-8 w-full xl:w-3/4 flex-col xl:flex-row"
    :class="{
      'border-b border-solid border-slate-50 dark:border-slate-700/30':
        showBorder,
    }"
  >
    <div class="w-full xl:w-1/4 min-w-0 xl:max-w-[30%] pr-12">
      <p
        v-if="title"
        class="text-base text-woot-500 dark:text-woot-500 mb-0 font-medium"
      >
        {{ title }}
      </p>
      <p
        class="text-sm mb-2 text-slate-700 dark:text-slate-300 leading-5 tracking-normal mt-2"
      >
        <slot v-if="subTitle" name="subTitle">
          {{ subTitle }}
        </slot>
      </p>
      <p v-if="note">
        <span class="font-semibold">{{ $t('INBOX_MGMT.NOTE') }}</span>
        {{ note }}
      </p>
    </div>
    <div class="w-full xl:w-1/2 min-w-0 xl:max-w-[50%]">
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
