<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { accountScopedRoute } = useAccount();

const activeTab = ref('general');
const isLoading = ref(true);
const isSaving = ref(false);

const assistant = ref({
  name: '',
  description: '',
  tone: 'friendly',
  formality: 'medium',
  empathy_level: 'medium',
  verbosity: 'balanced',
  emoji_usage: 'minimal',
  greeting_style: 'warm',
  custom_greeting: '',
  personality_description: '',
  custom_instructions: '',
  active: true,
});

const documents = ref([]);
const assignedInboxes = ref([]);
const stats = ref({
  messages: 0,
  conversations: 0,
  handoffs: 0,
});

const tabs = [
  { id: 'general', label: 'ALOO.TABS.GENERAL', icon: 'i-lucide-settings' },
  {
    id: 'instructions',
    label: 'ALOO.TABS.INSTRUCTIONS',
    icon: 'i-lucide-file-text',
  },
  {
    id: 'personality',
    label: 'ALOO.TABS.PERSONALITY',
    icon: 'i-lucide-user',
  },
  {
    id: 'knowledge',
    label: 'ALOO.TABS.KNOWLEDGE_BASE',
    icon: 'i-lucide-book-open',
  },
  { id: 'inboxes', label: 'ALOO.TABS.INBOXES', icon: 'i-lucide-inbox' },
  { id: 'stats', label: 'ALOO.TABS.STATS', icon: 'i-lucide-bar-chart-3' },
];

const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const assistantId = computed(() => route.params.assistantId);

onMounted(async () => {
  try {
    await Promise.all([
      store.dispatch('alooAssistants/show', assistantId.value),
      store.dispatch('inboxes/get'),
      store.dispatch('alooDocuments/getDocuments', {
        assistantId: assistantId.value,
      }),
    ]);

    const storedAssistant = getters['alooAssistants/getRecord'].value(
      assistantId.value
    );
    if (storedAssistant) {
      Object.assign(assistant.value, storedAssistant);
      assignedInboxes.value =
        storedAssistant.assigned_inboxes?.map(ai => ai.id) || [];
    }

    documents.value = getters['alooDocuments/getRecords'].value;
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }

  // Set active tab from route param
  if (route.params.tab && tabs.find(tab => tab.id === route.params.tab)) {
    activeTab.value = route.params.tab;
  }
});

watch(
  () => route.params.tab,
  newTab => {
    if (newTab && tabs.find(tab => tab.id === newTab)) {
      activeTab.value = newTab;
    }
  }
);

const setTab = tabId => {
  activeTab.value = tabId;
  router.replace({
    name: 'settings_aloo_edit',
    params: { assistantId: assistantId.value, tab: tabId },
  });
};

