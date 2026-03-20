<script setup>
import { computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  variant: {
    type: String,
    default: 'info',
    validator: value => ['info', 'success', 'warning'].includes(value),
  },
  ctaText: {
    type: String,
    default: '',
  },
  ctaLink: {
    type: String,
    default: '',
  },
  ctaExternal: {
    type: Boolean,
    default: false,
  },
  showIcon: {
    type: Boolean,
    default: true,
  },
  logoSrc: {
    type: String,
    default: '',
  },
  logoAlt: {
    type: String,
    default: 'Logo',
  },
});

const emit = defineEmits(['ctaClick']);

const variantClasses = computed(() => {
  const variants = {
    info: {
      container: 'bg-woot-50 border-woot-200',
      icon: 'i-lucide-info text-woot-600',
      text: 'text-woot-700',
      description: 'text-woot-600',
    },
    success: {
      container: 'bg-green-50 border-green-200',
      icon: 'i-lucide-sparkles text-green-600',
      text: 'text-green-700',
      description: 'text-green-600',
    },
    warning: {
      container: 'bg-yellow-50 border-yellow-200',
      icon: 'i-lucide-alert-circle text-yellow-600',
      text: 'text-yellow-700',
      description: 'text-yellow-600',
    },
  };
  return variants[props.variant];
});

const handleCtaClick = () => {
  emit('ctaClick');
};
</script>

<template>
  <div
    class="relative flex items-start gap-3 p-4 rounded-lg border"
    :class="variantClasses.container"
  >
    <div v-if="logoSrc || showIcon" class="flex-shrink-0 mt-0.5">
      <img
        v-if="logoSrc"
        :src="logoSrc"
        :alt="logoAlt"
        class="w-8 h-8 object-contain"
      />
      <i v-else class="w-5 h-5" :class="variantClasses.icon" />
    </div>

    <div class="flex-1 min-w-0">
      <h3 class="text-sm font-semibold mb-1" :class="variantClasses.text">
        {{ title }}
      </h3>
      <p class="text-sm leading-relaxed" :class="variantClasses.description">
        {{ description }}
      </p>

      <div v-if="ctaText" class="mt-3">
        <a
          v-if="ctaLink"
          :href="ctaLink"
          :target="ctaExternal ? '_blank' : '_self'"
          :rel="ctaExternal ? 'noopener noreferrer' : undefined"
          class="inline-block"
        >
          <NextButton
            sm
            :color-scheme="variant === 'success' ? 'primary' : 'secondary'"
            type="button"
          >
            {{ ctaText }}
          </NextButton>
        </a>
        <NextButton
          v-else
          sm
          :color-scheme="variant === 'success' ? 'primary' : 'secondary'"
          type="button"
          @click="handleCtaClick"
        >
          {{ ctaText }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
