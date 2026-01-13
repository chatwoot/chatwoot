<template>
  <div class="flex-shrink flex-grow overflow-auto p-4">
    <div class="flex flex-col">
      <div
        class="bg-white dark:bg-slate-800 border border-solid border-slate-75 dark:border-slate-700/50 rounded-sm mb-4 p-4"
      >
        <div class="flex">
          <div class="flex h-[6.25rem] w-[6.25rem]">
            <img
              :src="'/dashboard/images/integrations/' + integration.logo"
              class="max-w-full p-6"
            />
          </div>
          <div class="flex flex-col justify-center m-0 mx-4 flex-1">
            <h3
              class="text-xl font-medium mb-1 text-slate-800 dark:text-slate-100"
            >
              {{ integration.name }}
            </h3>
            <p class="text-slate-700 dark:text-slate-200">
              {{ integration.description }}
            </p>
          </div>
          <div class="flex justify-center items-center mb-0 w-[15%]">
            <div v-if="isOpenAIWithGlobalKey">
              <woot-button
                v-tooltip.top="
                  'Using global OpenAI key. Contact your system administrator to modify settings.'
                "
                class="nice"
                color-scheme="success"
                :disabled="true"
              >
                {{ $t('INTEGRATION_APPS.STATUS.ENABLED') }}
              </woot-button>
            </div>
            <div v-else-if="hasConnectedHooks">
              <div @click="$emit('delete', integration.hooks[0])">
                <woot-button class="nice alert">
                  {{ $t('INTEGRATION_APPS.DISCONNECT.BUTTON_TEXT') }}
                </woot-button>
              </div>
            </div>
            <div v-else>
              <woot-button class="button nice" @click="$emit('add')">
                {{ $t('INTEGRATION_APPS.CONNECT.BUTTON_TEXT') }}
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import hookMixin from './hookMixin';
export default {
  mixins: [hookMixin],
  props: {
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    isOpenAIWithGlobalKey() {
      return (
        this.integration.id === 'openai' &&
        this.isFeatureEnabledonAccount(this.accountId, 'use_global_openai_key')
      );
    },
  },
};
</script>
