<script setup>
import { computed } from 'vue';

const props = defineProps({
  width: {
    type: String,
    default: '',
  },
  align: {
    type: String,
    default: 'start',
    validator: value => ['start', 'center', 'end'].includes(value),
  },
  truncate: {
    type: Boolean,
    default: false,
  },
  whitespace: {
    type: String,
    default: 'normal',
    validator: value => ['normal', 'nowrap', 'pre', 'pre-wrap'].includes(value),
  },
});

const cellClasses = computed(() => {
  const classes = ['py-4 ltr:pr-4 rtl:pl-4'];

  if (props.width) {
    classes.push(props.width);
  }

  if (props.align === 'center') {
    classes.push('text-center');
  } else if (props.align === 'end') {
    classes.push('text-end');
  } else {
    classes.push('text-start');
  }

  if (props.truncate) {
    classes.push('max-w-0');
  }

  if (props.whitespace === 'nowrap') {
    classes.push('whitespace-nowrap');
  }

  return classes.join(' ');
});
</script>

<template>
  <td :class="cellClasses">
    <slot />
  </td>
</template>
