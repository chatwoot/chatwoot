<script setup>
import { useI18n } from 'vue-i18n';
import { computed, ref } from 'vue';
import LinkIssue from './LinkIssue.vue';
import CreateIssue from './CreateIssue.vue';

const props = defineProps({
  accountId: {
    type: [Number, String],
    required: true,
  },
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const selectedTabIndex = ref(0);

const title = computed(() => {
  const { meta: { sender: { name = null } = {} } = {} } = props.conversation;
  return t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_TITLE', {
    conversationId: props.conversation.id,
    name,
  });
});

const tabs = ref([
  {
    key: 0,
    name: t('INTEGRATION_SETTINGS.LINEAR.CREATE'),
  },
  {
    key: 1,
    name: t('INTEGRATION_SETTINGS.LINEAR.LINK.TITLE'),
  },
]);
const onClose = () => {
  emit('close');
};

const onClickTabChange = index => {
  selectedTabIndex.value = index;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.TITLE')"
      :header-content="
        $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.DESCRIPTION')
      "
    />

    <div class="flex flex-col h-auto overflow-auto">
      <div class="flex flex-col px-8 pb-4">
        <woot-tabs
          class="ltr:[&>ul]:pl-0 rtl:[&>ul]:pr-0"
          :index="selectedTabIndex"
          @change="onClickTabChange"
        >
          <woot-tabs-item
            v-for="(tab, index) in tabs"
            :key="tab.key"
            :index="index"
            :name="tab.name"
            :show-badge="false"
          />
        </woot-tabs>
      </div>
      <div v-if="selectedTabIndex === 0" class="flex flex-col px-8 pb-4">
        <CreateIssue
          :account-id="accountId"
          :conversation-id="conversation.id"
          :title="title"
          @close="onClose"
        />
      </div>

      <div v-else class="flex flex-col px-8 pb-4">
        <LinkIssue
          :conversation-id="conversation.id"
          :title="title"
          @close="onClose"
        />
      </div>
    </div>
  </div>
</template>
