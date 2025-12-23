<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  usersList: {
    type: Array,
    default: () => [],
  },
  size: {
    type: Number,
    default: 24,
  },
  showMoreCount: {
    type: Boolean,
    default: false,
  },
  moreCountText: {
    type: String,
    default: '',
  },
  gap: {
    type: String,
    default: 'normal',
    validator(value) {
      // The value must match one of these strings
      return ['normal', 'tight'].includes(value);
    },
  },
});

const gapClass = computed(() => {
  if (props.gap === 'tight') {
    return 'ltr:[&:not(:first-child)]:-ml-2 rtl:[&:not(:first-child)]:-mr-2';
  }
  return 'ltr:[&:not(:first-child)]:-ml-1 rtl:[&:not(:first-child)]:-mr-1';
});

const morePlaceholderClass = computed(() => {
  if (props.gap === 'tight') {
    return 'ltr:-ml-2 rtl:-mr-2';
  }
  return 'ltr:-ml-1 rtl:-mr-1';
});
</script>

<template>
  <div class="flex">
    <Avatar
      v-for="user in usersList"
      :key="user.id"
      v-tooltip="user.name"
      :title="user.name"
      :src="user.thumbnail"
      :name="user.name"
      :size="size"
      class="[&>span]:outline [&>span]:outline-1 [&>span]:outline-n-background [&>span]:shadow"
      :class="gapClass"
      rounded-full
    />
    <span
      v-if="showMoreCount"
      class="text-n-slate-11 bg-n-button-color outline outline-1 outline-n-weak text-xs font-420 rounded-full px-2 inline-flex items-center shadow relative"
      :class="morePlaceholderClass"
    >
      {{ moreCountText }}
    </span>
  </div>
</template>
