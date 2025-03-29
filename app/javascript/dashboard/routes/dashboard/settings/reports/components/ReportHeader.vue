<script setup>
import BackButton from 'dashboard/components/widgets/BackButton.vue';

defineProps({
  headerTitle: {
    required: true,
    type: String,
  },
  headerDescription: {
    type: String,
    default: '',
  },
  hasBackButton: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <section class="flex flex-col gap-1 pt-10 pb-5">
    <div v-if="hasBackButton">
      <BackButton compact />
    </div>
    <div class="flex justify-between w-full gap-5">
      <div class="flex flex-col gap-2">
        <div>
          <span class="text-xl font-medium text-n-slate-12">
            {{ headerTitle }}
          </span>
          <p v-if="headerDescription" class="text-n-slate-12 mt-2">
            {{ headerDescription }}
          </p>
        </div>
      </div>
      <div class="flex-shrink-0">
        <slot />
      </div>
    </div>
  </section>
</template>
