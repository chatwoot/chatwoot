<script setup>
import { ref, onMounted, onUnmounted, defineProps, computed, nextTick, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

import SectionLayout from 'dashboard/routes/dashboard/settings/account/components/SectionLayout.vue';
import WhatsappTemplateForm from './components/WhatsappTemplateForm.vue';
import WhatsappTemplatesList from './components/WhatsappTemplatesList.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  inbox: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

// Ref for the container element
const containerRef = ref(null);

const templates = ref([]);
const isLoading = ref(false);
const showForm = ref(false);
const isCreating = ref(false);
const deletingTemplateName = ref(null);

const hasTemplates = computed(() => templates.value.length > 0);

// Lock all scrollable containers when form is open to prevent double-scroll issue
const lockBodyScroll = (lock) => {
  const body = document.body;
  const html = document.documentElement;
  const settingsContainer = document.querySelector('.settings');
  const appWrapper = document.querySelector('.app-wrapper');

  if (lock) {
    body.style.overflow = 'hidden';
    html.style.overflow = 'hidden';
    if (settingsContainer) {
      settingsContainer.style.overflow = 'hidden';
    }
    if (appWrapper) {
      appWrapper.style.overflow = 'hidden';
    }
  } else {
    body.style.overflow = '';
    html.style.overflow = '';
    if (settingsContainer) {
      settingsContainer.style.overflow = '';
    }
    if (appWrapper) {
      appWrapper.style.overflow = '';
    }
  }
};

// Watch for form open/close to manage body scroll
watch(showForm, (isOpen) => {
  lockBodyScroll(isOpen);
});

// Cleanup on unmount
onUnmounted(() => {
  lockBodyScroll(false);
});

const fetchTemplates = async () => {
  try {
    isLoading.value = true;
    const response = await store.dispatch('inboxes/getMessageTemplates', {
      inboxId: props.inbox.id,
      params: { fetchAll: true },
    });
    templates.value = response.templates || [];
  } catch (error) {
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.FETCH_ERROR'));
    templates.value = [];
  } finally {
    isLoading.value = false;
  }
};

const handleCreateTemplate = async templateData => {
  try {
    isCreating.value = true;
    await store.dispatch('inboxes/createMessageTemplate', {
      inboxId: props.inbox.id,
      template: templateData,
    });
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_SUCCESS'));
    showForm.value = false;
    await fetchTemplates();
  } catch (error) {
    const errorMessage =
      error.response?.data?.error ||
      t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_ERROR');
    useAlert(errorMessage);
  } finally {
    isCreating.value = false;
  }
};

const handleDeleteTemplate = async ({ name, id }) => {
  deletingTemplateName.value = name;
  try {
    await store.dispatch('inboxes/deleteMessageTemplate', {
      inboxId: props.inbox.id,
      templateName: name,
      templateId: id,
    });
    useAlert(t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_SUCCESS'));
    await fetchTemplates();
  } catch (error) {
    const errorCode = error.response?.data?.code;
    let errorMessage;

    if (errorCode === 'INSUFFICIENT_PERMISSIONS') {
      errorMessage = t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_PERMISSION_ERROR');
    } else if (errorCode === 'TEMPLATE_UNDER_REVIEW') {
      errorMessage = t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_UNDER_REVIEW');
    } else {
      errorMessage =
        error.response?.data?.error ||
        t('INBOX_MGMT.WHATSAPP_TEMPLATES.DELETE_ERROR');
    }
    useAlert(errorMessage);
  } finally {
    deletingTemplateName.value = null;
  }
};

const handleRefresh = () => {
  fetchTemplates();
};

const scrollToTop = () => {
  // Find the parent settings container with overflow-auto and scroll to top
  const settingsContainer = document.querySelector('.settings');
  if (settingsContainer) {
    settingsContainer.scrollTo({ top: 0, behavior: 'instant' });
  }
};

const toggleForm = async () => {
  const wasHidden = !showForm.value;
  showForm.value = !showForm.value;

  // When opening the form, scroll to top to prevent scroll position issues
  if (wasHidden) {
    await nextTick();
    scrollToTop();
  }
};

onMounted(() => {
  fetchTemplates();
});
</script>

<template>
  <div ref="containerRef" class="mx-8">
    <SectionLayout
      :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.TITLE')"
      :description="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.DESCRIPTION')"
    >
      <template #headerActions>
        <div class="flex gap-2">
          <NextButton
            faded
            slate
            icon="i-lucide-refresh-cw"
            :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.SYNC_BUTTON')"
            :is-loading="isLoading"
            @click="handleRefresh"
          />
          <NextButton
            :icon="showForm ? 'i-lucide-x' : 'i-lucide-plus'"
            :label="
              showForm
                ? $t('INBOX_MGMT.WHATSAPP_TEMPLATES.CANCEL')
                : $t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_BUTTON')
            "
            @click="toggleForm"
          />
        </div>
      </template>

      <!-- Purpose Note -->
      <div class="flex gap-3 p-3 mb-4 rounded-lg bg-n-blue-2 border border-n-blue-6">
        <Icon icon="i-lucide-info" class="size-5 text-n-blue-11 flex-shrink-0 mt-0.5" />
        <p class="text-sm text-n-blue-11">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.PURPOSE_NOTE') }}
        </p>
      </div>

      <!-- Create Template Form -->
      <div v-if="showForm" class="mb-6">
        <WhatsappTemplateForm
          :is-loading="isCreating"
          @submit="handleCreateTemplate"
          @cancel="toggleForm"
        />
      </div>

      <!-- Templates List -->
      <div v-if="isLoading && !hasTemplates" class="flex justify-center py-8">
        <span class="text-n-slate-11">
          {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.LOADING') }}
        </span>
      </div>

      <WhatsappTemplatesList
        v-else
        :templates="templates"
        :is-loading="isLoading"
        :deleting-template-name="deletingTemplateName"
        @delete="handleDeleteTemplate"
      />

      <p
        v-if="!isLoading && !hasTemplates && !showForm"
        class="py-8 text-center text-n-slate-11"
      >
        {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.EMPTY_STATE') }}
      </p>
    </SectionLayout>
  </div>
</template>

