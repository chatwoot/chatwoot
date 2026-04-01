<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { computed } from 'vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

defineProps({
  showActions: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['add']);

const helpURL = computed(() => getHelpUrlForFeature('sla'));
</script>

<template>
  <div
    class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
  >
    <div class="min-w-0 space-y-2">
      <p
        class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
      >
        {{ $t('SLA.PAGE_EYEBROW') }}
      </p>
      <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
        {{ $t('SLA.HEADER') }}
      </h2>
      <p class="mb-0 max-w-2xl text-base text-on-primary-container">
        {{ $t('SLA.PAGE_SUBTITLE') }}
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
        >
          {{ $t('SLA.LEARN_MORE') }}
          <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
        </a>
      </CustomBrandPolicyWrapper>
    </div>
    <NextButton
      v-if="showActions"
      solid
      teal
      lg
      icon="i-lucide-plus"
      :label="$t('SLA.ADD_ACTION')"
      class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
      @click="$emit('add')"
    />
  </div>
</template>
