<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  COPILOT_BUILT_IN_TOOL_GROUPS,
  findSearchedAssistant,
} from '../constants';

import SectionLayout from '../../account/components/SectionLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  settings: { type: Object, required: true },
});

const emit = defineEmits(['manageKnowledge']);

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();
const assistants = useMapGetter('captainAssistants/getRecords');
const linearIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'linear'
);

const knowledgeDescription = computed(() => {
  if (!assistants.value.length) {
    return t('COPILOT_SETTINGS.TOOLS.GROUPS.FAQS.NO_ASSISTANTS');
  }
  const assistant = findSearchedAssistant(props.settings, assistants.value);
  if (!assistant) return t('COPILOT_SETTINGS.TOOLS.GROUPS.FAQS.NONE');
  return t('COPILOT_SETTINGS.TOOLS.GROUPS.FAQS.DESCRIPTION', {
    name: assistant.name,
  });
});

// Copilot offers Linear search only when the account has connected Linear. The row is hidden when Linear is not
// available on this installation at all.
const builtInTools = computed(() =>
  COPILOT_BUILT_IN_TOOL_GROUPS.filter(
    group => !group.integrationId || linearIntegration.value.id
  ).map(group => {
    const prefix = `COPILOT_SETTINGS.TOOLS.GROUPS.${group.key}`;
    const isConnected = !group.integrationId || linearIntegration.value.enabled;
    let description = t(`${prefix}.DESCRIPTION`);
    if (group.key === 'FAQS') description = knowledgeDescription.value;
    if (!isConnected) description = t(`${prefix}.NOT_CONNECTED_DESCRIPTION`);
    return {
      ...group,
      title: t(`${prefix}.TITLE`),
      description,
      isConnected,
    };
  })
);

// Custom tools and MCP servers belong to an assistant today, so Copilot cannot use any of these yet
const addOptions = computed(() =>
  [
    { key: 'CATALOG', icon: 'i-lucide-store' },
    { key: 'MCP', icon: 'i-lucide-server' },
    { key: 'CUSTOM', icon: 'i-lucide-wrench' },
  ].map(option => ({
    ...option,
    title: t(`COPILOT_SETTINGS.TOOLS.ADD_MORE.${option.key}.TITLE`),
    description: t(`COPILOT_SETTINGS.TOOLS.ADD_MORE.${option.key}.DESCRIPTION`),
  }))
);

onMounted(() => {
  store.dispatch('integrations/get');
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <div class="flex flex-col">
    <SectionLayout
      :title="t('COPILOT_SETTINGS.TOOLS.BUILT_IN.TITLE')"
      :description="t('COPILOT_SETTINGS.TOOLS.BUILT_IN.DESCRIPTION')"
    >
      <ul
        class="flex flex-col divide-y divide-n-weak rounded-xl outline outline-1 outline-n-container bg-n-solid-2"
      >
        <li
          v-for="tool in builtInTools"
          :key="tool.key"
          class="flex flex-wrap items-center gap-3 px-5 py-4"
        >
          <div
            class="flex items-center justify-center rounded-lg size-10 shrink-0 bg-n-alpha-2 text-n-slate-12"
          >
            <Icon v-if="tool.icon" :icon="tool.icon" class="size-5" />
            <template v-else>
              <img
                :src="`/dashboard/images/integrations/${tool.integrationId}.png`"
                class="size-5 dark:hidden"
              />
              <img
                :src="`/dashboard/images/integrations/${tool.integrationId}-dark.png`"
                class="size-5 hidden dark:block"
              />
            </template>
          </div>
          <div class="flex flex-col flex-1 min-w-0 gap-0.5">
            <h3 class="text-heading-3 text-n-slate-12">{{ tool.title }}</h3>
            <span class="text-body-main text-n-slate-11">
              {{ tool.description }}
            </span>
          </div>
          <Button
            v-if="tool.key === 'FAQS'"
            :label="t('COPILOT_SETTINGS.TOOLS.GROUPS.FAQS.MANAGE')"
            sm
            faded
            slate
            @click="emit('manageKnowledge')"
          />
          <router-link
            v-else-if="!tool.isConnected"
            :to="accountScopedRoute('settings_integrations_linear')"
            class="shrink-0"
          >
            <Button
              :label="t('COPILOT_SETTINGS.TOOLS.CONNECT_LINEAR')"
              sm
              faded
              slate
              trailing-icon
              icon="i-lucide-arrow-right"
            />
          </router-link>
          <Label
            v-else-if="tool.integrationId"
            :label="t('COPILOT_SETTINGS.TOOLS.STATUS.CONNECTED')"
            color="teal"
            compact
          />
        </li>
      </ul>
    </SectionLayout>

    <SectionLayout
      :title="t('COPILOT_SETTINGS.TOOLS.CONNECTED.TITLE')"
      :description="t('COPILOT_SETTINGS.TOOLS.CONNECTED.DESCRIPTION')"
      with-border
    >
      <p
        class="p-6 text-center rounded-xl outline outline-1 -outline-offset-1 outline-dashed outline-n-weak text-body-main text-n-slate-11"
      >
        {{ t('COPILOT_SETTINGS.TOOLS.CONNECTED.EMPTY') }}
      </p>
    </SectionLayout>

    <SectionLayout
      :title="t('COPILOT_SETTINGS.TOOLS.ADD_MORE.TITLE')"
      :description="t('COPILOT_SETTINGS.TOOLS.ADD_MORE.DESCRIPTION')"
      with-border
    >
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div
          v-for="option in addOptions"
          :key="option.key"
          class="flex flex-col items-start gap-3 p-4 rounded-xl outline outline-1 outline-n-weak bg-n-solid-1"
        >
          <div class="flex items-center justify-between w-full gap-2">
            <div
              class="flex items-center justify-center rounded-lg size-10 shrink-0 bg-n-alpha-2 text-n-slate-12"
            >
              <Icon :icon="option.icon" class="size-5" />
            </div>
            <Label
              :label="t('COPILOT_SETTINGS.TOOLS.ADD_MORE.COMING_SOON')"
              compact
            />
          </div>
          <div class="flex flex-col gap-0.5">
            <h3 class="text-heading-3 text-n-slate-12">{{ option.title }}</h3>
            <span class="text-body-main text-n-slate-11">
              {{ option.description }}
            </span>
          </div>
        </div>
      </div>
    </SectionLayout>
  </div>
</template>
