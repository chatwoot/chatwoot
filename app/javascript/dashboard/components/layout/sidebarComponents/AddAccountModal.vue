<template>
  <woot-modal
    :show="show"
    :on-close="() => $emit('close-account-create-modal')"
  >
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('CREATE_ACCOUNT.NEW_ACCOUNT')"
        :header-content="$t('CREATE_ACCOUNT.SELECTOR_SUBTITLE')"
      />
      <div v-if="!hasAccounts" class="text-sm mt-6 mx-8 mb-0">
        <div class="items-center rounded-md flex alert">
          <div class="ml-1 mr-3">
            <fluent-icon icon="warning" />
          </div>
          {{ $t('CREATE_ACCOUNT.NO_ACCOUNT_WARNING') }}
        </div>
      </div>

      <form class="flex flex-col w-full" @submit.prevent="addAccount">
        <div class="w-full">
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
        <div class="w-full">
          <div class="w-full">
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
import { useAlert } from 'dashboard/composables';

export default {
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
        useAlert(this.$t('CREATE_ACCOUNT.API.SUCCESS_MESSAGE'));
        window.location = `/app/accounts/${account_id}/dashboard`;
      } catch (error) {
        if (error.response.status === 422) {
          useAlert(this.$t('CREATE_ACCOUNT.API.EXIST_MESSAGE'));
        } else {
          useAlert(this.$t('CREATE_ACCOUNT.API.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>
