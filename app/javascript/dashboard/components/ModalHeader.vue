<template>
  <div class="flex flex-col items-start px-8 pt-8 pb-0">
    <img v-if="headerImage" :src="headerImage" alt="No image" />
    <h2
      ref="modalHeaderTitle"
      class="text-base font-semibold leading-6 text-slate-800 dark:text-slate-50"
    >
      {{ headerTitle }}
    </h2>
    <p
      v-if="headerContent"
      ref="modalHeaderContent"
      class="w-full mt-2 text-sm leading-5 break-words text-slate-600 dark:text-slate-300"
    >
      {{ headerContent }}
      <span
        v-if="headerContentValue"
        class="text-sm font-semibold text-slate-600 dark:text-slate-300"
      >
        {{ headerContentValue }}
      </span>
    </p>
    <slot />
  </div>
</template>

<script>
export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
    headerContentValue: {
      type: String,
      default: '',
    },
    headerImage: {
      type: String,
      default: '',
    },
  },
};
</script>
