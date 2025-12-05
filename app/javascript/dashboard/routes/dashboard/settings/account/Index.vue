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
          <label :class="{ error: $v.name.$error }">
            {{ $t('GENERAL_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @blur="$v.name.$touch"
            />
            <span v-if="$v.name.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.locale.$error }">
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
            <span v-if="$v.locale.$error" class="message">
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
            :class="{ error: $v.autoResolveDuration.$error }"
          >
            {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.LABEL') }}
            <input
              v-model="autoResolveDuration"
              type="number"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.PLACEHOLDER')
              "
              @blur="$v.autoResolveDuration.$touch"
            />
            <span v-if="$v.autoResolveDuration.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.ERROR') }}
            </span>
          </label>
        </div>
      </div>

      <div
        v-if="hasInstagramInbox"
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            Instagram Settings
          </h4>
          <p>Configure Instagram Comment notification message</p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <label>
            Instagram Comment Message
            <input
              v-model="instagramDmMessage"
              type="text"
              placeholder="Check your DM"
              maxlength="200"
            />
            <span class="help-text">
              This message will be posted as a comment when moving conversations
              to Instagram DM ({{ instagramDmMessage.length }}/200 characters)
            </span>
          </label>
        </div>
      </div>

      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('GENERAL_SETTINGS.FORM.CONTACT_ASSIGNMENT.TITLE') }}
          </h4>
          <p>
            {{ $t('GENERAL_SETTINGS.FORM.CONTACT_ASSIGNMENT.NOTE') }}
          </p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <label class="flex items-center gap-2">
            <input
              v-model="contactAssignmentEnabled"
              type="checkbox"
              class="w-4 h-4"
            />
            <span>Enable agent-level contact segregation</span>
          </label>
          <span class="help-text mt-2 block">
            When enabled:
            <ul class="list-disc ml-5 mt-1">
              <li>Agents only see contacts assigned to them</li>
              <li>New contacts auto-assigned to creator</li>
              <li>Customer replies route to contact owner</li>
              <li>Broadcasts filtered to sender's contacts</li>
              <li>Admins always see all contacts</li>
            </ul>
          </span>
        </div>
      </div>

      <div
        class="p-4 border-slate-25 dark:border-slate-700 text-black-900 dark:text-slate-300 flex flex-row"
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
      <div class="text-sm text-center p-4">
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

<script>
import { required, minValue, maxValue } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

export default {
  mixins: [accountMixin, alertMixin, configMixin, uiSettingsMixin],
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
      instagramDmMessage: 'Check your DM',
      hasInstagramInbox: false,
      contactAssignmentEnabled: false,
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
      accountId: 'getCurrentAccountId',
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
          has_instagram_inbox: hasInstagramInbox,
          custom_attributes: customAttributes,
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
        this.hasInstagramInbox = hasInstagramInbox || false;
        this.instagramDmMessage =
          customAttributes?.instagram_dm_message || 'Check your DM';
        this.contactAssignmentEnabled =
          customAttributes?.enable_contact_assignment === true;
      } catch (error) {
        // Ignore error
      }
    },

    async updateAccount() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        const updatePayload = {
          locale: this.locale,
          name: this.name,
          domain: this.domain,
          support_email: this.supportEmail,
          auto_resolve_duration: this.autoResolveDuration,
          enable_contact_assignment: this.contactAssignmentEnabled,
        };

        if (this.hasInstagramInbox) {
          updatePayload.instagram_dm_message = this.instagramDmMessage;
        }

        await this.$store.dispatch('accounts/update', updatePayload);
        this.$root.$i18n.locale = this.locale;
        this.getAccount(this.id).locale = this.locale;
        this.updateDirectionView(this.locale);
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
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
