<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';

const { t } = useI18n();
const store = useStore();
const config = useCaptainConfigStore();
const assistants = computed(
  () => store.getters['captainAssistants/getRecords']
);
const selection = ref('automatic');
const savedSelection = ref('automatic');
const saving = ref(false);
const selectedAssistant = computed(() =>
  assistants.value.find(assistant => String(assistant.id) === selection.value)
);

const groups = computed(() => [
  {
    title: t('COPILOT_SETTINGS.GROUPS.CONVERSATIONS'),
    icon: 'i-lucide-messages-square',
    tools: [
      { name: 'get_conversation', scope: 'READ' },
      { name: 'search_conversation', scope: 'SEARCH' },
    ],
  },
  {
    title: t('COPILOT_SETTINGS.GROUPS.CONTACTS'),
    icon: 'i-lucide-users-round',
    tools: [
      { name: 'get_contact', scope: 'READ' },
      { name: 'search_contacts', scope: 'SEARCH' },
    ],
  },
  {
    title: t('COPILOT_SETTINGS.GROUPS.HELP_CENTER'),
    icon: 'i-lucide-book-open',
    tools: [
      { name: 'get_article', scope: 'READ' },
      { name: 'search_articles', scope: 'SEARCH' },
    ],
  },
  {
    title: t('COPILOT_SETTINGS.GROUPS.ASSISTANT'),
    icon: 'i-lucide-sparkles',
    tools: [{ name: 'search_documentation', scope: 'SEARCH' }],
  },
  {
    title: t('COPILOT_SETTINGS.GROUPS.LINEAR'),
    icon: 'i-lucide-plug',
    tools: [{ name: 'search_linear_issues', scope: 'SEARCH' }],
  },
]);
const scopeLabels = {
  READ: t('COPILOT_SETTINGS.SCOPES.READ'),
  SEARCH: t('COPILOT_SETTINGS.SCOPES.SEARCH'),
  WRITE: t('COPILOT_SETTINGS.SCOPES.WRITE'),
};
const toolAvailable = name =>
  config.copilotTools?.find(tool => tool.name === name)?.available || false;
const visibleGroups = computed(() =>
  groups.value
    .map(group => ({
      ...group,
      scopes: group.tools.filter(tool => toolAvailable(tool.name)),
    }))
    .filter(group => group.scopes.length)
);

onMounted(async () => {
  await Promise.all([config.fetch(), store.dispatch('captainAssistants/get')]);
  selection.value = assistants.value.some(
    assistant => assistant.id === Number(config.copilotAssistantId)
  )
    ? String(config.copilotAssistantId)
    : 'automatic';
  savedSelection.value = selection.value;
});

const save = async () => {
  if (selection.value === savedSelection.value) return;

  const nextSelection = selection.value;
  saving.value = true;
  try {
    await config.updatePreferences({
      copilot_assistant_id:
        nextSelection === 'automatic' ? null : Number(nextSelection),
    });
    savedSelection.value = nextSelection;
  } catch (error) {
    selection.value = savedSelection.value;
    useAlert(t('COPILOT_SETTINGS.ERROR'));
  } finally {
    saving.value = false;
  }
};
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('COPILOT_SETTINGS.TITLE')"
        :description="t('COPILOT_SETTINGS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="max-w-4xl pb-20 sm:pb-0">
        <SectionLayout
          :title="t('COPILOT_SETTINGS.TOOLS_TITLE')"
          :description="t('COPILOT_SETTINGS.TOOLS_DESCRIPTION')"
        >
          <div
            class="divide-y divide-n-weak rounded-xl border border-n-weak bg-n-surface-2"
          >
            <div
              v-for="group in visibleGroups"
              :key="group.title"
              class="flex items-center gap-3 px-4 py-3"
            >
              <Icon
                :icon="group.icon"
                class="shrink-0 text-base text-n-slate-11"
              />
              <span class="min-w-0 flex-1 text-sm text-n-slate-12">{{
                group.title
              }}</span>
              <div class="flex flex-wrap justify-end gap-1.5">
                <span
                  v-for="tool in group.scopes"
                  :key="tool.name"
                  class="rounded-md bg-n-alpha-2 px-2 py-0.5 text-xs font-medium text-n-slate-11"
                >
                  {{ scopeLabels[tool.scope] }}
                </span>
              </div>
            </div>
          </div>
          <p class="mt-3 text-xs text-n-slate-10">
            {{ t('COPILOT_SETTINGS.TOOLS_NOTE') }}
          </p>
        </SectionLayout>

        <SectionLayout
          :title="t('COPILOT_SETTINGS.KNOWLEDGE_TITLE')"
          :description="t('COPILOT_SETTINGS.KNOWLEDGE_DESCRIPTION')"
          with-border
        >
          <div v-if="assistants.length" class="max-w-md">
            <label
              for="copilot-assistant"
              class="mb-2 block text-sm font-medium text-n-slate-12"
            >
              {{ t('COPILOT_SETTINGS.ASSISTANT_LABEL') }}
            </label>
            <select
              id="copilot-assistant"
              v-model="selection"
              :disabled="saving"
              class="w-full rounded-lg border border-n-weak bg-n-surface-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-11"
              @change="save"
            >
              <option value="automatic">
                {{ t('COPILOT_SETTINGS.AUTOMATIC') }}
              </option>
              <option
                v-for="assistant in assistants"
                :key="assistant.id"
                :value="String(assistant.id)"
              >
                {{ assistant.name }}
              </option>
            </select>
            <p
              v-if="selection === 'automatic'"
              class="mb-0 mt-2 text-xs leading-5 text-n-slate-10"
            >
              {{ t('COPILOT_SETTINGS.AUTOMATIC_HELP') }}
            </p>
            <p v-else class="mb-0 mt-2 text-xs leading-5 text-n-slate-10">
              {{
                t('COPILOT_SETTINGS.SELECTED_ASSISTANT_HELP', {
                  assistant: selectedAssistant?.name,
                })
              }}
            </p>
          </div>
          <p
            v-else-if="!assistants.length"
            class="mb-0 text-sm text-n-slate-10"
          >
            {{ t('COPILOT_SETTINGS.NO_ASSISTANTS') }}
          </p>
          <p
            v-if="assistants.length"
            role="status"
            class="mt-4 text-xs text-n-slate-10"
          >
            {{
              saving
                ? t('COPILOT_SETTINGS.SAVING')
                : t('COPILOT_SETTINGS.AUTOSAVE')
            }}
            {{ t('COPILOT_SETTINGS.APPLIES_TO_NEW') }}
          </p>
        </SectionLayout>
      </div>
    </template>
  </SettingsLayout>
</template>
