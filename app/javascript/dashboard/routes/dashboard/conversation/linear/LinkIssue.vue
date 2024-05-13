<template>
  <div>
    <div class="multiselect-wrap--small">
      <multiselect
        v-model="selectedOptions"
        class="no-margin !pl-0"
        placeholder="Type to search"
        select-label="Select issue"
        label="name"
        track-by="id"
        :options="options"
        :option-height="24"
        :show-labels="false"
        @search-change="handleSearchChange"
        @select="handleInput"
      >
        <template #noResult>
          {{ emptyText }}
        </template>
        <template #noOptions> No options </template>
      </multiselect>
    </div>
    <div class="flex items-center justify-end w-full gap-2 mt-8">
      <woot-button
        class="px-4 rounded-xl button clear outline-woot-200/50 outline"
        @click.prevent="onClose"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CANCEL') }}
      </woot-button>
      <woot-button
        :is-disabled="isSubmitDisabled"
        class="px-4 rounded-xl"
        :is-loading="isLinking"
        @click.prevent="linkIssue"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE') }}
      </woot-button>
    </div>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import LinearAPI from 'dashboard/api/integrations/linear';

export default {
  mixins: [alertMixin],
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      selectedOptions: [],
      options: [],
      inputStyles: {
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
      },
      isFetching: false,
      isLinking: false,
      searchQuery: '',
    };
  },
  computed: {
    emptyText() {
      if (this.isFetching) {
        return 'Loading...';
      }
      if (this.searchQuery) {
        return '';
      }
      return 'No results found';
    },
    isSubmitDisabled() {
      return !this.selectedOptions || this.isLinking;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async handleSearchChange(value) {
      if (!value) return;
      this.searchQuery = value;
      try {
        this.isFetching = true;
        const response = await LinearAPI.searchIssues(value);
        const options = response.data.map(issue => ({
          id: issue.id,
          name: issue.title,
          description: issue.description,
        }));
        this.options = options;
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ERROR')
        );
      } finally {
        this.isFetching = false;
      }
    },
    handleInput() {
      this.$emit('agents-filter-selection', this.selectedOptions);
    },
    async linkIssue() {
      const { id: issueId } = this.selectedOptions;
      try {
        this.isLinking = true;
        await LinearAPI.link_issue(this.conversationId, issueId);
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_SUCCESS')
        );
        this.searchQuery = '';
        this.onClose();
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CREATE_ERROR')
        );
      } finally {
        this.isLinking = false;
      }
    },
  },
};
</script>
