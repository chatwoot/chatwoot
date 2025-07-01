<script>
import { mapGetters } from 'vuex';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AddKnowledgeSource from './components/AddKnowledgeSource.vue';
import Modal from 'dashboard/components/Modal.vue';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { useAlert } from 'dashboard/composables';
import Auth from 'dashboard/api/auth';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
    AddKnowledgeSource,
    Modal,
    GalleryView,
  },
  data() {
    return {
      showAddKnowledgeSourceModal: false,
      knowledgeSources: [],
      loadingKnowledgeSources: false,
      showDeleteConfirm: false,
      sourceToDelete: null,
      showGalleryViewer: false,
      activeAttachment: {},
    };
  },
  computed: {
    ...mapGetters({
      prompts: 'prompts/getPrompts',
      uiFlags: 'prompts/getUIFlags',
      currentAccountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.$store.dispatch('prompts/get');
    this.fetchKnowledgeSources();
  },
  methods: {
    navigateToEditPrompt(prompt) {
      this.$router.push({
        name: 'prompts_edit',
        params: { id: prompt.id },
      });
    },
    openAddKnowledgeSourceModal() {
      this.showAddKnowledgeSourceModal = true;
    },
    hideAddKnowledgeSourceModal() {
      this.showAddKnowledgeSourceModal = false;
    },
    async fetchKnowledgeSources() {
      this.loadingKnowledgeSources = true;
      try {
        const authData = Auth.getAuthData();
        const headers = {
          'Content-Type': 'application/json',
        };

        if (authData) {
          headers['access-token'] = authData['access-token'];
          headers['token-type'] = authData['token-type'];
          headers.client = authData.client;
          headers.expiry = authData.expiry;
          headers.uid = authData.uid;
        }

        const response = await fetch(
          `/api/v1/accounts/${this.currentAccountId}/knowledge_bases`,
          {
            method: 'GET',
            headers,
          }
        );

        if (response.ok) {
          this.knowledgeSources = await response.json();
        } else {
          throw new Error('Failed to fetch knowledge sources');
        }
      } catch (error) {
        useAlert(this.$t('KNOWLEDGE_SOURCE.FETCH_ERROR'));
      } finally {
        this.loadingKnowledgeSources = false;
      }
    },
    viewKnowledgeSource(source) {
      if (source.source_type === 'image') {
        this.openGallery(source);
      } else if (
        source.source_type === 'file' ||
        source.source_type === 'webpage'
      ) {
        window.open(source.url, '_blank', 'noopener noreferrer');
      }
    },
    openGallery(source) {
      // Create an attachment object that GalleryView expects
      this.activeAttachment = {
        id: source.id,
        message_id: source.id, // GalleryView uses this for navigation
        file_type: 'image',
        data_url: source.url,
        created_at: source.created_at,
        sender: {
          name: 'Knowledge Base',
          id: 'system',
          avatar_url: '',
        },
      };
      this.showGalleryViewer = true;
    },
    onCloseGallery() {
      this.showGalleryViewer = false;
      this.activeAttachment = {};
    },
    confirmDeleteKnowledgeSource(knowledgeSource, event) {
      // Prevent the click from bubbling up to viewKnowledgeSource
      event.stopPropagation();
      this.sourceToDelete = knowledgeSource;
      this.showDeleteConfirm = true;
    },
    async deleteKnowledgeSource() {
      if (!this.sourceToDelete) return;

      try {
        const authData = Auth.getAuthData();
        const headers = {
          'Content-Type': 'application/json',
        };

        if (authData) {
          headers['access-token'] = authData['access-token'];
          headers['token-type'] = authData['token-type'];
          headers.client = authData.client;
          headers.expiry = authData.expiry;
          headers.uid = authData.uid;
        }

        const response = await fetch(
          `/api/v1/accounts/${this.currentAccountId}/knowledge_bases/${this.sourceToDelete.id}`,
          {
            method: 'DELETE',
            headers,
          }
        );

        if (response.ok) {
          useAlert(this.$t('KNOWLEDGE_SOURCE.DELETE_SUCCESS'));
          this.fetchKnowledgeSources(); // Refresh the list
        } else {
          throw new Error('Failed to delete knowledge source');
        }
      } catch (error) {
        useAlert(this.$t('KNOWLEDGE_SOURCE.DELETE_ERROR'));
      } finally {
        this.showDeleteConfirm = false;
        this.sourceToDelete = null;
      }
    },
    cancelDelete() {
      this.showDeleteConfirm = false;
      this.sourceToDelete = null;
    },
    getSourceIcon(sourceType) {
      switch (sourceType) {
        case 'webpage':
          return 'i-lucide-globe';
        case 'file':
          return 'i-lucide-file-text';
        case 'image':
          return 'i-lucide-image';
        default:
          return 'i-lucide-file';
      }
    },
    getSourceTypeDisplay(sourceType) {
      switch (sourceType) {
        case 'webpage':
          return this.$t('KNOWLEDGE_SOURCE.TYPE.URL');
        case 'file':
          return this.$t('KNOWLEDGE_SOURCE.TYPE.FILE');
        case 'image':
          return this.$t('KNOWLEDGE_SOURCE.TYPE.IMAGE');
        default:
          return this.$t('KNOWLEDGE_SOURCE.TYPE.UNKNOWN');
      }
    },
    formatDate(dateString) {
      const date = new Date(dateString);
      const now = new Date();
      const diffTime = Math.abs(now - date);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays === 1) {
        return this.$t('KNOWLEDGE_SOURCE.DATE.TODAY');
      }
      if (diffDays === 2) {
        return this.$t('KNOWLEDGE_SOURCE.DATE.YESTERDAY');
      }
      if (diffDays <= 7) {
        return this.$t('KNOWLEDGE_SOURCE.DATE.DAYS_AGO', {
          count: diffDays - 1,
        });
      }
      if (diffDays <= 14) {
        return this.$t('KNOWLEDGE_SOURCE.DATE.WEEK_AGO');
      }
      if (diffDays <= 30) {
        return this.$t('KNOWLEDGE_SOURCE.DATE.WEEKS_AGO', {
          count: Math.ceil(diffDays / 7),
        });
      }
      return this.$t('KNOWLEDGE_SOURCE.DATE.MONTHS_AGO', {
        count: Math.ceil(diffDays / 30),
      });
    },
    onKnowledgeSourceAdded() {
      // Refresh the knowledge sources list when a new one is added
      this.fetchKnowledgeSources();
    },
  },
};
</script>

