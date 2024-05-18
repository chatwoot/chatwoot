<template>
  <div class="flex flex-col">
    <search-issue
      :title="linkIssueTitle"
      class="w-full bg-slate-50 dark:bg-slate-800 hover:bg-slate-75 dark:hover:bg-slate-800"
      @click="toggleDropdown"
    >
      <template v-if="shouldShowDropdown" #dropdown>
        <search-list-dropdown
          v-if="items"
          v-on-clickaway="toggleDropdown"
          :items="items"
          :selected-id="selectedOption.id"
          class="flex flex-col w-[240px] overflow-y-auto left-0 md:left-auto md:right-0 top-10"
          @on-search="handleSearchChange"
          @click="onSelectIssue"
        />
      </template>
    </search-issue>
    <div class="flex items-center justify-end w-full gap-2 mt-64">
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
import LinearAPI from 'dashboard/api/integrations/linear';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'dashboard/composables/useI18n';
import { computed, ref } from 'vue';
import SearchListDropdown from './SearchListDropdown.vue';
import SearchIssue from './SearchIssue.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});
const { t } = useI18n();
const items = ref([]);
const shouldShowDropdown = ref(false);
const toggleDropdown = () => {
  items.value = [];
  shouldShowDropdown.value = !shouldShowDropdown.value;
};

const selectedOption = ref({
  id: null,
  name: '',
});
const isFetching = ref(false);
const isLinking = ref(false);
const searchQuery = ref('');

const linkIssueTitle = computed(() => {
  if (selectedOption.value.id) {
    return selectedOption.value.name;
  }
  return t('INTEGRATION_SETTINGS.LINEAR.LINK.SELECT');
});

const onSelectIssue = item => {
  selectedOption.value = item;
  toggleDropdown();
};

const isSubmitDisabled = computed(() => {
  return !selectedOption.value.id || isLinking.value;
});

const emits = defineEmits(['close']);

const onClose = () => {
  emits('close');
};

const handleSearchChange = async value => {
  if (!value) return;
  searchQuery.value = value;
  try {
    isFetching.value = true;
    const response = await LinearAPI.searchIssues(value);
    items.value = response.data.map(issue => ({
      id: issue.id,
      name: `${issue.identifier} ${issue.title}`,
    }));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.LINK.ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const linkIssue = async () => {
  const { id: issueId } = selectedOption.value;
  try {
    isLinking.value = true;
    await LinearAPI.link_issue(props.conversationId, issueId);
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_SUCCESS'));
    searchQuery.value = '';
    onClose();
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_ERROR'));
  } finally {
    isLinking.value = false;
  }
};
</script>
