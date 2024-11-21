<script setup>
import { computed } from 'vue';
import TextBubble from './bubbles/Text.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  variant: {
    type: String,
    required: true,
    validator: value => ['user', 'agent', 'system', 'private'].includes(value),
  },
  orientation: {
    type: String,
    default: 'left',
    validator: value => ['left', 'right', 'center'].includes(value),
  },
  text: {
    type: String,
    default: 'Hello World',
  },
  user: {
    type: String,
    default: '',
  },
});

const flexOrientationClass = computed(() => {
  const map = {
    left: 'justify-start',
    right: 'justify-end',
    center: 'justify-center',
  };

  return map[props.orientation];
});

const gridClass = computed(() => {
  const map = {
    left: 'grid grid-cols-[24px_1fr]',
    right: 'grid grid-cols-[1fr_24px]',
  };

  return map[props.orientation];
});

const gridTemplate = computed(() => {
  const map = {
    left: `
      "avatar bubble"
      "spacer meta"
    `,
    right: `
      "bubble avatar"
      "meta spacer"
    `,
  };

  return map[props.orientation];
});
</script>

<template>
  <div class="flex w-full" :class="flexOrientationClass">
    <div v-if="variant === 'system'">
      <TextBubble v-bind="props" />
    </div>
    <div
      v-else
      :class="gridClass"
      class="gap-x-3 gap-y-2 grid-area"
      :style="{
        gridTemplateAreas: gridTemplate,
        gridTemplateColumns:
          props.orientation === 'center' ? '1fr' : 'auto 1fr',
      }"
    >
      <div class="[grid-area:avatar] flex items-end">
        <Avatar :name="user" src="" size="24" />
      </div>
      <TextBubble v-bind="props" class="[grid-area:bubble]" />
      <div
        class="[grid-area:meta] text-xs text-n-slate-11 flex items-center gap-1.5"
        :class="flexOrientationClass"
      >
        <span>{{ user }} {{ '• 1m ago' }}</span>
        <Icon
          v-if="variant === 'private'"
          icon="i-lucide-lock-keyhole"
          class="text-n-slate-10 size-3"
        />
      </div>
    </div>
  </div>
</template>
