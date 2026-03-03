<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter, useStoreGetters } from 'dashboard/composables/store';
import { useStore } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();

const uiFlags = useMapGetter('messageTemplates/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);
const isSyncing = computed(() => uiFlags.value.isSyncing);

const templates = computed(
  () => getters['messageTemplates/getMessageTemplates'].value
);

const hasTemplates = computed(
  () => templates.value.length > 0 && !isFetching.value
);

// Inbox filter
const selectedInboxId = ref('');
const inboxes = computed(() => {
  const allInboxes = getters['inboxes/getInboxes'].value || [];
  return allInboxes.filter(
    inbox =>
      inbox.channel_type === 'Channel::Whatsapp' ||
      inbox.channel_type === 'Channel::TwilioSms'
  );
});
const inboxOptions = computed(() => [
  { value: '', label: t('MESSAGE_TEMPLATES.ALL_INBOXES') },
  ...inboxes.value.map(i => ({ value: i.id, label: i.name })),
]);

const filteredTemplates = computed(() => {
  if (!selectedInboxId.value) return templates.value;
  return templates.value.filter(
    tmpl => tmpl.inbox_id === Number(selectedInboxId.value)
  );
});

const deleteDialogRef = ref(null);
const templateToDelete = ref(null);

const confirmDelete = template => {
  templateToDelete.value = template;
  deleteDialogRef.value?.open();
};

const handleDelete = async () => {
  if (!templateToDelete.value) return;
  try {
    await store.dispatch('messageTemplates/delete', templateToDelete.value.id);
  } catch {
    // handled by store
  }
  deleteDialogRef.value?.close();
};

const handleSync = () => {
  if (!selectedInboxId.value) return;
  store.dispatch('messageTemplates/sync', selectedInboxId.value);
};

const statusColor = status => {
  const colors = {
    approved: 'text-n-green-11 bg-n-green-3',
    pending: 'text-n-amber-11 bg-n-amber-3',
    rejected: 'text-n-ruby-11 bg-n-ruby-3',
    draft: 'text-n-slate-11 bg-n-slate-3',
    paused: 'text-n-amber-11 bg-n-amber-3',
    disabled: 'text-n-slate-9 bg-n-slate-3',
  };
  return colors[status] || colors.draft;
};

const categoryLabel = category => {
  const labels = {
    marketing: t('MESSAGE_TEMPLATES.CATEGORIES.MARKETING'),
    utility: t('MESSAGE_TEMPLATES.CATEGORIES.UTILITY'),
    authentication: t('MESSAGE_TEMPLATES.CATEGORIES.AUTHENTICATION'),
  };
  return labels[category] || category;
};

const goToBuilder = () => {
  router.push({ name: 'message_templates_new' });
};

const goToEdit = template => {
  router.push({
    name: 'message_templates_edit',
    params: { templateId: template.id },
  });
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-heading-1 text-n-slate-12">
            {{ t('MESSAGE_TEMPLATES.HEADER_TITLE') }}
          </span>
          <div class="flex items-center gap-2">
            <Button
              v-if="selectedInboxId"
              :label="t('MESSAGE_TEMPLATES.SYNC')"
              icon="i-lucide-refresh-cw"
              size="sm"
              variant="ghost"
              color-scheme="secondary"
              :is-loading="isSyncing"
              @click="handleSync"
            />
            <Button
              :label="t('MESSAGE_TEMPLATES.NEW_TEMPLATE')"
              icon="i-lucide-plus"
              size="sm"
              @click="goToBuilder"
            />
          </div>
        </div>
        <!-- Inbox filter bar -->
        <div class="flex items-center gap-3 pb-4">
          <Select
            v-model="selectedInboxId"
            :options="inboxOptions"
            class="w-64"
          />
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto py-4">
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>

        <!-- Template list table -->
        <div v-else-if="hasTemplates">
          <table class="w-full">
            <thead>
              <tr
                class="text-left text-xs text-n-slate-11 border-b border-n-strong"
              >
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.NAME') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.CATEGORY') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.LANGUAGE') }}
                </th>
                <th class="pb-3 font-medium">
                  {{ t('MESSAGE_TEMPLATES.TABLE.STATUS') }}
                </th>
                <th class="pb-3 font-medium text-right">
                  {{ t('MESSAGE_TEMPLATES.TABLE.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="template in filteredTemplates"
                :key="template.id"
                class="border-b border-n-weak hover:bg-n-alpha-black2 transition-colors"
              >
                <td class="py-3">
                  <span class="text-sm font-medium text-n-slate-12">
                    {{ template.name }}
                  </span>
                </td>
                <td class="py-3">
                  <span class="text-sm text-n-slate-11">
                    {{ categoryLabel(template.category) }}
                  </span>
                </td>
                <td class="py-3">
                  <span
                    class="text-xs px-2 py-0.5 rounded bg-n-alpha-black2 text-n-slate-11"
                  >
                    {{ template.language }}
                  </span>
                </td>
                <td class="py-3">
                  <span
                    class="text-xs font-medium px-2 py-0.5 rounded capitalize"
                    :class="statusColor(template.status)"
                  >
                    {{ template.status }}
                  </span>
                </td>
                <td class="py-3 text-right">
                  <div class="flex items-center justify-end gap-1">
                    <Button
                      icon="i-lucide-pencil"
                      size="xs"
                      variant="ghost"
                      color-scheme="secondary"
                      @click="goToEdit(template)"
                    />
                    <Button
                      icon="i-lucide-trash-2"
                      size="xs"
                      variant="ghost"
                      color-scheme="alert"
                      @click="confirmDelete(template)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Empty state -->
        <div
          v-else
          class="flex flex-col items-center justify-center py-20 text-center"
        >
          <div
            class="flex items-center justify-center w-16 h-16 rounded-full bg-n-alpha-black2 mb-4"
          >
            <span class="i-lucide-file-text text-3xl text-n-slate-9" />
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 mb-2">
            {{ t('MESSAGE_TEMPLATES.EMPTY_STATE.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11 mb-6 max-w-md">
            {{ t('MESSAGE_TEMPLATES.EMPTY_STATE.SUBTITLE') }}
          </p>
          <Button
            :label="t('MESSAGE_TEMPLATES.NEW_TEMPLATE')"
            icon="i-lucide-plus"
            @click="goToBuilder"
          />
        </div>
      </div>
    </main>

    <!-- Delete confirmation dialog -->
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('MESSAGE_TEMPLATES.DELETE.TITLE')"
      :description="t('MESSAGE_TEMPLATES.DELETE.DESCRIPTION')"
      :confirm-button-label="t('MESSAGE_TEMPLATES.DELETE.CONFIRM')"
      :cancel-button-label="t('MESSAGE_TEMPLATES.DELETE.CANCEL')"
      @confirm="handleDelete"
    />
  </section>
</template>
