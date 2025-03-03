<script setup>
import {
  ref,
  computed,
  reactive,
  onMounted,
  onBeforeUnmount,
  watch,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactSelector from './ContactSelector.vue';
import TemplatePreview from './TemplatePreview.vue';
import ContactsAPI from 'dashboard/api/contacts';

defineProps({
  accountId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const store = useStore();
const { t } = useI18n();

// Form State
const currentStep = ref(1);
const formState = reactive({
  title: '',
  selectedInbox: null,
  selectedTemplate: null,
  scheduledAt: null,
  selectedContacts: [],
  isTemplateValid: true,
  previewPosition: { right: 0, top: 0 },
});

// Contact State
const contactState = reactive({
  searchQuery: '',
  contactList: [],
  isLoadingContacts: false,
  currentPage: 1,
  totalPages: 1,
  total_count: 0,
  sortAttribute: 'name',
});

// Computed Properties
const inboxes = computed(() => {
  const allInboxes = store.getters['inboxes/getInboxes'];
  return allInboxes.filter(inbox => inbox.provider === 'whatsapp_cloud');
});

const templateList = computed(() => {
  return formState.selectedInbox
    ? store.getters['inboxes/getWhatsAppTemplates'](formState.selectedInbox)
    : [];
});

const uiFlags = computed(() => store.getters['campaigns/getUIFlags']);

const isStep1Valid = computed(() => {
  return (
    !v$.value.title.$error &&
    !v$.value.selectedInbox.$error &&
    !v$.value.selectedTemplate.$error &&
    !v$.value.scheduledAt.$error &&
    formState.isTemplateValid
  );
});

const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

// Validation Rules
const rules = computed(() => {
  const step1Rules = {
    title: { required },
    selectedInbox: { required },
    selectedTemplate: { required },
    isTemplateValid: { required },
    scheduledAt: { required },
  };
  const step2Rules = {
    selectedContacts: {
      required,
      minLength: value => (value || []).length > 0,
    },
  };
  return currentStep.value === 1 ? step1Rules : step2Rules;
});

const v$ = useVuelidate(rules, formState);

// Methods
const calculatePreviewPosition = () => {
  const campaignForm = document.querySelector('.campaign-details-form');
  if (campaignForm) {
    const rect = campaignForm.getBoundingClientRect();
    formState.previewPosition = {
      right: window.innerWidth - rect.right - 320,
      top: rect.top - 107,
    };
  }
};

const handleTemplateValidation = isValid => {
  formState.isTemplateValid = isValid;
};

const handleInboxSelection = () => {
  if (formState.selectedInbox === 'create_new') {
    const baseUrl = window.location.origin;
    window.location.href = `${baseUrl}/app/accounts/${accountId}/settings/inboxes/new/whatsapp`;
    formState.selectedInbox = null;
  }
};

const fetchContacts = async (page = 1, search = '') => {
  try {
    contactState.isLoadingContacts = true;
    let data;
    if (search) {
      contactState.contactList = [];
      const { data: responseData } = await ContactsAPI.search(
        search,
        page,
        contactState.sortAttribute
      );
      data = responseData;
    } else {
      const { data: responseData } = await ContactsAPI.get(
        page,
        contactState.sortAttribute
      );
      data = responseData;
    }
    handleContactsResponse(data);
  } catch (error) {
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.API.CONTACTS_ERROR'));
    contactState.contactList = [];
  } finally {
    contactState.isLoadingContacts = false;
  }
};

const handleContactsResponse = data => {
  const { payload = [], meta = {} } = data;
  const filteredContacts = payload.filter(contact => contact.phone_number);
  if (contactState.currentPage === 1) {
    contactState.contactList = filteredContacts;
  } else {
    contactState.contactList = [
      ...contactState.contactList,
      ...filteredContacts,
    ];
  }
  contactState.total_count = meta.count || 0;
  contactState.totalPages = Math.ceil(meta.count / 30);
};

const loadMoreContacts = () => {
  if (
    contactState.currentPage < contactState.totalPages &&
    !contactState.isLoadingContacts
  ) {
    contactState.currentPage += 1;
    fetchContacts(contactState.currentPage, contactState.searchQuery);
  }
};

const handleSearch = query => {
  contactState.searchQuery = query;
  contactState.currentPage = 1;
  fetchContacts(1, query);
};

const handleFiltersCleared = () => {
  contactState.currentPage = 1;
  contactState.totalPages = 1;
  fetchContacts(1, contactState.searchQuery);
};

const onFilteredContacts = filteredContacts => {
  contactState.contactList = filteredContacts;
};

const contactSelector = ref(null);

const fetchAllContactIds = async (isFiltered, filteredContacts) => {
  try {
    let contactIds = [];
    if (isFiltered) {
      contactState.total_count = filteredContacts.length;
      contactIds = filteredContacts.map(contact => contact.id);
      formState.selectedContacts = contactIds;
    } else {
      const { data } = await ContactsAPI.getAllIds();
      contactState.total_count = data.total_count;
      contactIds = data.contact_ids;
      formState.selectedContacts = contactIds;
    }
    if (contactSelector.value) {
      contactSelector.value.updateSelectedContacts(contactIds);
    }
    useAlert(t('CAMPAIGN.WHATSAPP.CONTACT_SELECTOR.SELECTED_ALL.SUCCESS'));
  } catch (error) {
    useAlert(t('CAMPAIGN.WHATSAPP.CONTACT_SELECTOR.SELECTED_ALL.ERROR'));
  }
};

const goToNext = async () => {
  v$.value.$touch();
  if (isStep1Valid.value) {
    contactState.contactList = [];
    contactState.currentPage = 1;
    contactState.searchQuery = '';
    await fetchContacts(1);
    currentStep.value = 2;
  }
};

const goBack = () => {
  currentStep.value = 1;
};
const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const handleCancel = () => emit('cancel');

const createCampaign = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const contactIds =
      formState.selectedContacts.length > 0 &&
      typeof formState.selectedContacts[0] === 'object'
        ? formState.selectedContacts.map(contact => contact.id)
        : formState.selectedContacts;

    const campaignDetails = {
      campaign: {
        title: formState.title,
        inbox_id: formState.selectedInbox,
        template_id: formState.selectedTemplate?.id || null,
        scheduled_at: formState.scheduledAt
          ? formatToUTCString(formState.scheduledAt)
          : null,
        contacts: contactIds,
        enabled: true,
        trigger_only_during_business_hours: false,
      },
    };
    await store.dispatch('campaigns/create', campaignDetails);
    useAlert(t('CAMPAIGN.WHATSAPP.CREATE.API.SUCCESS_MESSAGE'));
    emit('cancel');
  } catch (error) {
    let errorMessage = t('CAMPAIGN.WHATSAPP.CREATE.API.ERROR_MESSAGE');
    if (error.response) {
      errorMessage =
        error.response.data?.error ||
        error.response.data?.message ||
        errorMessage;
    }
    useAlert(errorMessage);
  }
};

// Lifecycle Hooks
onMounted(() => {
  calculatePreviewPosition();
  window.addEventListener('resize', calculatePreviewPosition);
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', calculatePreviewPosition);
});
</script>

<template>
  <div class="h-auto">
    <woot-modal-header
      :header-title="$t('CAMPAIGN.WHATSAPP.CREATE.TITLE')"
      :header-content="$t('CAMPAIGN.WHATSAPP.CREATE.DESC')"
    />
    <!-- Step 1: Campaign Details -->
    <div v-if="currentStep === 1" class="campaign-details-form">
      <form class="flex flex-col w-full">
        <div class="w-full space-y-4">
          <Input
            v-model="formState.title"
            :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.LABEL')"
            type="text"
            :class="{ error: v$.title.$error }"
            :error="
              v$.title.$error
                ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.ERROR')
                : ''
            "
            :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.TITLE.PLACEHOLDER')"
            @blur="v$.title.$touch"
          />

          <div class="flex flex-col mb-0">
            <label class="text-sm font-medium text-slate-700">
              {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.LABEL') }}
              <select
                v-model="formState.selectedInbox"
                class="w-full p-2 mt-1 border-0 selectInbox"
                :class="{ 'border-red-500': v$.selectedInbox.$error }"
                @change="handleInboxSelection"
              >
                <option value="create_new" class="create-inbox-option">
                  {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.CREATE_INBOX.LABEL') }}
                </option>
                <option
                  v-for="inbox in inboxes"
                  :key="inbox.id"
                  :value="inbox.id"
                >
                  {{ inbox.name }}
                </option>
              </select>
              <span v-if="v$.selectedInbox.$error" class="text-xs text-red-500">
                {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.INBOX.ERROR') }}
              </span>
            </label>
          </div>

          <div class="flex flex-col mb-0">
            <label class="text-sm font-medium text-slate-700">
              {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SELECT_TEMPLATE.LABEL') }}
              <a
                href="https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/#create-and-manage-templates"
                target="_blank"
                rel="noopener noreferrer"
                class="text-xs text-[#369EFF] hover:text-[#1b67ae]"
              >
                {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.HELP.LABEL') }}
              </a>
              <select
                v-model="formState.selectedTemplate"
                class="w-full p-2 mt-1 selectTemplate border-0"
                :class="{ 'border-red-500': v$.selectedTemplate.$error }"
              >
                <option
                  v-for="template in templateList"
                  :key="template.id"
                  :value="template"
                >
                  {{ template.name }}
                </option>
              </select>
              <span
                v-if="v$.selectedTemplate.$error"
                class="text-xs text-red-500"
              >
                {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SELECT_TEMPLATE.ERROR') }}
              </span>
            </label>
          </div>

          <div class="flex flex-col">
            <label class="text-sm font-medium text-slate-700">
              {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.LABEL') }}
              <Input
                v-model="formState.scheduledAt"
                type="datetime-local"
                :min="currentDateTime"
                class="w-full p-2 mt-1"
                :placeholder="
                  t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')
                "
                :error="
                  v$.scheduledAt.$error
                    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.SCHEDULED_AT.ERROR')
                    : ''
                "
                @blur="v$.scheduledAt.$touch"
              />
            </label>
          </div>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-4">
          <Button
            type="button"
            :disabled="!isStep1Valid"
            variant="primary"
            @click="goToNext"
          >
            {{ t('CAMPAIGN.WHATSAPP.CREATE.NEXT_BUTTON_TEXT') }}
          </Button>
          <Button type="button" variant="clear" @click.prevent="handleCancel">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.CANCEL_BUTTON_TEXT') }}
          </Button>
        </div>
      </form>

      <TemplatePreview
        :selected-template="formState.selectedTemplate"
        :preview-position="formState.previewPosition"
        @template-validation="handleTemplateValidation"
      />
    </div>

    <!-- Step 2: Contact Selection -->
    <div v-else class="contact-selection">
      <ContactSelector
        ref="contactSelector"
        :contacts="contactState.contactList"
        :selected-contacts="formState.selectedContacts"
        :is-loading="contactState.isLoadingContacts"
        :has-more="contactState.currentPage < contactState.totalPages"
        @contacts-selected="contacts => (formState.selectedContacts = contacts)"
        @load-more="loadMoreContacts"
        @select-all-contacts="fetchAllContactIds"
        @filter-contacts="onFilteredContacts"
        @filters-cleared="handleFiltersCleared"
      />

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-4">
        <Button
          :is-loading="uiFlags.isCreating"
          :disabled="formState.selectedContacts.length === 0"
          variant="primary"
          @click="createCampaign"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.CREATE_BUTTON_TEXT') }}
        </Button>
        <Button type="button" variant="secondary" @click.stop="goBack">
          {{ t('CAMPAIGN.WHATSAPP.CREATE.BACK_BUTTON_TEXT') }}
        </Button>
        <Button
          type="button"
          variant="clear"
          class="cancel"
          @click.prevent="handleCancel"
        >
          {{ t('CAMPAIGN.WHATSAPP.CREATE.CANCEL_BUTTON_TEXT') }}
        </Button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.create-inbox-option {
  color: #369eff;
  font-weight: 500;
}

.cancel {
  margin-right: 10px;
}

select option[value='create_new'] {
  color: #369eff;
  font-weight: 500;
}

select {
  @apply w-full p-2 bg-[#F5F5F5] dark:bg-[#1B1C21] mb-0;
}

.campaign-details-form {
  @apply relative;
}

.contact-selection {
  @apply min-h-[400px];
}

@media (max-width: 1024px) {
  .flex-row {
    flex-direction: column;
  }

  .pr-4 {
    padding-right: 0;
    padding-bottom: 1rem;
  }
}

.text-[#369EFF] {
  color: #369eff;
}

.hover\:text-[#1b67ae]:hover {
  color: #1b67ae;
}

.border-red-500 {
  border-color: #ef4444;
}

.text-red-500 {
  color: #ef4444;
}
</style>
