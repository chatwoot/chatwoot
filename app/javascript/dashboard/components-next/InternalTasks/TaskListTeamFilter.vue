<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: { type: [Number, String, null], default: null },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const teams = useMapGetter('teams/getTeams');
const [showDropdown, toggleDropdown] = useToggle();

const selectedTeam = computed(() =>
  teams.value.find(team => team.id === Number(props.modelValue))
);

const selectTeam = teamId => {
  emit('update:modelValue', teamId);
  toggleDropdown(false);
};

const clearTeam = () => {
  emit('update:modelValue', null);
};
</script>

<template>
  <div class="flex items-center gap-2 min-w-0">
    <div class="relative flex shrink-0">
      <NextButton
        v-tooltip.right="$t('INTERNAL_TASKS.FILTER.TEAM_TOOLTIP')"
        icon="i-lucide-users"
        slate
        faded
        xs
        :class="{ 'text-n-slate-12': selectedTeam }"
        @click="toggleDropdown()"
      />
      <div
        v-if="showDropdown"
        v-on-click-outside="() => toggleDropdown(false)"
        class="mt-1 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-56 rounded-xl p-2 absolute z-40 top-full max-h-64 overflow-y-auto"
        :class="{
          'ltr:left-0 rtl:right-0': !isOnExpandedLayout,
          'ltr:right-0 rtl:left-0': isOnExpandedLayout,
        }"
      >
        <button
          type="button"
          class="w-full text-left px-2 py-1.5 text-sm rounded-lg hover:bg-n-alpha-1"
          :class="{ 'bg-n-alpha-1 font-medium': !modelValue }"
          @click="selectTeam(null)"
        >
          {{ $t('INTERNAL_TASKS.FORM.ALL_TEAMS') }}
        </button>
        <button
          v-for="team in teams"
          :key="team.id"
          type="button"
          class="w-full text-left px-2 py-1.5 text-sm rounded-lg hover:bg-n-alpha-1 truncate"
          :class="{
            'bg-n-alpha-1 font-medium': team.id === Number(modelValue),
          }"
          @click="selectTeam(team.id)"
        >
          {{ team.name }}
        </button>
      </div>
    </div>

    <span
      v-if="selectedTeam"
      class="inline-flex items-center gap-1 max-w-full px-2 py-0.5 rounded-md bg-n-slate-3 text-xs text-n-slate-12"
    >
      <span class="truncate">{{ selectedTeam.name }}</span>
      <button
        type="button"
        class="shrink-0 i-lucide-x size-3.5 text-n-slate-11 hover:text-n-slate-12"
        :aria-label="t('INTERNAL_TASKS.FILTER.CLEAR_TEAM')"
        @click="clearTeam"
      />
    </span>
  </div>
</template>
