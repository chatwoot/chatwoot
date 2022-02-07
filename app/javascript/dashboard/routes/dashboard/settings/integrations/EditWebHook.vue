<template>
  <div class="column content-box">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.TITLE')"
    />
    <form class="row" @submit.prevent="editWebhook">
      <div class="medium-12 columns">
        <label :class="{ error: $v.endPoint.$error }">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.FORM.END_POINT.LABEL') }}
          <input
            v-model.trim="endPoint"
            type="text"
            name="endPoint"
            :placeholder="
              $t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.FORM.END_POINT.PLACEHOLDER')
            "
            @input="$v.endPoint.$touch"
          />
          <span v-if="$v.endPoint.$error" class="message">
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.FORM.END_POINT.ERROR') }}
          </span>
        </label>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button
            :is-disabled="
              $v.endPoint.$invalid || uiFlags.updatingItem || endPoint === url
            "
            :is-loading="uiFlags.updatingItem"
          >
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.FORM.SUBMIT') }}
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.CANCEL') }}
          </woot-button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { required, url, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [alertMixin],
  props: {
    id: {
      type: Number,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      alertMessage: '',
      endPoint: this.url,
      webhookId: this.id,
    };
  },
  validations: {
    endPoint: {
      required,
      minLength: minLength(7),
      url,
    },
  },
  computed: {
    ...mapGetters({ uiFlags: 'webhooks/getUIFlags' }),
  },
  methods: {
    resetForm() {
      this.endPoint = '';
      this.$v.endPoint.$reset();
    },
    async editWebhook() {
      try {
        await this.$store.dispatch('webhooks/update', {
          webhook: { url: this.endPoint },
          id: this.webhookId,
        });
        this.alertMessage = this.$t(
          'INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.SUCCESS_MESSAGE'
        );
        this.resetForm();
        this.onClose();
      } catch (error) {
        this.alertMessage =
          error.response.data.message ||
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
