<script>
import { useVuelidate } from '@vuelidate/core';
import { required, url } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SectionLayout from './SectionLayout.vue';

export default {
  components: {
    WithLabel,
    NextInput,
    NextButton,
    SectionLayout,
  },
  setup() {
    const { accountId } = useAccount();
    const v$ = useVuelidate();

    return { accountId, v$ };
  },
  data() {
    return {
      ssoConfig: {
        enabled: false,
        provider_name: 'SSO',
        login_url: '',
        logout_url: '',
        secret_key: '',
        token_expiry: 5,
      },
      showSecretKey: false,
      isUpdating: false,
    };
  },
  validations() {
    return {
      ssoConfig: {
        provider_name: {
          required,
        },
        login_url: {
          required: this.ssoConfig.enabled ? required : true,
          url: this.ssoConfig.enabled ? url : true,
        },
        secret_key: {
          required: this.ssoConfig.enabled ? required : true,
        },
        token_expiry: {
          required,
        },
      },
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
    }),
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
  },
  mounted() {
    this.initializeSSO();
  },
  methods: {
    initializeSSO() {
      try {
        const { sso_config } = this.currentAccount;
        if (sso_config) {
          this.ssoConfig = {
            enabled: sso_config.enabled || false,
            provider_name: sso_config.provider_name || 'SSO',
            login_url: sso_config.login_url || '',
            logout_url: sso_config.logout_url || '',
            secret_key: sso_config.secret_key || '',
            token_expiry: sso_config.token_expiry || 5,
          };
        }
      } catch (error) {
        // Ignore error
      }
    },

    async updateSSO() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.SSO.FORM.ERROR'));
        return;
      }

      this.isUpdating = true;

      try {
        await this.$store.dispatch('accounts/update', {
          sso_config: this.ssoConfig,
        });
        useAlert(this.$t('GENERAL_SETTINGS.SSO.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.SSO.UPDATE.ERROR'));
      } finally {
        this.isUpdating = false;
      }
    },

    toggleSecretKey() {
      this.showSecretKey = !this.showSecretKey;
    },
  },
};
</script>

<template>
  <SectionLayout
    :title="$t('GENERAL_SETTINGS.SSO.TITLE')"
    :description="$t('GENERAL_SETTINGS.SSO.DESCRIPTION')"
  >
    <form class="grid gap-4" @submit.prevent="updateSSO">
      <WithLabel :label="$t('GENERAL_SETTINGS.SSO.FORM.ENABLE_SSO.LABEL')">
        <div class="flex items-center">
          <input v-model="ssoConfig.enabled" type="checkbox" class="mr-2" />
          <span>{{ $t('GENERAL_SETTINGS.SSO.FORM.ENABLE_SSO.HELP') }}</span>
        </div>
      </WithLabel>

      <template v-if="ssoConfig.enabled">
        <WithLabel
          :has-error="v$.ssoConfig.provider_name.$error"
          :label="$t('GENERAL_SETTINGS.SSO.FORM.PROVIDER_NAME.LABEL')"
          :error-message="$t('GENERAL_SETTINGS.SSO.FORM.PROVIDER_NAME.ERROR')"
        >
          <NextInput
            v-model="ssoConfig.provider_name"
            type="text"
            class="w-full"
            :placeholder="
              $t('GENERAL_SETTINGS.SSO.FORM.PROVIDER_NAME.PLACEHOLDER')
            "
            @blur="v$.ssoConfig.provider_name.$touch"
          />
        </WithLabel>

        <WithLabel
          :has-error="v$.ssoConfig.login_url.$error"
          :label="$t('GENERAL_SETTINGS.SSO.FORM.LOGIN_URL.LABEL')"
          :error-message="$t('GENERAL_SETTINGS.SSO.FORM.LOGIN_URL.ERROR')"
        >
          <NextInput
            v-model="ssoConfig.login_url"
            type="url"
            class="w-full"
            :placeholder="$t('GENERAL_SETTINGS.SSO.FORM.LOGIN_URL.PLACEHOLDER')"
            @blur="v$.ssoConfig.login_url.$touch"
          />
          <template #help>
            {{ $t('GENERAL_SETTINGS.SSO.FORM.LOGIN_URL.HELP') }}
          </template>
        </WithLabel>

        <WithLabel :label="$t('GENERAL_SETTINGS.SSO.FORM.LOGOUT_URL.LABEL')">
          <NextInput
            v-model="ssoConfig.logout_url"
            type="url"
            class="w-full"
            :placeholder="
              $t('GENERAL_SETTINGS.SSO.FORM.LOGOUT_URL.PLACEHOLDER')
            "
          />
          <template #help>
            {{ $t('GENERAL_SETTINGS.SSO.FORM.LOGOUT_URL.HELP') }}
          </template>
        </WithLabel>

        <WithLabel
          :has-error="v$.ssoConfig.secret_key.$error"
          :label="$t('GENERAL_SETTINGS.SSO.FORM.SECRET_KEY.LABEL')"
          :error-message="$t('GENERAL_SETTINGS.SSO.FORM.SECRET_KEY.ERROR')"
        >
          <div class="relative">
            <NextInput
              v-model="ssoConfig.secret_key"
              :type="showSecretKey ? 'text' : 'password'"
              class="w-full pr-10"
              :placeholder="
                $t('GENERAL_SETTINGS.SSO.FORM.SECRET_KEY.PLACEHOLDER')
              "
              @blur="v$.ssoConfig.secret_key.$touch"
            />
            <button
              type="button"
              class="absolute right-2 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700"
              @click="toggleSecretKey"
            >
              <svg
                v-if="showSecretKey"
                class="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
                />
              </svg>
              <svg
                v-else
                class="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                />
              </svg>
            </button>
          </div>
          <template #help>
            {{ $t('GENERAL_SETTINGS.SSO.FORM.SECRET_KEY.HELP') }}
          </template>
        </WithLabel>

        <WithLabel
          :has-error="v$.ssoConfig.token_expiry.$error"
          :label="$t('GENERAL_SETTINGS.SSO.FORM.TOKEN_EXPIRY.LABEL')"
          :error-message="$t('GENERAL_SETTINGS.SSO.FORM.TOKEN_EXPIRY.ERROR')"
        >
          <NextInput
            v-model="ssoConfig.token_expiry"
            type="number"
            class="w-full"
            min="1"
            max="60"
            :placeholder="
              $t('GENERAL_SETTINGS.SSO.FORM.TOKEN_EXPIRY.PLACEHOLDER')
            "
            @blur="v$.ssoConfig.token_expiry.$touch"
          />
          <template #help>
            {{ $t('GENERAL_SETTINGS.SSO.FORM.TOKEN_EXPIRY.HELP') }}
          </template>
        </WithLabel>
      </template>

      <div>
        <NextButton blue :is-loading="isUpdating" type="submit">
          {{ $t('GENERAL_SETTINGS.SSO.SUBMIT') }}
        </NextButton>
      </div>
    </form>
  </SectionLayout>
</template>
