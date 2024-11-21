<script setup>
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from '../../../../helper/featureHelper';
import BackButton from '../../../../components/widgets/BackButton.vue';
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  iconName: {
    type: String,
    default: '',
  },
  linkText: {
    type: String,
    default: '',
  },
  featureName: {
    type: String,
    default: '',
  },
  backButtonLabel: {
    type: String,
    default: '',
  },
});

const helpURL = getHelpUrlForFeature(props.featureName);

const openInNewTab = url => {
  if (!url) return;
  window.open(url, '_blank', 'noopener noreferrer');
};
</script>

<template>
  <div class="flex flex-col items-start w-full gap-2 max-w-[960px] mx-auto">
    <div
      class="flex items-center justify-between w-full gap-4 h-20 border-b border-n-weak"
    >
      <div class="flex gap-3">
        <BackButton v-if="backButtonLabel" compact />
        <h1
          class="text-xl font-interDisplay tracking-[0.3px] font-medium text-n-slate-12"
        >
          {{ title }}
        </h1>
      </div>
      <!-- Slot for additional actions on larger screens -->
      <div class="hidden gap-2 sm:flex">
        <slot name="actions" />
      </div>
    </div>
    <div class="flex flex-col gap-4 text-n-slate-11 w-full pt-3">
      <p
        class="mb-0 text-sm font-normal line-clamp-5 sm:line-clamp-none max-w-3xl leading-6"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL && linkText"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="sm:inline-flex hidden gap-1 w-fit items-center text-n-brand text-sm font-medium hover:underline"
        >
          {{ linkText }}
          <fluent-icon
            size="16"
            icon="chevron-right"
            type="outline"
            class="flex-shrink-0 text-n-brand"
          />
        </a>
      </CustomBrandPolicyWrapper>
    </div>
    <div
      class="flex items-start justify-start w-full gap-3 sm:hidden flex-wrap"
    >
      <slot name="actions" />
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <woot-button
          v-if="helpURL && linkText"
          color-scheme="secondary"
          icon="arrow-outwards"
          class="flex-row-reverse rounded-md text-sm min-w-0 !bg-slate-50 !text-slate-900 dark:!text-white dark:!bg-slate-800"
          @click="openInNewTab(helpURL)"
        >
          {{ linkText }}
        </woot-button>
      </CustomBrandPolicyWrapper>
    </div>
  </div>
</template>
