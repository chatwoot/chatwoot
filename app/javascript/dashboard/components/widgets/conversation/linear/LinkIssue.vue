<template>
  <div
    class="flex flex-col justify-between"
    :class="shouldShowDropdown ? 'h-[256px]' : 'gap-2'"
  >
    <filter-button
      right-icon="chevron-down"
      :button-text="linkIssueTitle"
      class="justify-between w-full bg-slate-50 dark:bg-slate-800 hover:bg-slate-75 dark:hover:bg-slate-800"
      @click="toggleDropdown"
    >
      <template v-if="shouldShowDropdown" #dropdown>
        <filter-list-dropdown
          v-if="issues"
          v-on-clickaway="toggleDropdown"
          :show-clear-filter="false"
          :list-items="issues"
          :active-filter-id="selectedOption.id"
          :is-loading="isFetching"
          :input-placeholder="$t('INTEGRATION_SETTINGS.LINEAR.LINK.SEARCH')"
          :loading-placeholder="$t('INTEGRATION_SETTINGS.LINEAR.LINK.LOADING')"
          enable-search
          class="left-0 flex flex-col w-full overflow-y-auto h-fit !max-h-[160px] md:left-auto md:right-0 top-10"
          @on-search="onSearch"
          @click="onSelectIssue"
        />
      </template>
    </filter-button>
    <div class="flex items-center justify-end w-full gap-2">
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
        {{ $t('INTEGRATION_SETTINGS.LINEAR.LINK.TITLE') }}
      </woot-button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';
import LinearAPI from 'dashboard/api/integrations/linear';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import FilterListDropdown from 'dashboard/components/ui/Dropdown/DropdownList.vue';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  title: {
    type: String,
    default: null,
  },
});

const emits = defineEmits(['close']);

const { t } = useI18n();
const issues = ref([]);
const shouldShowDropdown = ref(false);
const selectedOption = ref({ id: null, name: '' });
const isFetching = ref(false);
const isLinking = ref(false);
const searchQuery = ref('');

const toggleDropdown = () => {
  issues.value = [];
  shouldShowDropdown.value = !shouldShowDropdown.value;
};

const linkIssueTitle = computed(() => {
  return selectedOption.value.id
    ? selectedOption.value.name
    : t('INTEGRATION_SETTINGS.LINEAR.LINK.SELECT');
});

const isSubmitDisabled = computed(() => {
  return !selectedOption.value.id || isLinking.value;
});

const onSelectIssue = item => {
  selectedOption.value = item;
  toggleDropdown();
};

const onClose = () => {
  emits('close');
};

const onSearch = async value => {
  issues.value = [];
  if (!value) return;
  searchQuery.value = value;
  try {
    isFetching.value = true;
    const response = await LinearAPI.searchIssues(value);
    issues.value = response.data.map(issue => ({
      id: issue.id,
      name: `${issue.identifier} ${issue.title}`,
    }));
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.LINK.ERROR')
    );
    useAlert(errorMessage);
  } finally {
    isFetching.value = false;
  }
};

const linkIssue = async () => {
  const { id: issueId } = selectedOption.value;
  try {
    isLinking.value = true;
    await LinearAPI.link_issue(props.conversationId, issueId, props.title);
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_SUCCESS'));
    searchQuery.value = '';
    issues.value = [];
    onClose();
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_ERROR')
    );
    useAlert(errorMessage);
  } finally {
    isLinking.value = false;
  }
};
</script>
