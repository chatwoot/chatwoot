<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { picoSearch } from '@scmmishra/pico-search';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import SimpleReplyCard from 'dashboard/components-next/captain/assistant/SimpleReplyCard.vue';
import AddNewSimpleReplyDialog from 'dashboard/components-next/captain/assistant/AddNewSimpleReplyDialog.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const assistantId = computed(() => Number(route.params.assistantId));

const uiFlags = useMapGetter('captainSimpleReplies/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const simpleReplies = useMapGetter('captainSimpleReplies/getRecords');

const searchQuery = ref('');

const filteredSimpleReplies = computed(() => {
  const query = searchQuery.value.trim();
  const source = simpleReplies.value;
  if (!query) return source;
  return picoSearch(source, query, ['name', 'reply', 'keywords']);
});

const addSimpleReply = async simpleReply => {
  try {
    await store.dispatch('captainSimpleReplies/create', {
      assistantId: assistantId.value,
      ...simpleReply,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

const updateSimpleReply = async simpleReply => {
  const { id, ...updateObj } = simpleReply;
  try {
    await store.dispatch('captainSimpleReplies/update', {
      id,
      assistantId: assistantId.value,
      ...updateObj,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const deleteSimpleReply = async id => {
  try {
    await store.dispatch('captainSimpleReplies/delete', {
      id,
      assistantId: assistantId.value,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.API.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  store.dispatch('captainSimpleReplies/get', {
    assistantId: assistantId.value,
  });
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.TITLE')"
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <SettingsHeader
        :heading="$t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.TITLE')"
        :description="$t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.DESCRIPTION')"
      />
      <div class="flex mt-7 flex-col gap-4">
        <div class="flex justify-between items-center">
          <AddNewSimpleReplyDialog @add="addSimpleReply" />
          <div
            v-if="simpleReplies.length"
            class="max-w-[22.5rem] w-full min-w-0"
          >
            <Input
              v-model="searchQuery"
              :placeholder="
                t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.LIST.SEARCH_PLACEHOLDER')
              "
            />
          </div>
        </div>
        <div v-if="simpleReplies.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else-if="filteredSimpleReplies.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SIMPLE_REPLIES.SEARCH_EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else class="flex flex-col gap-2">
          <SimpleReplyCard
            v-for="simpleReply in filteredSimpleReplies"
            :id="simpleReply.id"
            :key="simpleReply.id"
            :name="simpleReply.name"
            :keywords="simpleReply.keywords"
            :reply="simpleReply.reply"
            :match-type="simpleReply.match_type"
            :enabled="simpleReply.enabled"
            @delete="deleteSimpleReply(simpleReply.id)"
            @update="updateSimpleReply"
          />
        </div>
      </div>
    </template>
  </PageLayout>
</template>
