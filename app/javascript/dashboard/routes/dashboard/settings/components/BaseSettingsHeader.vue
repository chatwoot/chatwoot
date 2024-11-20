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
  <div class="flex flex-col items-start w-full gap-2 pt-4">
    <BackButton
      v-if="backButtonLabel"
      compact
      :button-label="backButtonLabel"
    />
    <div class="flex items-center justify-between w-full gap-4">
      <div class="flex items-center gap-3">
        <div
          v-if="iconName"
          class="flex items-center w-10 h-10 p-1 rounded-full bg-woot-25/60 dark:bg-woot-900/60"
        >
          <div
            class="flex items-center justify-center w-full h-full rounded-full bg-woot-75/70 dark:bg-woot-800/40"
          >
            <fluent-icon
              size="14"
              :icon="iconName"
              type="outline"
              class="flex-shrink-0 text-woot-500 dark:text-woot-500"
            />
          </div>
        </div>
        <h1
          class="text-2xl font-semibold font-interDisplay tracking-[0.3px] text-slate-900 dark:text-slate-25"
        >
          {{ title }}
        </h1>
      </div>
      <!-- Slot for additional actions on larger screens -->
      <div class="hidden gap-2 sm:flex">
        <slot name="actions" />
      </div>
    </div>
    <div class="flex flex-col gap-3 text-slate-600 dark:text-slate-300 w-full">
      <p
        class="mb-0 text-base font-normal line-clamp-5 sm:line-clamp-none max-w-3xl tracking-[-0.1px]"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL && linkText"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="sm:inline-flex hidden gap-1 w-fit items-center text-woot-500 dark:text-woot-500 text-sm font-medium hover:underline"
        >
          {{ linkText }}
          <fluent-icon
            size="16"
            icon="chevron-right"
            type="outline"
            class="flex-shrink-0 text-woot-500 dark:text-woot-500"
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
          class="flex-row-reverse rounded-md min-w-0 !bg-slate-50 !text-slate-900 dark:!text-white dark:!bg-slate-800"
          @click="openInNewTab(helpURL)"
        >
          {{ linkText }}
        </woot-button>
      </CustomBrandPolicyWrapper>
    </div>
  </div>
</template>
