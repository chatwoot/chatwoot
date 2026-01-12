<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import InboxesAPI from 'dashboard/api/inboxes';
import WhatsappTemplatesAPI from 'dashboard/api/whatsappTemplates';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import Modal from 'dashboard/components/Modal.vue';
import TemplateBuilder from 'dashboard/components-next/Templates/TemplateBuilder/TemplateBuilder.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const inboxes = useMapGetter('inboxes/getInboxes');

// Filter only WhatsApp Cloud inboxes
const whatsAppCloudInboxes = computed(() => {
  return inboxes.value.filter(
    inbox =>
      inbox.channel_type === INBOX_TYPES.WHATSAPP &&
      inbox.provider === 'whatsapp_cloud'
  );
});

// Current inbox
const currentInbox = computed(() => {
  const inboxId = parseInt(route.params.inboxId, 10);
  if (Number.isNaN(inboxId)) return null;
  return whatsAppCloudInboxes.value.find(i => i.id === inboxId);
});

// State
const isLoading = ref(true);
const isSyncing = ref(false);
const templates = ref([]);
const showCreateModal = ref(false);
const isCreating = ref(false);
const isDeleting = ref(false);
const templateToDelete = ref(null);

// Computed
const safeTemplates = computed(() => {
  const templateList = Array.isArray(templates.value) ? templates.value : [];
  return templateList.filter(tpl => tpl !== null && tpl !== undefined);
});

const approvedTemplates = computed(() => {
  return safeTemplates.value.filter(tpl => tpl.status === 'APPROVED');
});

const pendingTemplates = computed(() => {
  return safeTemplates.value.filter(tpl => tpl.status === 'PENDING');
});

const rejectedTemplates = computed(() => {
  return safeTemplates.value.filter(tpl => tpl.status === 'REJECTED');
});

// Methods
const loadTemplates = () => {
  if (!currentInbox.value) {
    isLoading.value = false;
    return;
  }
  isLoading.value = true;
  try {
    const inboxData = store.getters['inboxes/getInbox'](currentInbox.value.id);
    templates.value = inboxData?.message_templates || [];
  } finally {
    isLoading.value = false;
  }
};

const syncTemplates = async () => {
  if (!currentInbox.value) return;
  isSyncing.value = true;
  try {
    await InboxesAPI.syncTemplates(currentInbox.value.id);
    await store.dispatch('inboxes/get', { inboxId: currentInbox.value.id });
    const inboxData = store.getters['inboxes/getInbox'](currentInbox.value.id);
    templates.value = inboxData?.message_templates || [];
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_SUCCESS'));
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_ERROR')
    );
  } finally {
    isSyncing.value = false;
  }
};

const openCreateModal = () => {
  showCreateModal.value = true;
};

const closeCreateModal = () => {
  showCreateModal.value = false;
};

const delay = ms =>
  new Promise(resolve => {
    setTimeout(resolve, ms);
  });

const createTemplate = async payload => {
  if (!currentInbox.value) return;
  isCreating.value = true;
  try {
    await WhatsappTemplatesAPI.createTemplate(currentInbox.value.id, payload);
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_SUCCESS'));
    closeCreateModal();
    await delay(4000);
    await syncTemplates();
  } catch (error) {
    let errorMessage;
    if (error.response?.data?.details?.error?.message) {
      errorMessage = error.response.data.details.error.message;
    } else if (error.response?.data?.error) {
      errorMessage = error.response.data.error;
    } else if (error.message) {
      errorMessage = error.message;
    } else {
      errorMessage = t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_ERROR');
    }
    useAlert(errorMessage);
  } finally {
    isCreating.value = false;
  }
};

const confirmDelete = template => {
  templateToDelete.value = template;
};

const cancelDelete = () => {
  templateToDelete.value = null;
};

const deleteTemplate = async () => {
  if (!templateToDelete.value || !currentInbox.value) return;
  isDeleting.value = true;
  try {
    await WhatsappTemplatesAPI.deleteTemplate(
      currentInbox.value.id,
      templateToDelete.value.name
    );
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_SUCCESS'));
    templateToDelete.value = null;
    await syncTemplates();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_ERROR')
    );
  } finally {
    isDeleting.value = false;
  }
};

