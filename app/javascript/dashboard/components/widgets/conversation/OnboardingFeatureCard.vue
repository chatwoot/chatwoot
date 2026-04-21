<script setup>
defineProps({
  imageSrc: {
    type: String,
    default: '',
  },
  imageAlt: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  to: {
    type: String,
    default: '',
  },
  linkText: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="h-full w-full bg-s-surface border border-s-border rounded-lg p-4 flex flex-col"
  >
    <div class="flex-1 flex items-center justify-center">
      <img :src="imageSrc" :alt="imageAlt" class="h-36 w-auto mx-auto" />
    </div>
    <div class="mt-auto">
      <p
        class="text-base text-s-primary font-interDisplay font-semibold tracking-[0.3px]"
      >
        {{ title }}
      </p>
      <p class="text-s-muted text-sm">
        {{ description }}
      </p>
      <router-link
        v-if="to"
        :to="{ name: to }"
        class="no-underline text-s-brand text-sm font-medium"
      >
        <span>{{ linkText }}</span>
        <span class="ml-2">{{ `→` }}</span>
      </router-link>
    </div>
  </div>
</template>
