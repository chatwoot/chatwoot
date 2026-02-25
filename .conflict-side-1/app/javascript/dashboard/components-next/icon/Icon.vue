<script setup>
import { h, isVNode } from 'vue';

const props = defineProps({
  icon: { type: [String, Object, Function], required: true },
});

const renderIcon = () => {
  if (!props.icon) return null;
  if (typeof props.icon === 'function' || isVNode(props.icon)) {
    return props.icon;
  }
  return h('span', { class: props.icon });
};
</script>

<template>
  <component :is="renderIcon" />
</template>
