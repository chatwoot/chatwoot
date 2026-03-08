<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { format } from 'date-fns';
import AppointmentsAPI from 'dashboard/api/appointments';

import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const appointments = ref([]);
const isLoading = ref(false);
const totalEntries = ref(0);
const perPage = ref(25);
const searchValue = ref(route.query?.search || '');
const expandedRows = ref(new Set());

const toggleExpand = id => {
  const newSet = new Set(expandedRows.value);
  if (newSet.has(id)) {
    newSet.delete(id);
  } else {
    newSet.add(id);
  }
  expandedRows.value = newSet;
};

const isExpanded = id => expandedRows.value.has(id);

const currentPage = computed(() => Number(route.query.page) || 1);
const noRecordsFound = computed(() => appointments.value.length === 0);
const accountId = computed(() => store.state.auth.currentAccountId);

const STATUS_BADGE = {
  initiated: {
    bg: 'bg-n-slate-3',
    text: 'text-n-slate-11',
    icon: 'i-lucide-circle-dashed',
  },
  pending: {
    bg: 'bg-n-yellow-3',
    text: 'text-n-yellow-11',
    icon: 'i-lucide-clock',
  },
  scheduled: {
    bg: 'bg-n-blue-3',
    text: 'text-n-blue-11',
    icon: 'i-lucide-calendar-check',
  },
  completed: {
    bg: 'bg-n-teal-3',
    text: 'text-n-teal-11',
    icon: 'i-lucide-check-circle-2',
  },
  cancelled: {
    bg: 'bg-n-ruby-3',
    text: 'text-n-ruby-11',
    icon: 'i-lucide-x-circle',
  },
  no_show: {
    bg: 'bg-n-orange-3',
    text: 'text-n-orange-11',
    icon: 'i-lucide-user-x',
  },
};

const getStatusBadge = status => STATUS_BADGE[status] || STATUS_BADGE.initiated;

const formatDate = dateString => {
  if (!dateString) return '-';
  return format(new Date(dateString), 'MMM d, yyyy h:mm a');
};

const updatePageParam = (page, search = '') => {
  const query = { ...route.query, page: page.toString() };
  if (search) {
    query.search = search;
  } else {
    delete query.search;
  }
  router.replace({ query });
};

const fetchAppointments = async (page = 1) => {
  isLoading.value = true;
  try {
    const response = await AppointmentsAPI.index({
      page,
      q: searchValue.value || undefined,
    });
    appointments.value = response.data.data;
    totalEntries.value = response.data.meta.total;
    perPage.value = response.data.meta.per_page || 25;
    updatePageParam(page, searchValue.value);
  } catch {
    appointments.value = [];
  } finally {
    isLoading.value = false;
  }
};

const onPageChange = page => {
  fetchAppointments(page);
};

const onSearch = value => {
  searchValue.value = value;
  fetchAppointments(1);
};

const copyToClipboard = async url => {
  try {
    await navigator.clipboard.writeText(url);
  } catch {
    // Failed to copy
  }
};

const openLink = url => {
  window.open(url, '_blank', 'noopener,noreferrer');
};

const navigateToConversation = conversationId => {
  router.push({
    name: 'inbox_conversation',
    params: { accountId: accountId.value, conversation_id: conversationId },
  });
};

const navigateToContact = contactId => {
  router.push({
    name: 'contact_profile',
    params: { accountId: accountId.value, id: contactId },
  });
};

