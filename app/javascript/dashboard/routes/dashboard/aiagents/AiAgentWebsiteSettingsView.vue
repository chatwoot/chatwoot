<script setup>
import { computed, nextTick, reactive, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import aiAgents from '../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import WebCollectorView from './knowledge-sources/WebCollectorView.vue';
import useVuelidate from '@vuelidate/core';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

const tabs = ref([t('AGENT_MGMT.WEBSITE_SETTINGS.BATCH_LINKS'), t('AGENT_MGMT.WEBSITE_SETTINGS.SINGLE_LINK')]);
const activeTabIndex = ref(0);
const showCollectUrlModal = ref(false);
const collectUrlEditModal = ref();
const state = reactive({
  url: '',
});
const rules = {
  url: {},
};
const validate = useVuelidate(rules, state);

function addUrl() {
  const stateUrl = state.url.trim();
  if (!stateUrl) {
    return;
  }
  collectUrlEditModal.value = {
    url: stateUrl,
    activeTabIndex: activeTabIndex.value,
  };
  showCollectUrlModal.value = false;
  nextTick(() => {
    showCollectUrlModal.value = true;
  });
}

const searchLink = ref('');

function groupBy(list, keyGetter) {
  const map = new Map();
  list.forEach(item => {
    const key = keyGetter(item);
    const collection = map.get(key);
    if (!collection) {
      map.set(key, [item]);
    } else {
      collection.push(item);
    }
  });
  return map;
}

const toggleLinks = ref({});
const links = ref([]);
const mappedLinks = computed(() => {
  return links.value.map(e => ({
    ...e,
    isSelected: ref(false),
  }));
});
const filteredLinks = computed(() => {
  return mappedLinks.value.filter(v =>
    v.parent_url.includes(searchLink.value.trim())
  );
});
const groupedLinks = computed(() => {
  return groupBy(filteredLinks.value, v => v.knowledge_source_id);
});

function selectAll(value) {
  mappedLinks.value.forEach(t => {
    t.isSelected.value = value;
  });
}

const isAllSelected = computed(() => {
  return mappedLinks.value.every(t => t.isSelected.value);
});
const hasSelectedLink = computed(() => {
  return mappedLinks.value.some(t => t.isSelected.value);
});

watch(groupedLinks, v => {
  toggleLinks.value = {};
});

const isFetching = ref(false);
async function fetchKnowledge() {
  try {
    isFetching.value = true;
    const data = await aiAgents.getKnowledgeSources(props.data.id);
    links.value = data.data?.knowledge_source_websites || [];
  } catch (e) {
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
}

watch(
  () => props.data,
  v => {
    if (!v) {
      return;
    }
    fetchKnowledge();
  },
  {
    immediate: true,
    deep: true,
  }
);

const showDeleteModal = ref();
const isDeleting = ref(false);
async function deleteData() {
  try {
    const selectedIds = mappedLinks.value
      .filter(t => t.isSelected.value)
      .map(t => t.id);
    if (!selectedIds.length) {
      return;
    }

    showDeleteModal.value = false;
    isDeleting.value = true;

    await aiAgents.deleteKnowledgeWebsite(props.data.id, {
      ids: selectedIds,
    });

    fetchKnowledge();
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.DELETE_SUCCESS'));
  } catch (e) {
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.DELETE_ERROR'));
  } finally {
    isDeleting.value = false;
  }
}

function isChildrenAllLinksSelected(links) {
  return links.every(t => !!t.isSelected.value);
}

const showEditContentModal = ref(false);
const editContentData = ref();
const contentLink = ref('');
const savingContent = ref(false);

watch(editContentData, v => {
  contentLink.value = v?.content || '';
});

async function saveContent() {
  try {
    savingContent.value = true;

    await aiAgents.editKnowledgeWebsite(props.data.id, {
      id: editContentData.value.id,
      url: editContentData.value.url,
      markdown: contentLink.value.trim(),
    });

    showEditContentModal.value = false;
    fetchKnowledge();
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.SAVE_SUCCESS'));
  } catch (e) {
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.SAVE_ERROR'));
  } finally {
    savingContent.value = false;
  }
}
</script>

<template>
  <div class="flex flex-col justify-stretch gap-4">
    <div v-if="isFetching" class="text-center">
      <span class="mt-4 mb-4 spinner" />
    </div>

    <div class="pb-4">
        <span class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.ADD_WEBSITE_LINK') }}</span>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.DESCRIPTION') }}</p>
        <div class="border-b border-gray-200 dark:border-gray-700"></div>
      <div class="py-2">
        <div>
          <div>
            <div class="flex flex-col gap-2 items-start">
              <label>{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.ADD_OTHER_LINK') }}</label>
              <woot-tabs
                :index="activeTabIndex"
                class="mb-2"
                @change="
                  i => {
                    activeTabIndex = i;
                  }
                "
              >
                <woot-tabs-item
                  v-for="(item, index) in tabs"
                  :key="item"
                  :index="index"
                  :name="item"
                  :show-badge="false"
                />
              </woot-tabs>
            </div>
            <div class="flex flex-row gap-2 items-center mb-1">
              <Input
                id="linkurl"
                v-model="state.url"
                class="flex-1"
                :placeholder="$t('AGENT_MGMT.WEBSITE_SETTINGS.ADD_LINK_PLACEHOLDER')"
              />
              <Button size="sm" @click="() => addUrl()">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.ADD_BUTTON') }}</Button>
            </div>
            <span class="text-sm">
              {{
                activeTabIndex === 0
                  ? $t('AGENT_MGMT.WEBSITE_SETTINGS.BATCH_DESCRIPTION')
                  : $t('AGENT_MGMT.WEBSITE_SETTINGS.SINGLE_DESCRIPTION')
              }}
            </span>
          </div>
        </div>
      </div>
      <WebCollectorView
        :id-agent="props.data?.id"
        :show="showCollectUrlModal"
        :existing-links="collectUrlEditModal"
        @onRefresh="() => {
          fetchKnowledge()
        }"
      />
    </div>

    <div>
      <span class="text-xl font-bold">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.TRAINED_LINKS') }}</span>
      <div class="flex flex-row gap-2 items-center mt-2">
        <div class="py-4 pr-2 flex flex-row gap-4 items-center">
          <CheckBox
            id="select-all"
            :is-checked="isAllSelected"
            :value="isAllSelected"
            @update="
              (_, value) => {
                selectAll(value);
              }
            "
          />
          <label for="select-all">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.SELECT_ALL') }}</label>
        </div>
        <Button
          v-if="hasSelectedLink"
          variant="ghost"
          icon="i-lucide-trash"
          size="sm"
          color="ruby"
          :is-loading="isDeleting"
          @click="
            () => {
              showDeleteModal = true;
            }
          "
        >
          {{ $t('AGENT_MGMT.WEBSITE_SETTINGS.DELETE_BUTTON') }}
        </Button>
        <Input v-model="searchLink" class="flex-1" :placeholder="$t('AGENT_MGMT.WEBSITE_SETTINGS.SEARCH_LINKS_PLACEHOLDER')" />
      </div>
      <div
        v-for="(item, index) in groupedLinks"
        :key="index"
        class="py-2 flex flex-row gap-4"
      >
        <CheckBox
          class="mt-5"
          :is-checked="isChildrenAllLinksSelected(item[1])"
          :value="isChildrenAllLinksSelected(item[1])"
          @update="
            (_, value) => {
              item[1].forEach(v => {
                v.isSelected.value = value;
              });
            }
          "
        />
        <div class="py-2 flex-1 min-w-0">
          <div class="flex flex-col gap-2 border border-n-gray-5 rounded-lg">
            <div class="flex flex-row gap-2 items-center py-2 px-4">
              <div class="flex-1">
                <a
                  :href="item[1][0].parent_url"
                  target="_blank"
                  class="hover:underline"
                >
                  <span class="text-base">{{ item[1][0].parent_url }}</span>
                </a>
              </div>
              <div class="flex flex-row gap-3 items-center">
                <div class="rounded-lg bg-n-gray-4 text-sm px-2 py-1">
                  <span class="font-bold">
                    {{ item[1].reduce((sum, link) => sum + (link.content?.length || 0), 0) }}
                  </span>
                  <span>{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.CHARACTERS') }}</span>
                </div>
                <div
                  class="rounded-lg bg-n-gray-4 text-sm px-2 py-1 cursor-pointer flex flex-row items-center gap-1"
                  @click="
                    () => {
                      toggleLinks[index] = !toggleLinks[index];
                    }
                  "
                >
                  <span class="font-bold">
                    {{ item[1].length }}
                  </span>
                  <span>{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.LINKS') }}</span>
                  <span
                    :class="
                      toggleLinks[index]
                        ? 'i-lucide-chevron-up'
                        : 'i-lucide-chevron-down'
                    "
                    class="size-5"
                    aria-hidden="true"
                  />
                </div>
              </div>
            </div>
            <div
              v-if="toggleLinks[index]"
              class="flex flex-col px-4 gap-3 pb-4"
            >
              <span class="text-sm font-bold">{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.LINKS') }}</span>
              <div
                v-for="(linkItem, linkIndex) in item[1]"
                :key="linkIndex"
                class="flex flex-row gap-2"
              >
                <div class="flex-1 flex flex-row gap-4 items-center">
                  <CheckBox
                    :is-checked="linkItem.isSelected.value"
                    :value="linkItem.isSelected.value"
                    @update="
                      (_, value) => {
                        linkItem.isSelected.value = value;
                      }
                    "
                  />
                  <div
                    class="bg-n-gray-4 px-4 py-1 cursor-pointer flex-1"
                    @click="
                      () => {
                        linkItem.isSelected.value = !linkItem.isSelected.value;
                      }
                    "
                  >
                    <a
                      :href="linkItem.url"
                      target="_blank"
                      class="hover:underline"
                    >
                      <span class="text-base">{{ linkItem.url }}</span>
                    </a>
                  </div>
                </div>
                <Button
                  variant="ghost"
                  icon="i-lucide-pencil"
                  size="sm"
                  @click="
                    () => {
                      editContentData = linkItem;
                      showEditContentModal = true;
                    }
                  "
                >
                  {{ $t('AGENT_MGMT.WEBSITE_SETTINGS.EDIT_BUTTON') }}
                </Button>
                <div
                  class="bg-n-gray-4 text-sm px-2 py-1 flex flex-row gap-1 items-center"
                >
                  <span class="font-bold">
                    {{ linkItem.content?.length || 0 }}
                  </span>
                  <span>{{ $t('AGENT_MGMT.WEBSITE_SETTINGS.CHARACTERS') }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      class="context-menu--delete-modal"
      :on-close="
        () => {
          showDeleteModal = false;
        }
      "
      :on-confirm="() => deleteData()"
      :title="$t('AGENT_MGMT.WEBSITE_SETTINGS.DELETE_MODAL_TITLE')"
      :message="$t('AGENT_MGMT.WEBSITE_SETTINGS.DELETE_MODAL_MESSAGE')"
      :confirm-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.DELETE')"
      :reject-text="$t('CONVERSATION.CONTEXT_MENU.DELETE_CONFIRMATION.CANCEL')"
    />

    <woot-modal
      :show="showEditContentModal"
      :on-close="
        () => {
          showEditContentModal = false;
        }
      "
    >
      <woot-modal-header
        :header-title="$t('AGENT_MGMT.WEBSITE_SETTINGS.EDIT_CONTENT_MODAL_TITLE')"
        :header-content="editContentData?.url"
      />

      <div class="px-8 py-4">
        <div>
          <TextArea
            id="system_prompts"
            v-model="contentLink"
            custom-text-area-wrapper-class=""
            custom-text-area-class="!outline-none"
            auto-height
          />
        </div>
      </div>

      <div class="flex items-center justify-end gap-2 px-8 pt-4 pb-8">
        <Button
          class="w-full button success expanded nice"
          :is-loading="savingContent"
          :disabled="savingContent"
          @click="
            () => {
              saveContent();
            }
          "
        >
          {{ $t('AGENT_MGMT.WEBSITE_SETTINGS.SAVE_BUTTON') }}
        </Button>
      </div>
    </woot-modal>
  </div>
</template>

<style lang="css">
.note-editing-area {
  background: white;
}
.tabs-rm-margin .tabs {
  padding-left: 0px !important;
}
</style>
