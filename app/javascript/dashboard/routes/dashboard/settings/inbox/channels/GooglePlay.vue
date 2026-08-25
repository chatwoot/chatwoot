<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import googlePlayClient from 'dashboard/api/channel/googlePlayClient';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const { t } = useI18n();

// Surface any error the OAuth callback redirected back with
onMounted(() => {
  if (route.query.error) {
    useAlert(String(route.query.error));
  }
});

const state = reactive({
  inboxName: '',
  appId: '',
});

const isConnecting = ref(false);

const rules = {
  inboxName: { required },
  appId: { required },
};

const v$ = useVuelidate(rules, state);

const connectWithGoogle = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    isConnecting.value = true;
    const {
      data: { url },
    } = await googlePlayClient.generateAuthorization({
      app_id: state.appId.trim(),
      inbox_name: state.inboxName.trim(),
    });
    window.location.href = url;
  } catch (error) {
    isConnecting.value = false;
    useAlert(t('INBOX_MGMT.ADD.GOOGLE_PLAY.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.GOOGLE_PLAY.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.GOOGLE_PLAY.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="connectWithGoogle"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.GOOGLE_PLAY.INBOX_NAME.LABEL') }}
          <input
            v-model="state.inboxName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.GOOGLE_PLAY.INBOX_NAME.PLACEHOLDER')
            "
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.GOOGLE_PLAY.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.appId.$error }">
          {{ $t('INBOX_MGMT.ADD.GOOGLE_PLAY.APP_ID.LABEL') }}
          <input
            v-model="state.appId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.GOOGLE_PLAY.APP_ID.PLACEHOLDER')"
            @blur="v$.appId.$touch"
          />
          <span v-if="v$.appId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.GOOGLE_PLAY.APP_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="isConnecting"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.GOOGLE_PLAY.CONNECT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
