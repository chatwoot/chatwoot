<script>
import { useAIAgent } from '../../../../../composables/useAIAgent';
import { useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { computed, onMounted, ref } from 'vue';
import AiAgentTopicAPI from 'dashboard/api/ai_agent/topic';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  setup() {
    const store = useStore();
    const route = useRoute();
    const router = useRouter();
    const { aiAgentEnabled } = useAIAgent();

    const loading = ref(true);
    const saving = ref(false);
    const topic = ref({});
    const inboxes = ref([]);
    const selectedInboxes = ref([]);
    const availableInboxes = ref([]);

    const topicId = computed(() => route.params.topicId);

    const fetchData = async () => {
      loading.value = true;
      try {
        // Fetch topic data
        const topicResponse = await store.dispatch(
          'aiAgentTopics/show',
          topicId.value
        );
        topic.value = topicResponse;

        // In a real implementation, we would fetch the inboxes from the API
        // For now, just simulate with dummy data
        inboxes.value = [
          { id: 1, name: 'Website' },
          { id: 2, name: 'Email' },
        ];
        selectedInboxes.value = [1]; // Simulate currently linked inboxes
        availableInboxes.value = inboxes.value.filter(
          inbox => !selectedInboxes.value.includes(inbox.id)
        );
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        loading.value = false;
      }
    };

    const saveInboxes = async () => {
      saving.value = true;
      try {
        // In a real implementation, we would save the selected inboxes to the server
        // using something like:
        // await axios.post(`${AiAgentTopicAPI.url}/${topicId.value}/inboxes`, {
        //   inbox_ids: selectedInboxes.value
        // });

        // For now, just simulate a delay
        await new Promise(resolve => setTimeout(resolve, 1000));

        router.push({
          name: 'ai_agent_topics_edit',
          params: { topicId: topicId.value },
        });
      } catch (error) {
        console.error('Error saving inboxes:', error);
      } finally {
        saving.value = false;
      }
    };

    const toggleInbox = inboxId => {
      if (selectedInboxes.value.includes(inboxId)) {
        selectedInboxes.value = selectedInboxes.value.filter(
          id => id !== inboxId
        );
      } else {
        selectedInboxes.value.push(inboxId);
      }
      // Update available inboxes
      availableInboxes.value = inboxes.value.filter(
        inbox => !selectedInboxes.value.includes(inbox.id)
      );
    };

    const goBack = () => {
      router.push({
        name: 'ai_agent_topics_edit',
        params: { topicId: topicId.value },
      });
    };

    onMounted(fetchData);

    return {
      loading,
      saving,
      topic,
      inboxes,
      selectedInboxes,
      availableInboxes,
      topicId,
      aiAgentEnabled,
      fetchData,
      saveInboxes,
      toggleInbox,
      goBack,
    };
  },
};
</script>

<template>
  <div class="column content-box">
    <woot-modal-header
      :header-title="$t('AI_AGENT.TOPICS.INBOXES.HEADER')"
      :header-content="$t('AI_AGENT.TOPICS.INBOXES.DESCRIPTION')"
      @close="goBack"
    />

    <div v-if="loading" class="medium-12 columns with-loading">
      <Spinner />
    </div>
    <div v-else class="inboxes-container">
      <div class="current-topic">
        <h3>{{ topic.name }}</h3>
        <p>{{ topic.description }}</p>
      </div>

      <div class="inbox-list">
        <h4>{{ $t('AI_AGENT.TOPICS.INBOXES.LINKED') }}</h4>
        <div v-if="selectedInboxes.length" class="inbox-items">
          <div
            v-for="inbox in inboxes.filter(i => selectedInboxes.includes(i.id))"
            :key="`selected-${inbox.id}`"
            class="inbox-item selected"
          >
            <span>{{ inbox.name }}</span>
            <woot-button class="button clear" @click="toggleInbox(inbox.id)">
              {{ $t('REMOVE') }}
            </woot-button>
          </div>
        </div>
        <div v-else class="empty-inboxes">
          {{ $t('AI_AGENT.TOPICS.INBOXES.NO_LINKED') }}
        </div>

        <h4>{{ $t('AI_AGENT.TOPICS.INBOXES.AVAILABLE') }}</h4>
        <div v-if="availableInboxes.length" class="inbox-items">
          <div
            v-for="inbox in availableInboxes"
            :key="`available-${inbox.id}`"
            class="inbox-item available"
          >
            <span>{{ inbox.name }}</span>
            <woot-button class="button success" @click="toggleInbox(inbox.id)">
              {{ $t('ADD') }}
            </woot-button>
          </div>
        </div>
        <div v-else class="empty-inboxes">
          {{ $t('AI_AGENT.TOPICS.INBOXES.NO_AVAILABLE') }}
        </div>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button class="button clear" @click="goBack">
            {{ $t('CANCEL') }}
          </woot-button>
          <woot-button
            class="button success"
            :is-loading="saving"
            :disabled="saving"
            @click="saveInboxes"
          >
            {{ $t('SAVE') }}
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.inboxes-container {
  padding: var(--space-normal);
}

.current-topic {
  margin-bottom: var(--space-medium);
  padding-bottom: var(--space-normal);
  border-bottom: 1px solid var(--color-border);

  h3 {
    margin-bottom: var(--space-smaller);
  }

  p {
    color: var(--color-body);
    font-size: var(--font-size-small);
  }
}

.inbox-list {
  h4 {
    margin: var(--space-normal) 0 var(--space-small);
  }
}

.inbox-items {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
}

.inbox-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-small);
  border-radius: var(--border-radius-normal);
  background-color: var(--white);
  border: 1px solid var(--color-border);
}

.empty-inboxes {
  font-size: var(--font-size-small);
  color: var(--color-body);
  font-style: italic;
  padding: var(--space-normal) 0;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: var(--space-normal) 0;
  margin-top: var(--space-normal);
  border-top: 1px solid var(--color-border);
}
</style>