onMounted(() => {
  fetchAppointments(currentPage.value);
});
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <header class="sticky top-0 z-10">
        <div
          class="flex items-start sm:items-center justify-between w-full py-6 px-6 gap-2 mx-auto max-w-[60rem]"
        >
          <span class="text-xl font-medium truncate text-n-slate-12">
            {{ t('APPOINTMENTS_LIST.HEADER') }}
          </span>
          <div
            class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4"
          >
            <div class="flex items-center gap-2 w-full">
              <Input
                :model-value="searchValue"
                type="search"
                :placeholder="
                  t('APPOINTMENTS_LIST.HEADER_CONTROLS.SEARCH_PLACEHOLDER')
                "
                :custom-input-class="[
                  'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
                ]"
                class="w-full"
                @input="onSearch($event.target.value)"
              >
                <template #prefix>
                  <Icon
                    icon="i-lucide-search"
                    class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                  />
                </template>
              </Input>
            </div>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-y-auto">
        <div class="w-full mx-auto max-w-[60rem]">
          <div class="flex flex-col gap-4 px-6 pb-6">
            <div v-if="isLoading" class="flex justify-center py-10">
              <Spinner size="large" />
            </div>

            <div
              v-else-if="noRecordsFound && !searchValue && !isLoading"
              class="flex flex-col items-center justify-center py-20"
            >
              <span class="text-lg text-n-slate-11">
                {{ t('APPOINTMENTS_LIST.EMPTY_STATE') }}
              </span>
            </div>

            <table v-else class="min-w-full divide-y divide-n-weak">
              <thead>
                <tr>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.EVENT') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.CONTACT') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.STATUS') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.SCHEDULED_AT') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.CREATED_BY') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.CONVERSATION') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ t('APPOINTMENTS_LIST.TABLE.ACTIONS') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak text-n-slate-12">
                <tr v-if="noRecordsFound && searchValue">
                  <td colspan="7" class="py-10 text-center">
                    <span class="text-base text-n-slate-11">
                      {{ t('APPOINTMENTS_LIST.TABLE.NO_RESULTS_SEARCH') }}
                    </span>
                  </td>
                </tr>
                <template
                  v-for="appointment in appointments"
                  :key="appointment.id"
                >
                  <tr
                    class="cursor-pointer hover:bg-n-alpha-1 transition-colors"
                    @click="toggleExpand(appointment.id)"
                  >
                    <td class="py-4 ltr:pr-4 rtl:pl-4">
                      <div class="flex flex-col gap-0.5">
                        <span class="font-medium">
                          {{ appointment.event_type_name || '-' }}
                        </span>
                        <span class="text-xs text-n-slate-11">
                          {{ formatDate(appointment.created_at) }}
                        </span>
                      </div>
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4">
                      <button
                        v-if="appointment.contact"
                        class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
                        @click.stop="navigateToContact(appointment.contact.id)"
                      >
                        {{
                          appointment.contact.name ||
                          appointment.contact.email ||
                          appointment.contact.phone_number
                        }}
                      </button>
                      <span v-else class="text-n-slate-11">-</span>
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4">
                      <span
                        class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
                        :class="[
                          getStatusBadge(appointment.status).bg,
                          getStatusBadge(appointment.status).text,
                        ]"
                      >
                        <Icon
                          :icon="getStatusBadge(appointment.status).icon"
                          class="text-sm"
                        />
                        <span>
                          {{
                            t(
                              `APPOINTMENTS_LIST.STATUS.${appointment.status.toUpperCase()}`
                            )
                          }}
                        </span>
                      </span>
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
                      {{ formatDate(appointment.scheduled_at) }}
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
                      {{ appointment.created_by?.name || '-' }}
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4">
                      <button
                        v-if="appointment.conversation"
                        class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
                        @click.stop="
                          navigateToConversation(
                            appointment.conversation.display_id
                          )
                        "
                      >
                        #{{ appointment.conversation.display_id }}
                      </button>
                      <span v-else class="text-n-slate-11">-</span>
                    </td>
                    <td class="py-4 ltr:pr-4 rtl:pl-4">
                      <div class="flex items-center gap-2" @click.stop>
                        <Button
                          v-if="appointment.scheduling_url"
                          v-tooltip.top="t('APPOINTMENTS_LIST.TABLE.COPY_URL')"
                          icon="i-lucide-copy"
                          slate
                          xs
                          faded
                          @click="copyToClipboard(appointment.scheduling_url)"
                        />
                        <Button
                          v-if="appointment.scheduling_url"
                          v-tooltip.top="t('APPOINTMENTS_LIST.TABLE.OPEN_LINK')"
                          icon="i-lucide-external-link"
                          slate
                          xs
                          faded
                          @click="openLink(appointment.scheduling_url)"
                        />
                      </div>
                    </td>
                  </tr>
                  <tr v-if="isExpanded(appointment.id)" class="bg-n-alpha-1">
                    <td colspan="7" class="py-4 px-4">
                      <div class="ltr:ml-4 rtl:mr-4">
                        <div
                          class="grid grid-cols-2 sm:grid-cols-3 gap-4 text-sm"
                        >
                          <div class="flex flex-col gap-1">
                            <span class="text-xs font-medium text-n-slate-11">
                              {{
                                t('APPOINTMENTS_LIST.TABLE.DETAILS.PROVIDER')
                              }}
                            </span>
                            <span class="text-n-slate-12 capitalize">
                              {{ appointment.provider || '-' }}
                            </span>
                          </div>
                          <div class="flex flex-col gap-1">
                            <span class="text-xs font-medium text-n-slate-11">
                              {{
                                t(
                                  'APPOINTMENTS_LIST.TABLE.DETAILS.CONTACT_EMAIL'
                                )
                              }}
                            </span>
                            <span class="text-n-slate-12">
                              {{ appointment.contact?.email || '-' }}
                            </span>
                          </div>
                          <div class="flex flex-col gap-1">
                            <span class="text-xs font-medium text-n-slate-11">
                              {{
                                t(
                                  'APPOINTMENTS_LIST.TABLE.DETAILS.CONTACT_PHONE'
                                )
                              }}
                            </span>
                            <span class="text-n-slate-12">
                              {{ appointment.contact?.phone_number || '-' }}
                            </span>
                          </div>
                          <div class="flex flex-col gap-1">
                            <span class="text-xs font-medium text-n-slate-11">
                              {{
                                t('APPOINTMENTS_LIST.TABLE.DETAILS.EVENT_ID')
                              }}
                            </span>
                            <span class="text-n-slate-12 break-all">
                              {{ appointment.external_event_id || '-' }}
                            </span>
                          </div>
                          <div class="flex flex-col gap-1">
                            <span class="text-xs font-medium text-n-slate-11">
                              {{
                                t('APPOINTMENTS_LIST.TABLE.DETAILS.UPDATED_AT')
                              }}
                            </span>
                            <span class="text-n-slate-12">
                              {{ formatDate(appointment.updated_at) }}
                            </span>
                          </div>
                        </div>
                        <div
                          v-if="appointment.scheduling_url"
                          class="mt-3 flex items-start gap-2 text-sm text-n-slate-11"
                        >
                          <Icon icon="i-lucide-link" class="text-sm mt-0.5" />
                          <div>
                            <span class="font-medium text-n-slate-12">
                              {{
                                t(
                                  'APPOINTMENTS_LIST.TABLE.DETAILS.SCHEDULING_URL'
                                )
                              }}:
                            </span>
                            <a
                              :href="appointment.scheduling_url"
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-n-iris-9 hover:text-n-iris-10 hover:underline break-all"
                              @click.stop
                            >
                              {{ appointment.scheduling_url }}
                            </a>
                          </div>
                        </div>
                      </div>
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>

            <PaginationFooter
              v-if="appointments.length > 0"
              current-page-info="APPOINTMENTS_LIST.PAGINATION_FOOTER.SHOWING"
              :current-page="currentPage"
              :total-items="totalEntries"
              :items-per-page="perPage"
              @update:current-page="onPageChange"
            />
          </div>
        </div>
      </main>
    </div>
  </section>
</template>
