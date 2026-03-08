<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import WhatsAppTemplateCreator from './WhatsAppTemplateCreator.vue';

const props = defineProps({
  inboxId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const isSyncing = ref(false);
const isDeleting = ref(false);
const deleteTemplateName = ref('');
const creatorRef = ref(null);
const createDialogRef = ref(null);
const deleteDialogRef = ref(null);

const getFilteredTemplates = useMapGetter('inboxes/getWhatsAppTemplates');

const templates = computed(() => {
  const raw = getFilteredTemplates.value(Number(props.inboxId));
  if (!raw || !Array.isArray(raw)) return [];
  return raw;
});

const statusClass = status => {
  const s = status?.toUpperCase();
  if (s === 'APPROVED') return 'bg-n-teal-3 text-n-teal-11';
  if (s === 'REJECTED') return 'bg-n-ruby-3 text-n-ruby-11';
  return 'bg-n-amber-3 text-n-amber-11';
};

const handleSync = async () => {
  isSyncing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', Number(props.inboxId));
    useAlert(t('WHATSAPP_TEMPLATES.MANAGER.SYNC_SUCCESS'));
    await store.dispatch('inboxes/get');
  } catch {
    useAlert(t('WHATSAPP_TEMPLATES.MANAGER.SYNC_ERROR'));
  } finally {
    isSyncing.value = false;
  }
};

const openCreateDialog = () => createDialogRef.value?.open();

const handleCreateTemplate = async templateData => {
  try {
    const result = await store.dispatch('inboxes/createWhatsAppTemplate', {
      inboxId: Number(props.inboxId),
      templateData,
    });
    if (result?.template) {
      useAlert(t('WHATSAPP_TEMPLATES.CREATOR.SUCCESS'));
      creatorRef.value?.resetForm();
      createDialogRef.value?.close();
      await store.dispatch('inboxes/get');
    } else {
      useAlert(result?.error || t('WHATSAPP_TEMPLATES.CREATOR.ERROR'));
    }
  } catch {
    useAlert(t('WHATSAPP_TEMPLATES.CREATOR.ERROR'));
  }
};

const confirmDelete = name => {
  deleteTemplateName.value = name;
  deleteDialogRef.value?.open();
};

const handleDelete = async () => {
  isDeleting.value = true;
  try {
    const result = await store.dispatch('inboxes/deleteWhatsAppTemplate', {
      inboxId: Number(props.inboxId),
      templateName: deleteTemplateName.value,
    });
    if (result?.success) {
      useAlert(t('WHATSAPP_TEMPLATES.MANAGER.DELETE_SUCCESS'));
      await store.dispatch('inboxes/get');
    } else {
      useAlert(result?.error || t('WHATSAPP_TEMPLATES.MANAGER.DELETE_ERROR'));
    }
  } catch {
    useAlert(t('WHATSAPP_TEMPLATES.MANAGER.DELETE_ERROR'));
  } finally {
    isDeleting.value = false;
    deleteDialogRef.value?.close();
  }
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ t('WHATSAPP_TEMPLATES.MANAGER.TITLE') }}
      </h2>
      <div class="flex gap-2">
        <Button
          variant="faded"
          color="slate"
          :label="t('WHATSAPP_TEMPLATES.MANAGER.SYNC')"
          :is-loading="isSyncing"
          :disabled="isSyncing"
          @click="handleSync"
        />
        <Button
          :label="t('WHATSAPP_TEMPLATES.MANAGER.CREATE_NEW')"
          @click="openCreateDialog"
        />
      </div>
    </div>

    <!-- Templates Table -->
    <div
      v-if="templates.length > 0"
      class="overflow-hidden rounded-xl border border-n-weak"
    >
      <table class="w-full text-sm text-left">
        <thead class="bg-n-alpha-black2">
          <tr>
            <th class="px-4 py-3 font-medium text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.MANAGER.TABLE.NAME') }}
            </th>
            <th class="px-4 py-3 font-medium text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.MANAGER.TABLE.CATEGORY') }}
            </th>
            <th class="px-4 py-3 font-medium text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.MANAGER.TABLE.LANGUAGE') }}
            </th>
            <th class="px-4 py-3 font-medium text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.MANAGER.TABLE.STATUS') }}
            </th>
            <th class="px-4 py-3 font-medium text-n-slate-11">
              {{ t('WHATSAPP_TEMPLATES.MANAGER.TABLE.ACTIONS') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak">
          <tr
            v-for="tmpl in templates"
            :key="tmpl.id || tmpl.name"
            class="hover:bg-n-alpha-black2 transition-colors"
          >
            <td class="px-4 py-3 font-medium text-n-slate-12">
              {{ tmpl.name }}
            </td>
            <td class="px-4 py-3 text-n-slate-11">
              {{ tmpl.category }}
            </td>
            <td class="px-4 py-3 text-n-slate-11">
              {{ tmpl.language }}
            </td>
            <td class="px-4 py-3">
              <span
                class="px-2 py-0.5 rounded-full text-xs font-medium"
                :class="statusClass(tmpl.status)"
              >
                {{ tmpl.status }}
              </span>
            </td>
            <td class="px-4 py-3">
              <Button
                variant="faded"
                color="ruby"
                size="sm"
                :label="t('WHATSAPP_TEMPLATES.MANAGER.DELETE_BUTTON')"
                @click="confirmDelete(tmpl.name)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="flex flex-col items-center justify-center gap-3 p-12 rounded-xl border border-n-weak bg-n-alpha-black2"
    >
      <p class="mb-0 text-sm text-n-slate-11">
        {{ t('WHATSAPP_TEMPLATES.MANAGER.EMPTY_STATE') }}
      </p>
      <Button
        :label="t('WHATSAPP_TEMPLATES.MANAGER.CREATE_NEW')"
        @click="openCreateDialog"
      />
    </div>

    <!-- Create Template Dialog -->
    <Dialog
      ref="createDialogRef"
      :title="t('WHATSAPP_TEMPLATES.CREATOR.TITLE')"
      :description="t('WHATSAPP_TEMPLATES.CREATOR.DESCRIPTION')"
      :show-confirm-button="false"
      :show-cancel-button="false"
      overflow-y-auto
      width="3xl"
    >
      <WhatsAppTemplateCreator
        ref="creatorRef"
        @submit="handleCreateTemplate"
        @cancel="createDialogRef?.close()"
      />
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="
        t('WHATSAPP_TEMPLATES.MANAGER.DELETE_CONFIRM', {
          name: deleteTemplateName,
        })
      "
      :confirm-button-label="t('WHATSAPP_TEMPLATES.MANAGER.DELETE_BUTTON')"
      :is-loading="isDeleting"
      @confirm="handleDelete"
    />
  </div>
</template>
