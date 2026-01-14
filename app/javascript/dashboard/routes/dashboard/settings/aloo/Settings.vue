<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';

import GeneralPage from './settingsPage/GeneralPage.vue';
import InstructionsPage from './settingsPage/InstructionsPage.vue';
import PersonalityPage from './settingsPage/PersonalityPage.vue';
import FeaturesPage from './settingsPage/FeaturesPage.vue';
import VoicePage from './settingsPage/VoicePage.vue';
import KnowledgePage from './settingsPage/KnowledgePage.vue';
import InboxesPage from './settingsPage/InboxesPage.vue';
import AnalyticsPage from './settingsPage/AnalyticsPage.vue';
import PlaygroundPage from './settingsPage/PlaygroundPage.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();

const isLoading = ref(true);
const isSaving = ref(false);
const selectedTabIndex = ref(0);

const assistant = ref({
  id: null,
  name: '',
  description: '',
  tone: 'friendly',
  formality: 'medium',
  empathy_level: 'medium',
  verbosity: 'balanced',
  emoji_usage: 'minimal',
  greeting_style: 'warm',
  custom_greeting: '',
  language: 'en',
  dialect: '',
  personality_description: '',
  custom_instructions: '',
  active: true,
  features: {
    handoff_enabled: true,
    resolve_enabled: true,
    snooze_enabled: true,
    labels_enabled: true,
  },
  admin_config: {},
  voice_enabled: false,
  voice_config: {},
});

const tabs = computed(() => [
  { key: 'general', name: t('ALOO.TABS.GENERAL') },
  { key: 'instructions', name: t('ALOO.TABS.INSTRUCTIONS') },
  { key: 'personality', name: t('ALOO.TABS.PERSONALITY') },
  { key: 'features', name: t('ALOO.TABS.FEATURES') },
  { key: 'voice', name: t('ALOO.TABS.VOICE') },
  { key: 'knowledge', name: t('ALOO.TABS.KNOWLEDGE_BASE') },
  { key: 'inboxes', name: t('ALOO.TABS.INBOXES') },
  { key: 'playground', name: t('ALOO.TABS.PLAYGROUND') },
  { key: 'analytics', name: t('ALOO.TABS.ANALYTICS') },
]);

const selectedTabKey = computed(() => tabs.value[selectedTabIndex.value]?.key);
const assistantId = computed(() => route.params.assistantId);

