<template>
  <div class="column content-box">
    <woot-modal-header
        :header-title="$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.TITLE')"
    />
    <form class="row" @submit.prevent="editShopify">
      <div class="medium-12 columns">
        <label :class="{ error: $v.accountName.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.LABEL') }}
          <input
              v-model.trim="accountName"
              type="text"
              name="accountName"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.PLACEHOLDER'
                )
              "
              @input="$v.accountName.$touch"
          />
          <span v-if="$v.accountName.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.ERROR') }}
            </span>
        </label>

        <label :class="{ error: $v.apiKey.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.LABEL') }}
          <input
              v-model.trim="apiKey"
              type="text"
              name="apiKey"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.PLACEHOLDER'
                )
              "
              @input="$v.apiKey.$touch"
          />
          <span v-if="$v.apiKey.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_KEY.ERROR') }}
            </span>
        </label>

        <label :class="{ error: $v.apiSecret.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.LABEL') }}
          <input
              v-model.trim="apiSecret"
              type="text"
              name="apiSecret"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.PLACEHOLDER'
                )
              "
              @input="$v.apiSecret.$touch"
          />
          <span v-if="$v.apiSecret.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_SECRET.ERROR') }}
            </span>
        </label>

        <label :class="{ error: $v.redirectUrl.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.LABEL') }}
          <input
              v-model.trim="redirectUrl"
              type="text"
              name="redirectUrl"
              :placeholder="
              $t(
                'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.PLACEHOLDER'
              )
            "
              @input="$v.redirectUrl.$touch"
          />
          <span v-if="$v.redirectUrl.$error" class="message">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.REDIRECT_URL.ERROR') }}
          </span>
				</label>
         <h7>{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.LATEST_TOKEN')+' '+(this.accessToken?moment(this.updatedAt).format("YYYY-MM-DD HH:mm"):"-")}}</h7>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button class="button"  color-scheme="success" @click.prevent="onAuthorize">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.AUTHORIZE') }}
          </woot-button>
          <woot-button
              :is-disabled="
              $v.apiKey.$invalid || $v.accountName.$invalid || $v.apiSecret.$invalid || $v.redirectUrl.$invalid || uiFlags.updatingItem
            "
              :is-loading="uiFlags.updatingItem"
          >
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.FORM.SUBMIT') }}
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.CANCEL') }}
          </woot-button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import {required, url, minLength, maxLength} from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import {mapGetters} from 'vuex';
import moment from "moment";
export default {
  mixins: [alertMixin],
  props: {
    accountName: {
      type: String,
      required: true,
    },
    apiKey: {
      type: String,
      required: true,
    },
    apiSecret: {
      type: String,
      required: true
    },
    redirectUrl: {
      type: String,
      required: true
    },
    onClose: {
      type: Function,
      required: true,
    },
    id: {
      type: Number,
      required: true
    },
    accessToken: {
      type: String,
      required: true
    },
    updatedAt: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      shopfiyId: this.id,
    };
  },
  validations: {
    accountName: {
      required,
      minLength: minLength(3)
    },
    apiKey: {
      required,
      minLength: minLength(32),
      maxLength: maxLength(40)
    },
    apiSecret: {
      required,
      minLength: minLength(30),
      maxLength: maxLength(40)
    },
    redirectUrl: {
      required
    }
  },
  computed: {
    ...mapGetters({uiFlags: 'webhooks/getUIFlags'}),
  },
  methods: {
    getAuthorizePopup(){
      window.location.href=`https://${this.accountName}/admin/oauth/authorize?client_id=${this.apiKey}&scope=read_orders,write_orders,read_customers,write_customers&redirect_uri=${this.redirectUrl}`;
    },
    closeAuthorizePopup(){
      this.showAuthorizePopup = false;
    },
    resetForm() {
      this.accountName = '';
      this.apiKey = '';
      this.apiSecret = '';
      this.redirectUrl = '';
      this.$v.accountName.$reset();
      this.$v.apiKey.$reset();
      this.$v.apiSecret.$reset();
      this.$v.redirectUrl.$reset();
    },
    onAuthorize(){
      this.getAuthorizePopup();
    },
    async editShopify() {
      try {
        await this.$store.dispatch('shopify/update', {
          id: this.shopfiyId,
          account_name: this.accountName,
          api_key: this.apiKey,
          api_secret: this.apiSecret,
          redirect_url: this.redirectUrl
        });
        this.alertMessage = this.$t(
            'INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.SUCCESS_MESSAGE'
        );
        await this.$store.dispatch('shopify/get');
        this.resetForm();
        this.onClose();
      } catch (error) {
        this.alertMessage =
            error.response.data.message ||
            this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    moment(){
      return new moment();
    }
  },
};
</script>
