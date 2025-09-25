<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      mspId: '',
      businessId: '',
      secret: '',
      merchantId: '',
      applePayMerchantCert: '',
      imessageExtensionBid:
        'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension',
      // OAuth2 Settings
      oauth2Providers: {
        google: {
          enabled: false,
          clientId: '',
          clientSecret: '',
        },
        linkedin: {
          enabled: false,
          clientId: '',
          clientSecret: '',
        },
        facebook: {
          enabled: false,
          clientId: '',
          clientSecret: '',
        },
      },
      // Apple Pay Settings
      paymentSettings: {
        applePayEnabled: false,
        merchantIdentifier: '',
        merchantDomain: '',
        supportedNetworks: ['visa', 'masterCard', 'amex'],
        merchantCapabilities: ['supports3DS', 'supportsDebit', 'supportsCredit'],
        countryCode: 'US',
        currencyCode: 'USD',
      },
      // Payment Processors
      paymentProcessors: {
        stripe: {
          enabled: false,
          publishableKey: '',
          secretKey: '',
        },
        square: {
          enabled: false,
          applicationId: '',
          accessToken: '',
        },
        braintree: {
          enabled: false,
          merchantId: '',
          publicKey: '',
          privateKey: '',
        },
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    mspId: { required },
    businessId: { required },
    secret: { required },
    imessageExtensionBid: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const appleMessagesChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'apple_messages_for_business',
              msp_id: this.mspId,
              business_id: this.businessId,
              secret: this.secret,
              merchant_id: this.merchantId,
              apple_pay_merchant_cert: this.applePayMerchantCert,
              imessage_extension_bid: this.imessageExtensionBid,
              oauth2_providers: this.oauth2Providers,
              payment_settings: this.paymentSettings,
              payment_processors: this.paymentProcessors,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: appleMessagesChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          this.$t(
            'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.API.ERROR_MESSAGE'
          )
        );
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.DESC')"
    />

    <div class="mb-6 p-4 bg-n-alpha-2 rounded-lg border border-n-weak">
      <h3 class="text-sm font-medium text-n-slate-12 mb-2">
        {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11 mb-3">
        {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.DESC') }}
      </p>
      <ol class="text-sm text-n-slate-11 space-y-1 list-decimal list-inside">
        <li>
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.STEP_1')
          }}
        </li>
        <li>
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.STEP_2')
          }}
        </li>
        <li>
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.STEP_3')
          }}
        </li>
        <li>
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SETUP_GUIDE.STEP_4')
          }}
        </li>
      </ol>
    </div>

    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.channelName.$error }">
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.CHANNEL_NAME.LABEL')
          }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.CHANNEL_NAME.PLACEHOLDER'
              )
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.mspId.$error }">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MSP_ID.LABEL') }}
          <input
            v-model="mspId"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MSP_ID.PLACEHOLDER'
              )
            "
            @blur="v$.mspId.$touch"
          />
          <span v-if="v$.mspId.$error" class="message">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MSP_ID.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.businessId.$error }">
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.LABEL')
          }}
          <input
            v-model="businessId"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.PLACEHOLDER'
              )
            "
            @blur="v$.businessId.$touch"
          />
          <span v-if="v$.businessId.$error" class="message">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.BUSINESS_ID.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.secret.$error }">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SECRET.LABEL') }}
          <input
            v-model="secret"
            type="password"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SECRET.PLACEHOLDER'
              )
            "
            @blur="v$.secret.$touch"
          />
          <span v-if="v$.secret.$error" class="message">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SECRET.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label>
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MERCHANT_ID.LABEL')
          }}
          <input
            v-model="merchantId"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MERCHANT_ID.PLACEHOLDER'
              )
            "
          />
          <span class="help-text">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.MERCHANT_ID.HELP')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label>
          {{
            $t(
              'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY_CERT.LABEL'
            )
          }}
          <textarea
            v-model="applePayMerchantCert"
            rows="4"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY_CERT.PLACEHOLDER'
              )
            "
          />
          <span class="help-text">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY_CERT.HELP')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.imessageExtensionBid.$error }">
          {{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_BID.LABEL')
          }}
          <input
            v-model="imessageExtensionBid"
            type="text"
            :placeholder="
              $t(
                'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_BID.PLACEHOLDER'
              )
            "
            @blur="v$.imessageExtensionBid.$touch"
          />
          <span v-if="v$.imessageExtensionBid.$error" class="message">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_BID.ERROR')
          }}</span>
          <span class="help-text">{{
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.IMESSAGE_BID.HELP')
          }}</span>
        </label>
      </div>

      <!-- OAuth2 Authentication Settings -->
      <div class="w-full mt-8">
        <h3 class="text-lg font-semibold text-n-slate-12 mb-4 border-b border-n-weak pb-2">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mb-4">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.DESC') }}
        </p>

        <!-- Google OAuth2 -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="google-oauth"
              v-model="oauth2Providers.google.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="google-oauth" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.GOOGLE_ENABLED') }}
            </label>
          </div>
          <div v-if="oauth2Providers.google.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID') }}
              </label>
              <input
                v-model="oauth2Providers.google.clientId"
                type="text"
                placeholder="Google OAuth2 Client ID"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET') }}
              </label>
              <input
                v-model="oauth2Providers.google.clientSecret"
                type="password"
                placeholder="Google OAuth2 Client Secret"
                class="w-full"
              />
            </div>
          </div>
        </div>

        <!-- LinkedIn OAuth2 -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="linkedin-oauth"
              v-model="oauth2Providers.linkedin.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="linkedin-oauth" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.LINKEDIN_ENABLED') }}
            </label>
          </div>
          <div v-if="oauth2Providers.linkedin.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID') }}
              </label>
              <input
                v-model="oauth2Providers.linkedin.clientId"
                type="text"
                placeholder="LinkedIn OAuth2 Client ID"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET') }}
              </label>
              <input
                v-model="oauth2Providers.linkedin.clientSecret"
                type="password"
                placeholder="LinkedIn OAuth2 Client Secret"
                class="w-full"
              />
            </div>
          </div>
        </div>

        <!-- Facebook OAuth2 -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="facebook-oauth"
              v-model="oauth2Providers.facebook.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="facebook-oauth" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.FACEBOOK_ENABLED') }}
            </label>
          </div>
          <div v-if="oauth2Providers.facebook.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID') }}
              </label>
              <input
                v-model="oauth2Providers.facebook.clientId"
                type="text"
                placeholder="Facebook App ID"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET') }}
              </label>
              <input
                v-model="oauth2Providers.facebook.clientSecret"
                type="password"
                placeholder="Facebook App Secret"
                class="w-full"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Apple Pay Settings -->
      <div class="w-full mt-8">
        <h3 class="text-lg font-semibold text-n-slate-12 mb-4 border-b border-n-weak pb-2">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mb-4">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.DESC') }}
        </p>

        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-4">
            <input
              id="apple-pay-enabled"
              v-model="paymentSettings.applePayEnabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="apple-pay-enabled" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.ENABLED') }}
            </label>
          </div>

          <div v-if="paymentSettings.applePayEnabled" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-n-slate-11 mb-1">
                  {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.MERCHANT_IDENTIFIER') }}
                </label>
                <input
                  v-model="paymentSettings.merchantIdentifier"
                  type="text"
                  placeholder="merchant.com.yourcompany"
                  class="w-full"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-n-slate-11 mb-1">
                  {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.MERCHANT_DOMAIN') }}
                </label>
                <input
                  v-model="paymentSettings.merchantDomain"
                  type="text"
                  placeholder="yourcompany.com"
                  class="w-full"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-n-slate-11 mb-1">
                  {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.COUNTRY_CODE') }}
                </label>
                <select v-model="paymentSettings.countryCode" class="w-full">
                  <option value="US">United States (US)</option>
                  <option value="CA">Canada (CA)</option>
                  <option value="GB">United Kingdom (GB)</option>
                  <option value="AU">Australia (AU)</option>
                  <option value="JP">Japan (JP)</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-n-slate-11 mb-1">
                  {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.CURRENCY_CODE') }}
                </label>
                <select v-model="paymentSettings.currencyCode" class="w-full">
                  <option value="USD">US Dollar (USD)</option>
                  <option value="CAD">Canadian Dollar (CAD)</option>
                  <option value="GBP">British Pound (GBP)</option>
                  <option value="AUD">Australian Dollar (AUD)</option>
                  <option value="JPY">Japanese Yen (JPY)</option>
                </select>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-2">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.SUPPORTED_NETWORKS') }}
              </label>
              <div class="flex flex-wrap gap-3">
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="visa"
                    class="mr-2"
                  />
                  Visa
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="masterCard"
                    class="mr-2"
                  />
                  Mastercard
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="amex"
                    class="mr-2"
                  />
                  American Express
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="discover"
                    class="mr-2"
                  />
                  Discover
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Payment Processors -->
      <div v-if="paymentSettings.applePayEnabled" class="w-full mt-8">
        <h3 class="text-lg font-semibold text-n-slate-12 mb-4 border-b border-n-weak pb-2">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mb-4">
          {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.DESC') }}
        </p>

        <!-- Stripe -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="stripe-enabled"
              v-model="paymentProcessors.stripe.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="stripe-enabled" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.STRIPE_ENABLED') }}
            </label>
          </div>
          <div v-if="paymentProcessors.stripe.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PUBLISHABLE_KEY') }}
              </label>
              <input
                v-model="paymentProcessors.stripe.publishableKey"
                type="text"
                placeholder="pk_..."
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.SECRET_KEY') }}
              </label>
              <input
                v-model="paymentProcessors.stripe.secretKey"
                type="password"
                placeholder="sk_..."
                class="w-full"
              />
            </div>
          </div>
        </div>

        <!-- Square -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="square-enabled"
              v-model="paymentProcessors.square.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="square-enabled" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.SQUARE_ENABLED') }}
            </label>
          </div>
          <div v-if="paymentProcessors.square.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.APPLICATION_ID') }}
              </label>
              <input
                v-model="paymentProcessors.square.applicationId"
                type="text"
                placeholder="Square Application ID"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.ACCESS_TOKEN') }}
              </label>
              <input
                v-model="paymentProcessors.square.accessToken"
                type="password"
                placeholder="Square Access Token"
                class="w-full"
              />
            </div>
          </div>
        </div>

        <!-- Braintree -->
        <div class="bg-n-alpha-2 rounded-lg p-4 mb-4">
          <div class="flex items-center mb-3">
            <input
              id="braintree-enabled"
              v-model="paymentProcessors.braintree.enabled"
              type="checkbox"
              class="mr-3"
            />
            <label for="braintree-enabled" class="text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.BRAINTREE_ENABLED') }}
            </label>
          </div>
          <div v-if="paymentProcessors.braintree.enabled" class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.MERCHANT_ID') }}
              </label>
              <input
                v-model="paymentProcessors.braintree.merchantId"
                type="text"
                placeholder="Braintree Merchant ID"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PUBLIC_KEY') }}
              </label>
              <input
                v-model="paymentProcessors.braintree.publicKey"
                type="text"
                placeholder="Braintree Public Key"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-11 mb-1">
                {{ $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PRIVATE_KEY') }}
              </label>
              <input
                v-model="paymentProcessors.braintree.privateKey"
                type="password"
                placeholder="Braintree Private Key"
                class="w-full"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="
            $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.SUBMIT_BUTTON')
          "
        />
      </div>
    </form>
  </div>
</template>
