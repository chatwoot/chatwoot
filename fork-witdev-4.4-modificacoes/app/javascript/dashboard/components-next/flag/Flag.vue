<script setup>
import { h, defineProps } from 'vue';

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

<style>
@import 'flag-icons/css/flag-icons.min.css';
</style>
