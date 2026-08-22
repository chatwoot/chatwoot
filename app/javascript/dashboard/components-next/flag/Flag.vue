<script setup>
import { h } from 'vue';
// Vendored copy of flag-icons' stylesheet (see assets/css). Without it the
// `fi fi-xx` classes below render an empty span.
import 'assets/css/flag-icons.min.css';

const props = defineProps({
  country: { type: String, required: true },
  squared: { type: Boolean, default: false },
});

const renderFlag = () => {
  const classes = ['fi', `fi-${props.country.toLowerCase()}`, 'flex-shrink-0'];
  if (props.squared) {
    classes.push('fis');
  }
  return h('span', { class: classes });
};
</script>

<template>
  <component :is="renderFlag" />
</template>
