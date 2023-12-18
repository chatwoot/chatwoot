<template>
  <div
    v-if="!hidden"
    class="flex items-center gap-2 p-2 text-sm rounded-md"
    :class="{
      'text-slate-800 dark:text-slate-100 bg-slate-50 dark:bg-slate-800':
        isActive,
      'opacity-50': !isActive && !isComplete,
      hidden: hidden,
    }"
  >
    <div
      class="grid w-4 h-4 font-bold rounded-full text-xxs place-content-center"
      :class="{
        'bg-slate-200 dark:bg-slate-600': !isComplete,
        'bg-green-500': isComplete,
      }"
    >
      <fluent-icon
        v-if="isComplete"
        size="13"
        class="text-white"
        icon="checkmark"
      />
      <template v-else>
        {{ stepNumber }}
      </template>
    </div>
    <span
      :class="{
        'line-through': isComplete,
      }"
    >
      {{ title }}
    </span>
  </div>
</template>

<script>
export default {
  name: 'ModalStep',
  props: {
    title: {
      type: String,
      required: true,
    },
    stepNumber: {
      type: Number,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: false,
    },
    hidden: {
      type: Boolean,
      default: false,
    },
    isComplete: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
