<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import globalConstants from 'dashboard/constants/globals';

const store = useStore();
const { t } = useI18n();

const channelName = ref('');
const appId = ref('');
const issuerId = ref('');
const keyId = ref('');
const privateKey = ref('');
const appStoreReviewsInboxDocsUrl =
  globalConstants.APP_STORE_REVIEWS_INBOX_DOCS_URL;

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);

const rules = {
  channelName: { required },
  appId: { required },
  issuerId: { required },
  keyId: { required },
  privateKey: { required },
};

const v$ = useVuelidate(rules, {
  channelName,
  appId,
  issuerId,
  keyId,
  privateKey,
});

const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const appStoreChannel = await store.dispatch('inboxes/createChannel', {
      name: channelName.value?.trim(),
      channel: {
        type: 'app_store',
        app_id: appId.value.trim(),
        issuer_id: issuerId.value.trim(),
        key_id: keyId.value.trim(),
        private_key: privateKey.value.trim(),
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: appStoreChannel.id,
      },
    });
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ADD.APP_STORE.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.APP_STORE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.APP_STORE.DESC')"
    />
    <a
      :href="appStoreReviewsInboxDocsUrl"
      target="_blank"
      rel="noopener noreferrer"
      class="inline-flex items-center gap-1 mb-5 text-sm font-medium text-n-brand"
    >
      {{ $t('INBOX_MGMT.ADD.APP_STORE.LEARN_MORE') }}
      <Icon icon="i-lucide-external-link" class="size-4" />
    </a>
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.LABEL') }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.appId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.APP_ID.LABEL') }}
          <input
            v-model="appId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.APP_ID.PLACEHOLDER')"
            @blur="v$.appId.$touch"
          />
          <span v-if="v$.appId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.APP_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.issuerId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.LABEL') }}
          <input
            v-model="issuerId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.PLACEHOLDER')"
            @blur="v$.issuerId.$touch"
          />
          <span v-if="v$.issuerId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.keyId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.LABEL') }}
          <input
            v-model="keyId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.PLACEHOLDER')"
            @blur="v$.keyId.$touch"
          />
          <span v-if="v$.keyId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.privateKey.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.LABEL') }}
          <textarea
            v-model="privateKey"
            rows="8"
            :placeholder="
              $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.PLACEHOLDER')
            "
            @blur="v$.privateKey.$touch"
          />
          <span v-if="v$.privateKey.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.APP_STORE.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