const getStatusClass = status => {
  switch (status) {
    case 'APPROVED':
      return 'text-n-teal-11';
    case 'PENDING':
      return 'text-n-amber-11';
    case 'REJECTED':
      return 'text-n-ruby-11';
    default:
      return 'text-n-slate-11';
  }
};

const getCategoryClass = category => {
  switch (category) {
    case 'MARKETING':
      return 'text-n-violet-11';
    case 'UTILITY':
      return 'text-n-blue-11';
    case 'AUTHENTICATION':
      return 'text-n-orange-11';
    default:
      return 'text-n-slate-11';
  }
};

const getTemplateBody = template => {
  const bodyComponent = template.components?.find(c => c.type === 'BODY');
  return bodyComponent?.text || '';
};

const selectInbox = inboxId => {
  router.push({
    name: 'templates_whatsapp_index',
    params: {
      accountId: route.params.accountId,
      inboxId,
    },
  });
};

// Watch for inbox changes
watch(
  () => route.params.inboxId,
  () => {
    loadTemplates();
  }
);

// Initial load
onMounted(async () => {
  await store.dispatch('inboxes/get');
  loadTemplates();
});
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <!-- Empty state when no WhatsApp Cloud inboxes -->
    <div
      v-if="whatsAppCloudInboxes.length === 0"
      class="flex flex-col items-center justify-center flex-1 py-16 text-center"
    >
      <div
        class="w-16 h-16 rounded-full bg-n-alpha-2 flex items-center justify-center mb-4"
      >
        <i class="i-lucide-message-square-off text-3xl text-n-slate-11" />
      </div>
      <h3 class="text-lg font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.NO_WHATSAPP_INBOXES.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11 max-w-md">
        {{ t('TEMPLATES.NO_WHATSAPP_INBOXES.DESCRIPTION') }}
      </p>
    </div>

    <!-- Main content -->
    <template v-else>
      <!-- Header -->
      <header class="sticky top-0 z-10 px-6 lg:px-0">
        <div class="w-full max-w-[60rem] mx-auto">
          <div class="flex items-center justify-between w-full h-20 gap-2">
            <span class="text-xl font-medium text-n-slate-12">
              {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.TITLE') }}
            </span>
            <div v-if="currentInbox" class="flex items-center gap-2">
              <NextButton
                variant="ghost"
                color="slate"
                icon="i-lucide-refresh-cw"
                :is-loading="isSyncing"
                size="sm"
                @click="syncTemplates"
              />
              <NextButton
                :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_BUTTON')"
                icon="i-lucide-plus"
                size="sm"
                @click="openCreateModal"
              />
            </div>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="flex-1 px-6 overflow-y-auto lg:px-0">
        <div class="w-full max-w-[60rem] mx-auto py-4">
          <!-- Inbox Selector (horizontal list) -->
          <div
            v-if="whatsAppCloudInboxes.length > 1"
            class="flex gap-2 mb-6 pb-4 border-b border-n-weak overflow-x-auto"
          >
            <button
              v-for="inbox in whatsAppCloudInboxes"
              :key="inbox.id"
              class="px-4 py-2 text-sm rounded-lg transition-colors whitespace-nowrap flex-shrink-0"
              :class="
                currentInbox?.id === inbox.id
                  ? 'bg-woot-500 text-white'
                  : 'bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3'
              "
              @click="selectInbox(inbox.id)"
            >
              {{ inbox.name }}
            </button>
          </div>

          <!-- Current Inbox Name (when single inbox) -->
          <div
            v-else-if="currentInbox"
            class="flex items-center gap-2 mb-6 pb-4 border-b border-n-weak"
          >
            <span class="text-sm font-medium text-n-slate-12">
              {{ currentInbox.name }}
            </span>
          </div>

          <!-- Templates Content -->
          <div v-if="currentInbox">
            <!-- Loading State -->
            <div
              v-if="isLoading"
              class="flex items-center justify-center py-10 text-n-slate-11"
            >
              <Spinner />
            </div>

            <!-- Empty State -->
            <div
              v-else-if="templates.length === 0"
              class="text-center py-14 text-n-slate-11"
            >
              <div
                class="i-lucide-file-text text-4xl mx-auto mb-3 opacity-50"
              />
              <p class="text-base">
                {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.EMPTY') }}
              </p>
            </div>

            <!-- Templates List -->
            <template v-else>
              <!-- Stats -->
              <div class="flex items-center gap-4 mb-6 text-sm text-n-slate-11">
                <span class="flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-green-500" />
                  <span class="font-medium text-n-slate-12">{{
                    approvedTemplates.length
                  }}</span>
                  {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.APPROVED') }}
                </span>
                <span class="flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-yellow-500" />
                  <span class="font-medium text-n-slate-12">{{
                    pendingTemplates.length
                  }}</span>
                  {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.PENDING') }}
                </span>
                <span class="flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-red-500" />
                  <span class="font-medium text-n-slate-12">{{
                    rejectedTemplates.length
                  }}</span>
                  {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.STATS.REJECTED') }}
                </span>
              </div>

              <!-- Template Cards -->
              <div class="flex flex-col gap-4">
                <div
                  v-for="template in safeTemplates"
                  :key="template.id || template.name"
                  class="flex flex-row justify-between items-center w-full gap-3 px-6 py-5 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2"
                >
                  <div
                    class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2"
                  >
                    <div class="flex justify-between gap-3 w-fit">
                      <span
                        class="text-base font-medium text-n-slate-12 line-clamp-1"
                      >
                        {{ template.name }}
                      </span>
                      <span
                        class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
                        :class="getStatusClass(template.status)"
                      >
                        {{
                          t(
                            `INBOX_MGMT.WHATSAPP_TEMPLATES.STATUS.${template.status}`
                          )
                        }}
                      </span>
                      <span
                        class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
                        :class="getCategoryClass(template.category)"
                      >
                        {{
                          t(
                            `INBOX_MGMT.WHATSAPP_TEMPLATES.CATEGORY.${template.category}`
                          )
                        }}
                      </span>
                    </div>
                    <div class="text-sm text-n-slate-11 line-clamp-1 h-6">
                      {{ getTemplateBody(template) }}
                    </div>
                    <div
                      class="flex items-center w-full h-6 gap-2 overflow-hidden text-sm text-n-slate-11"
                    >
                      {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.LANGUAGE') }}:
                      {{ template.language }}
                    </div>
                  </div>
                  <div class="flex items-center justify-end w-20 gap-2">
                    <NextButton
                      variant="faded"
                      color="ruby"
                      size="sm"
                      icon="i-lucide-trash"
                      @click="confirmDelete(template)"
                    />
                  </div>
                </div>
              </div>
            </template>
          </div>

          <!-- No inbox selected -->
          <div
            v-else-if="route.params.inboxId === 'select'"
            class="text-center py-14 text-n-slate-11"
          >
            <div class="i-lucide-inbox text-4xl mx-auto mb-3 opacity-50" />
            <p class="text-base">{{ t('TEMPLATES.SELECT_INBOX') }}</p>
          </div>
        </div>
      </main>

      <!-- Create Template Modal -->
      <Modal
        v-if="currentInbox"
        v-model:show="showCreateModal"
        :on-close="closeCreateModal"
        size="large"
      >
        <TemplateBuilder
          :inbox-id="currentInbox.id"
          :is-creating="isCreating"
          @create="createTemplate"
          @cancel="closeCreateModal"
        />
      </Modal>

      <!-- Delete Confirmation Modal -->
      <Modal
        v-if="templateToDelete"
        :show="!!templateToDelete"
        :on-close="cancelDelete"
        size="small"
      >
        <div class="p-6">
          <h2 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_CONFIRM_TITLE') }}
          </h2>
          <p class="text-sm text-n-slate-11 mb-4">
            {{
              t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_CONFIRM_MESSAGE', {
                name: templateToDelete.name,
              })
            }}
          </p>
          <div class="flex justify-end gap-2">
            <NextButton
              variant="ghost"
              color="slate"
              :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.FORM.CANCEL')"
              @click="cancelDelete"
            />
            <NextButton
              color="ruby"
              :is-loading="isDeleting"
              :label="t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_BUTTON')"
              @click="deleteTemplate"
            />
          </div>
        </div>
      </Modal>
    </template>
  </section>
</template>
