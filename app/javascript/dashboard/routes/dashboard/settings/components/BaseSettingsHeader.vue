<script setup>
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from '../../../../helper/featureHelper';
import BackButton from '../../../../components/widgets/BackButton.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

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
  searchPlaceholder: {
    type: String,
    default: '',
  },
});

const searchQuery = defineModel('searchQuery', { type: String, default: '' });

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
    <div class="flex items-center justify-between w-full gap-4 min-h-10 mb-1">
      <div class="flex items-center gap-3">
        <div
          v-if="iconName"
          class="flex items-center w-10 h-10 p-1 rounded-full bg-n-blue-2"
        >
          <div
            class="flex items-center justify-center w-full h-full rounded-full bg-n-blue-3"
          >
            <fluent-icon
              size="14"
              :icon="iconName"
              type="outline"
              class="flex-shrink-0 text-n-brand"
            />
          </div>
        </div>
        <h1 class="text-heading-1 leading-6 tracking-tight text-n-slate-12">
          {{ title }}
        </h1>
      </div>
      <!-- Slot for additional actions on larger screens -->
      <div class="hidden gap-3 sm:flex">
        <Input
          v-if="searchPlaceholder"
          v-model="searchQuery"
          :placeholder="searchPlaceholder"
          autofocus
          class="w-56 min-w-0 [&>input]:ltr:!pl-8 [&>input]:rtl:!pr-8 [&>input]:!rounded-[0.625rem]"
          size="md"
          type="search"
        >
          <template #prefix>
            <Icon
              icon="i-lucide-search"
              class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2.5 rtl:right-2.5"
            />
          </template>
        </Input>
        <slot name="actions" />
      </div>
    </div>
    <div class="flex flex-col w-full gap-3 text-n-slate-11 mt-1">
      <p class="mb-0 line-clamp-5 sm:line-clamp-none max-w-3xl text-body-main">
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