<template>
  <div class="flex flex-col w-full">
    <BaseSettingsHeader
      :title="$t('PROMPTS_PAGE.TITLE')"
      :description="$t('PROMPTS_PAGE.DESCRIPTION')"
    >
      <template #actions>
        <NextButton @click="openAddKnowledgeSourceModal">
          {{ $t('ADD_KNOWLEDGE_SOURCE_BUTTON') }}
        </NextButton>
      </template>
    </BaseSettingsHeader>

    <div v-if="!uiFlags.isFetching" class="mt-6">
      <div v-if="prompts.length === 0" class="text-center py-8">
        <p class="text-slate-600 dark:text-slate-400">
          {{ $t('PROMPTS_PAGE.EMPTY_STATE') }}
        </p>
      </div>

      <div v-else class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <div
          v-for="prompt in prompts"
          :key="prompt.id"
          data-testid="prompt-card"
          class="group relative bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-6 transition-colors cursor-pointer hover:border-slate-300 dark:hover:border-slate-600"
          @click="navigateToEditPrompt(prompt)"
        >
          <div class="flex items-start justify-between mb-3">
            <h3
              class="text-lg font-semibold text-slate-900 dark:text-slate-100 line-clamp-1"
            >
              {{ prompt.prompt_key }}
            </h3>
            <div
              class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <NextButton
                v-tooltip.top="$t('PROMPTS_PAGE.EDIT')"
                data-testid="edit-button"
                icon="i-lucide-pen"
                slate
                xs
                faded
                @click.stop="navigateToEditPrompt(prompt)"
              />
            </div>
          </div>
          <p class="text-slate-600 dark:text-slate-400 text-sm line-clamp-3">
            {{ prompt.text }}
          </p>
        </div>
      </div>
    </div>

    <div v-else class="flex justify-center py-8">
      <div class="text-slate-600 dark:text-slate-400">
        {{ $t('PROMPTS_PAGE.LOADING') }}
      </div>
    </div>

    <!-- Knowledge Sources Section -->
    <div class="mt-12">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100 mb-6">
        {{ $t('KNOWLEDGE_SOURCE.TITLE') }}
      </h2>

      <div v-if="loadingKnowledgeSources" class="flex justify-center py-8">
        <div class="text-slate-600 dark:text-slate-400">
          {{ $t('KNOWLEDGE_SOURCE.LOADING') }}
        </div>
      </div>

      <div v-else-if="knowledgeSources.length === 0" class="text-center py-8">
        <p class="text-slate-600 dark:text-slate-400">
          {{ $t('KNOWLEDGE_SOURCE.EMPTY_STATE') }}
        </p>
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="source in knowledgeSources"
          :key="source.id"
          class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer transition-colors hover:border-slate-300 dark:hover:border-slate-600"
          @click="viewKnowledgeSource(source)"
        >
          <div class="flex items-center gap-3">
            <i
              :class="getSourceIcon(source.source_type)"
              class="text-slate-600 dark:text-slate-400 text-lg"
            />
            <div>
              <p class="font-medium text-slate-900 dark:text-slate-100">
                {{ source.name }}
              </p>
              <p class="text-sm text-slate-600 dark:text-slate-400">
                {{ getSourceTypeDisplay(source.source_type) }} •
                {{ formatDate(source.created_at) }}
              </p>
            </div>
          </div>
          <NextButton
            icon="i-lucide-trash-2"
            slate
            xs
            faded
            @click="confirmDeleteKnowledgeSource(source, $event)"
          />
        </div>
      </div>
    </div>

    <!-- Add Knowledge Source Modal -->
    <AddKnowledgeSource
      :show="showAddKnowledgeSourceModal"
      @close="hideAddKnowledgeSourceModal"
      @refresh="onKnowledgeSourceAdded"
    />

    <!-- Gallery View for Images -->
    <GalleryView
      v-if="showGalleryViewer"
      v-model:show="showGalleryViewer"
      :attachment="activeAttachment"
      :all-attachments="[activeAttachment]"
      @close="onCloseGallery"
    />

    <!-- Delete Confirmation Modal -->
    <Modal v-if="showDeleteConfirm" :show="showDeleteConfirm" size="small">
      <div class="flex flex-col">
        <woot-modal-header
          :header-title="$t('KNOWLEDGE_SOURCE.DELETE_CONFIRM.TITLE')"
        />
        <div class="p-6">
          <p class="text-slate-600 dark:text-slate-400">
            {{
              $t('KNOWLEDGE_SOURCE.DELETE_CONFIRM.MESSAGE', {
                name: sourceToDelete?.name,
              })
            }}
          </p>
        </div>
        <div
          class="flex items-center justify-end gap-3 p-6 border-t border-slate-200 dark:border-slate-700"
        >
          <NextButton slate outline @click="cancelDelete">
            {{ $t('KNOWLEDGE_SOURCE.DELETE_CONFIRM.CANCEL') }}
          </NextButton>
          <NextButton variant="danger" @click="deleteKnowledgeSource">
            {{ $t('KNOWLEDGE_SOURCE.DELETE_CONFIRM.DELETE') }}
          </NextButton>
        </div>
      </div>
    </Modal>
  </div>
</template>
