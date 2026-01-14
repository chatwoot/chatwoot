<script setup>
import { computed, useSlots } from 'vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from '../../../../helper/featureHelper';
import BackButton from '../../../../components/widgets/BackButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
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

const slots = useSlots();

const searchQuery = defineModel('searchQuery', { type: String, default: '' });

const hasHeaderActions = computed(
  () => props.searchPlaceholder || slots.actions
);

const helpURL = getHelpUrlForFeature(props.featureName);
</script>

<template>
  <div class="flex flex-col items-start w-full">
    <BackButton
      v-if="backButtonLabel"
      compact
      :button-label="backButtonLabel"
      class="mb-1"
    />
    <div
      v-if="title"
      class="flex items-center justify-between w-full gap-4 min-h-10"
      :class="!hasHeaderActions ? 'mb-1' : 'mb-3'"
    >
      <h1 class="text-heading-1 text-n-slate-12">
        {{ title }}
      </h1>
      <div v-if="searchPlaceholder || slots.actions" class="gap-3 flex">
        <Input
          v-if="searchPlaceholder"
          v-model="searchQuery"
          :placeholder="searchPlaceholder"
          autofocus
          class="w-56 min-w-0 hidden sm:flex [&>input]:ltr:!pl-8 [&>input]:rtl:!pr-8 [&>input]:!rounded-[0.625rem]"
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
    <div
      v-if="description || $slots.description || linkText || helpURL"
      class="flex flex-col w-full gap-2 text-n-slate-11 my-3"
    >
      <p
        v-if="description || $slots.description"
        class="mb-0 line-clamp-5 sm:line-clamp-none max-w-3xl text-body-main"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL && linkText"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="items-center gap-1 text-label inline-flex w-fit text-n-blue-11 hover:underline"
        >
          {{ linkText }}
        </a>
      </CustomBrandPolicyWrapper>
    </div>
  </div>
</template>
