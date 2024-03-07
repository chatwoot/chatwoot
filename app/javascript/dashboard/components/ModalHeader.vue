<template>
  <div class="flex flex-col items-start pt-8 px-8 pb-0">
    <img v-if="headerImage" :src="headerImage" alt="No image" />
    <h2
      ref="modalHeaderTitle"
      class="text-slate-800 text-lg font-semibold dark:text-slate-50"
    >
      {{ headerTitle }}
    </h2>
    <p
      v-if="headerContent"
      ref="modalHeaderContent"
      class="w-full break-words text-slate-600 mt-2 text-sm dark:text-slate-300"
    >
      {{ headerContent }}
      <span
        v-if="headerContentValue"
        class="font-semibold text-sm text-slate-600 dark:text-slate-300"
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
