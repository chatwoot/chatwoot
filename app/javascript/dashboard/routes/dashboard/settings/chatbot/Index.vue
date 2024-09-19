<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ChatbotTableRow from './ChatbotTableRow.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeleteConfirmationPopup = ref(false);
const selectedChatbot = ref({});

const records = computed(() => getters['chatbots/getChatbots'].value);
const uiFlags = computed(() => getters['chatbots/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedChatbot.value.name}?`);

onMounted(() => {
  store.dispatch('chatbots/get');
});

const deleteChatbot = async id => {
  try {
    await store.dispatch('chatbots/delete', id);
    useAlert(t('CHATBOTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CHATBOTS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedChatbot.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteChatbot(selectedChatbot.value.id);
};
</script>

<template>
  <SettingsLayout
    :no-records-message="$t('CHATBOTS.LIST.404')"
    :no-records-found="!records.length"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('CHATBOTS.LOADING')"
    feature-name="chatbots"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('CHATBOTS.HEADER')"
        :description="$t('CHATBOTS.DESCRIPTION')"
        :link-text="$t('CHATBOTS.LEARN_MORE')"
        feature-name="chatbots"
      >
        <template #actions>
          <router-link
            v-if="isAdmin"
            :to="{ name: 'chatbots_new' }"
            class="button rounded-md primary"
          >
            <fluent-icon icon="add-circle" />
            <span class="button__content">
              {{ $t('CHATBOTS.NEW_CHATBOT') }}
            </span>
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table class="min-w-full divide-y divide-slate-75 dark:divide-slate-700">
        <thead>
          <th
            v-for="thHeader in $t('CHATBOTS.LIST.TABLE_HEADER')"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-slate-700 dark:text-slate-300"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody
          class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
        >
          <ChatbotTableRow
            v-for="(chatbot, index) in records"
            :key="index"
            :chatbot="chatbot"
            @delete="openDeletePopup(chatbot)"
          />
        </tbody>
      </table>
      <woot-delete-modal
        :show.sync="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('CHATBOTS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('CHATBOTS.DELETE.CONFIRM.YES')"
        :reject-text="$t('CHATBOTS.DELETE.CONFIRM.NO')"
      />
      <!-- <table -->
      <!-- v-else
        class="min-w-full divide-y divide-slate-75 dark:divide-slate-700"
      >
        <tbody class="divide-y divide-slate-50 dark:divide-slate-800">
          <tr v-for="chatbot in records" :key="chatbot.id">
            <td class="py-4 pr-4">
              <span class="block font-medium capitalize">{{ team.name }}</span>
              <p class="mb-0">{{ team.description }}</p>
            </td>
          </tr> -->

      <!-- <div class="w-full lg:w-3/5">
        <div v-if="!records.length" class="p-3">
          <p class="flex h-full items-center flex-col justify-center">
            {{ $t('CHATBOTS.LIST.404') }}
          </p>
        </div>
        <table v-if="records.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t('CHATBOTS.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <ChatbotTableRow
              v-for="(chatbot, index) in records"
              :key="index"
              :chatbot="chatbot"
              @delete="openDeletePopup(chatbot, index)"
            />
          </tbody>
        </table>
      </div>
      <div class="hidden lg:block w-1/3">
        <span v-dompurify-html="$t('CHATBOTS.SIDEBAR_TXT')" />
      </div> -->
      <!-- </div> -->
      <!-- <woot-confirm-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('CHATBOTS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedChatbot.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @onConfirm="confirmDeletion"
      @onClose="closeDelete"
    />
  </div> -->
    </template>
  </SettingsLayout>
</template>
