<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const store = useStore();
const { t } = useI18n();

const agentBots = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedBot = ref({});
const loading = ref({});

// Bot Form Fields
const botName = ref('');
const botDescription = ref('');
const botUrl = ref('');
const botAvatar = ref(null);
const botAvatarUrl = ref('');
const botErrors = ref({});

const tableHeaders = computed(() => {
  return [
    t('AGENT_BOTS.LIST.TABLE_HEADER.DETAILS'),
    t('AGENT_BOTS.LIST.TABLE_HEADER.URL'),
  ];
});

const deleteMessage = computed(() => ` ${selectedBot.value.name}?`);

// Form validation
const isFormValid = computed(() => {
  return (
    botName.value &&
    botName.value.trim() &&
    botUrl.value &&
    botUrl.value.trim() &&
    botUrl.value.startsWith('http') &&
    Object.keys(botErrors.value).length === 0
  );
});

// We no longer need this helper function as the API now returns the thumbnail field
// Keeping this comment for reference

const resetForm = () => {
  botName.value = '';
  botDescription.value = '';
  botUrl.value = '';
  botAvatar.value = null;
  botAvatarUrl.value = '';
  botErrors.value = {};
};

// Modal functions
const openAddPopup = () => {
  resetForm();
  showAddPopup.value = true;
};

const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = bot => {
  selectedBot.value = bot;
  botName.value = bot.name || '';
  botDescription.value = bot.description || '';
  botUrl.value = bot.outgoing_url || bot.bot_config?.webhook_url || '';
  // Use the thumbnail field from the API
  botAvatarUrl.value = bot.thumbnail || '';
  botErrors.value = {};
  showEditPopup.value = true;
};

// This is used after successful update
const hideEditPopup = () => {
  showEditPopup.value = false;
  // Reset form state to prevent any lingering data
  botErrors.value = {};
};

// This is used for cancel button - doesn't trigger success message
const cancelEditPopup = () => {
  showEditPopup.value = false;
  botErrors.value = {};
};

