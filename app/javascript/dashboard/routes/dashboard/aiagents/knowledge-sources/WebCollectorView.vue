<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { computed, reactive, ref, watch } from 'vue';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import useVuelidate from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import aiAgents from '../../../../api/aiAgents';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  idAgent: {
    type: Object,
    required: true,
  },
  existingLinks: {
    type: Object,
    required: true,
  },
});

const showModel = defineModel('show');

watch(
  () => props.existingLinks,
  v => {
    if (v) {
      state.url = v.url;
      activeTabIndex.value = v.activeTabIndex;
      addUrl();
    }
  },
  {
    immediate: true,
    deep: true,
  }
);

const tabs = ref(['Tautan batch', 'Tautan Tunggal']);
const activeTabIndex = ref(0);

const links = ref([]);
watch(
  () => showModel.value,
  v => {
    if (!v) {
      links.value = [];
    }
  }
);
const mappedLinks = computed(() => {
  return links.value.map(e => ({
    ...e,
    toggleView: ref(false),
    hasSelectedChild:
      e.children && e.children.length
        ? computed(() => {
            return e.children.some(t => t.isSelected);
          })
        : ref(false),
    isSelected:
      e.children && e.children.length
        ? computed(() => {
            const isAllChildrenSelected = e.children.every(t => t.isSelected);
            return isAllChildrenSelected;
          })
        : ref(false),
  }));
});

const state = reactive({
  url: '',
});
const v$ = useVuelidate(
  {
    url: { required },
  },
  state
);
const addingUrl = ref(false);
async function addUrl() {
  if (!(await v$.value.$validate())) {
    return;
  }

  try {
    addingUrl.value = true;

    const stateUrl = state.url;
    if (activeTabIndex.value === 0) {
      const response = await aiAgents.collectKnowledgeLinksWebsite(
        props.idAgent,
        {
          url: stateUrl,
        }
      );
      links.value.splice(0, 0, {
        url: stateUrl,
        children: response.links.map(e => ({
          url: e,
          isSelected: false,
        })),
      });
    } else if (activeTabIndex.value === 1) {
      links.value.splice(0, 0, {
        url: stateUrl,
      });
    }
    state.url = '';
  } catch (e) {
    useAlert('Gagal menambah link');
  } finally {
    addingUrl.value = false;
  }
}

const hasSelectedItem = computed(() => {
  return mappedLinks.value.some(t =>
    t.children && t.children.length
      ? t.hasSelectedChild.value
      : t.isSelected.value
  );
});
function selectAll() {
  const isFirstSelected = mappedLinks.value.length
    ? mappedLinks.value[0].isSelected.value
    : false;
  mappedLinks.value.forEach(v => {
    v.isSelected.value = !isFirstSelected;

    v.children?.forEach(e => {
      e.isSelected = !isFirstSelected;
    });
  });
}

const isTraining = ref(false);
async function train() {
  try {
    isTraining.value = true;

    const selectedLinks = [];
    mappedLinks.value.forEach(t => {
      if (t.children && t.children.length) {
        t.children.forEach(v => {
          if (v.isSelected) {
            selectedLinks.push(v.url);
          }
        });
      } else if (t.isSelected.value) {
        selectedLinks.push(t.url);
      }
    });
    await aiAgents.addKnowledgeWebsite(props.idAgent, {
      links: selectedLinks,
    });
  } catch (e) {
    useAlert('Gagal train link');
  } finally {
    isTraining.value = false;
  }
}
</script>

<template>
  <woot-modal
    :show="showModel"
    :on-close="
      () => {
        showModel = false;
      }
    "
    size="w-[1024px]"
    modal
  >
    <woot-modal-header header-title="Kumpulan Link" header-content="" />
    <div class="px-8 py-4 flex flex-col gap-2">
      <div>
        <div class="flex flex-row gap-2 items-center">
          <label>Tambah Link Lain</label>
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
        <div class="flex flex-row gap-2 items-center">
          <Input v-model="state.url" class="flex-1" placeholder="Cari links" />
          <Button
            size="sm"
            :is-loading="addingUrl"
            :disabled="addingUrl || v$.$invalid"
            @click="() => addUrl()"
          >
            Tambah
          </Button>
        </div>
      </div>
      <div class="flex flex-row gap-2 mt-3">
        <Button size="sm" variant="outline" @click="selectAll">
          Pilih Semua
        </Button>
        <Button
          size="sm"
          :is-loading="isTraining"
          :disabled="!hasSelectedItem || isTraining"
          @click="() => train()"
        >
          Train
        </Button>
      </div>
      <div class="flex flex-col gap-0">
        <div
          v-for="(item, index) in mappedLinks"
          :key="index"
          class="flex flex-row gap-4"
        >
          <CheckBox
            class="mt-5"
            :is-checked="item.isSelected.value"
            :value="item.isSelected.value"
            @update="
              (_, value) => {
                if (item.children && item.children.length) {
                  item.children.forEach(v => {
                    v.isSelected = value;
                  });
                } else {
                  item.isSelected.value = value;
                }
              }
            "
          />
          <div class="py-2 flex-1 min-w-0">
            <div class="flex flex-col gap-2 border border-n-gray-5 rounded-lg">
              <div class="flex flex-row gap-2 items-center py-2 px-4">
                <div class="flex-1">
                  <a :href="item.url" target="_blank" class="hover:underline">
                    <span class="text-base">{{ item.url }}</span>
                  </a>
                </div>
                <div
                  v-if="item.children && item.children.length"
                  class="flex flex-row gap-3 items-center"
                >
                  >
                  <div
                    class="rounded-lg bg-n-gray-4 text-sm px-2 py-1 cursor-pointer flex flex-row items-center gap-1"
                    @click="
                      () => {
                        item.toggleView.value = !item.toggleView.value;
                      }
                    "
                  >
                    <span class="font-bold">
                      {{ item.children.length }}
                    </span>
                    <span> links </span>
                    <span
                      :class="
                        item.toggleView.value
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
                v-if="
                  item.children && item.children.length && item.toggleView.value
                "
                class="flex flex-col px-4 gap-3 pb-4"
              >
                " >
                <span class="text-sm font-bold"> Links </span>
                <div
                  v-for="(item, index) in item.children"
                  :key="index"
                  class="flex flex-row gap-2"
                >
                  <div class="flex-1 flex flex-row gap-4 items-center">
                    <CheckBox
                      :is-checked="item.isSelected"
                      :value="item.isSelected"
                      @update="
                        (_, value) => {
                          item.isSelected = value;
                        }
                      "
                    />
                    <div
                      class="bg-n-gray-4 px-4 py-1 cursor-pointer"
                      @click="
                        () => {
                          item.isSelected = item.isSelected ? false : true;
                        }
                      "
                    >
                      <a
                        :href="item.url"
                        target="_blank"
                        class="hover:underline"
                      >
                        <span class="text-base">{{ item.url }}</span>
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<style>
.tabs-rm-margin .tabs {
  padding-left: 0px !important;
}
</style>
