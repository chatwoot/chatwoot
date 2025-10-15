<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
  primaryAction: {
    type: Object,
    default: () => ({ label: 'Try now', color: 'slate' }),
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

const emit = defineEmits(['primaryAction', 'secondaryAction', 'cardClick']);

const handlePrimaryAction = () => {
  emit('primaryAction', { card: props.card });
};

const handleSecondaryAction = () => {
  emit('secondaryAction', { card: props.card });
};

const handleCardClick = () => {
  emit('cardClick', { card: props.card });
};
</script>

<template>
  <div
    data-testid="changelog-card"
    class="flex flex-col justify-between w-full p-3 border-n-weak hover:shadow-md rounded-lg border bg-n-background text-n-slate-12 shadow-sm transition-all duration-200 cursor-pointer"
    :class="{ 'animate-fade-out pointer-events-none': isDismissing }"
    @click="handleCardClick"
  >
    <div>
      <h5
        :title="card.title"
        class="line-clamp-1 font-semibold text-sm text-n-slate-12 mb-1"
      >
        {{ card.title }}
      </h5>
      <p
        :title="card.description"
        class="text-xs text-n-slate-11 line-clamp-2 mb-0 leading-relaxed"
      >
        {{ card.description }}
      </p>
    </div>

    <a
      v-if="card.media"
      :href="card.media.src"
      target="_blank"
      rel="noopener noreferrer"
      class="my-3 border border-n-weak/40 rounded-md block overflow-hidden"
      @click.stop
    >
      <video
        v-if="card.media.type === 'video'"
        :src="card.media.src"
        :alt="card.media.alt || card.title"
        class="w-full h-24 object-cover rounded-md"
        :poster="card.media.poster"
        controls
        preload="metadata"
      />
      <img
        v-else-if="card.media.type === 'image'"
        :src="card.media.src"
        :alt="card.media.alt || card.title"
        class="w-full h-24 object-cover rounded-md"
        loading="lazy"
      />
    </a>

    <div v-if="showActions" class="mt-2 flex items-center justify-between">
      <Button
        :label="primaryAction.label"
        :color="primaryAction.color"
        link
        sm
        class="text-xs font-normal hover:!no-underline"
        @click.stop="handlePrimaryAction"
      />
      <Button
        :label="secondaryAction.label"
        :color="secondaryAction.color"
        link
        sm
        class="text-xs font-normal hover:!no-underline"
        @click.stop="handleSecondaryAction"
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