const openDeletePopup = bot => {
  selectedBot.value = bot;
  showDeleteConfirmationPopup.value = true;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

// Action handlers
const validateForm = () => {
  const errors = {};

  if (!botName.value || !botName.value.trim()) {
    errors.name = t('AGENT_BOTS.FORM.ERRORS.NAME');
  }

  if (!botUrl.value || !botUrl.value.trim()) {
    errors.url = t('AGENT_BOTS.FORM.ERRORS.URL');
  } else if (!botUrl.value.startsWith('http')) {
    errors.url = t('AGENT_BOTS.FORM.ERRORS.VALID_URL');
  }

  botErrors.value = errors;
  return Object.keys(errors).length === 0;
};

const handleImageUpload = ({ file, url }) => {
  botAvatar.value = file;
  botAvatarUrl.value = url;
};

const handleAvatarDelete = async () => {
  if (selectedBot.value.id) {
    try {
      await store.dispatch(
        'agentBots/deleteAgentBotAvatar',
        selectedBot.value.id
      );
      botAvatar.value = null;
      // Set to empty to reflect the deleted avatar
      botAvatarUrl.value = '';
      useAlert(t('AGENT_BOTS.AVATAR.SUCCESS_DELETE'));
    } catch (error) {
      useAlert(t('AGENT_BOTS.AVATAR.ERROR_DELETE'));
    }
  } else {
    botAvatar.value = null;
    botAvatarUrl.value = '';
  }
};

const handleCreateBot = async () => {
  if (!validateForm()) return;

  try {
    // Create FormData for file upload
    const formData = new FormData();
    formData.append('name', botName.value);
    formData.append('description', botDescription.value);
    formData.append('bot_type', 'webhook');
    formData.append('outgoing_url', botUrl.value);

    // Add avatar file if available
    if (botAvatar.value) {
      formData.append('avatar', botAvatar.value);
    }

    await store.dispatch('agentBots/create', formData);
    // Refresh the bots list to get updated data
    await store.dispatch('agentBots/get');
    hideAddPopup();
    useAlert(t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.ADD.API.ERROR_MESSAGE'));
  }
};

const handleUpdateBot = async () => {
  if (!validateForm()) return;

  loading.value[selectedBot.value.id] = true;
  try {
    // Create FormData for file upload
    const formData = new FormData();
    formData.append('name', botName.value);
    formData.append('description', botDescription.value);
    formData.append('bot_type', 'webhook');
    formData.append('outgoing_url', botUrl.value);

    // Add avatar file if available
    if (botAvatar.value) {
      formData.append('avatar', botAvatar.value);
    }

    await store.dispatch('agentBots/update', {
      id: selectedBot.value.id,
      data: formData,
    });

    // Refresh the bots list to get updated data
    await store.dispatch('agentBots/get');
    hideEditPopup();
    useAlert(t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.EDIT.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedBot.value.id] = false;
  }
};

const deleteAgentBot = async id => {
  try {
    await store.dispatch('agentBots/delete', id);
    useAlert(t('AGENT_BOTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedBot.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedBot.value.id] = true;
  closeDeletePopup();
  deleteAgentBot(selectedBot.value.id);
};

// Validate form when inputs change
watch(
  [botName, botUrl],
  () => {
    validateForm();
  },
  { immediate: false }
);

onMounted(() => {
  store.dispatch('agentBots/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AGENT_BOTS.LIST.LOADING')"
    :no-records-found="!agentBots.length"
    :no-records-message="$t('AGENT_BOTS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('AGENT_BOTS.HEADER')"
        :description="$t('AGENT_BOTS.DESCRIPTION')"
        :link-text="$t('AGENT_BOTS.LEARN_MORE')"
        feature-name="agent_bots"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('AGENT_BOTS.ADD.TITLE')"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-slate-700 dark:text-slate-300"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody
          class="flex-1 divide-y divide-slate-25 dark:divide-slate-800 text-slate-700 dark:text-slate-100"
        >
          <tr v-for="(bot, index) in agentBots" :key="bot.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-row items-center gap-4">
                <Thumbnail
                  :src="bot.thumbnail"
                  :username="bot.name"
                  size="40px"
                />
                <div>
                  <span class="block font-medium break-words">
                    {{ bot.name }}
                    <span
                      v-if="bot.system_bot"
                      class="text-xs text-white bg-woot-500 inline-block rounded px-1 ml-2"
                    >
                      {{ $t('AGENT_BOTS.GLOBAL_BOT_BADGE') }}
                    </span>
                  </span>
                  <span class="text-sm text-slate-600 dark:text-slate-400">
                    {{ bot.description }}
                  </span>
                </div>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4 text-sm">
              {{ bot.outgoing_url || bot.bot_config?.webhook_url }}
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-if="!bot.system_bot"
                  v-tooltip.top="$t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  :is-loading="loading[bot.id]"
                  @click="openEditPopup(bot)"
                />
                <Button
                  v-if="!bot.system_bot"
                  v-tooltip.top="$t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[bot.id]"
                  @click="openDeletePopup(bot, index)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <!-- Add Bot Modal -->
    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <div class="px-8 pt-8 pb-6">
        <h3
          class="text-base font-semibold text-slate-800 dark:text-slate-50 mb-2"
        >
          {{ $t('AGENT_BOTS.ADD.TITLE') }}
        </h3>

        <form @submit.prevent="handleCreateBot">
          <div class="flex flex-col gap-4">
            <div class="mb-2 flex flex-col items-center">
              <Avatar
                :src="botAvatarUrl"
                :name="botName || $t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
                :size="80"
                allow-upload
                @upload="handleImageUpload"
                @delete="handleAvatarDelete"
              />
              <div class="mt-2 flex flex-col items-center">
                <span class="text-sm text-slate-600 dark:text-slate-400">
                  {{ $t('AVATAR.UPLOAD_TITLE') }}
                </span>
                <Button
                  v-if="botAvatarUrl"
                  class="mt-2"
                  size="tiny"
                  variant="clear"
                  scheme="secondary"
                  icon="i-lucide-trash-2"
                  :label="$t('PROFILE_SETTINGS.DELETE_AVATAR')"
                  @click="handleAvatarDelete"
                />
              </div>
            </div>
            <Input
              v-model="botName"
              :error="botErrors.name"
              :label="$t('AGENT_BOTS.FORM.NAME.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
              required
            />
            <TextArea
              v-model="botDescription"
              :label="$t('AGENT_BOTS.FORM.DESCRIPTION.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.DESCRIPTION.PLACEHOLDER')"
            />
            <Input
              v-model="botUrl"
              :error="botErrors.url"
              :label="$t('AGENT_BOTS.FORM.WEBHOOK_URL.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.WEBHOOK_URL.PLACEHOLDER')"
              required
            />
          </div>

          <div class="mt-6 flex justify-end gap-2 px-0 py-2">
            <Button
              icon="i-lucide-x"
              slate
              faded
              :label="$t('AGENT_BOTS.FORM.CANCEL')"
              @click="hideAddPopup"
            />
            <Button
              type="submit"
              icon="i-lucide-plus"
              :label="$t('AGENT_BOTS.FORM.CREATE')"
              :is-loading="uiFlags.isCreating"
              :disabled="!isFormValid"
            />
          </div>
        </form>
      </div>
    </woot-modal>

    <!-- Edit Bot Modal -->
    <woot-modal v-model:show="showEditPopup" :on-close="cancelEditPopup">
      <div class="px-8 pt-8 pb-6">
        <h3
          class="text-base font-semibold text-slate-800 dark:text-slate-50 mb-2"
        >
          {{ $t('AGENT_BOTS.EDIT.TITLE') }}
        </h3>

        <form @submit.prevent="handleUpdateBot">
          <div class="flex flex-col gap-4">
            <div class="mb-2 flex flex-col items-center">
              <Avatar
                :src="botAvatarUrl"
                :name="botName"
                :size="80"
                allow-upload
                @upload="handleImageUpload"
                @delete="handleAvatarDelete"
              />
              <div class="mt-2 flex flex-col items-center">
                <span class="text-sm text-slate-600 dark:text-slate-400">
                  {{ $t('AVATAR.UPLOAD_TITLE') }}
                </span>
                <Button
                  v-if="botAvatarUrl"
                  class="mt-2"
                  size="tiny"
                  variant="clear"
                  scheme="secondary"
                  icon="i-lucide-trash-2"
                  :label="$t('PROFILE_SETTINGS.DELETE_AVATAR')"
                  @click="handleAvatarDelete"
                />
              </div>
            </div>
            <Input
              v-model="botName"
              :error="botErrors.name"
              :label="$t('AGENT_BOTS.FORM.NAME.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
              required
            />
            <TextArea
              v-model="botDescription"
              :label="$t('AGENT_BOTS.FORM.DESCRIPTION.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.DESCRIPTION.PLACEHOLDER')"
            />
            <Input
              v-model="botUrl"
              :error="botErrors.url"
              :label="$t('AGENT_BOTS.FORM.WEBHOOK_URL.LABEL')"
              :placeholder="$t('AGENT_BOTS.FORM.WEBHOOK_URL.PLACEHOLDER')"
              required
            />
          </div>

          <div class="mt-6 flex justify-end gap-2 px-0 py-2">
            <Button
              icon="i-lucide-x"
              slate
              faded
              :label="$t('AGENT_BOTS.FORM.CANCEL')"
              @click="cancelEditPopup"
            />
            <Button
              type="submit"
              icon="i-lucide-check"
              :label="$t('AGENT_BOTS.FORM.UPDATE')"
              :is-loading="uiFlags.isUpdating"
              :disabled="!isFormValid"
            />
          </div>
        </form>
      </div>
    </woot-modal>

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('AGENT_BOTS.DELETE.CONFIRM.TITLE')"
      :message="$t('AGENT_BOTS.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('AGENT_BOTS.DELETE.CONFIRM.YES')"
      :reject-text="$t('AGENT_BOTS.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
