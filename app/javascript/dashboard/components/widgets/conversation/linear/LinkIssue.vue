<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useAlert } from 'dashboard/composables';
import LinearAPI from 'dashboard/api/integrations/linear';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import FilterListDropdown from 'dashboard/components/ui/Dropdown/DropdownList.vue';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';
import { LINEAR_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Button from 'dashboard/components-next/button/Button.vue';

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

const emit = defineEmits(['close']);

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
  emit('close');
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
      icon: 'status',
      iconColor: issue.state.color,
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
    useTrack(LINEAR_EVENTS.LINK_ISSUE);
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

<template>
  <div
    class="flex flex-col justify-between"
    :class="shouldShowDropdown ? 'h-[256px]' : 'gap-2'"
  >
    <FilterButton
      trailing-icon
      icon="i-lucide-chevron-down"
      :button-text="linkIssueTitle"
      class="justify-between w-full h-[2.5rem] py-1.5 px-3 rounded-xl bg-n-alpha-black2 outline outline-1 outline-n-weak dark:outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6"
      @click="toggleDropdown"
    >
      <template v-if="shouldShowDropdown" #dropdown>
        <FilterListDropdown
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
          @select="onSelectIssue"
        />
      </template>
    </FilterButton>
    <div class="flex items-center justify-end w-full gap-2 mt-2">
      <Button
        faded
        slate
        type="reset"
        :label="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.CANCEL')"
        @click.prevent="onClose"
      />
      <Button
        type="submit"
        :label="$t('INTEGRATION_SETTINGS.LINEAR.LINK.TITLE')"
        :disabled="isSubmitDisabled"
        :is-loading="isLinking"
        @click.prevent="linkIssue"
      />
    </div>
  </div>
</template>
