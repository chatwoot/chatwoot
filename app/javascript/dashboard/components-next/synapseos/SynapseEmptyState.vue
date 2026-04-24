<script setup>
// CUSTOMIZAÇÃO_SYNAPSEOS — Empty state reutilizável.
// Uso:
//   <SynapseEmptyState
//     icon="i-lucide-inbox"
//     title="Sem dados no período"
//     description="Conecte uma inbox ou avance leads no pipeline pra começar a medir."
//   >
//     <SynapseButton variant="primary" size="sm">Conectar inbox</SynapseButton>
//   </SynapseEmptyState>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  icon: { type: String, default: 'i-lucide-inbox' },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  size: {
    type: String,
    default: 'md',
    validator: v => ['sm', 'md', 'lg'].includes(v),
  },
});
</script>

<template>
  <div
    class="flex flex-col items-center justify-center text-center mx-auto"
    :class="{
      'gap-1.5 py-4 max-w-xs': size === 'sm',
      'gap-2 py-6 max-w-sm': size === 'md',
      'gap-3 py-10 max-w-md': size === 'lg',
    }"
  >
    <div
      class="rounded-full bg-s-subtle border border-s-border flex items-center justify-center mb-1"
      :class="{
        'size-10': size === 'sm',
        'size-12': size === 'md',
        'size-14': size === 'lg',
      }"
    >
      <Icon
        :icon="icon"
        class="text-s-muted"
        :class="{
          'size-4': size === 'sm',
          'size-5': size === 'md',
          'size-6': size === 'lg',
        }"
      />
    </div>
    <h3
      class="font-semibold text-s-secondary"
      :class="{
        'text-xs': size === 'sm',
        'text-sm': size === 'md',
        'text-base': size === 'lg',
      }"
    >
      {{ title }}
    </h3>
    <p
      v-if="description"
      class="text-s-muted leading-relaxed"
      :class="{
        'text-xs': size === 'sm' || size === 'md',
        'text-sm': size === 'lg',
      }"
    >
      {{ description }}
    </p>
    <div v-if="$slots.default" class="mt-2">
      <slot />
    </div>
  </div>
</template>
