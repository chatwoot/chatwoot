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

<template>
  <div
    class="ml-0 mr-0 py-8 w-full"
    :class="{
      'border-b border-solid border-n-weak/60 dark:border-n-weak': showBorder,
    }"
  >
    <div class="grid grid-cols-1 lg:grid-cols-8 gap-6">
      <div class="col-span-2">
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
      <div class="col-span-6 xl:col-span-5">
        <slot />
      </div>
    </div>
  </div>
</template>
