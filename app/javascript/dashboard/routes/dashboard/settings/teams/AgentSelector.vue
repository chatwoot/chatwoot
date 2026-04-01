<script>
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';

export default {
  components: {
    NextButton,
    Avatar,
  },
  props: {
    agentList: {
      type: Array,
      default: () => [],
    },
    selectedAgents: {
      type: Array,
      default: () => [],
    },
    updateSelectedAgents: {
      type: Function,
      default: () => {},
    },
    isWorking: {
      type: Boolean,
      default: false,
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  computed: {
    selectedAgentCount() {
      return this.selectedAgents.length;
    },
    allAgentsSelected() {
      return (
        this.agentList.length > 0 &&
        this.selectedAgents.length === this.agentList.length
      );
    },
    disableSubmitButton() {
      return this.selectedAgentCount === 0;
    },
  },
  methods: {
    isAgentSelected(agentId) {
      return this.selectedAgents.includes(agentId);
    },
    handleSelectAgent(agentId) {
      const shouldRemove = this.isAgentSelected(agentId);
      let result = [];
      if (shouldRemove) {
        result = this.selectedAgents.filter(item => item !== agentId);
      } else {
        result = [...this.selectedAgents, agentId];
      }
      this.updateSelectedAgents(result);
    },
    selectAllAgents() {
      const result = this.agentList.map(item => item.id);
      this.updateSelectedAgents(result);
    },
    toggleSelectAll() {
      if (this.allAgentsSelected) {
        this.updateSelectedAgents([]);
      } else {
        this.selectAllAgents();
      }
    },
  },
};
</script>

<template>
  <div class="w-full">
    <div
      class="overflow-hidden rounded-xl border border-outline-variant/10 bg-surface-container-lowest/40 shadow-sm"
    >
      <div
        class="grid grid-cols-12 border-b border-surface-container-high/50 bg-surface-container-high/30 px-4 py-3"
      >
        <div class="col-span-1 flex items-center">
          <input
            name="select-all-agents"
            type="checkbox"
            :checked="allAgentsSelected"
            class="size-4 rounded border-outline-variant/40 bg-surface-container-lowest text-secondary focus:ring-secondary"
            :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
            @change="toggleSelectAll"
          />
        </div>
        <div
          class="col-span-5 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
        >
          {{ $t('TEAMS_SETTINGS.AGENTS.AGENT') }}
        </div>
        <div
          class="col-span-6 text-[11px] font-bold uppercase tracking-widest text-tertiary/60 ltr:text-left rtl:text-right"
        >
          {{ $t('TEAMS_SETTINGS.AGENTS.EMAIL') }}
        </div>
      </div>
      <div
        class="max-h-[min(28rem,55vh)] divide-y divide-surface-container-high/30 overflow-y-auto"
      >
        <div
          v-for="agent in agentList"
          :key="agent.id"
          class="grid grid-cols-12 items-center px-4 py-3 transition-colors duration-150"
          :class="{
            'bg-secondary/10 ring-1 ring-inset ring-secondary/20':
              isAgentSelected(agent.id),
            'hover:bg-surface-container-high/35': !isAgentSelected(agent.id),
          }"
        >
          <div class="col-span-1 flex items-center">
            <input
              type="checkbox"
              class="size-4 rounded border-outline-variant/40 bg-surface-container-lowest text-secondary focus:ring-secondary"
              :checked="isAgentSelected(agent.id)"
              @change="() => handleSelectAgent(agent.id)"
            />
          </div>
          <div class="col-span-5 min-w-0">
            <div class="flex min-w-0 items-center gap-3">
              <Avatar
                :src="agent.thumbnail"
                :name="agent.name"
                :status="agent.availability_status"
                :size="28"
                hide-offline-status
              />
              <span
                class="truncate text-sm font-semibold text-on-surface"
                :title="agent.name"
              >
                {{ agent.name }}
              </span>
            </div>
          </div>
          <div
            class="col-span-6 min-w-0 truncate text-xs text-on-primary-container ltr:text-left rtl:text-right"
            :title="agent.email || undefined"
          >
            {{ agent.email || '—' }}
          </div>
        </div>
      </div>
    </div>
    <div
      class="mt-4 flex flex-col gap-4 border-t border-outline-variant/15 pt-4 sm:flex-row sm:items-center sm:justify-between"
    >
      <p class="mb-0 text-sm text-on-primary-container">
        {{
          $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
            selected: selectedAgents.length,
            total: agentList.length,
          })
        }}
      </p>
      <NextButton
        type="submit"
        solid
        teal
        md
        :label="submitButtonText"
        :disabled="disableSubmitButton"
        :is-loading="isWorking"
        class="w-full shrink-0 font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.35)] sm:w-auto sm:min-w-[10rem] rounded-xl"
      />
    </div>
  </div>
</template>
