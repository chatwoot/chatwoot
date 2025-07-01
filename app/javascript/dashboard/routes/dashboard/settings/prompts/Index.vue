<script>
import { mapGetters } from 'vuex';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AddKnowledgeSource from './components/AddKnowledgeSource.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
    AddKnowledgeSource,
    Icon,
  },
  data() {
    return {
      showAddKnowledgeSourceModal: false,
      knowledgeSources: [
        {
          id: 1,
          name: 'https://docs.chatwoot.com/product/features/reports',
          type: 'URL',
          icon: 'i-lucide-globe',
          uploadedDate: 'May 20, 2024',
        },
        {
          id: 2,
          name: 'pricing-details.pdf',
          type: 'File',
          icon: 'i-lucide-file-text',
          uploadedDate: 'May 18, 2024',
        },
        {
          id: 3,
          name: 'logo-dark.png',
          type: 'Image',
          icon: 'i-lucide-image',
          uploadedDate: 'May 17, 2024',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      prompts: 'prompts/getPrompts',
      uiFlags: 'prompts/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('prompts/get');
  },
  methods: {
    openAddKnowledgeSourceModal() {
      this.showAddKnowledgeSourceModal = true;
    },
    hideAddKnowledgeSourceModal() {
      this.showAddKnowledgeSourceModal = false;
    },
    navigateToEditPrompt(prompt) {
      this.$router.push({
        name: 'prompts_edit',
        params: { id: prompt.id },
      });
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
        <NextButton icon="i-lucide-plus" @click="openAddKnowledgeSourceModal">
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
    <div class="mt-8">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100 mb-4">
        {{ $t('KNOWLEDGE_SOURCES.TITLE') }}
      </h2>
      <div
        class="bg-white dark:bg-slate-800 rounded-lg border border-slate-50 dark:border-slate-700/50"
      >
        <ul>
          <li
            v-for="(source, index) in knowledgeSources"
            :key="source.id"
            class="flex items-center justify-between p-4"
            :class="{
              'border-b border-slate-50 dark:border-slate-700/50':
                index < knowledgeSources.length - 1,
            }"
          >
            <div class="flex items-center gap-4">
              <Icon
                :icon="source.icon"
                class="w-6 h-6 text-slate-600 dark:text-slate-300"
              />
              <div class="flex flex-col">
                <p class="font-semibold text-slate-900 dark:text-slate-100">
                  {{ source.name }}
                </p>
                <p class="text-sm text-slate-600 dark:text-slate-300">
                  {{ source.type }}
                  <span>·</span>
                  {{
                    $t('KNOWLEDGE_SOURCES.UPLOADED_ON', {
                      date: source.uploadedDate,
                    })
                  }}
                </p>
              </div>
            </div>
            <NextButton
              v-tooltip.top="$t('PROMPTS_PAGE.DELETE')"
              icon="i-lucide-trash-2"
              variant="smooth"
              color-scheme="secondary"
            />
          </li>
        </ul>
      </div>
    </div>

    <!-- Add Knowledge Source Modal -->
    <AddKnowledgeSource
      v-if="showAddKnowledgeSourceModal"
      @close="hideAddKnowledgeSourceModal"
    />
  </div>
</template>
