<script setup>
defineProps({
  greeting: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>

<template>
  <div
    class="relative flex text-body-main items-start justify-center w-full min-h-screen bg-white py-12 px-4 overflow-hidden"
  >
    <!-- Grid background with corner fade -->
    <div
      class="absolute inset-0 bg-[size:96px_96px] bg-[image:linear-gradient(to_right,rgb(var(--border-weak))_1px,transparent_1px),linear-gradient(to_bottom,rgb(var(--border-weak))_1px,transparent_1px)] [mask-image:radial-gradient(ellipse_80%_80%_at_100%_0%,black_5%,transparent_50%),radial-gradient(ellipse_80%_80%_at_0%_100%,black_5%,transparent_50%)] [mask-composite:add] [-webkit-mask-composite:source-over]"
    />
    <div class="relative w-full max-w-[580px]">
      <div class="relative pl-12">
        <!-- Timeline dotted line -->
        <div
          class="absolute left-[15px] top-10 bottom-10 border-l border-dashed border-n-slate-3"
        />

        <!-- Greeting -->
        <div class="mb-6 -ml-12 flex items-start gap-4">
          <div
            class="flex items-center justify-center w-8 h-8 z-10 flex-shrink-0"
          >
            <slot name="greeting-icon">
              <svg
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M8.00008 14.0007C8.73646 14.0007 9.33341 13.4037 9.33341 12.6673C9.33341 11.9309 8.73646 11.334 8.00008 11.334C7.2637 11.334 6.66675 11.9309 6.66675 12.6673C6.66675 13.4037 7.2637 14.0007 8.00008 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M8.00008 4.66667C8.73646 4.66667 9.33341 4.06971 9.33341 3.33333C9.33341 2.59695 8.73646 2 8.00008 2C7.2637 2 6.66675 2.59695 6.66675 3.33333C6.66675 4.06971 7.2637 4.66667 8.00008 4.66667Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M10.6666 9.33268C11.403 9.33268 11.9999 8.73573 11.9999 7.99935C11.9999 7.26297 11.403 6.66602 10.6666 6.66602C9.93021 6.66602 9.33325 7.26297 9.33325 7.99935C9.33325 8.73573 9.93021 9.33268 10.6666 9.33268Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M13.3333 14.0007C14.0697 14.0007 14.6667 13.4037 14.6667 12.6673C14.6667 11.9309 14.0697 11.334 13.3333 11.334C12.597 11.334 12 11.9309 12 12.6673C12 13.4037 12.597 14.0007 13.3333 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M2.66659 14.0007C3.40297 14.0007 3.99992 13.4037 3.99992 12.6673C3.99992 11.9309 3.40297 11.334 2.66659 11.334C1.93021 11.334 1.33325 11.9309 1.33325 12.6673C1.33325 13.4037 1.93021 14.0007 2.66659 14.0007Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path
                  d="M5.33333 9.33268C6.06971 9.33268 6.66667 8.73573 6.66667 7.99935C6.66667 7.26297 6.06971 6.66602 5.33333 6.66602C4.59695 6.66602 4 7.26297 4 7.99935C4 8.73573 4.59695 9.33268 5.33333 9.33268Z"
                  stroke="#D3D4DB"
                  stroke-width="1.33333"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
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

      <!-- Footer (continue button etc.) -->
      <div v-if="$slots.footer" class="pl-12">
        <slot name="footer" />
      </div>
    </div>
  </div>
</template>
