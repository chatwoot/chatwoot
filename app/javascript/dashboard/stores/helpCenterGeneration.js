import { defineStore } from 'pinia';

// Tracks the onboarding help center article generation, fed live by the
// `help_center.*` ActionCable events (see dashboard/helper/actionCable.js).
// The connector is created at app init, so events accumulate here before the
// onboarding screen mounts. State is in-memory only; a reload restarts the
// count from the next event (the generation_id comes from the account).
export const useHelpCenterGenerationStore = defineStore(
  'helpCenterGeneration',
  {
    state: () => ({
      generationId: null,
      status: null, // 'generating' | 'completed' | 'skipped' | null
      articlesCount: 0,
    }),

    getters: {
      isGenerating: state => state.status === 'generating',
      isCompleted: state => state.status === 'completed',
      isSkipped: state => state.status === 'skipped',
    },

    actions: {
      // Called by the component on mount with the account's generation_id.
      // No-op when events have already started populating this generation.
      hydrate(generationId) {
        if (!generationId || this.generationId === generationId) return;

        this.generationId = generationId;
        this.status = 'generating';
        this.articlesCount = 0;
      },

      handleArticleGenerated({
        generation_id: generationId,
        articles_finished: articlesFinished,
      }) {
        if (this.generationId && this.generationId !== generationId) return;

        this.generationId = generationId;
        this.articlesCount = articlesFinished ?? this.articlesCount + 1;
        if (!this.isCompleted && !this.isSkipped) this.status = 'generating';
      },

      handleGenerationCompleted({ generation_id: generationId, status }) {
        if (this.generationId && this.generationId !== generationId) return;

        this.generationId = generationId;
        this.status = status === 'skipped' ? 'skipped' : 'completed';
      },
    },
  }
);
