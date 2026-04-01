<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
const { currentAccount } = useAccount();

const accountIdText = computed(() => currentAccount.value.id.toString());

const copyId = async () => {
  await copyTextToClipboard(accountIdText.value);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
};
</script>

<template>
  <section
    class="p-6 bg-surface-container-low rounded-xl border border-outline-variant/10 shadow-lg relative overflow-hidden group"
  >
    <div
      class="absolute -right-4 -top-4 w-24 h-24 bg-secondary/5 rounded-full blur-2xl group-hover:bg-secondary/10 transition-all duration-500"
      aria-hidden="true"
    />
    <h4
      class="text-xs font-bold text-secondary uppercase tracking-[0.2em] mb-4 relative"
    >
      {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.CARD_TITLE') }}
    </h4>
    <div class="space-y-4 relative">
      <div class="space-y-2">
        <span
          class="block text-[10px] font-bold text-on-primary-container uppercase"
        >
          {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.LABEL') }}
        </span>
        <div class="flex items-center gap-2">
          <div
            class="flex-1 min-w-0 bg-surface-container-lowest/50 border border-outline-variant/20 rounded-lg px-3 py-2 font-mono text-xs text-on-surface-variant truncate"
            :title="accountIdText"
          >
            {{ accountIdText }}
          </div>
          <button
            type="button"
            class="p-2 shrink-0 bg-surface-container-highest rounded-lg text-secondary hover:bg-secondary hover:text-on-secondary transition-all outline-none focus-visible:ring-2 focus-visible:ring-secondary"
            :title="t('COMPONENTS.CODE.BUTTON_TEXT')"
            @click="copyId"
          >
            <Icon icon="i-lucide-copy" class="size-[18px]" />
          </button>
        </div>
      </div>
      <p class="text-[11px] text-on-primary-container leading-relaxed mb-0">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
      </p>
    </div>
  </section>
</template>
