<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { accountScopedRoute } = useAccount();

const wizardData = computed(() => getters['alooWizard/getWizardData'].value);
const inboxIds = computed(() => getters['alooWizard/getInboxIds'].value);
const documents = computed(() => getters['alooWizard/getDocuments'].value);

const isSubmitting = ref(false);
const searchQuery = ref('');

const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const filteredInboxes = computed(() => {
  if (!searchQuery.value) return inboxes.value;
  const query = searchQuery.value.toLowerCase();
  return inboxes.value.filter(inbox =>
    inbox.name.toLowerCase().includes(query)
  );
});

onMounted(() => {
  store.dispatch('inboxes/get');
});

const isSelected = inboxId => {
  return inboxIds.value.includes(inboxId);
};

const toggleInbox = inboxId => {
  store.dispatch('alooWizard/toggleInbox', inboxId);
};

const getInboxIcon = inbox => {
  const iconMap = {
    'Channel::WebWidget': 'i-lucide-globe',
    'Channel::FacebookPage': 'i-lucide-facebook',
    'Channel::TwitterProfile': 'i-lucide-twitter',
    'Channel::TwilioSms': 'i-lucide-message-square',
    'Channel::Whatsapp': 'i-lucide-message-circle',
    'Channel::Api': 'i-lucide-code',
    'Channel::Email': 'i-lucide-mail',
    'Channel::Telegram': 'i-lucide-send',
    'Channel::Line': 'i-lucide-message-circle',
    'Channel::Sms': 'i-lucide-smartphone',
  };
  return iconMap[inbox.channel_type] || 'i-lucide-inbox';
};

const createAssistant = async () => {
  const data = wizardData.value;

  if (!data.name || !data.name.trim()) {
    useAlert(t('ALOO.FORM.NAME.ERROR'));
    return;
  }

  isSubmitting.value = true;
  try {
    // Create the assistant
    const assistantData = {
      name: data.name,
      description: data.description,
      tone: data.tone,
      formality: data.formality,
      empathy_level: data.empathy_level,
      verbosity: data.verbosity,
      emoji_usage: data.emoji_usage,
      greeting_style: data.greeting_style,
      custom_greeting: data.custom_greeting,
      language: data.language,
      dialect: data.dialect,
      personality_description: data.personality_description,
      active: true,
    };

    const assistant = await store.dispatch(
      'alooAssistants/create',
      assistantData
    );

    // Assign inboxes in parallel
    await Promise.all(
      inboxIds.value.map(inboxId =>
        store.dispatch('alooAssistants/assignInbox', {
          assistantId: assistant.id,
          inboxId,
        })
      )
    );

    // Upload documents in parallel
    await Promise.all(
      documents.value.map(doc => {
        const formData = new FormData();
        formData.append('file', doc.file);
        formData.append('title', doc.name);
        return store.dispatch('alooDocuments/uploadDocument', {
          assistantId: assistant.id,
          formData,
        });
      })
    );

    // Reset wizard data after successful creation
    store.dispatch('alooWizard/reset');

    useAlert(t('ALOO.MESSAGES.CREATED'));
    router.push(accountScopedRoute('settings_aloo_list'));
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message || t('ALOO.MESSAGES.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_new_knowledge'));
};

const selectedCount = computed(() => inboxIds.value.length);
</script>

<template>
  <div class="flex flex-col h-full p-8">
    <div class="flex-1">
      <h2 class="text-xl font-semibold text-n-slate-12 mb-2">
        {{ $t('ALOO.WIZARD.STEP_4') }}
      </h2>
      <p class="text-n-slate-11 mb-8">
        {{ $t('ALOO.INBOXES.DESCRIPTION') }}
      </p>

      <div class="max-w-2xl">
        <!-- Search -->
        <div class="mb-4">
          <Input
            v-model="searchQuery"
            :placeholder="$t('ALOO.INBOXES.SEARCH_PLACEHOLDER')"
            icon="i-lucide-search"
          />
        </div>

        <!-- Selected Count -->
        <p v-if="selectedCount > 0" class="text-sm text-n-slate-11 mb-4">
          {{
            $t('ALOO.INBOXES.SELECTED', { count: selectedCount }, selectedCount)
          }}
        </p>

        <!-- Inbox List -->
        <div
          v-if="filteredInboxes.length"
          class="space-y-2 border rounded-lg border-n-weak divide-y divide-n-weak"
        >
          <div
            v-for="inbox in filteredInboxes"
            :key="inbox.id"
            class="flex items-center gap-4 p-4 cursor-pointer hover:bg-n-alpha-1 transition-colors"
            :class="{ 'bg-n-blue-2': isSelected(inbox.id) }"
            @click="toggleInbox(inbox.id)"
          >
            <Checkbox :model-value="isSelected(inbox.id)" />
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

        <!-- Empty State -->
        <div
          v-else
          class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-inbox text-3xl text-n-slate-9 mb-2" />
          <p class="text-sm text-n-slate-11">
            {{ $t('ALOO.INBOXES.NO_INBOXES') }}
          </p>
        </div>
      </div>
    </div>

    <div class="flex justify-between pt-6 border-t border-n-weak">
      <Button variant="faded" slate @click="goBack">
        {{ $t('ALOO.ACTIONS.BACK') }}
      </Button>
      <Button :is-loading="isSubmitting" @click="createAssistant">
        {{ $t('ALOO.ACTIONS.FINISH') }}
      </Button>
    </div>
  </div>
</template>
