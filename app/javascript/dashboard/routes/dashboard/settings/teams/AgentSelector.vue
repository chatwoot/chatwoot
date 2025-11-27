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
  data() {
    return {};
  },
  computed: {
    selectedAgentCount() {
      return this.selectedAgents.length;
    },
    allAgentsSelected() {
      return this.selectedAgents.length === this.agentList.length;
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
    agentRowClass(agentId) {
      return { 'is-active': this.isAgentSelected(agentId) };
    },
  },
};
</script>

<template>
  <div>
    <div class="add-agents__header" />
    <table>
      <thead
        class="[&>th]:font-semibold [&>th]:tracking-[1px] ltr:[&>th]:text-left rtl:[&>th]:text-right [&>th]:px-2.5 [&>th]:uppercase [&>th]:text-n-slate-12"
      >
        <tr>
          <td class="ltr:pl-2.5 rtl:pr-2.5">
            <div class="flex items-center">
              <input
                name="select-all-agents"
                type="checkbox"
                :checked="allAgentsSelected ? 'checked' : ''"
                :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
                @click.self="selectAllAgents"
              />
            </div>
          </td>
          <td class="text-n-slate-12 ltr:pl-2.5 rtl:pr-2.5">
            {{ $t('TEAMS_SETTINGS.AGENTS.AGENT') }}
          </td>
          <td class="text-n-slate-12 ltr:pl-2.5 rtl:pr-2.5">
            {{ $t('TEAMS_SETTINGS.AGENTS.EMAIL') }}
          </td>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="agent in agentList"
          :key="agent.id"
          :class="agentRowClass(agent.id)"
          class="border-b border-n-weak [&>td]:p-2.5 [&>td]:text-n-slate-12"
        >
          <td class="w-12">
            <div class="flex items-center">
              <input
                type="checkbox"
                :checked="isAgentSelected(agent.id)"
                @click.self="() => handleSelectAgent(agent.id)"
              />
            </div>
          </td>
          <td>
            <div class="flex items-center gap-2">
              <Avatar
                :src="agent.thumbnail"
                :name="agent.name"
                :status="agent.availability_status"
                :size="24"
                hide-offline-status
                rounded-full
              />
              <h4 class="text-base mb-0 text-n-slate-12">
                {{ agent.name }}
              </h4>
            </div>
          </td>
          <td>
            {{ agent.email || '---' }}
          </td>
        </tr>
      </tbody>
    </table>
    <div class="flex items-center justify-between mt-2">
      <p>
        {{
          $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
            selected: selectedAgents.length,
            total: agentList.length,
          })
        }}
      </p>
      <NextButton
        type="submit"
        :label="submitButtonText"
        :disabled="disableSubmitButton"
        :is-loading="isWorking"
      />
    </div>
  </div>
</template>

<style scoped>
input {
  @apply mb-0;
}
</style>
