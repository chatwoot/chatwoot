<script setup>
import { inject, ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { accountScopedRoute } = useAccount();

const wizardData = inject('wizardData');

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
  return wizardData.value.inbox_ids.includes(inboxId);
};

const toggleInbox = inboxId => {
  const index = wizardData.value.inbox_ids.indexOf(inboxId);
  if (index === -1) {
    wizardData.value.inbox_ids.push(inboxId);
  } else {
    wizardData.value.inbox_ids.splice(index, 1);
  }
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
  // Validate name before submission
  if (!wizardData.value.name || !wizardData.value.name.trim()) {
    useAlert(t('ALOO.FORM.NAME.ERROR'));
    return;
  }

  isSubmitting.value = true;
  try {
    // Create the assistant
    const assistantData = {
      name: wizardData.value.name,
      description: wizardData.value.description,
      tone: wizardData.value.tone,
      formality: wizardData.value.formality,
      empathy_level: wizardData.value.empathy_level,
      verbosity: wizardData.value.verbosity,
      emoji_usage: wizardData.value.emoji_usage,
      greeting_style: wizardData.value.greeting_style,
      custom_greeting: wizardData.value.custom_greeting,
      language: wizardData.value.language,
      dialect: wizardData.value.dialect,
      personality_description: wizardData.value.personality_description,
      active: true,
    };

    const assistant = await store.dispatch(
      'alooAssistants/create',
      assistantData
    );

    // Assign inboxes in parallel
    await Promise.all(
      wizardData.value.inbox_ids.map(inboxId =>
        store.dispatch('alooAssistants/assignInbox', {
          assistantId: assistant.id,
          inboxId,
        })
      )
    );

    // Upload documents in parallel
    await Promise.all(
      wizardData.value.documents.map(doc => {
        const formData = new FormData();
        formData.append('file', doc.file);
        formData.append('title', doc.name);
        return store.dispatch('alooDocuments/uploadDocument', {
          assistantId: assistant.id,
          formData,
        });
      })
    );

    useAlert(t('ALOO.MESSAGES.CREATED'));
    router.push(accountScopedRoute('settings_aloo_list'));
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_new_knowledge'));
};

const selectedCount = computed(() => wizardData.value.inbox_ids.length);
</script>

<template>
  <div class="flex flex-col h-full p-8">
    <div class="flex-1 overflow-y-auto">
      <h2 class="text-xl font-semibold text-n-slate-12 mb-2">
        {{ $t('ALOO.WIZARD.STEP_4') }}
      </h2>
      <p class="text-n-slate-11 mb-8">
        {{ $t('ALOO.INBOXES.DESCRIPTION') }}
      </p>

      <div class="max-w-2xl">
        <!-- Search -->
        <div class="mb-4">
          <div class="relative">
            <span
              class="absolute left-3 top-1/2 -translate-y-1/2 i-lucide-search text-n-slate-9"
            />
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="$t('ALOO.INBOXES.SEARCH_PLACEHOLDER')"
              class="w-full pl-10 pr-4 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
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
