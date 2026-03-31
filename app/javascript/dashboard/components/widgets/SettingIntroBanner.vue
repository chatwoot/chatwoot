<script setup>
import BackButton from 'dashboard/components/widgets/BackButton.vue';

defineProps({
  headerTitle: { type: String, default: '' },
  headerContent: { type: String, default: '' },
  headerImage: { type: String, default: '' },
  backUrl: { type: [String, Object], default: '' },
});
</script>

<template>
  <div class="border-b border-solid border-n-weak/60">
    <div class="max-w-6xl w-full mx-auto pt-4 pb-0 px-8">
      <h2 class="flex items-center gap-3 text-2xl text-n-slate-12 mb-1 font-medium">
        <BackButton v-if="backUrl" :back-url="backUrl" />
        {{ headerTitle }}
      </h2>
      <p v-if="headerContent" class="w-full text-n-slate-11 text-sm mb-2">
        {{ headerContent }}
      </p>
      <slot />
    </div>
  </div>
</template>
