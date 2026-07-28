<script>
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useFacebookPageConnect } from 'dashboard/composables/useFacebookPageConnect';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import { useBranding } from 'shared/composables/useBranding';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

import * as Sentry from '@sentry/vue';

export default {
  components: {
    LoadingState,
    PageHeader,
    NextButton,
    ComboBox,
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    const { preloadSdk, loginAndFetchPages } = useFacebookPageConnect();
    return {
      replaceInstallationName,
      preloadSdk,
      loginAndFetchPages,
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      isCreating: false,
      hasError: false,
      user_access_token: '',
      selectedPage: { name: null, id: null },
      pageName: '',
      pageList: [],
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      errorStateMessage: '',
      errorStateDescription: '',
      hasLoginStarted: false,
    };
  },

  validations: {
    pageName: {
      required,
    },

    selectedPage: {
      isEmpty() {
        return this.selectedPage !== null && !!this.selectedPage.name;
      },
    },
  },

  computed: {
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    getSelectablePages() {
      return this.pageList.filter(item => !item.exists);
    },
    comboBoxPageOptions() {
      return this.getSelectablePages.map(({ id, name }) => ({
        value: id,
        label: name,
      }));
    },
  },

  mounted() {
    // Warm the SDK so the login click opens its popup within the gesture's
    // activation window (see useFacebookPageConnect).
    this.preloadSdk();
  },

  methods: {
    async startLogin() {
      this.hasLoginStarted = true;
      try {
        const result = await this.loginAndFetchPages();
        if (!result) {
          // Cancelled popup / not authorized — surface a generic auth error.
          this.hasError = true;
          this.errorStateMessage = this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH');
          this.errorStateDescription = '';
          return;
        }
        this.pageList = result.pages;
        this.user_access_token = result.userAccessToken;
      } catch (error) {
        if (error.name === 'ScriptLoaderError') {
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_LOADING'));
        } else {
          Sentry.captureException(error);
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
        }
      }
    },

    setPageName(pageId) {
      const page = this.pageList.find(p => p.id === pageId);
      if (page) {
        this.selectedPage = page;
        this.pageName = page.name;
      } else {
        this.selectedPage = { name: null, id: null };
        this.pageName = '';
      }
      this.v$.selectedPage.$touch();
    },

    channelParams() {
      return {
        user_access_token: this.user_access_token,
        page_access_token: this.selectedPage.access_token,
        page_id: this.selectedPage.id,
        inbox_name: this.selectedPage.name?.trim(),
      };
    },

    createChannel() {
      this.v$.$touch();
      if (!this.v$.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createFBChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(() => {
            this.isCreating = false;
          });
      }
    },
  },
};
</script>

<template>
  <div class="w-full h-full col-span-6 p-6 overflow-auto">
    <div
      v-if="!hasLoginStarted"
      class="flex flex-col items-center justify-center h-full text-center"
    >
      <a href="#" @click="startLogin()">
        <img
          class="w-auto h-10 rounded-md"
          src="~dashboard/assets/images/channels/facebook_login.png"
          alt="Facebook-logo"
        />
      </a>
      <p class="py-6">
        {{ replaceInstallationName($t('INBOX_MGMT.ADD.FB.HELP')) }}
      </p>
    </div>
    <div v-else>
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <LoadingState v-else-if="showLoader" :message="emptyStateMessage" />
      <form
        v-else
        class="flex flex-col flex-wrap mx-0"
        @submit.prevent="createChannel()"
      >
        <div class="w-full">
          <PageHeader
            :header-title="$t('INBOX_MGMT.ADD.DETAILS.TITLE')"
            :header-content="
              replaceInstallationName($t('INBOX_MGMT.ADD.DETAILS.DESC'))
            "
          />
        </div>
        <div class="w-3/5">
          <div class="w-full mb-2">
            <div class="input-wrap" :class="{ error: v$.selectedPage.$error }">
              <span class="text-n-slate-12 text-start">
                {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PAGE') }}
              </span>
              <ComboBox
                :model-value="selectedPage.id"
                :options="comboBoxPageOptions"
                :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_A_VALUE')"
                :has-error="v$.selectedPage.$error"
                class="[&>div>button]:!bg-n-alpha-black2 mt-1"
                @update:model-value="setPageName"
              />
              <span v-if="v$.selectedPage.$error" class="message mt-0.5">
                {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PLACEHOLDER') }}
              </span>
            </div>
          </div>
          <div class="w-full">
            <label :class="{ error: v$.pageName.$error }">
              {{ $t('INBOX_MGMT.ADD.FB.INBOX_NAME') }}
              <input
                v-model="pageName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_NAME')"
                @input="v$.pageName.$touch"
              />
              <span v-if="v$.pageName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.FB.ADD_NAME') }}
              </span>
            </label>
          </div>
          <div class="w-full text-right">
            <NextButton :label="$t('INBOX_MGMT.ADD.FB.CREATE_INBOX')" />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
