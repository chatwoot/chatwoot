<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import AddLocation from './AddLocation.vue';
import EditLocation from './EditLocation.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLocation = ref({});
const expandedLocations = ref(new Set());

const locationTree = computed(() => getters['locations/getLocationTree'].value);
const uiFlags = computed(() => getters['locations/getUIFlags'].value);

const toggleExpand = locationId => {
  const next = new Set(expandedLocations.value);
  if (next.has(locationId)) {
    next.delete(locationId);
  } else {
    next.add(locationId);
  }
  expandedLocations.value = next;
};

const isExpanded = locationId => expandedLocations.value.has(locationId);

const allRecords = computed(() => getters['locations/getLocations'].value);
const deleteMessage = computed(() => ` ${selectedLocation.value.name}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = location => {
  showEditPopup.value = true;
  selectedLocation.value = location;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = location => {
  showDeleteConfirmationPopup.value = true;
  selectedLocation.value = location;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteLocation = async id => {
  try {
    await store.dispatch('locations/delete', id);
    useAlert(t('LOCATIONS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LOCATIONS.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedLocation.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedLocation.value.id] = true;
  closeDeletePopup();
  deleteLocation(selectedLocation.value.id);
};

onBeforeMount(() => {
  store.dispatch('locations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LOCATIONS.LOADING')"
    :no-records-found="!allRecords.length"
    :no-records-message="$t('LOCATIONS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('LOCATIONS.HEADER')"
        :description="$t('LOCATIONS.DESCRIPTION')"
        :link-text="$t('LOCATIONS.LEARN_MORE')"
        feature-name="locations"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('LOCATIONS.HEADER_BTN_TXT')"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <template v-for="location in locationTree" :key="location.id">
            <!-- Parent row -->
            <tr class="bg-n-solid-2">
              <td
                class="py-4 px-4"
                :class="isExpanded(location.id) ? 'ltr:border-l-2 rtl:border-r-2 border-n-solid-2' : ''"
              >
                <div class="flex items-start gap-2">
                  <button
                    v-if="location.children?.length"
                    class="mt-0.5 shrink-0 text-n-slate-11 hover:text-n-slate-12 transition-colors"
                    @click="toggleExpand(location.id)"
                  >
                    <span
                      :class="isExpanded(location.id) ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
                      class="w-4 h-4"
                    />
                  </button>
                  <span v-else class="w-4 h-4 shrink-0" />
                  <div class="flex flex-col gap-0.5">
                    <div class="flex items-center gap-2">
                      <span class="font-medium break-words text-n-slate-12">
                        {{ location.name }}
                      </span>
                      <span
                        v-if="location.children?.length"
                        class="inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-n-solid-3 text-n-slate-11"
                      >
                        {{ location.children.length }}
                      </span>
                    </div>
                    <span class="text-sm text-n-slate-11 break-words">
                      {{ location.description }}
                    </span>
                  </div>
                </div>
              </td>
              <td class="py-4 ltr:pr-4 rtl:pl-4">
                <span
                  v-if="location.type_name"
                  class="px-2 py-0.5 text-xs rounded-full bg-n-solid-3 text-n-slate-11 whitespace-nowrap"
                >
                  {{ location.type_name }}
                </span>
              </td>
              <td class="py-4 ltr:pr-4 rtl:pl-4">
                <div v-if="location.address" class="flex flex-col">
                  <span class="text-sm text-n-slate-12">
                    {{ location.address.city }}
                  </span>
                  <span class="text-xs text-n-slate-11">
                    {{ location.address.state }}
                  </span>
                </div>
              </td>
              <td class="py-4 ltr:pr-4 rtl:pl-4" />
              <td class="py-4 ltr:pr-4 rtl:pl-4 min-w-xs" :class="isExpanded(location.id) ? 'ltr:border-r-2 rtl:border-l-2 border-n-solid-2' : ''"  >
                <div class="flex gap-1 justify-end">
                  <Button
                    v-tooltip.top="$t('LOCATIONS.FORM.EDIT')"
                    icon="i-lucide-pen"
                    slate
                    xs
                    faded
                    :is-loading="loading[location.id]"
                    @click="openEditPopup(location)"
                  />
                  <Button
                    v-tooltip.top="$t('LOCATIONS.FORM.DELETE')"
                    icon="i-lucide-trash-2"
                    xs
                    ruby
                    faded
                    :is-loading="loading[location.id]"
                    @click="openDeletePopup(location)"
                  />
                </div>
              </td>
            </tr>

            <!-- Child rows -->
            <template v-if="isExpanded(location.id)">
              <tr
                v-for="(child, childIndex) in location.children"
                :key="child.id"
              >
                <td class="py-0 ltr:pr-4 rtl:pl-4 ltr:border-l-2 rtl:border-r-2 border-n-solid-2 ltr:pl-3.5 rtl:pr-3.5">
                  <div class="flex items-start gap-2 ltr:pl-5 rtl:pr-5">
                    <!-- Tree connector: vertical line + horizontal branch -->
                    <div class="flex flex-col items-center self-stretch shrink-0 w-3">
                      <div class="w-px flex-1 bg-n-weak" />
                      <div class="w-full h-px bg-n-weak" />
                      <div
                        class="w-px flex-1"
                        :class="childIndex < location.children.length - 1 ? 'bg-n-weak' : 'bg-transparent'"
                      />
                    </div>
                    <div class="flex flex-col gap-0.5 py-1">
                      <span class="font-medium break-words text-n-slate-12">
                        {{ child.name }}
                      </span>
                      <span class="text-sm text-n-slate-11 break-words">
                        {{ child.description }}
                      </span>
                    </div>
                  </div>
                </td>
                <td class="py-0 ltr:pr-4 rtl:pl-4">
                  <span
                    v-if="child.type_name"
                    class="px-2 py-0.5 text-xs rounded-full bg-n-solid-3 text-n-slate-11 whitespace-nowrap"
                  >
                    {{ child.type_name }}
                  </span>
                </td>
                <td class="py-0 ltr:pr-4 rtl:pl-4">
                  <div v-if="child.address" class="flex flex-col">
                    <span class="text-sm text-n-slate-12">
                      {{ child.address.city }}
                    </span>
                    <span class="text-xs text-n-slate-11">
                      {{ child.address.state }}
                    </span>
                  </div>
                </td>
                <td class="py-0 ltr:pr-4 rtl:pl-4" />
                <td class="py-0 ltr:pr-4 rtl:pl-4 min-w-xs ltr:border-r-2 rtl:border-l-2 border-n-solid-2">
                  <div class="flex gap-1 justify-end">
                    <Button
                      v-tooltip.top="$t('LOCATIONS.FORM.EDIT')"
                      icon="i-lucide-pen"
                      slate
                      xs
                      faded
                      :is-loading="loading[child.id]"
                      @click="openEditPopup(child)"
                    />
                    <Button
                      v-tooltip.top="$t('LOCATIONS.FORM.DELETE')"
                      icon="i-lucide-trash-2"
                      xs
                      ruby
                      faded
                      :is-loading="loading[child.id]"
                      @click="openDeletePopup(child)"
                    />
                  </div>
                </td>
              </tr>
            </template>
          </template>
        </tbody>
      </table>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddLocation @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditLocation :selected-location="selectedLocation" @close="hideEditPopup" />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LOCATIONS.DELETE.CONFIRM.TITLE')"
      :message="$t('LOCATIONS.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('LOCATIONS.DELETE.CONFIRM.YES')"
      :reject-text="$t('LOCATIONS.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
