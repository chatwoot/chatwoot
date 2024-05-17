<template>
  <div>
    <div class="multiselect-wrap--small">
      <multiselect
        v-model="selectedOptions"
        class="no-margin !pl-0"
        :placeholder="$t('INTEGRATION_SETTINGS.LINEAR.LINK.SEARCH')"
        :select-label="$t('INTEGRATION_SETTINGS.LINEAR.LINK.SELECT')"
        label="title"
        track-by="id"
        :options="options"
        :option-height="24"
        :show-labels="false"
        :max-height="500"
        @search-change="handleSearchChange"
      >
        <template #noResult>
          <div class="flex items-center justify-center">
            {{ emptyText }}
          </div>
        </template>
        <template #noOptions>
          <div class="flex items-center justify-center">
            {{ $t('INTEGRATION_SETTINGS.LINEAR.LINK.EMPTY_LIST') }}
          </div>
        </template>
      </multiselect>
    </div>
    <div class="flex items-center justify-end w-full gap-2 mt-8">
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

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});
const { t } = useI18n();

const selectedOptions = ref(null);
const options = ref([]);
const isFetching = ref(false);
const isLinking = ref(false);
const searchQuery = ref('');

const emptyText = computed(() => {
  if (isFetching.value) {
    return t('INTEGRATION_SETTINGS.LINEAR.LINK.LOADING');
  }
  if (searchQuery.value) {
    return '';
  }
  return t('INTEGRATION_SETTINGS.LINEAR.LINK.EMPTY_LIST');
});

const isSubmitDisabled = computed(() => {
  return !selectedOptions.value || isLinking.value;
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
    options.value = response.data;
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.LINK.ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const linkIssue = async () => {
  const { id: issueId } = selectedOptions.value;
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
