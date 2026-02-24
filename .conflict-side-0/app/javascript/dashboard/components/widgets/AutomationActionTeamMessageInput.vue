<script>
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';

export default {
  components: {
    MultiSelect,
  },
  props: {
    teams: { type: Array, required: true },
    modelValue: { type: Object, required: true },
    dropdownMaxHeight: { type: String, default: 'max-h-80' },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      selectedTeams: [],
      message: '',
    };
  },
  mounted() {
    const { team_ids: teamIds, message } = this.modelValue || {};
    this.selectedTeams = teamIds || [];
    this.message = message || '';
  },
  methods: {
    updateValue() {
      this.$emit('update:modelValue', {
        team_ids: this.selectedTeams.map(team => team.id),
        message: this.message,
      });
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <MultiSelect
      v-model="selectedTeams"
      :options="teams"
      :dropdown-max-height="dropdownMaxHeight"
      @update:model-value="updateValue"
    />
    <textarea
      v-model="message"
      class="mb-0 !text-sm"
      rows="4"
      :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
      @input="updateValue"
    />
  </div>
</template>