onMounted(async () => {
  try {
    await Promise.all([
      store.dispatch('alooAssistants/show', assistantId.value),
      store.dispatch('inboxes/get'),
    ]);

    const storedAssistant = getters['alooAssistants/getRecord'].value(
      assistantId.value
    );
    if (storedAssistant) {
      assistant.value = {
        ...assistant.value,
        ...storedAssistant,
        tone: storedAssistant.personality?.tone || storedAssistant.tone,
        formality:
          storedAssistant.personality?.formality || storedAssistant.formality,
        empathy_level:
          storedAssistant.personality?.empathy_level ||
          storedAssistant.empathy_level,
        verbosity:
          storedAssistant.personality?.verbosity || storedAssistant.verbosity,
        emoji_usage:
          storedAssistant.personality?.emoji_usage ||
          storedAssistant.emoji_usage,
        greeting_style:
          storedAssistant.personality?.greeting_style ||
          storedAssistant.greeting_style,
        custom_greeting:
          storedAssistant.personality?.custom_greeting ||
          storedAssistant.custom_greeting,
        personality_description:
          storedAssistant.personality?.personality_description ||
          storedAssistant.personality_description,
        features: storedAssistant.features || assistant.value.features,
        voice_enabled: storedAssistant.voice?.enabled ?? false,
        voice_config: storedAssistant.voice?.config || {},
      };
    }

    // Set active tab from route param
    const tabParam = route.params.tab;
    if (tabParam) {
      const tabIndex = tabs.value.findIndex(tab => tab.key === tabParam);
      if (tabIndex >= 0) {
        selectedTabIndex.value = tabIndex;
      }
    }
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
});

watch(
  () => route.params.tab,
  newTab => {
    if (newTab) {
      const tabIndex = tabs.value.findIndex(tab => tab.key === newTab);
      if (tabIndex >= 0) {
        selectedTabIndex.value = tabIndex;
      }
    }
  }
);

const onTabChange = index => {
  selectedTabIndex.value = index;
  const tabKey = tabs.value[index]?.key;
  if (tabKey) {
    window.history.replaceState(
      {},
      '',
      router.resolve({
        name: 'settings_aloo_edit',
        params: { assistantId: assistantId.value, tab: tabKey },
      }).href
    );
  }
};

const saveChanges = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('alooAssistants/update', {
      id: assistantId.value,
      name: assistant.value.name,
      description: assistant.value.description,
      active: assistant.value.active,
      tone: assistant.value.tone,
      formality: assistant.value.formality,
      empathy_level: assistant.value.empathy_level,
      verbosity: assistant.value.verbosity,
      emoji_usage: assistant.value.emoji_usage,
      greeting_style: assistant.value.greeting_style,
      custom_greeting: assistant.value.custom_greeting,
      language: assistant.value.language,
      dialect: assistant.value.dialect,
      personality_description: assistant.value.personality_description,
      custom_instructions: assistant.value.custom_instructions,
      admin_config: assistant.value.admin_config,
      voice_enabled: assistant.value.voice_enabled,
      voice_config: assistant.value.voice_config,
    });
    useAlert(t('ALOO.MESSAGES.UPDATED'));
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const updateAssistant = data => {
  // Handle nested admin_config updates by merging
  if (data.admin_config) {
    assistant.value.admin_config = {
      ...assistant.value.admin_config,
      ...data.admin_config,
    };
    // Also update the features display state
    Object.keys(data.admin_config).forEach(key => {
      const featureKey = key.replace('feature_', '') + '_enabled';
      if (assistant.value.features) {
        assistant.value.features[featureKey] = data.admin_config[key];
      }
    });
  } else if (data.voice_config) {
    // Handle nested voice_config updates by merging
    assistant.value.voice_config = {
      ...assistant.value.voice_config,
      ...data.voice_config,
    };
  } else {
    Object.assign(assistant.value, data);
  }
};
</script>

<template>
  <div
    class="overflow-auto flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings"
  >
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('ALOO.ANALYTICS.LOADING')" />
    </div>

    <template v-else>
      <SettingIntroBanner :header-title="assistant.name">
        <woot-tabs
          class="[&_ul]:p-0"
          :index="selectedTabIndex"
          :border="false"
          @change="onTabChange"
        >
          <woot-tabs-item
            v-for="(tab, index) in tabs"
            :key="tab.key"
            :index="index"
            :name="tab.name"
            :show-badge="false"
            is-compact
          />
        </woot-tabs>
      </SettingIntroBanner>

      <section class="mx-auto w-full max-w-6xl">
        <div v-if="selectedTabKey === 'general'" class="mx-8">
          <GeneralPage
            :assistant="assistant"
            :is-saving="isSaving"
            @update="updateAssistant"
            @save="saveChanges"
          />
        </div>

        <div v-if="selectedTabKey === 'instructions'" class="mx-8">
          <InstructionsPage
            :assistant="assistant"
            :is-saving="isSaving"
            @update="updateAssistant"
            @save="saveChanges"
          />
        </div>

        <div v-if="selectedTabKey === 'personality'" class="mx-8">
          <PersonalityPage
            :assistant="assistant"
            :is-saving="isSaving"
            @update="updateAssistant"
            @save="saveChanges"
          />
        </div>

        <div v-if="selectedTabKey === 'features'" class="mx-8">
          <FeaturesPage
            :assistant="assistant"
            :is-saving="isSaving"
            @update="updateAssistant"
            @save="saveChanges"
          />
        </div>

        <div v-if="selectedTabKey === 'voice'" class="mx-8">
          <VoicePage
            :assistant="assistant"
            :is-saving="isSaving"
            @update="updateAssistant"
            @save="saveChanges"
          />
        </div>

        <div v-if="selectedTabKey === 'knowledge'" class="mx-8">
          <KnowledgePage :assistant-id="assistantId" />
        </div>

        <div v-if="selectedTabKey === 'inboxes'" class="mx-8">
          <InboxesPage :assistant-id="assistantId" />
        </div>

        <div v-if="selectedTabKey === 'playground'" class="mx-8">
          <PlaygroundPage :assistant-id="assistantId" />
        </div>

        <div v-if="selectedTabKey === 'analytics'" class="mx-8">
          <AnalyticsPage :assistant-id="assistantId" />
        </div>
      </section>
    </template>
  </div>
</template>
