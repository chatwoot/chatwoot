<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  greeting: { type: String, required: true },
  subtitle: { type: String, default: '' },
  continueLabel: { type: String, default: 'Continue' },
  isLoading: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});

defineEmits(['continue']);
</script>

<template>
  <div
    class="relative flex text-body-main items-start justify-center w-full min-h-screen bg-n-surface-2 py-12 px-4 overflow-hidden"
  >
    <!-- Grid background with corner fade -->
    <div
      class="absolute inset-0 bg-[size:96px_96px] bg-[image:linear-gradient(to_right,rgb(var(--border-weak))_1px,transparent_1px),linear-gradient(to_bottom,rgb(var(--border-weak))_1px,transparent_1px)] [mask-image:radial-gradient(ellipse_80%_80%_at_100%_0%,black_5%,transparent_50%),radial-gradient(ellipse_80%_80%_at_0%_100%,black_5%,transparent_50%)] [mask-composite:add] [-webkit-mask-composite:source-over]"
    />
    <div class="relative w-full max-w-[580px]">
      <div class="relative ps-12">
        <!-- Timeline dotted line -->
        <svg
          class="absolute start-[16px] top-10 bottom-20 overflow-visible text-n-slate-5"
          width="1"
          height="100%"
          preserveAspectRatio="none"
        >
          <line
            x1="0"
            y1="0"
            x2="0"
            y2="97%"
            stroke="currentColor"
            stroke-width="1"
            stroke-dasharray="3 3"
          />
        </svg>

        <!-- Greeting -->
        <div class="mb-6 -ms-12 flex items-start gap-4">
          <div
            class="flex items-center justify-center w-8 h-8 z-10 flex-shrink-0"
          >
            <slot name="greeting-icon">
              <span class="i-woot-onboarding-greeting size-4 text-n-slate-7" />
            </slot>
          </div>
          <div>
            <h1 class="text-heading-1 text-n-slate-12">
              {{ greeting }}
            </h1>
            <p v-if="subtitle" class="text-sm text-n-slate-11">
              {{ subtitle }}
            </p>
          </div>
        </div>

        <!-- Sections -->
        <slot />
      </div>

      <!-- Continue button with curved connector -->
      <div class="relative ps-12 overflow-visible">
        <!-- Curved line (absolutely positioned, doesn't affect layout) -->
        <svg
          width="48"
          height="40"
          viewBox="0 0 47 40"
          fill="none"
          class="absolute start-0 top-0 overflow-visible rtl:-scale-x-100"
        >
          <defs>
            <linearGradient
              id="line-gradient"
              x1="15"
              y1="0"
              x2="48"
              y2="20"
              gradientUnits="userSpaceOnUse"
            >
              <stop offset="0%" stop-color="rgb(var(--slate-5))" />
              <stop offset="100%" stop-color="rgb(var(--blue-9))" />
            </linearGradient>
          </defs>
          <path
            d="M15.5 0 C15.5 24, 15.5 20, 48 20"
            stroke="url(#line-gradient)"
            stroke-width="1"
            stroke-dasharray="3 3"
            fill="none"
          />
        </svg>
        <!-- Triangle pointer (positioned at button's leading edge, pointing inward) -->
        <svg
          width="6"
          height="6"
          viewBox="0 0 6 6"
          fill="none"
          class="absolute start-[42px] top-1/2 -translate-y-1/2 z-10 rtl:-scale-x-100"
        >
          <path d="M6 0L0 3L6 6Z" fill="rgb(var(--blue-9))" />
        </svg>
        <NextButton
          type="submit"
          blue
          :is-loading="isLoading"
          :disabled="disabled"
          class="w-full justify-center"
          @click="$emit('continue')"
        >
          {{ continueLabel }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
