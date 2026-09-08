<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { useFacebookPageConnect } from 'dashboard/composables/useFacebookPageConnect';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const emit = defineEmits(['back', 'created']);

const { t } = useI18n();
const store = useStore();
const { isAuthenticating, preloadSdk, loginAndFetchPages } =
  useFacebookPageConnect();

// null until the login + page fetch completes.
const pages = ref(null);
const userAccessToken = ref('');
const selectedPageId = ref('');
const errored = ref(false);
const isCreating = ref(false);

const hasFetched = computed(() => pages.value !== null);
// Pages already connected as inboxes come back with `exists: true`.
const pageOptions = computed(() =>
  (pages.value || [])
    .filter(page => !page.exists)
    .map(page => ({ value: page.id, label: page.name }))
);

// Warm the SDK on open so the login click opens its popup within the gesture's
// activation window (see useFacebookPageConnect).
onMounted(preloadSdk);

const connect = async () => {
  errored.value = false;
  try {
    const result = await loginAndFetchPages();
    if (!result) return; // cancelled — stay on the connect prompt
    userAccessToken.value = result.userAccessToken;
    pages.value = result.pages;
  } catch {
    errored.value = true;
  }
};

const createInbox = async () => {
  const page = (pages.value || []).find(p => p.id === selectedPageId.value);
  if (!page || isCreating.value) return;

  isCreating.value = true;
  try {
    await store.dispatch('inboxes/createFBChannel', {
      user_access_token: userAccessToken.value,
      page_access_token: page.access_token,
      page_id: page.id,
      inbox_name: page.name,
    });
    useAlert(t('ONBOARDING_INBOX_SETUP.FACEBOOK_CONNECTED'));
    emit('created');
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t('ONBOARDING_INBOX_SETUP.ERROR'));
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div
      v-if="isAuthenticating"
      class="flex items-center justify-center gap-3 py-8"
    >
      <Spinner :size="16" class="text-n-blue-10" />
      <span class="text-sm text-n-slate-11">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_LOADING') }}
      </span>
    </div>

    <template v-else-if="hasFetched && pageOptions.length">
      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_SELECT_PAGE') }}
        </label>
        <ComboBox
          v-model="selectedPageId"
          :options="pageOptions"
          :placeholder="
            t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_SELECT_PAGE')
          "
        />
      </div>
      <div class="flex items-center gap-3">
        <NextButton
          type="button"
          slate
          faded
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.BACK')"
          @click="emit('back')"
        />
        <NextButton
          type="button"
          blue
          class="flex-1 justify-center"
          :is-loading="isCreating"
          :disabled="!selectedPageId"
          :label="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.CONNECT')"
          @click="createInbox"
        />
      </div>
    </template>

    <template v-else-if="hasFetched">
      <p class="text-sm text-n-slate-11">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_NO_PAGES') }}
      </p>
      <div class="flex">
        <NextButton
          type="button"
          slate
          faded
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.BACK')"
          @click="emit('back')"
        />
      </div>
    </template>

    <template v-else>
      <p v-if="errored" class="text-sm text-n-ruby-11">
        {{ t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_ERROR') }}
      </p>
      <div class="flex items-center gap-3">
        <NextButton
          type="button"
          slate
          faded
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.BACK')"
          @click="emit('back')"
        />
        <NextButton
          type="button"
          blue
          class="flex-1 justify-center"
          :label="t('ONBOARDING_INBOX_SETUP.CHANNELS_DIALOG.FACEBOOK_LAUNCH')"
          @click="connect"
        />
      </div>
    </template>
  </div>
</template>