const saveChanges = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('alooAssistants/update', {
      id: assistantId.value,
      ...assistant.value,
    });
    useAlert(t('ALOO.MESSAGES.UPDATED'));
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const toggleInbox = async inboxId => {
  const isAssigned = assignedInboxes.value.includes(inboxId);
  try {
    if (isAssigned) {
      await store.dispatch('alooAssistants/unassignInbox', {
        assistantId: assistantId.value,
        inboxId,
      });
      assignedInboxes.value = assignedInboxes.value.filter(
        id => id !== inboxId
      );
      useAlert(t('ALOO.MESSAGES.INBOX_UNASSIGNED'));
    } else {
      await store.dispatch('alooAssistants/assignInbox', {
        assistantId: assistantId.value,
        inboxId,
      });
      assignedInboxes.value.push(inboxId);
      useAlert(t('ALOO.MESSAGES.INBOX_ASSIGNED'));
    }
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const deleteDocument = async documentId => {
  try {
    await store.dispatch('alooDocuments/deleteDocument', {
      assistantId: assistantId.value,
      documentId,
    });
    documents.value = documents.value.filter(doc => doc.id !== documentId);
    useAlert(t('ALOO.MESSAGES.DOCUMENT_DELETED'));
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_list'));
};

const toneOptions = [
  { value: 'professional', label: t('ALOO.FORM.TONE.OPTIONS.PROFESSIONAL') },
  { value: 'friendly', label: t('ALOO.FORM.TONE.OPTIONS.FRIENDLY') },
  { value: 'casual', label: t('ALOO.FORM.TONE.OPTIONS.CASUAL') },
  { value: 'formal', label: t('ALOO.FORM.TONE.OPTIONS.FORMAL') },
];

const formalityOptions = [
  { value: 'high', label: t('ALOO.FORM.FORMALITY.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.FORMALITY.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.FORMALITY.OPTIONS.LOW') },
];

const empathyOptions = [
  { value: 'high', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.HIGH') },
  { value: 'medium', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.MEDIUM') },
  { value: 'low', label: t('ALOO.FORM.EMPATHY_LEVEL.OPTIONS.LOW') },
];

const verbosityOptions = [
  { value: 'concise', label: t('ALOO.FORM.VERBOSITY.OPTIONS.CONCISE') },
  { value: 'balanced', label: t('ALOO.FORM.VERBOSITY.OPTIONS.BALANCED') },
  { value: 'detailed', label: t('ALOO.FORM.VERBOSITY.OPTIONS.DETAILED') },
];

const emojiOptions = [
  { value: 'none', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.NONE') },
  { value: 'minimal', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MINIMAL') },
  { value: 'moderate', label: t('ALOO.FORM.EMOJI_USAGE.OPTIONS.MODERATE') },
];

const getInboxIcon = inbox => {
  const iconMap = {
    'Channel::WebWidget': 'i-lucide-globe',
    'Channel::FacebookPage': 'i-lucide-facebook',
    'Channel::Whatsapp': 'i-lucide-message-circle',
    'Channel::Email': 'i-lucide-mail',
  };
  return iconMap[inbox.channel_type] || 'i-lucide-inbox';
};

const formatFileSize = bytes => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const getStatusClass = status => {
  const classes = {
    pending: 'bg-n-amber-3 text-n-amber-11',
    processing: 'bg-n-blue-3 text-n-blue-11',
    available: 'bg-n-green-3 text-n-green-11',
    failed: 'bg-n-ruby-3 text-n-ruby-11',
  };
  return classes[status] || classes.pending;
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div v-if="isLoading" class="flex items-center justify-center h-full">
      <woot-loading-state :message="$t('ALOO.TITLE')" />
    </div>

    <template v-else>
      <!-- Header -->
      <div
        class="flex items-center justify-between px-6 py-4 border-b border-n-weak"
      >
        <div class="flex items-center gap-4">
          <button
            class="p-2 rounded-lg hover:bg-n-alpha-2 text-n-slate-11"
            @click="goBack"
          >
            <span class="i-lucide-arrow-left text-xl" />
          </button>
          <div>
            <h1 class="text-lg font-semibold text-n-slate-12">
              {{ assistant.name }}
            </h1>
            <p class="text-sm text-n-slate-10">
              {{ assistant.description || $t('ALOO.TITLE') }}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <span class="text-sm text-n-slate-11">
              {{ $t('ALOO.FORM.ACTIVE.LABEL') }}
            </span>
            <Switch v-model="assistant.active" />
          </div>
          <Button :is-loading="isSaving" @click="saveChanges">
            {{ $t('ALOO.ACTIONS.SAVE') }}
          </Button>
        </div>
      </div>

      <!-- Tabs -->
      <div class="flex border-b border-n-weak px-6">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          class="flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 -mb-[2px] transition-colors"
          :class="[
            activeTab === tab.id
              ? 'border-n-blue-9 text-n-blue-11'
              : 'border-transparent text-n-slate-11 hover:text-n-slate-12',
          ]"
          @click="setTab(tab.id)"
        >
          <span :class="[tab.icon]" />
          {{ $t(tab.label) }}
        </button>
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <!-- General Tab -->
        <div v-if="activeTab === 'general'" class="max-w-lg space-y-6">
          <Input
            v-model="assistant.name"
            :label="$t('ALOO.FORM.NAME.LABEL')"
            :placeholder="$t('ALOO.FORM.NAME.PLACEHOLDER')"
          />
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.DESCRIPTION.LABEL') }}
            </label>
            <textarea
              v-model="assistant.description"
              :placeholder="$t('ALOO.FORM.DESCRIPTION.PLACEHOLDER')"
              rows="4"
              class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
        </div>

        <!-- Instructions Tab -->
        <div v-if="activeTab === 'instructions'" class="max-w-2xl space-y-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.CUSTOM_INSTRUCTIONS.LABEL') }}
            </label>
            <p class="text-sm text-n-slate-10 mb-3">
              {{ $t('ALOO.FORM.CUSTOM_INSTRUCTIONS.DESCRIPTION') }}
            </p>
            <textarea
              v-model="assistant.custom_instructions"
              :placeholder="$t('ALOO.FORM.CUSTOM_INSTRUCTIONS.PLACEHOLDER')"
              rows="12"
              class="w-full px-3 py-2 text-sm border rounded-lg resize-y border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono"
            />
            <p class="text-xs text-n-slate-9 mt-2">
              {{ $t('ALOO.FORM.CUSTOM_INSTRUCTIONS.HINT') }}
            </p>
          </div>
        </div>

        <!-- Personality Tab -->
        <div
          v-if="activeTab === 'personality'"
          class="max-w-3xl grid grid-cols-2 gap-6"
        >
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.TONE.LABEL') }}
            </label>
            <select
              v-model="assistant.tone"
              class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            >
              <option
                v-for="option in toneOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.FORMALITY.LABEL') }}
            </label>
            <select
              v-model="assistant.formality"
              class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            >
              <option
                v-for="option in formalityOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.EMPATHY_LEVEL.LABEL') }}
            </label>
            <select
              v-model="assistant.empathy_level"
              class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            >
              <option
                v-for="option in empathyOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.VERBOSITY.LABEL') }}
            </label>
            <select
              v-model="assistant.verbosity"
              class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            >
              <option
                v-for="option in verbosityOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.EMOJI_USAGE.LABEL') }}
            </label>
            <select
              v-model="assistant.emoji_usage"
              class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            >
              <option
                v-for="option in emojiOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div class="col-span-2">
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('ALOO.FORM.PERSONALITY_DESCRIPTION.LABEL') }}
            </label>
            <textarea
              v-model="assistant.personality_description"
              :placeholder="$t('ALOO.FORM.PERSONALITY_DESCRIPTION.PLACEHOLDER')"
              rows="4"
              class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
        </div>

        <!-- Knowledge Base Tab -->
        <div v-if="activeTab === 'knowledge'" class="max-w-2xl">
          <div v-if="documents.length" class="space-y-3">
            <div
              v-for="doc in documents"
              :key="doc.id"
              class="flex items-center justify-between p-4 bg-n-alpha-1 rounded-lg border border-n-weak"
            >
              <div class="flex items-center gap-3">
                <span class="i-lucide-file-text text-xl text-n-slate-9" />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ doc.title }}
                  </p>
                  <p class="text-xs text-n-slate-10">
                    {{ formatFileSize(doc.file_size || 0) }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <span
                  class="px-2 py-1 text-xs font-medium rounded"
                  :class="getStatusClass(doc.status)"
                >
                  {{
                    $t(
                      `ALOO.DOCUMENTS.STATUS.${(doc.status || 'pending').toUpperCase()}`
                    )
                  }}
                </span>
                <Button
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  @click="deleteDocument(doc.id)"
                />
              </div>
            </div>
          </div>
          <div
            v-else
            class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <span class="i-lucide-files text-3xl text-n-slate-9" />
            <p class="text-sm text-n-slate-11 mt-2">
              {{ $t('ALOO.DOCUMENTS.EMPTY_STATE.DESCRIPTION') }}
            </p>
          </div>
        </div>

        <!-- Inboxes Tab -->
        <div v-if="activeTab === 'inboxes'" class="max-w-2xl">
          <div
            v-if="inboxes.length"
            class="space-y-2 border rounded-lg border-n-weak divide-y divide-n-weak"
          >
            <div
              v-for="inbox in inboxes"
              :key="inbox.id"
              class="flex items-center gap-4 p-4 cursor-pointer hover:bg-n-alpha-1 transition-colors"
              :class="{
                'bg-n-blue-2': assignedInboxes.includes(inbox.id),
              }"
              @click="toggleInbox(inbox.id)"
            >
              <Checkbox :model-value="assignedInboxes.includes(inbox.id)" />
              <div
                class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2"
              >
                <span
                  class="text-xl text-n-slate-11"
                  :class="[getInboxIcon(inbox)]"
                />
              </div>
              <div class="flex-1">
                <p class="text-sm font-medium text-n-slate-12">
                  {{ inbox.name }}
                </p>
                <p class="text-xs text-n-slate-10">
                  {{ inbox.channel_type.replace('Channel::', '') }}
                </p>
              </div>
            </div>
          </div>
          <div
            v-else
            class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <span class="i-lucide-inbox text-3xl text-n-slate-9" />
            <p class="text-sm text-n-slate-11 mt-2">
              {{ $t('ALOO.INBOXES.NO_INBOXES') }}
            </p>
          </div>
        </div>

        <!-- Stats Tab -->
        <div v-if="activeTab === 'stats'" class="max-w-2xl">
          <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ stats.messages }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.STATS.MESSAGES') }}
              </p>
            </div>
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ stats.conversations }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.STATS.CONVERSATIONS') }}
              </p>
            </div>
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ stats.handoffs }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.STATS.HANDOFFS') }}
              </p>
            </div>
          </div>
          <p class="mt-4 text-sm text-n-slate-10 italic">
            {{ $t('ALOO.STATS.EMPTY') }}
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
