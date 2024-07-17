<template>
  <woot-modal
    :show="showAccountModal"
    :on-close="() => $emit('close-account-modal')"
  >
    <woot-modal-header
      :header-title="$t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS')"
      :header-content="$t('SIDEBAR_ITEMS.SELECTOR_SUBTITLE')"
    />
    <div class="px-8 py-4">
      <div
        v-for="account in currentUser.accounts"
        :id="`account-${account.id}`"
        :key="account.id"
        class="pt-0 pb-0"
      >
        <button
          class="flex justify-between items-center expanded clear link cursor-pointer px-4 py-3 w-full rounded-lg hover:underline hover:bg-slate-25 dark:hover:bg-slate-900"
          @click="onChangeAccount(account.id)"
        >
          <span class="w-full">
            <label :for="account.name" class="text-left rtl:text-right">
              <div
                class="text-slate-700 text-lg dark:text-slate-100 font-medium hover:underline-offset-4 leading-5"
              >
                {{ account.name }}
              </div>
              <div
                class="text-slate-500 text-xs dark:text-slate-500 font-medium hover:underline-offset-4"
              >
                {{ account.role }}
              </div>
            </label>
          </span>
          <fluent-icon
            v-show="account.id === accountId"
            class="text-slate-800 dark:text-slate-100"
            icon="checkmark-circle"
            type="solid"
            size="24"
          />
        </button>
      </div>
    </div>

    <div
      v-if="globalConfig.createNewAccountFromDashboard"
      class="flex justify-end items-center px-8 pb-8 pt-4 gap-2"
    >
      <button
        class="button success large expanded nice w-full"
        @click="$emit('show-create-account-modal')"
      >
        {{ $t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
      </button>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    showAccountModal: {
      type: Boolean,
      default: true,
    },
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
  },
  methods: {
    onChangeAccount(accountId) {
      const accountUrl = `/app/accounts/${accountId}/dashboard`;
      window.location.href = accountUrl;
    },
  },
};
</script>
