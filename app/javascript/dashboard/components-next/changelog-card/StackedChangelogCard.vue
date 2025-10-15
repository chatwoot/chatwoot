<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
  primaryAction: {
    type: Object,
    default: () => ({ label: 'Read more', color: 'slate' }),
  },
  secondaryAction: {
    type: Object,
    default: () => ({ label: 'Dismiss', color: 'slate' }),
  },
  showActions: {
    type: Boolean,
    default: true,
  },
  isDismissing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['readMore', 'dismiss', 'cardClick']);

const handleReadMore = () => {
  emit('readMore', { card: props.card });
};

const handleDismiss = () => {
  emit('dismiss', { card: props.card });
};

const handleCardClick = () => {
  emit('cardClick', { card: props.card });
};
</script>

<template>
  <div
    data-testid="changelog-card"
    class="flex flex-col justify-between p-3 w-full rounded-lg border shadow-sm transition-all duration-200 cursor-pointer border-n-weak hover:shadow-md bg-n-background text-n-slate-12"
    :class="{ 'animate-fade-out pointer-events-none': isDismissing }"
    @click="handleCardClick"
  >
    <div>
      <h5
        :title="card.title"
        class="mb-1 text-sm font-semibold line-clamp-1 text-n-slate-12"
      >
        {{ card.title }}
      </h5>
      <p
        :title="card.excerpt"
        class="mb-0 text-xs leading-relaxed text-n-slate-11 line-clamp-2"
      >
        {{ card.excerpt }}
      </p>
    </div>

    <div
      v-if="card.feature_image"
      class="block overflow-hidden my-3 rounded-md border border-n-weak/40"
    >
      <img
        :src="card.feature_image"
        :alt="`${card.title} preview image`"
        class="object-cover w-full h-24 rounded-md"
        loading="lazy"
      />
    </div>
    <div
      v-else
      class="block overflow-hidden my-3 rounded-md border border-n-weak/40"
    >
      <img
        src="https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600"
        :alt="`${card.title} preview image`"
        class="object-cover w-full h-24 rounded-md"
        loading="lazy"
      />
    </div>

    <div v-if="showActions" class="flex justify-between items-center mt-2">
      <Button
        :label="primaryAction.label"
        :color="primaryAction.color"
        link
        sm
        class="text-xs font-normal hover:!no-underline"
        @click.stop="handleReadMore"
      />
      <Button
        :label="secondaryAction.label"
        :color="secondaryAction.color"
        link
        sm
        class="text-xs font-normal hover:!no-underline"
        @click.stop="handleDismiss"
      />
    </div>
  </div>
</template>

<style scoped>
@keyframes fade-out {
  from {
    opacity: 1;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(0.95);
  }
}

.animate-fade-out {
  animation: fade-out 0.2s ease-out forwards;
}
</style>
