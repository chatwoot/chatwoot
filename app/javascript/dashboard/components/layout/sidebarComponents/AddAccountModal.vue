<template>
  <woot-modal
    :show="show"
    :on-close="() => $emit('close-account-create-modal')"
    class="account-selector--modal"
  >
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('CREATE_ACCOUNT.NEW_ACCOUNT')"
        :header-content="$t('CREATE_ACCOUNT.SELECTOR_SUBTITLE')"
      />
      <div v-if="!hasAccounts" class="alert-wrap">
        <div class="callout alert">
          <div class="icon-wrap">
            <i class="ion-alert-circled"></i>
          </div>
          {{ $t('CREATE_ACCOUNT.NO_ACCOUNT_WARNING') }}
        </div>
      </div>

      <form class="row" @submit.prevent="addAccount">
        <div class="medium-12 columns">
          <label :class="{ error: $v.accountName.$error }">
            {{ $t('CREATE_ACCOUNT.FORM.NAME.LABEL') }}
            <input
              v-model.trim="accountName"
              type="text"
              :placeholder="$t('CREATE_ACCOUNT.FORM.NAME.PLACEHOLDER')"
              @input="$v.accountName.$touch"
            />
          </label>
        </div>
        <div class="modal-footer medium-12 columns">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="
                $v.accountName.$invalid ||
                  $v.accountName.$invalid ||
                  uiFlags.isCreating
              "
              :button-text="$t('CREATE_ACCOUNT.FORM.SUBMIT')"
              :loading="uiFlags.isCreating"
              button-class="large expanded"
            />
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    hasAccounts: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      accountName: '',
    };
  },
  validations: {
    accountName: {
      required,
      minLength: minLength(1),
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/getUIFlags',
    }),
  },
  methods: {
    async addAccount() {
      try {
        const account_id = await this.$store.dispatch('accounts/create', {
          account_name: this.accountName,
        });
        this.$emit('close-account-create-modal');
        this.showAlert(this.$t('CREATE_ACCOUNT.API.SUCCESS_MESSAGE'));
        window.location = `/app/accounts/${account_id}/dashboard`;
      } catch (error) {
        if (error.response.status === 422) {
          this.showAlert(this.$t('CREATE_ACCOUNT.API.EXIST_MESSAGE'));
        } else {
          this.showAlert(this.$t('CREATE_ACCOUNT.API.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>
<style lang="scss">
.alert-wrap {
  margin: var(--space-zero) var(--space-large);
  margin-top: var(--space-medium);
  .callout {
    display: flex;
    justify-content: center;
  }
}

.icon-wrap {
  font-size: var(--font-size-big);
  margin-left: var(--space-smaller);
  margin-right: var(--space-slab);
}
</style>
