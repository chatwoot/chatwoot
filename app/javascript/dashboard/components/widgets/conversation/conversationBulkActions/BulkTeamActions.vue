<script setup>
import { useTemplateRef, computed, ref, onMounted } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  conversationCount: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();
const store = useStore();
const containerRef = useTemplateRef('containerRef');
const [showDropdown, toggleDropdown] = useToggle(false);
const selectedTeam = ref(null);

const teams = useMapGetter('teams/getTeams');

const teamMenuItems = computed(() => {
  const items = [
    {
      action: 'select',
      value: 'none',
      label: t('BULK_ACTION.TEAMS.NONE'),
    },
  ];

  teams.value.forEach(team => {
    items.push({
      action: 'select',
      value: team.id,
      label: team.name,
      isSelected: selectedTeam.value?.id === team.id,
    });
  });

  return items;
});

const handleSelectTeam = item => {
  if (item.value === 'none') {
    selectedTeam.value = { id: 0, name: 'None' };
  } else {
    const foundTeam = teams.value.find(team => team.id === item.value);
    selectedTeam.value = foundTeam || { id: 0, name: 'None' };
  }
};

const handleAssign = () => {
  emit('select', selectedTeam.value);
  selectedTeam.value = null;
  toggleDropdown(false);
};

const handleCancel = () => {
  selectedTeam.value = null;
};

onMounted(() => {
  store.dispatch('teams/fetch');
});
</script>

<template>
  <div ref="containerRef" class="relative">
    <Button
      v-tooltip="$t('BULK_ACTION.ASSIGN_TEAM_TOOLTIP')"
      icon="i-lucide-users-round"
      slate
      xs
      ghost
      :class="{ 'bg-n-alpha-2': showDropdown }"
      @click="toggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      v-on-click-outside="[
        () => toggleDropdown(false),
        { ignore: [containerRef] },
      ]"
      :menu-items="teamMenuItems"
      show-search
      :search-placeholder="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
      class="ltr:-right-2 rtl:-left-2 top-8 w-60 max-h-80 overflow-y-auto"
      @action="handleSelectTeam"
    >
      <template #footer>
        <div
          v-if="selectedTeam"
          class="pt-2 pb-2 border-t border-n-weak sticky bottom-0 rounded-b-md z-20 bg-n-alpha-3 backdrop-blur-[4px] after:absolute after:-bottom-2 after:left-0 after:w-full after:h-2 after:bg-n-alpha-3 after:backdrop-blur-[4px]"
        >
          <div class="flex flex-col gap-2">
            <I18nT
              v-if="selectedTeam.id"
              keypath="BULK_ACTION.TEAMS.ASSIGN_CONFIRMATION_LABEL"
              tag="p"
              class="text-xs text-n-slate-11 px-1 mb-0"
              :plural="props.conversationCount"
            >
              <template #conversationCount>
                <strong class="text-n-slate-12">
                  {{ props.conversationCount }}
                </strong>
              </template>
              <template #teamName>
                <strong class="text-n-slate-12">
                  {{ selectedTeam.name }}
                </strong>
              </template>
            </I18nT>
            <I18nT
              v-else
              keypath="BULK_ACTION.TEAMS.UNASSIGN_CONFIRMATION_LABEL"
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
  </div>
</template>
