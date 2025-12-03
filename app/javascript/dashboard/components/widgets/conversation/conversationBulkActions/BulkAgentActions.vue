<script setup>
import { useTemplateRef, computed, ref } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  selectedInboxes: {
    type: Array,
    default: () => [],
  },
  conversationCount: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();
const store = useStore();

const containerRef = useTemplateRef('containerRef');
const [showDropdown, toggleDropdown] = useToggle(false);
const selectedAgent = ref(null);

const assignableAgentsUiFlags = computed(
  () => store.getters['inboxAssignableAgents/getUIFlags']
);

const isLoading = computed(() => assignableAgentsUiFlags.value.isFetching);

const assignableAgentsList = useMapGetter(
  'inboxAssignableAgents/getAssignableAgents'
);
const assignableAgents = computed(() =>
  assignableAgentsList.value(props.selectedInboxes.join(','))
);

const agentMenuItems = computed(() => {
  const items = [
    {
      action: 'select',
      value: 'none',
      label: 'None',
      thumbnail: {
        name: 'None',
        src: '',
      },
    },
  ];

  assignableAgents.value.forEach(agent => {
    items.push({
      action: 'select',
      value: agent.id,
      label: agent.name,
      thumbnail: {
        name: agent.name,
        src: agent.thumbnail,
      },
      isSelected: selectedAgent.value?.id === agent.id,
    });
  });

  return items;
});

const handleSelectAgent = item => {
  if (item.value === 'none') {
    selectedAgent.value = { id: null, name: 'None' };
  } else {
    const agent = assignableAgents.value.find(a => a.id === item.value);
    selectedAgent.value = agent || { id: null, name: 'None' };
  }
};

const handleAssign = () => {
  emit('select', selectedAgent.value);
  selectedAgent.value = null;
  toggleDropdown(false);
};

const handleCancel = () => {
  selectedAgent.value = null;
};

const handleToggleDropdown = () => {
  const willOpen = !showDropdown.value;
  toggleDropdown();

  // Fetch agents only when opening the dropdown
  if (willOpen && props.selectedInboxes.length > 0) {
    store.dispatch('inboxAssignableAgents/fetch', props.selectedInboxes);
  }
};
</script>

<template>
  <div ref="containerRef" class="relative">
    <Button
      v-tooltip="$t('BULK_ACTION.ASSIGN_AGENT_TOOLTIP')"
      icon="i-lucide-user-round-check"
      slate
      xs
      ghost
      :class="{ 'bg-n-alpha-2': showDropdown }"
      @click="handleToggleDropdown"
    />
    <Transition
      enter-active-class="transition-all duration-150 ease-out origin-top"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-100 ease-in origin-top"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <DropdownMenu
        v-if="showDropdown"
        v-on-click-outside="[
          () => toggleDropdown(false),
          { ignore: [containerRef] },
        ]"
        :menu-items="agentMenuItems"
        :is-loading="isLoading"
        show-search
        :search-placeholder="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
        class="ltr:-right-10 rtl:-left-10 ltr:2xl:right-0 rtl:2xl:left-0 top-8 w-60 max-h-80 overflow-y-auto"
        @action="handleSelectAgent"
      >
        <template #footer>
          <div
            v-if="selectedAgent"
            class="pt-2 pb-2 border-t border-n-weak sticky bottom-0 rounded-b-md z-20 bg-n-alpha-3 backdrop-blur-[4px] after:absolute after:-bottom-2 after:left-0 after:w-full after:h-2 after:bg-n-alpha-3 after:backdrop-blur-[4px]"
          >
            <div class="flex flex-col gap-2">
              <I18nT
                v-if="selectedAgent.id"
                keypath="BULK_ACTION.ASSIGN_CONFIRMATION_LABEL"
                tag="p"
                class="text-xs text-n-slate-11 px-1 mb-0"
                :plural="props.conversationCount"
              >
                <template #conversationCount>
                  <strong class="text-n-slate-12">
                    {{ props.conversationCount }}
                  </strong>
                </template>
                <template #agentName>
                  <strong class="text-n-slate-12">
                    {{ selectedAgent.name }}
                  </strong>
                </template>
              </I18nT>
              <I18nT
                v-else
                keypath="BULK_ACTION.UNASSIGN_CONFIRMATION_LABEL"
                tag="p"
                class="text-xs text-n-slate-11 px-1 mb-0"
                :plural="props.conversationCount"
              >
                <template #n>
                  <strong class="text-n-slate-12">
                    {{ props.conversationCount }}
                  </strong>
                </template>
              </I18nT>
              <div class="flex gap-2">
                <Button
                  sm
                  faded
                  slate
                  class="flex-1"
                  :label="t('BULK_ACTION.CANCEL')"
                  @click="handleCancel"
                />
                <Button
                  sm
                  class="flex-1"
                  :label="t('BULK_ACTION.YES')"
                  @click="handleAssign"
                />
              </div>
            </div>
          </div>
        </template>
      </DropdownMenu>
    </Transition>
  </div>
</template>
