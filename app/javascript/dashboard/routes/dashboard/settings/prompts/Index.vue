<script>
import { mapGetters } from 'vuex';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
  },
  data() {
    return {};
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
  <div class="flex flex-col max-w-4xl mx-auto w-full">
    <BaseSettingsHeader
      :title="$t('PROMPTS_PAGE.TITLE')"
      :description="$t('PROMPTS_PAGE.DESCRIPTION')"
    />

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
  </div>
</template>
