<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import ZaloOaChannel from 'dashboard/api/channel/zaloOaChannel';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const appId = ref('');
const appSecret = ref('');
const oaSecretKey = ref('');
const isConnecting = ref(false);

const rules = {
  appId: { required },
  appSecret: { required },
  oaSecretKey: { required },
};

const v$ = useVuelidate(rules, { appId, appSecret, oaSecretKey });

const isSubmitDisabled = computed(() => v$.value.$invalid);

const connect = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isConnecting.value = true;
  try {
    const {
      data: { redirect_url: redirectUrl },
    } = await ZaloOaChannel.generateAuthorization({
      app_id: appId.value,
      app_secret: appSecret.value,
      oa_secret_key: oaSecretKey.value,
    });
    window.location.href = redirectUrl;
  } catch (error) {
    isConnecting.value = false;
    useAlert(
      error.message || t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.API.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.DESC')"
    />
    <form class="flex flex-wrap flex-col mx-0" @submit.prevent="connect">
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.appId.$error }">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.APP_ID.LABEL') }}
          <input
            v-model="appId"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.APP_ID.PLACEHOLDER')
            "
            @blur="v$.appId.$touch"
          />
        </label>
      </div>
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.appSecret.$error }">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.APP_SECRET.LABEL') }}
          <input
            v-model="appSecret"
            type="password"
            :placeholder="
              $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.APP_SECRET.PLACEHOLDER')
            "
            @blur="v$.appSecret.$touch"
          />
        </label>
      </div>
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.oaSecretKey.$error }">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.OA_SECRET_KEY.LABEL') }}
          <input
            v-model="oaSecretKey"
            type="password"
            :placeholder="
              $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.OA_SECRET_KEY.PLACEHOLDER')
            "
            @blur="v$.oaSecretKey.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.OA_SECRET_KEY.SUBTITLE') }}
        </p>
      </div>
      <div class="w-full mt-4">
        <NextButton
          :is-loading="isConnecting"
          :disabled="isSubmitDisabled"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.ZALO_OA_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
