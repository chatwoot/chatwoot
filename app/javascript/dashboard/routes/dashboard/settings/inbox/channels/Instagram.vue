<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import instagramClient from 'dashboard/api/channel/instagramClient';
import Button from 'dashboard/components-next/button/Button.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { META_RESTRICTION_STATUS_URL } from 'dashboard/constants/globals';

const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const hasError = ref(false);
const errorStateMessage = ref('');
const errorStateDescription = ref('');
const isRequestingAuthorization = ref(false);
const isInstagramConnectionRestricted = computed(() => {
  return isOnChatwootCloud.value;
});

onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search);
  //  TODO: Handle error type
  // const errorType = urlParams.get('error_type');
  const errorCode = urlParams.get('code');
  const errorMessage = urlParams.get('error_message');

  if (errorMessage) {
    hasError.value = true;
    if (errorCode === '400') {
      errorStateMessage.value = errorMessage;
      errorStateDescription.value = t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH');
    } else {
      errorStateMessage.value = t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_MESSAGE');
      errorStateDescription.value = errorMessage;
    }
  }
  // User need to remove the error params from the url to avoid the error to be shown again after page reload, so that user can try again
  const cleanURL = window.location.pathname;
  window.history.replaceState({}, document.title, cleanURL);
});

const requestAuthorization = async () => {
  isRequestingAuthorization.value = true;
  const response = await instagramClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};
</script>

<template>
  <div class="h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0">
    <div class="flex flex-col items-center justify-start h-full text-center">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center w-full px-8 py-10 text-center rounded-2xl outline outline-1 outline-n-weak"
      >
        <h6 class="text-2xl font-medium">
          {{ $t('INBOX_MGMT.ADD.INSTAGRAM.CONNECT_YOUR_INSTAGRAM_PROFILE') }}
        </h6>
        <p class="py-6 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.INSTAGRAM.HELP') }}
        </p>
        <Button
          class="text-white !rounded-full !px-6 bg-gradient-to-r from-[#833AB4] via-[#FD1D1D] to-[#FCAF45]"
          lg
          icon="i-ri-instagram-line"
          :disabled="
            isRequestingAuthorization || isInstagramConnectionRestricted
          "
          :is-loading="isRequestingAuthorization"
          :label="$t('INBOX_MGMT.ADD.INSTAGRAM.CONTINUE_WITH_INSTAGRAM')"
          @click="requestAuthorization()"
        />
        <Banner
          v-if="isInstagramConnectionRestricted"
          color="amber"
          class="w-full max-w-2xl mt-6"
        >
          <div class="flex items-start gap-3 text-left">
            <Icon
              icon="i-lucide-triangle-alert"
              class="flex-shrink-0 size-4 mt-0.5"
            />
            <span>
              {{ $t('INBOX_MGMT.ADD.INSTAGRAM.RESTRICTED_WARNING') }}
              <a
                :href="META_RESTRICTION_STATUS_URL"
                class="link underline"
                rel="noopener noreferrer nofollow"
                target="_blank"
              >
                {{ $t('INBOX_MGMT.ADD.INSTAGRAM.STATUS_LINK') }}
              </a>
            </span>
          </div>
        </Banner>
      </div>
    </div>
  </div>
</template>
