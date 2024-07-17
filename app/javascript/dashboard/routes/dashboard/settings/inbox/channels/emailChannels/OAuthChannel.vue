<script setup>
import { ref, computed } from 'vue';

import microsoftClient from 'dashboard/api/channel/microsoftClient';
import googleClient from 'dashboard/api/channel/googleClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';

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
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <settings-sub-page-header
      :header-title="title"
      :header-content="description"
    />
    <form class="mt-6" @submit.prevent="requestAuthorization">
      <woot-input
        v-model="email"
        type="email"
        :placeholder="inputPlaceholder"
      />
      <woot-submit-button
        icon="brand-twitter"
        type="submit"
        :button-text="submitButtonText"
        :loading="isRequestingAuthorization"
      />
    </form>
  </div>
</template>
