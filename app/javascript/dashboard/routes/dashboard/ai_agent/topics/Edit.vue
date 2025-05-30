<script>
import { useAIAgent } from '../../../../composables/useAIAgent';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'AiAgentTopicEdit',
  components: {
    Spinner,
  },
  setup() {
    const { aiAgentEnabled } = useAIAgent();
    return { aiAgentEnabled };
  },
  data() {
    return {
      loading: true,
      saving: false,
      topic: {
        name: '',
        description: '',
      },
    };
  },
  computed: {
    topicId() {
      return this.$route.params.topicId;
    },
    isNew() {
      return this.topicId === 'new';
    },
    pageTitle() {
      return this.isNew
        ? this.$t('AI_AGENT.TOPICS.ADD')
        : this.$t('AI_AGENT.TOPICS.EDIT');
    },
  },
  mounted() {
    this.fetchTopic();
  },
  methods: {
    async fetchTopic() {
      if (this.isNew) {
        this.topic = {
          name: '',
          description: '',
        };
        this.loading = false;
        return;
      }

      this.loading = true;
      // In a real implementation, we would fetch the topic from the server
      // For now, just simulate a delay
      setTimeout(() => {
        this.topic = {
          id: parseInt(this.topicId, 10),
          name: 'Product Knowledge',
          description: 'Information about our products and features',
        };
        this.loading = false;
      }, 1000);
    },
    async saveTopic() {
      this.saving = true;
      // In a real implementation, we would save the topic to the server
      // For now, just simulate a delay
      setTimeout(() => {
        this.saving = false;
        this.$router.push({ name: 'ai_agent_topics' });
      }, 1000);
    },
    goBack() {
      this.$router.push({ name: 'ai_agent_topics' });
    },
  },
};
</script>

<template>
  <div class="column content-box">
    <woot-modal-header
      :header-title="pageTitle"
      :header-content="$t('AI_AGENT.TOPICS.FORM_DESCRIPTION')"
      @close="goBack"
    />

    <div v-if="loading" class="medium-12 columns with-loading">
      <Spinner />
    </div>
    <div v-else class="topic-form">
      <div class="medium-12 columns">
        <woot-input
          v-model="topic.name"
          :label="$t('AI_AGENT.TOPICS.NAME.LABEL')"
          :placeholder="$t('AI_AGENT.TOPICS.NAME.PLACEHOLDER')"
          :error="$v.topic.name.$error ? $t('AI_AGENT.TOPICS.NAME.ERROR') : ''"
          @input="$v.topic.name.$touch"
        />
      </div>

      <div class="medium-12 columns">
        <woot-input
          v-model="topic.description"
          :label="$t('AI_AGENT.TOPICS.DESCRIPTION.LABEL')"
          :placeholder="$t('AI_AGENT.TOPICS.DESCRIPTION.PLACEHOLDER')"
          :error="
            $v.topic.description.$error
              ? $t('AI_AGENT.TOPICS.DESCRIPTION.ERROR')
              : ''
          "
          multiline
          @input="$v.topic.description.$touch"
        />
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button class="button clear" @click="goBack">
            {{ $t('CANCEL') }}
          </woot-button>
          <woot-button
            class="button success"
            :is-loading="saving"
            :disabled="saving || $v.$invalid"
            @click="saveTopic"
          >
            {{ $t('SAVE') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.topic-form {
  padding: var(--space-normal);

  .columns {
    margin-bottom: var(--space-normal);
  }
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: var(--space-normal) 0;
  margin-top: var(--space-normal);
  border-top: 1px solid var(--color-border);
}
</style>
