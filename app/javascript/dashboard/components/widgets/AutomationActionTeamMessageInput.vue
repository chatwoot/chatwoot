<template>
  <div>
    <div class="multiselect-wrap--small">
      <multiselect
        v-model="selectedTeams"
        track-by="id"
        label="name"
        :placeholder="'Select Teams'"
        :multiple="true"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :max-height="160"
        :options="teams"
        :allow-empty="false"
        @input="updateValue"
      />
      <textarea
        v-model="message"
        rows="4"
        placeholder="Enter your message here"
        @input="updateValue"
      ></textarea>
    </div>
  </div>
</template>

<script>
export default {
  // Could
  props: ['teams', 'value'],
  data() {
    return {
      selectedTeams: [],
      message: '',
    };
  },
  mounted() {
    const { team_ids: teamIds } = this.value;
    this.selectedTeams = teamIds;
    this.message = this.value.message;
  },
  methods: {
    updateValue() {
      this.$emit('input', {
        team_ids: this.selectedTeams.map(team => team.id),
        message: this.message,
      });
    },
  },
};
</script>

<style scoped>
.multiselect {
  margin: var(--space-smaller) var(--space-zero);
}
textarea {
  margin-bottom: var(--space-zero);
}
</style>
