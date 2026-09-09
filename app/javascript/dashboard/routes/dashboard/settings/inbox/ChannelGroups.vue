<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';

const MAX_NAME_LENGTH = 100;

const { t } = useI18n();
const store = useStore();
const groups = useMapGetter('channelGroups/getGroups');
const inboxes = useMapGetter('inboxes/getInboxes');

const isLoading = ref(false);
const isSaving = ref(false);
const hasLoadError = ref(false);
const editorDialog = ref(null);
const deleteDialog = ref(null);
const editingGroupId = ref(null);
const deletingGroup = ref(null);
const name = ref('');
const inboxIds = ref([]);
const searchQuery = ref('');
const errorMessage = ref('');

const groupByInboxId = computed(() =>
  Object.fromEntries(
    groups.value.flatMap(group => group.inbox_ids.map(id => [id, group]))
  )
);

const filteredInboxes = computed(() =>
  [...inboxes.value]
    .sort((a, b) => a.name.localeCompare(b.name))
    .filter(inbox =>
      inbox.name
        .toLocaleLowerCase()
        .includes(searchQuery.value.toLocaleLowerCase())
    )
);

const currentGroupOf = inbox => {
  const group = groupByInboxId.value[inbox.id];
  return group?.id === editingGroupId.value ? null : group;
};

const canSave = computed(() => {
  const trimmedName = name.value.trim();
  return (
    trimmedName.length > 0 &&
    trimmedName.length <= MAX_NAME_LENGTH &&
    !isSaving.value
  );
});

const load = async () => {
  isLoading.value = true;
  hasLoadError.value = false;
  try {
    await Promise.all([
      store.dispatch('channelGroups/get'),
      store.dispatch('inboxes/get'),
    ]);
  } catch {
    hasLoadError.value = true;
  } finally {
    isLoading.value = false;
  }
};

onMounted(load);

const openEditor = (group = null) => {
  editingGroupId.value = group?.id ?? null;
  name.value = group?.name ?? '';
  inboxIds.value = [...(group?.inbox_ids ?? [])];
  searchQuery.value = '';
  errorMessage.value = '';
  editorDialog.value.open();
};

const save = async () => {
  if (!canSave.value) return;

  isSaving.value = true;
  errorMessage.value = '';
  try {
    const payload = { name: name.value.trim(), inbox_ids: inboxIds.value };
    if (editingGroupId.value) {
      await store.dispatch('channelGroups/update', {
        id: editingGroupId.value,
        ...payload,
      });
    } else {
      await store.dispatch('channelGroups/create', payload);
    }
    editorDialog.value.close();
    useAlert(t('CHANNEL_GROUPS.SAVED'));
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || t('CHANNEL_GROUPS.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const confirmDelete = group => {
  deletingGroup.value = group;
  deleteDialog.value.open();
};

const remove = async () => {
  if (isSaving.value) return;

  isSaving.value = true;
  try {
    await store.dispatch('channelGroups/delete', deletingGroup.value.id);
    deleteDialog.value.close();
    useAlert(t('CHANNEL_GROUPS.DELETED'));
  } catch {
    useAlert(t('CHANNEL_GROUPS.DELETE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :no-records-found="!groups.length && !hasLoadError"
    :no-records-message="t('CHANNEL_GROUPS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('CHANNEL_GROUPS.TITLE')"
        :description="t('CHANNEL_GROUPS.DESCRIPTION')"
      >
        <template #actions>
          <RouterLink :to="{ name: 'settings_inbox_list' }">
            <Button slate size="sm" :label="t('CHANNEL_GROUPS.BACK')" />
          </RouterLink>
          <Button
            size="sm"
            :label="t('CHANNEL_GROUPS.CREATE')"
            :disabled="isLoading || hasLoadError"
            @click="openEditor()"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        v-if="hasLoadError"
        role="alert"
        class="flex items-center gap-3 text-n-ruby-11"
      >
        {{ t('CHANNEL_GROUPS.LOAD_ERROR') }}
        <Button
          slate
          size="sm"
          :label="t('CHANNEL_GROUPS.RETRY')"
          @click="load"
        />
      </div>
      <div
        v-for="group in groups"
        :key="group.id"
        class="flex items-center justify-between gap-4 py-4 border-b border-n-weak"
      >
        <div class="min-w-0">
          <h3 class="truncate text-heading-3 text-n-slate-12">
            {{ group.name }}
          </h3>
          <p class="text-body-main text-n-slate-11">
            {{
              t('CHANNEL_GROUPS.CHANNEL_COUNT', {
                count: group.inbox_ids.length,
              })
            }}
          </p>
        </div>
        <div class="flex gap-2">
          <Button
            slate
            size="sm"
            :label="t('CHANNEL_GROUPS.EDIT')"
            @click="openEditor(group)"
          />
          <Button
            slate
            size="sm"
            icon="i-lucide-trash-2"
            :aria-label="t('CHANNEL_GROUPS.DELETE_NAMED', { name: group.name })"
            @click="confirmDelete(group)"
          />
        </div>
      </div>
    </template>
    <Dialog
      ref="editorDialog"
      :title="
        editingGroupId ? t('CHANNEL_GROUPS.EDIT') : t('CHANNEL_GROUPS.CREATE')
      "
      :confirm-button-label="t('CHANNEL_GROUPS.SAVE')"
      :disable-confirm-button="!canSave"
      :is-loading="isSaving"
      @confirm="save"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-model="name"
          autofocus
          :label="t('CHANNEL_GROUPS.NAME')"
          :placeholder="t('CHANNEL_GROUPS.NAME_PLACEHOLDER')"
          :message="t('CHANNEL_GROUPS.NAME_HINT', { count: MAX_NAME_LENGTH })"
          :disabled="isSaving"
        />
        <p class="text-sm text-n-slate-11">
          {{ t('CHANNEL_GROUPS.MEMBERS_HINT') }}
        </p>
        <Input v-model="searchQuery" :label="t('CHANNEL_GROUPS.SEARCH')" />
        <div class="flex flex-col gap-1 overflow-y-auto max-h-64">
          <label
            v-for="inbox in filteredInboxes"
            :key="inbox.id"
            class="flex items-center gap-2 px-2 py-2 text-sm rounded-lg text-n-slate-12 hover:bg-n-alpha-2"
          >
            <input
              v-model="inboxIds"
              type="checkbox"
              :value="inbox.id"
              :disabled="isSaving"
              class="border rounded border-n-weak"
            />
            <ChannelIcon :inbox="inbox" class="flex-shrink-0 size-4" />
            <span class="truncate">{{ inbox.name }}</span>
            <span
              v-if="currentGroupOf(inbox)"
              class="text-xs ms-auto text-n-slate-10"
            >
              {{ currentGroupOf(inbox).name }}
            </span>
          </label>
          <p v-if="!filteredInboxes.length" class="text-sm text-n-slate-11">
            {{ t('CHANNEL_GROUPS.NO_CHANNELS') }}
          </p>
        </div>
        <p v-if="errorMessage" role="alert" class="text-sm text-n-ruby-11">
          {{ errorMessage }}
        </p>
      </div>
    </Dialog>
    <Dialog
      ref="deleteDialog"
      type="alert"
      :title="t('CHANNEL_GROUPS.DELETE_NAMED', { name: deletingGroup?.name })"
      :description="t('CHANNEL_GROUPS.DELETE_DESCRIPTION')"
      :confirm-button-label="t('CHANNEL_GROUPS.DELETE')"
      :is-loading="isSaving"
      @confirm="remove"
    />
  </SettingsLayout>
</template>
