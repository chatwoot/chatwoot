<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';

defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  features: { type: Array, default: () => [] },
});

const emit = defineEmits(['click']);

const handleClick = () => {
  emit('click');
};
</script>

<template>
  <CardLayout class="[&>div]:px-5 cursor-pointer" @click="handleClick">
    <div class="flex flex-col items-start gap-2">
      <div class="flex justify-between w-full items-center">
        <h3 class="text-n-slate-12 text-base font-medium">{{ title }}</h3>
        <Button
          xs
          slate
          ghost
          icon="i-lucide-chevron-right"
          @click.stop="handleClick"
        />
      </div>
      <p class="text-n-slate-11 text-sm mb-0">{{ description }}</p>
    </div>

    <ul class="flex flex-col items-start gap-3 mt-3">
      <li
        v-for="feature in features"
        :key="feature.id"
        class="flex items-center gap-3 text-sm"
      >
        <Icon
          :icon="feature.icon"
          class="text-n-slate-11 size-4 flex-shrink-0"
        />
        {{ feature.label }}
      </li>
    </ul>
  </CardLayout>
</template>
