<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minValue, maxValue } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  setup() {
    const { updateUISettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const { accountId } = useAccount();
    const v$ = useVuelidate();

    return { updateUISettings, v$, enabledLanguages, accountId };
  },
  data() {
    return {
      id: '',
      name: '',
      locale: 'en',
      domain: '',
      supportEmail: '',
      features: {},
      autoResolveDuration: null,
      latestChatwootVersion: null,
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
    autoResolveDuration: {
      minValue: minValue(1),
      maxValue: maxValue(999),
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    showAutoResolutionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
      );
    },
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }

      return semver.lt(
        this.globalConfig.appVersion,
        this.latestChatwootVersion
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },

    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },

    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },

    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },

    getAccountId() {
      return this.id.toString();
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const {
          name,
          locale,
          id,
          domain,
          support_email,
          features,
          auto_resolve_duration,
          latest_chatwoot_version: latestChatwootVersion,
        } = this.getAccount(this.accountId);

        this.$root.$i18n.locale = locale;
        this.name = name;
        this.locale = locale;
        this.id = id;
        this.domain = domain;
        this.supportEmail = support_email;
        this.features = features;
        this.autoResolveDuration = auto_resolve_duration;
        this.latestChatwootVersion = latestChatwootVersion;
      } catch (error) {
        // Ignore error
      }
    },

    async updateAccount() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        await this.$store.dispatch('accounts/update', {
          locale: this.locale,
          name: this.name,
          domain: this.domain,
          support_email: this.supportEmail,
          auto_resolve_duration: this.autoResolveDuration,
        });
        this.$root.$i18n.locale = this.locale;
        this.getAccount(this.id).locale = this.locale;
        this.updateDirectionView(this.locale);
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },

    updateDirectionView(locale) {
      const isRTLSupported = getLanguageDirection(locale);
      this.updateUISettings({
        rtl_view: isRTLSupported,
      });
    },
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateAccount">
      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE') }}</p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <label :class="{ error: v$.name.$error }">
            {{ $t('GENERAL_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @blur="v$.name.$touch"
            />
            <span v-if="v$.name.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: v$.locale.$error }">
            {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL') }}
            <select v-model="locale">
              <option
                v-for="lang in languagesSortedByCode"
                :key="lang.iso_639_1_code"
                :value="lang.iso_639_1_code"
              >
                {{ lang.name }}
              </option>
            </select>
            <span v-if="v$.locale.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR') }}
            </span>
          </label>
          <label v-if="featureInboundEmailEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.FEATURES.INBOUND_EMAIL_ENABLED') }}
          </label>
          <label v-if="featureCustomReplyDomainEnabled">
            {{
              $t('GENERAL_SETTINGS.FORM.FEATURES.CUSTOM_EMAIL_DOMAIN_ENABLED')
            }}
          </label>
          <label v-if="featureCustomReplyDomainEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.DOMAIN.LABEL') }}
            <input
              v-model="domain"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.DOMAIN.PLACEHOLDER')"
            />
          </label>
          <label v-if="featureCustomReplyEmailEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.LABEL') }}
            <input
              v-model="supportEmail"
              type="text"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.PLACEHOLDER')
              "
            />
          </label>
          <label
            v-if="showAutoResolutionConfig"
            :class="{ error: v$.autoResolveDuration.$error }"
          >
            {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.LABEL') }}
            <input
              v-model="autoResolveDuration"
              type="number"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.PLACEHOLDER')
              "
              @blur="v$.autoResolveDuration.$touch"
            />
            <span v-if="v$.autoResolveDuration.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.ERROR') }}
            </span>
          </label>
        </div>
      </div>

      <div
        class="flex flex-row p-4 border-slate-25 dark:border-slate-700 text-black-900 dark:text-slate-300"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE') }}
          </h4>
          <p>
            {{ $t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
          </p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <woot-code :script="getAccountId" />
        </div>
      </div>
      <div class="p-4 text-sm text-center">
        <div>{{ `v${globalConfig.appVersion}` }}</div>
        <div v-if="hasAnUpdateAvailable && globalConfig.displayManifest">
          {{
            $t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
              latestChatwootVersion: latestChatwootVersion,
            })
          }}
        </div>
        <div class="build-id">
          <div>{{ `Build ${globalConfig.gitSha}` }}</div>
        </div>
      </div>

      <woot-submit-button
        class="button nice success button--fixed-top"
        :button-text="$t('GENERAL_SETTINGS.SUBMIT')"
        :loading="isUpdating"
      />
    </form>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>
