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
  <section class="flex flex-col gap-1 pt-6 pb-5">
    <div v-if="hasBackButton">
      <BackButton compact />
    </div>
    <div class="flex justify-between w-full gap-5">
      <div class="flex flex-col gap-2">
        <div class="flex flex-col gap-3 items-start">
          <span
            class="text-heading-1 text-n-slate-12 min-h-10 flex items-center"
          >
            {{ headerTitle }}
          </span>
          <p
            v-if="headerDescription"
            class="text-n-slate-11 mb-0 line-clamp-5 sm:line-clamp-none text-body-main"
          >
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
