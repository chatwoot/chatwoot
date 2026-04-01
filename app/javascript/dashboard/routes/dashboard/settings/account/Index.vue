<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AccountId from './components/AccountId.vue';
import BuildInfo from './components/BuildInfo.vue';
import AccountDelete from './components/AccountDelete.vue';
import AudioTranscription from './components/AudioTranscription.vue';
export default {
  components: {
    NextButton,
    Icon,
    AccountId,
    BuildInfo,
    AccountDelete,
    AudioTranscription,
    WithLabel,
    NextInput,
  },
  setup() {
    const { updateUISettings, uiSettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const { accountId } = useAccount();
    const v$ = useVuelidate();

    return { updateUISettings, uiSettings, v$, enabledLanguages, accountId };
  },
  data() {
    return {
      id: '',
      name: '',
      locale: 'en',
      domain: '',
      supportEmail: '',
      features: {},
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
    }),
    showAudioTranscriptionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.CAPTAIN
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
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const { name, locale, id, domain, support_email, features } =
          this.getAccount(this.accountId);

        this.$root.$i18n.locale = this.uiSettings?.locale || locale;
        this.name = name;
        this.locale = locale;
        this.id = id;
        this.domain = domain;
        this.supportEmail = support_email;
        this.features = features;
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
        });
        // If user locale is set, update the locale with user locale
        if (this.uiSettings?.locale) {
          this.$root.$i18n.locale = this.uiSettings?.locale;
        } else {
          // If user locale is not set, update the locale with account locale
          this.$root.$i18n.locale = this.locale;
        }
        this.getAccount(this.id).locale = this.locale;
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },
  },
};
</script>

