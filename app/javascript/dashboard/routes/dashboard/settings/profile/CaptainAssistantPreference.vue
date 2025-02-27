<script>
import { useUISettings } from 'dashboard/composables/useUISettings';
import CaptainAssistantAPI from 'dashboard/api/captain/assistant';

export default {
  name: 'CaptainAssistantPreference',
  data() {
    return {
      assistants: [],
      selectedAssistantId: null,
      isLoading: true,
      isSaving: false,
    };
  },
  computed: {
    hasAssistants() {
      return this.assistants.length > 0;
    },
  },
  mounted() {
    this.fetchAssistants();
    this.loadPreferredAssistant();
  },
  methods: {
    async fetchAssistants() {
      this.isLoading = true;
      try {
        const { data } = await CaptainAssistantAPI.getAll();
        this.assistants = data.payload;
      } catch (error) {
        this.$toast.error(
          this.$t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.FETCH_ERROR')
        );
      } finally {
        this.isLoading = false;
      }
    },
    loadPreferredAssistant() {
      const { uiSettings } = useUISettings();
      this.selectedAssistantId =
        uiSettings.value.preferred_captain_assistant_id || null;
    },
    async savePreference() {
      const { updateUISettings } = useUISettings();
      this.isSaving = true;

      try {
        await updateUISettings({
          preferred_captain_assistant_id: this.selectedAssistantId,
        });
        this.$toast.success(
          this.$t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.SAVE_SUCCESS')
        );
      } catch (error) {
        this.$toast.error(
          this.$t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.SAVE_ERROR')
        );
      } finally {
        this.isSaving = false;
      }
    },
  },
};
</script>

<template>
  <div class="captain-assistant-preference">
    <div v-if="isLoading" class="loading-state">
      {{ $t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.LOADING') }}
    </div>
    <div v-else-if="!hasAssistants" class="empty-state">
      {{ $t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.NO_ASSISTANTS') }}
    </div>
    <div v-else class="form-wrapper">
      <div class="form-group">
        <label for="assistant-select">
          {{ $t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.SELECT_LABEL') }}
        </label>
        <select
          id="assistant-select"
          v-model="selectedAssistantId"
          class="assistant-select"
        >
          <option value="">
            {{ $t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.DEFAULT_OPTION') }}
          </option>
          <option
            v-for="assistant in assistants"
            :key="assistant.id"
            :value="assistant.id"
          >
            {{ assistant.name }}
          </option>
        </select>
      </div>
      <button class="save-button" :disabled="isSaving" @click="savePreference">
        {{ $t('PROFILE_SETTINGS.FORM.CAPTAIN_ASSISTANT.SAVE_BUTTON') }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.captain-assistant-preference {
  margin-top: 1rem;
}

.loading-state,
.empty-state {
  padding: 1rem 0;
  color: var(--s-600);
}

.form-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--s-900);
}

.assistant-select {
  padding: 0.5rem;
  border: 1px solid var(--s-200);
  border-radius: 0.25rem;
  background-color: var(--white);
  font-size: 0.875rem;
}

.save-button {
  align-self: flex-start;
  padding: 0.5rem 1rem;
  background-color: var(--w-600);
  color: var(--white);
  border: none;
  border-radius: 0.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.save-button:hover {
  background-color: var(--w-700);
}

.save-button:disabled {
  background-color: var(--s-300);
  cursor: not-allowed;
}
</style>
