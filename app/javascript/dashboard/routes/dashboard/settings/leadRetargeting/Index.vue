<script setup>
import {
  computed,
  onMounted,
  onActivated,
  onBeforeUnmount,
  ref,
  watch,
} from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import leadFollowUpSequencesAPI from 'dashboard/api/leadFollowUpSequences';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const getters = useStoreGetters();

const sequences = ref([]);
const loading = ref(true);
const accountId = computed(() => getters.getCurrentAccountId.value);
const dialogRef = ref(null);
const sequenceToDelete = ref(null);

const fetchSequences = async () => {
  try {
    loading.value = true;
    const response = await leadFollowUpSequencesAPI.get();
    sequences.value = response.data;
  } catch (error) {
    useAlert(t('LEAD_RETARGETING.LIST.API.ERROR_MESSAGE'));
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchSequences();
});

// Refetch cuando el componente se reactive (para resolver el bug de lista no actualizada)
onActivated(() => {
  fetchSequences();
});

// También refetch cuando la ruta cambie a esta vista (fallback)
watch(
  () => route.name,
  newName => {
    if (newName === 'copilots_list') {
      fetchSequences();
    }
  }
);

const resetData = () => {
  sequences.value = [];
  sequenceToDelete.value = null;
};

onBeforeUnmount(() => {
  resetData();
});

const goToNew = () => {
  router.push({ name: 'copilots_new' });
};

const goToEdit = sequenceId => {
  router.push({
    name: 'copilots_edit',
    params: { sequenceId },
  });
};

const goToShow = sequenceId => {
  router.push({
    name: 'copilots_show',
    params: { sequenceId },
  });
};

const toggleActive = async sequence => {
  try {
    if (sequence.active) {
      await leadFollowUpSequencesAPI.deactivate(sequence.id);
      useAlert(t('LEAD_RETARGETING.TOGGLE.DEACTIVATED'));
    } else {
      await leadFollowUpSequencesAPI.activate(sequence.id);
      useAlert(t('LEAD_RETARGETING.TOGGLE.ACTIVATED'));
    }
    await fetchSequences();
  } catch (error) {
    useAlert(t('LEAD_RETARGETING.TOGGLE.ERROR'));
  }
};

const openDeleteDialog = sequence => {
  sequenceToDelete.value = sequence;
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const closeDeleteDialog = () => {
  if (dialogRef.value) {
    dialogRef.value.close();
  }
  sequenceToDelete.value = null;
};

const confirmDeletion = async () => {
  if (!sequenceToDelete.value) return;

  try {
    await leadFollowUpSequencesAPI.delete(sequenceToDelete.value.id);
    useAlert(t('LEAD_RETARGETING.DELETE.SUCCESS_MESSAGE'));
    closeDeleteDialog();
    await fetchSequences();
  } catch (error) {
    useAlert(t('LEAD_RETARGETING.DELETE.ERROR_MESSAGE'));
    closeDeleteDialog();
  }
};
</script>

<template>
  <SettingsLayout
    :no-records-found="!loading && sequences.length === 0"
    :no-records-message="t('LEAD_RETARGETING.LIST.404')"
    :is-loading="loading"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('LEAD_RETARGETING.HEADER')"
        :description="t('LEAD_RETARGETING.DESCRIPTION')"
        :link-text="t('LEAD_RETARGETING.LEARN_MORE')"
        feature-name="lead_retargeting"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="t('LEAD_RETARGETING.HEADER_BTN_TXT')"
            @click="goToNew"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
        <thead>
          <tr>
            <th
              class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
            >
              {{ t('LEAD_RETARGETING.LIST.TABLE_HEADER.NAME') }}
            </th>
            <th
              class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
            >
              {{ t('LEAD_RETARGETING.LIST.TABLE_HEADER.STATUS') }}
            </th>
            <th
              class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
            >
              {{ t('LEAD_RETARGETING.LIST.TABLE_HEADER.SOURCE') }}
            </th>
            <th
              class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
            >
              {{ t('LEAD_RETARGETING.LIST.TABLE_HEADER.STEPS') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak text-n-slate-12">
          <tr v-for="sequence in sequences" :key="sequence.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span class="block font-medium">{{ sequence.name }}</span>
              <p
                v-if="sequence.description"
                class="mb-0 text-sm text-n-slate-11"
              >
                {{ sequence.description }}
              </p>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-col gap-1 items-start">
                <span
                  class="inline-flex px-2 py-1 text-xs rounded-full"
                  :class="[
                    sequence.active
                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                      : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300',
                  ]"
                >
                  {{
                    sequence.active
                      ? t('LEAD_RETARGETING.STATUS.ACTIVE')
                      : t('LEAD_RETARGETING.STATUS.INACTIVE')
                  }}
                </span>
                <span
                  v-if="
                    !sequence.active &&
                    sequence.metadata?.auto_deactivation_reason ===
                      'all_conversations_completed'
                  "
                  class="inline-flex items-center gap-1 text-xs text-n-teal-11"
                >
                  <i class="i-lucide-check-circle text-xs" />
                  Auto-completado
                </span>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div v-if="sequence.source_type === 'notion_database'" class="flex items-center gap-2">
                <i class="i-lucide-database text-n-purple-11" />
                <span class="text-sm">{{ sequence.source_config?.notion_database_name || 'Notion Database' }}</span>
              </div>
              <div v-else>
                {{ sequence.inbox?.name || '-' }}
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              {{ sequence.steps.length }}
              <span
                v-if="sequence.stats.total_enrolled"
                class="text-n-slate-11"
              >
                ({{ sequence.stats.total_enrolled }}
                {{ t('LEAD_RETARGETING.LIST.ENROLLED') }})
              </span>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-tooltip.top="'Ver Detalle'"
                  icon="i-lucide-eye"
                  slate
                  xs
                  faded
                  @click="goToShow(sequence.id)"
                />
                <Button
                  v-tooltip.top="t('LEAD_RETARGETING.LIST.EDIT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="goToEdit(sequence.id)"
                />
                <Button
                  v-tooltip.top="
                    sequence.active
                      ? t('LEAD_RETARGETING.LIST.DEACTIVATE')
                      : t('LEAD_RETARGETING.LIST.ACTIVATE')
                  "
                  :icon="sequence.active ? 'i-lucide-pause' : 'i-lucide-play'"
                  xs
                  faded
                  :class="
                    sequence.active ? 'text-orange-600' : 'text-green-600'
                  "
                  @click="toggleActive(sequence)"
                />
                <Button
                  v-tooltip.top="t('LEAD_RETARGETING.LIST.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  @click="openDeleteDialog(sequence)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </SettingsLayout>

  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('LEAD_RETARGETING.DELETE.CONFIRM.TITLE')"
    :description="
      t('LEAD_RETARGETING.DELETE.CONFIRM.MESSAGE', {
        name: sequenceToDelete?.name || '',
      })
    "
    :confirm-button-label="t('LEAD_RETARGETING.DELETE.CONFIRM.YES')"
    :cancel-button-label="t('LEAD_RETARGETING.DELETE.CONFIRM.NO')"
    @confirm="confirmDeletion"
  />
</template>