<template>
  <div
    class="account-settings-page flex flex-col w-full mx-auto space-y-10 text-on-surface antialiased selection:bg-secondary/30"
  >
    <header class="space-y-1">
      <h1 class="text-3xl font-bold tracking-tight text-on-surface">
        {{ $t('GENERAL_SETTINGS.TITLE') }}
      </h1>
      <p class="text-on-primary-container text-lg mb-0">
        {{ $t('GENERAL_SETTINGS.PAGE_SUBTITLE') }}
      </p>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <div class="md:col-span-2 space-y-8">
        <section
          class="p-6 bg-surface-container-low rounded-xl border border-outline-variant/5 shadow-sm"
        >
          <h3
            class="text-lg font-semibold text-on-surface mb-6 flex items-center gap-2"
          >
            <Icon
              icon="i-lucide-sliders-horizontal"
              class="size-5 text-secondary shrink-0"
            />
            {{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE') }}
          </h3>
          <woot-loading-state v-if="uiFlags.isFetchingItem" />
          <form v-else class="space-y-6" @submit.prevent="updateAccount">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <WithLabel
                name="account-settings-name"
                :has-error="v$.name.$error"
                :label="$t('GENERAL_SETTINGS.FORM.NAME.LABEL')"
                :error-message="$t('GENERAL_SETTINGS.FORM.NAME.ERROR')"
              >
                <NextInput
                  v-model="name"
                  type="text"
                  custom-input-class="!px-4"
                  class="w-full"
                  :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
                  @blur="v$.name.$touch"
                />
                <template #help>
                  {{ $t('GENERAL_SETTINGS.FORM.NAME.HELP') }}
                </template>
              </WithLabel>
              <WithLabel
                v-if="featureCustomReplyEmailEnabled"
                name="account-settings-support-email"
                :label="$t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.LABEL')"
              >
                <NextInput
                  v-model="supportEmail"
                  type="text"
                  custom-input-class="!px-4"
                  class="w-full"
                  :placeholder="
                    $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.PLACEHOLDER')
                  "
                />
              </WithLabel>
            </div>
            <WithLabel
              name="account-settings-locale"
              :has-error="v$.locale.$error"
              :label="$t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL')"
              :error-message="$t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR')"
            >
              <div class="relative">
                <select
                  v-model="locale"
                  class="w-full bg-surface-container-lowest !bg-none border border-outline-variant/30 rounded-lg py-2.5 ltr:pl-4 ltr:!pr-10 rtl:!pl-10 rtl:pr-4 text-on-surface appearance-none cursor-pointer text-sm !mb-0 !outline-none hover:!outline-none focus:!outline-none focus-visible:!outline-none ring-0 focus:ring-0 ring-offset-0"
                >
                  <option
                    v-for="lang in languagesSortedByCode"
                    :key="lang.iso_639_1_code"
                    :value="lang.iso_639_1_code"
                  >
                    {{ lang.name }}
                  </option>
                </select>
                <Icon
                  icon="i-lucide-chevron-down"
                  class="absolute right-3 top-1/2 -translate-y-1/2 size-4 text-on-primary-container pointer-events-none"
                />
              </div>
              <template #help>
                <span class="italic">
                  {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.HELP') }}
                </span>
              </template>
            </WithLabel>
            <WithLabel
              v-if="featureCustomReplyDomainEnabled"
              name="account-settings-domain"
              :label="$t('GENERAL_SETTINGS.FORM.DOMAIN.LABEL')"
            >
              <NextInput
                v-model="domain"
                type="text"
                custom-input-class="!px-4"
                class="w-full"
                :placeholder="$t('GENERAL_SETTINGS.FORM.DOMAIN.PLACEHOLDER')"
              />
              <template #help>
                {{
                  featureInboundEmailEnabled &&
                  $t('GENERAL_SETTINGS.FORM.FEATURES.INBOUND_EMAIL_ENABLED')
                }}
                {{
                  featureCustomReplyDomainEnabled &&
                  $t(
                    'GENERAL_SETTINGS.FORM.FEATURES.CUSTOM_EMAIL_DOMAIN_ENABLED'
                  )
                }}
              </template>
            </WithLabel>
            <div
              class="pt-4 border-t border-outline-variant/15 flex justify-end"
            >
              <NextButton
                type="submit"
                solid
                teal
                md
                trailing-icon
                icon="i-lucide-save"
                :is-loading="isUpdating"
                class="font-bold hover:shadow-[0_0_15px_rgba(4,190,153,0.4)]"
              >
                {{ $t('GENERAL_SETTINGS.SUBMIT') }}
              </NextButton>
            </div>
          </form>
        </section>

        <AudioTranscription v-if="showAudioTranscriptionConfig" />
        <div v-if="!uiFlags.isFetchingItem && isOnChatwootCloud">
          <AccountDelete />
        </div>
      </div>

      <div class="space-y-6">
        <AccountId />
        <div
          class="p-6 bg-surface-container-low rounded-xl border border-outline-variant/5"
        >
          <div class="flex items-center gap-3 mb-4">
            <Icon
              icon="i-lucide-alert-triangle"
              class="size-5 text-amber-400 shrink-0"
            />
            <h4
              class="text-xs font-bold text-on-surface uppercase tracking-wider mb-0"
            >
              {{ $t('GENERAL_SETTINGS.SYSTEM_ALERT.TITLE') }}
            </h4>
          </div>
          <p class="text-xs text-on-primary-container leading-relaxed mb-0">
            {{ $t('GENERAL_SETTINGS.SYSTEM_ALERT.MESSAGE') }}
          </p>
        </div>
        <BuildInfo />
      </div>
    </div>
  </div>
</template>

<style scoped>
.account-settings-page :deep(.space-y-1 > label:not(.text-n-ruby-12)) {
  @apply !text-xs !font-semibold !text-on-surface-variant uppercase tracking-wider;
}

.account-settings-page :deep(.space-y-1 > label.text-n-ruby-12) {
  @apply !text-xs !font-semibold uppercase tracking-wider;
}

.account-settings-page :deep(.space-y-1 .text-n-slate-10) {
  @apply !text-[11px] !text-on-primary-container;
}
</style>
