<script setup>
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from '../../../../helper/featureHelper';
import BackButton from '../../../../components/widgets/BackButton.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
  <div class="flex flex-col items-start w-full gap-2">
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
              class="flex-shrink-0 text-n-brand"
            />
          </div>
        </div>
        <h1 class="text-xl font-medium tracking-tight text-n-slate-12">
          {{ title }}
        </h1>
      </div>
      <!-- Slot for additional actions on larger screens -->
      <div class="hidden gap-2 sm:flex">
        <slot name="actions" />
      </div>
    </div>
    <div class="flex flex-col w-full gap-3 text-n-slate-11">
      <p
        class="mb-0 text-sm font-normal line-clamp-5 sm:line-clamp-none max-w-3xl"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL && linkText"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="items-center hidden gap-1 text-sm font-medium sm:inline-flex w-fit text-n-blue-text hover:underline"
        >
          {{ linkText }}
          <Icon
            icon="i-lucide-chevron-right"
            class="flex-shrink-0 text-n-blue-text size-4"
          />
        </a>
      </CustomBrandPolicyWrapper>
    </div>
    <div
      class="flex flex-wrap items-start justify-start w-full gap-3 sm:hidden"
    >
      <slot name="actions" />
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <Button
          v-if="helpURL && linkText"
          blue
          link
          icon="i-lucide-chevron-right"
          trailing-icon
          :label="linkText"
          @click="openInNewTab(helpURL)"
        />
      </CustomBrandPolicyWrapper>
    </div>
  </div>
</template>
