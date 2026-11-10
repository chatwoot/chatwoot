<script setup>
import { computed } from 'vue';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { isSafeHttpLink } from 'shared/helpers/documentHelper';
import {
  SOCIAL_NETWORKS,
  socialProfileHandle,
  socialProfileUrl,
} from './socialProfiles';

const props = defineProps({
  network: { type: String, required: true },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
});

const handle = defineModel({ type: String, default: '' });

const config = computed(() => SOCIAL_NETWORKS[props.network]);
const isCustomLink = computed(() => /^https?:\/\//i.test(handle.value));
const link = computed(() => socialProfileUrl(props.network, handle.value));

const onInput = event => {
  handle.value = socialProfileHandle(props.network, event.target.value);
  event.target.value = handle.value;
};
</script>

<template>
  <label class="flex flex-col min-w-0 gap-1">
    <span v-if="label" class="mb-0.5 text-heading-3 text-n-slate-12">
      {{ label }}
    </span>
    <span
      class="flex items-center h-10 gap-2 px-3 transition-all duration-500 ease-in-out rounded-lg outline outline-1 outline-offset-[-1px] bg-n-alpha-black2 outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand"
      :class="{ 'opacity-50 cursor-not-allowed': disabled }"
    >
      <a
        v-if="isSafeHttpLink(link)"
        :href="link"
        target="_blank"
        rel="noopener noreferrer"
        class="shrink-0 text-n-slate-11 hover:text-n-slate-12"
      >
        <Icon :icon="config.icon" class="block size-4" />
      </a>
      <Icon
        v-else
        :icon="config.icon"
        class="size-4 shrink-0 text-n-slate-10"
      />
      <span dir="ltr" class="flex items-center flex-1 min-w-0 text-sm">
        <span v-if="!isCustomLink" class="shrink-0 text-n-slate-10">
          {{ config.hosts[0] }}
        </span>
        <input
          :value="handle"
          type="text"
          :placeholder="placeholder"
          :disabled="disabled"
          class="flex-1 min-w-0 p-0 text-sm bg-transparent border-0 outline-none reset-base text-n-slate-12 placeholder:text-n-slate-10 disabled:cursor-not-allowed"
          @input="onInput"
        />
      </span>
    </span>
  </label>
</template>
