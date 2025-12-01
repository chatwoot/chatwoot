<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  creditGrants: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const dialogRef = ref(null);

const formattedGrants = computed(() => {
  return props.creditGrants.map(grant => ({
    ...grant,
    formattedEffectiveAt: grant.effective_at
      ? format(new Date(grant.effective_at), 'dd MMM, yyyy')
      : '-',
    formattedExpiresAt: grant.expires_at
      ? format(new Date(grant.expires_at), 'dd MMM, yyyy')
      : '-',
  }));
});

const handleClose = () => {
  emit('close');
};

const open = () => {
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('BILLING_SETTINGS.CREDIT_HISTORY.TITLE')"
    :description="t('BILLING_SETTINGS.CREDIT_HISTORY.DESCRIPTION')"
    width="2xl"
    :show-confirm-button="false"
    :show-cancel-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <span class="i-lucide-loader-2 size-6 animate-spin text-n-slate-11" />
    </div>

    <div v-else-if="formattedGrants.length === 0" class="py-8 text-center">
      <span
        class="i-lucide-credit-card size-12 text-n-slate-9 mx-auto block mb-3"
      />
      <p class="text-sm text-n-slate-11">
        {{ t('BILLING_SETTINGS.CREDIT_HISTORY.NO_RECORDS') }}
      </p>
    </div>

    <div v-else class="overflow-hidden border rounded-lg border-n-weak">
      <table class="w-full">
        <thead class="bg-n-alpha-1">
          <tr>
            <th
              class="px-4 py-3 text-xs font-medium tracking-wider text-left uppercase text-n-slate-10"
            >
              {{ t('BILLING_SETTINGS.CREDIT_HISTORY.NAME') }}
            </th>
            <th
              class="px-4 py-3 text-xs font-medium tracking-wider text-left uppercase text-n-slate-10"
            >
              {{ t('BILLING_SETTINGS.CREDIT_HISTORY.CREDITS') }}
            </th>
            <th
              class="px-4 py-3 text-xs font-medium tracking-wider text-left uppercase text-n-slate-10"
            >
              {{ t('BILLING_SETTINGS.CREDIT_HISTORY.SOURCE') }}
            </th>
            <th
              class="px-4 py-3 text-xs font-medium tracking-wider text-left uppercase text-n-slate-10"
            >
              {{ t('BILLING_SETTINGS.CREDIT_HISTORY.EFFECTIVE_AT') }}
            </th>
            <th
              class="px-4 py-3 text-xs font-medium tracking-wider text-left uppercase text-n-slate-10"
            >
              {{ t('BILLING_SETTINGS.CREDIT_HISTORY.EXPIRES_AT') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak">
          <tr v-for="grant in formattedGrants" :key="grant.id">
            <td class="px-4 py-3 text-sm text-n-slate-12">
              {{ grant.name || '-' }}
            </td>
            <td
              class="px-4 py-3 text-sm font-medium tabular-nums text-n-slate-12"
            >
              {{ grant.credits?.toLocaleString() || 0 }}
            </td>
            <td class="px-4 py-3">
              <span
                class="px-2 py-1 text-xs font-medium rounded bg-n-alpha-2 text-n-slate-11"
              >
                {{ grant.source || grant.category || '-' }}
              </span>
            </td>
            <td class="px-4 py-3 text-sm text-n-slate-11">
              {{ grant.formattedEffectiveAt }}
            </td>
            <td class="px-4 py-3 text-sm text-n-slate-11">
              {{ grant.formattedExpiresAt }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <template #footer>
      <div class="flex justify-end w-full">
        <Button
          variant="faded"
          color="slate"
          :label="t('BILLING_SETTINGS.CREDIT_HISTORY.CLOSE')"
          @click="close"
        />
      </div>
    </template>
  </Dialog>
</template>
