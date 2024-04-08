<template>
  <div
    :class="`flex items-center px-0 py-2 text-xs font-medium text-left uppercase col-span-${span} text-slate-700 dark:text-slate-100 rtl:text-right`"
  >
    <slot v-if="labelKey">
      {{ $t(labelKey) }}
    </slot>
  </div>
</template>

<script>
export default {
  name: 'TableHeaderCell',
  props: {
    span: {
      type: Number,
      required: true,
    },
    labelKey: {
      type: String,
      required: true,
    },
  },
};
</script>
