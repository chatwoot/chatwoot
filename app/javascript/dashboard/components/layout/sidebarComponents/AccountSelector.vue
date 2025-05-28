<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    showAccountModal: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['closeAccountModal', 'showCreateAccountModal'],
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

<template>
  <woot-modal
    :show="showAccountModal"
    :on-close="() => $emit('closeAccountModal')"
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
          class="flex items-center justify-between w-full px-4 py-3 rounded-lg cursor-pointer expanded clear link hover:underline hover:bg-slate-25 dark:hover:bg-slate-900"
          @click="onChangeAccount(account.id)"
        >
          <span class="w-full">
            <label :for="account.name" class="text-left rtl:text-right">
              <div
                class="text-lg font-medium leading-5 text-slate-700 dark:text-slate-100 hover:underline-offset-4"
              >
                {{ account.name }}
              </div>
              <div
                class="text-xs font-medium lowercase text-slate-500 dark:text-slate-500 hover:underline-offset-4"
              >
                {{
                  account.custom_role_id
                    ? account.custom_role.name
                    : account.role
                }}
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
      class="flex items-center justify-end gap-2 px-8 pt-4 pb-8"
    >
      <button
        class="w-full button success large expanded nice"
        @click="$emit('showCreateAccountModal')"
      >
        {{ $t('CREATE_ACCOUNT.NEW_ACCOUNT') }}
      </button>
    </div>
  </woot-modal>
</template>
