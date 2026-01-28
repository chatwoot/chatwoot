<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  card: {
    type: Object,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
  isDismissing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['readMore', 'dismiss', 'imgClick']);

const handleReadMore = () => {
  emit('readMore');
};

const handleDismiss = () => {
  emit('dismiss');
};

const handleImgClick = () => {
  emit('imgClick');
};
</script>

<template>
  <div
    data-testid="changelog-card"
    class="flex flex-col justify-between p-3 w-full rounded-lg border shadow-sm transition-all duration-200 border-n-weak bg-n-card text-n-slate-12"
    :class="{
      'animate-fade-out pointer-events-none': isDismissing,
      'hover:shadow': isActive,
    }"
  >
    <div>
      <h5
        :title="card.meta_title"
        class="mb-1 text-sm font-semibold line-clamp-1 text-n-slate-12"
      >
        {{ card.meta_title }}
      </h5>
      <p
        :title="card.meta_description"
        class="mb-0 text-xs leading-relaxed text-n-slate-11 line-clamp-2"
      >
        {{ card.meta_description }}
      </p>
    </div>

    <div
      v-if="card.feature_image"
      class="block overflow-hidden my-3 rounded-md border border-n-weak/40"
    >
      <img
        :src="card.feature_image"
        :alt="`${card.title} preview image`"
        class="object-cover w-full h-24 rounded-md cursor-pointer"
        loading="lazy"
        @click.stop="handleImgClick"
      />
    </div>
    <div
      v-else
      class="block overflow-hidden my-3 rounded-md border border-n-weak/40"
    >
      <img
        :src="card.feature_image"
        :alt="`${card.title} preview image`"
        class="object-cover w-full h-24 rounded-md cursor-pointer"
        loading="lazy"
        @click.stop="handleImgClick"
      />
    </div>

    <div class="flex justify-between items-center mt-1">
      <Button
        label="Read more"
        color="slate"
        link
        sm
        class="text-xs font-normal hover:!no-underline"
        @click.stop="handleReadMore"
      />
      <Button
        label="Dismiss"
        color="slate"
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
