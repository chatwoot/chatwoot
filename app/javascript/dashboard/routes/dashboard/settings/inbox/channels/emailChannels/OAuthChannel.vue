<script setup>
import { ref, computed } from 'vue';

import microsoftClient from 'dashboard/api/channel/microsoftClient';
import googleClient from 'dashboard/api/channel/googleClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

import { useAlert } from 'dashboard/composables';

const props = defineProps({
  provider: {
    type: String,
    required: true,
    validate: value => ['microsoft', 'google'].includes(value),
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  submitButtonText: {
    type: String,
    required: true,
  },
  errorMessage: {
    type: String,
    required: true,
  },
  inputPlaceholder: {
    type: String,
    required: true,
  },
});

const isRequestingAuthorization = ref(false);
const email = ref('');

const client = computed(() => {
  if (props.provider === 'microsoft') {
    return microsoftClient;
  }

  return googleClient;
});

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await client.value.generateAuthorization({
      email: email.value,
    });
    const {
      data: { url },
    } = response;

    window.location.href = url;
  } catch (error) {
    useAlert(props.errorMessage);
  } finally {
    isRequestingAuthorization.value = false;
  }
}
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <SettingsSubPageHeader
      :header-title="title"
      :header-content="description"
    />
    <form class="mt-6" @submit.prevent="requestAuthorization">
      <woot-input
        v-model="email"
        type="email"
        :placeholder="inputPlaceholder"
      />
      <NextButton
        :is-loading="isRequestingAuthorization"
        type="submit"
        solid
        blue
        :label="submitButtonText"
      />
    </form>
  </div>
</template>
