<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const isLoading = ref(true);
const activeFilter = ref('all');
const currentPage = ref(1);

const memoryTypes = [
  { key: 'all', label: 'All' },
  { key: 'faq', label: 'FAQ' },
  { key: 'preference', label: 'Preference' },
  { key: 'correction', label: 'Correction' },
  { key: 'procedure', label: 'Procedure' },
  { key: 'insight', label: 'Insight' },
  { key: 'commitment', label: 'Commitment' },
  { key: 'gap', label: 'Gap' },
];

const memories = computed(() => getters['alooMemories/getRecords'].value);
const meta = computed(() => getters['alooMemories/getMeta'].value || {});

const fetchMemories = async () => {
  isLoading.value = true;
  try {
    await store.dispatch('alooMemories/getMemories', {
      assistantId: props.assistantId,
      page: currentPage.value,
      memoryType: activeFilter.value === 'all' ? null : activeFilter.value,
    });
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchMemories);

watch([activeFilter, currentPage], () => {
  fetchMemories();
});

const setFilter = type => {
  activeFilter.value = type;
  currentPage.value = 1;
};

const deleteMemory = async memoryId => {
  try {
    await store.dispatch('alooMemories/deleteMemory', {
      assistantId: props.assistantId,
      memoryId,
    });
    useAlert(t('ALOO.MEMORIES.DELETED'));
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const getTypeColor = type => {
  const colors = {
    faq: 'bg-n-blue-3 text-n-blue-11',
    preference: 'bg-n-purple-3 text-n-purple-11',
    correction: 'bg-n-amber-3 text-n-amber-11',
    procedure: 'bg-n-green-3 text-n-green-11',
    insight: 'bg-n-cyan-3 text-n-cyan-11',
    commitment: 'bg-n-pink-3 text-n-pink-11',
    gap: 'bg-n-ruby-3 text-n-ruby-11',
    decision: 'bg-n-orange-3 text-n-orange-11',
  };
  return colors[type] || 'bg-n-slate-3 text-n-slate-11';
};

const formatConfidence = confidence => {
  return `${Math.round((confidence || 0) * 100)}%`;
};
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.MEMORIES.TITLE')"
      :sub-title="$t('ALOO.MEMORIES.DESCRIPTION')"
      :show-border="false"
    >
      <!-- Filter Tabs -->
      <div class="flex flex-wrap gap-2 mb-6">
        <button
          v-for="type in memoryTypes"
          :key="type.key"
          class="px-3 py-1.5 rounded-lg text-sm font-medium transition-colors"
          :class="
            activeFilter === type.key
              ? 'bg-n-blue-9 text-white'
              : 'bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3'
          "
          @click="setFilter(type.key)"
        >
          {{ type.label }}
          <span
            v-if="type.key !== 'all' && meta.counts_by_type?.[type.key]"
            class="ml-1 text-xs opacity-75"
          >
            ({{ meta.counts_by_type[type.key] }})
          </span>
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="flex items-center justify-center py-12">
        <woot-loading-state :message="$t('ALOO.MEMORIES.LOADING')" />
      </div>

      <!-- Memories List -->
      <template v-else>
        <div v-if="memories.length" class="space-y-3">
          <div
            v-for="memory in memories"
            :key="memory.id"
            class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-2">
                  <span
                    class="px-2 py-0.5 text-xs font-medium rounded"
                    :class="getTypeColor(memory.memory_type)"
                  >
                    {{ memory.memory_type }}
                  </span>
                  <span class="text-xs text-n-slate-10">
                    {{ $t('ALOO.MEMORIES.CONFIDENCE') }}:
                    {{ formatConfidence(memory.confidence) }}
                  </span>
                  <span
                    v-if="memory.flagged_for_review"
                    class="px-2 py-0.5 text-xs font-medium rounded bg-n-ruby-3 text-n-ruby-11"
                  >
                    {{ $t('ALOO.MEMORIES.FLAGGED') }}
                  </span>
                </div>
                <p class="text-sm text-n-slate-12 mb-2">
                  {{ memory.content }}
                </p>
                <div class="flex items-center gap-4 text-xs text-n-slate-10">
                  <span>
                    {{ $t('ALOO.MEMORIES.OBSERVATIONS') }}:
                    {{ memory.observation_count || 0 }}
                  </span>
                  <span v-if="memory.helpful_count">
                    {{ $t('ALOO.MEMORIES.HELPFUL') }}:
                    {{ memory.helpful_count }}
                  </span>
                  <span v-if="memory.not_helpful_count">
                    {{ $t('ALOO.MEMORIES.NOT_HELPFUL') }}:
                    {{ memory.not_helpful_count }}
                  </span>
                </div>
              </div>
              <Button
                icon="i-lucide-trash-2"
                xs
                ruby
                faded
                @click="deleteMemory(memory.id)"
              />
            </div>
          </div>

          <!-- Pagination -->
          <div
            v-if="meta.total_pages > 1"
            class="flex items-center justify-center gap-2 pt-4"
          >
            <Button
              :disabled="currentPage === 1"
              xs
              faded
              slate
              @click="currentPage--"
            >
              {{ $t('ALOO.PAGINATION.PREVIOUS') }}
            </Button>
            <span class="text-sm text-n-slate-11">
              {{ currentPage }} / {{ meta.total_pages }}
            </span>
            <Button
              :disabled="currentPage >= meta.total_pages"
              xs
              faded
              slate
              @click="currentPage++"
            >
              {{ $t('ALOO.PAGINATION.NEXT') }}
            </Button>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-brain text-3xl text-n-slate-9" />
          <p class="text-sm text-n-slate-11 mt-2">
            {{ $t('ALOO.MEMORIES.EMPTY') }}
          </p>
        </div>
      </template>
    </SettingsSection>
  </div>
</template>
