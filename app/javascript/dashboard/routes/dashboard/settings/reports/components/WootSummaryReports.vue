<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      v-if="!showAdvancedFilters"
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ downloadButtonLabel }}
    </woot-button>
    <div
      v-if="agentTableType === 'overview'"
      class="flex items-center button--fixed-top w-[350px]"
    >
      <span class="mr-2 text-sm w-[125px]">Metrics type</span>
      <multiselect
        v-model="selectedMetricType"
        class="no-margin"
        :placeholder="'Select metrics type'"
        :options="metricTypeOptions"
        :option-height="20"
        :show-labels="false"
        @input="onMetricTypeChange"
      />
    </div>
    <report-filter-selector
      :show-agents-filter="false"
      :show-labels-filter="showAdvancedFilters"
      :show-inbox-filter="
        showAdvancedFilters && agentTableType !== 'callOverview'
      "
      @filter-change="onFilterChange"
    />
    <ve-table
      max-height="calc(100vh - 21.875rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
      :scroll-width="scrollWidth"
      style="overflow-x: auto"
    />
  </div>
</template>

<script>
import ReportFilterSelector from './FilterSelector.vue';
import { formatTime } from '@chatwoot/utils';

import reportMixin from '../../../../../mixins/reportMixin';
import alertMixin from 'shared/mixins/alertMixin';

import { generateFileName } from '../../../../../helper/downloadHelper';
import { VeTable } from 'vue-easytable';

export default {
  components: {
    VeTable,
    ReportFilterSelector,
  },
  mixins: [reportMixin, alertMixin],
  props: {
    type: {
      type: String,
      default: 'account',
    },
    getterKey: {
      type: String,
      default: '',
    },
    actionKey: {
      type: String,
      default: '',
    },
    summaryKey: {
      type: String,
      default: '',
    },
    downloadButtonLabel: {
      type: String,
      default: 'Download Reports',
    },
    showAdvancedFilters: {
      type: Boolean,
      default: false,
    },
    agentTableType: {
      type: String,
      default: 'default',
    },
  },
  data() {
    return {
      from: 0,
      to: 0,
      selectedFilter: null,
      businessHours: false,
      selectedMetricType: 'Average',
      activeDropdownId: null,
    };
  },
  computed: {
    scrollWidth() {
      // Calculate the total width based on the number of columns
      // Assuming a minimum width of 150px per column
      return `${this.columns.length * 150}px`;
    },
    metricTypeOptions() {
      return ['Average', 'Median'];
    },
    columns() {
      // TODO: make a format to add definitions with ?
      if (this.agentTableType === 'overview') {
        const baseColumns = [
          {
            field: 'agent',
            key: 'agent',
            title: this.type,
            fixed: 'left',
            align: this.isRTLView ? 'right' : 'left',
            width: 25,
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <div class="user-block">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                    {row.name}
                  </h6>
                </div>
              </div>
            ),
          },
          {
            field: 'resolutionsCount',
            key: 'resolutionsCount',
            title: 'Resolved',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
        ];

        if (this.selectedMetricType === 'Median') {
          baseColumns.push(
            {
              field: 'medianFirstResponseTime',
              key: 'medianFirstResponseTime',
              title: 'Median first response time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            },
            {
              field: 'medianResolutionTime',
              key: 'medianResolutionTime',
              title: 'Median resolution time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
              renderBodyCell: ({ row }) => (
                <div class="relative">
                  <div class="flex items-center gap-2">
                    <span>{row.medianResolutionTime}</span>
                    <button
                      class="text-gray-600 hover:text-gray-900"
                      onClick={e => {
                        e.stopPropagation();
                        this.toggleDropdown(row.id);
                      }}
                    >
                      <svg
                        width="14"
                        height="14"
                        viewBox="0 0 14 14"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <g clip-path="url(#clip0_1587_43802)">
                          <path
                            d="M11.7791 5.08266C11.746 5.00271 11.69 4.93437 11.618 4.88628C11.5461 4.83819 11.4615 4.81252 11.375 4.8125H2.62499C2.53841 4.81243 2.45376 4.83805 2.38175 4.88612C2.30974 4.93419 2.25361 5.00254 2.22047 5.08253C2.18733 5.16251 2.17866 5.25053 2.19557 5.33545C2.21248 5.42036 2.25421 5.49834 2.31546 5.55953L6.69046 9.93453C6.73109 9.97521 6.77934 10.0075 6.83246 10.0295C6.88557 10.0515 6.9425 10.0628 6.99999 10.0628C7.05749 10.0628 7.11442 10.0515 7.16753 10.0295C7.22064 10.0075 7.26889 9.97521 7.30952 9.93453L11.6845 5.55953C11.7457 5.49831 11.7873 5.42033 11.8042 5.33545C11.821 5.25056 11.8123 5.16259 11.7791 5.08266Z"
                            fill="#999999"
                          />
                        </g>
                        <defs>
                          <clipPath id="clip0_1587_43802">
                            <rect width="14" height="14" fill="white" />
                          </clipPath>
                        </defs>
                      </svg>
                    </button>
                  </div>
                  {this.activeDropdownId === row.id && (
                    <div class="absolute rounded-lg bg-slate-25 dark:bg-slate-900 shadow-lg w-[256px] z-[3] left-0 mt-1">
                      <div class="">
                        <div class="flex justify-between items-center border-b !px-3 !py-1 mb-4">
                          <span class="font-medium">
                            Median Resolution Time Split
                          </span>
                          <woot-button
                            color-scheme="secondary"
                            icon="dismiss"
                            variant="clear"
                            onClick={e => {
                              e.stopPropagation();
                              this.toggleDropdown(null);
                            }}
                          />
                        </div>
                        <div class="space-y-3 !p-3">
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">
                              New Assigned
                            </span>
                            <span>
                              {
                                row.medianResolutionTimeOfNewAssignedConversations
                              }
                            </span>
                          </div>
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">Reopened</span>
                            <span>
                              {row.medianResolutionTimeOfReopenedConversations}
                            </span>
                          </div>
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">
                              Carry forwarded
                            </span>
                            <span>
                              {
                                row.medianResolutionTimeOfCarryForwardedConversations
                              }
                            </span>
                          </div>
                          <div class="flex justify-between items-center !pt-3 border-t">
                            <span class="text-gray-600 text-xs">Median</span>
                            <span>{row.medianResolutionTime}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ),
            },
            {
              field: 'medianResponseTime',
              key: 'medianResponseTime',
              title: 'Median response time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            },
            {
              field: 'medianCsatScore',
              key: 'medianCsatScore',
              title: 'Median CSAT score',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            }
          );
        }

        if (this.selectedMetricType === 'Average') {
          baseColumns.push(
            {
              field: 'avgFirstResponseTime',
              key: 'avgFirstResponseTime',
              title: 'Avg. first response time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            },
            {
              field: 'avgResolutionTime',
              key: 'avgResolutionTime',
              title: 'Avg. resolution time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
              renderBodyCell: ({ row }) => (
                <div class="relative">
                  <div class="flex items-center gap-2">
                    <span>{row.avgResolutionTime}</span>
                    <button
                      class="text-gray-600 hover:text-gray-900"
                      onClick={e => {
                        e.stopPropagation();
                        this.toggleDropdown(row.id);
                      }}
                    >
                      <svg
                        width="14"
                        height="14"
                        viewBox="0 0 14 14"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <g clip-path="url(#clip0_1587_43802)">
                          <path
                            d="M11.7791 5.08266C11.746 5.00271 11.69 4.93437 11.618 4.88628C11.5461 4.83819 11.4615 4.81252 11.375 4.8125H2.62499C2.53841 4.81243 2.45376 4.83805 2.38175 4.88612C2.30974 4.93419 2.25361 5.00254 2.22047 5.08253C2.18733 5.16251 2.17866 5.25053 2.19557 5.33545C2.21248 5.42036 2.25421 5.49834 2.31546 5.55953L6.69046 9.93453C6.73109 9.97521 6.77934 10.0075 6.83246 10.0295C6.88557 10.0515 6.9425 10.0628 6.99999 10.0628C7.05749 10.0628 7.11442 10.0515 7.16753 10.0295C7.22064 10.0075 7.26889 9.97521 7.30952 9.93453L11.6845 5.55953C11.7457 5.49831 11.7873 5.42033 11.8042 5.33545C11.821 5.25056 11.8123 5.16259 11.7791 5.08266Z"
                            fill="#999999"
                          />
                        </g>
                        <defs>
                          <clipPath id="clip0_1587_43802">
                            <rect width="14" height="14" fill="white" />
                          </clipPath>
                        </defs>
                      </svg>
                    </button>
                  </div>
                  {this.activeDropdownId === row.id && (
                    <div class="absolute rounded-lg bg-slate-25 dark:bg-slate-900 shadow-lg w-[256px] z-[3] left-0 mt-1">
                      <div class="">
                        <div class="flex justify-between items-center border-b !px-3 !py-1 mb-4">
                          <span class="font-medium">
                            Avg Resolution Time Split
                          </span>
                          <woot-button
                            color-scheme="secondary"
                            icon="dismiss"
                            variant="clear"
                            onClick={e => {
                              e.stopPropagation();
                              this.toggleDropdown(null);
                            }}
                          />
                        </div>
                        <div class="space-y-3 !p-3">
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">
                              New Assigned
                            </span>
                            <span>
                              {row.avgResolutionTimeOfNewAssignedConversations}
                            </span>
                          </div>
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">Reopened</span>
                            <span>
                              {row.avgResolutionTimeOfReopenedConversations}
                            </span>
                          </div>
                          <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-xs">
                              Carry forwarded
                            </span>
                            <span>
                              {
                                row.avgResolutionTimeOfCarryForwardedConversations
                              }
                            </span>
                          </div>
                          <div class="flex justify-between items-center !pt-3 border-t">
                            <span class="text-gray-600 text-xs">Average</span>
                            <span>{row.avgResolutionTime}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ),
            },
            {
              field: 'avgResponseTime',
              key: 'avgResponseTime',
              title: 'Avg. response time',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            },
            {
              field: 'avgCsatScore',
              key: 'avgCsatScore',
              title: 'Avg. CSAT score',
              align: this.isRTLView ? 'right' : 'left',
              width: 20,
            }
          );
        }
        return baseColumns;
      }

      if (this.agentTableType === 'conversationStates') {
        const baseColumns = [
          {
            field: 'agent',
            key: 'agent',
            title: this.type,
            fixed: 'left',
            align: this.isRTLView ? 'right' : 'left',
            width: 25,
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <div class="user-block">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                    {row.name}
                  </h6>
                </div>
              </div>
            ),
          },
          {
            field: 'handled',
            key: 'handled',
            title: 'Handled',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'newAssigned',
            key: 'newAssigned',
            title: 'New Assigned',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'open',
            key: 'open',
            title: 'Open',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'reopened',
            key: 'reopened',
            title: 'Reopened',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'carryForwarded',
            key: 'carryForwarded',
            title: 'Carry Forwarded',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'resolved',
            key: 'resolved',
            title: 'Resolved',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'waitingAgentResponse',
            key: 'waitingAgentResponse',
            title: 'Waiting agent response',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'waitingCustomerResponse',
            key: 'waitingCustomerResponse',
            title: 'Waiting customer response',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'snoozed',
            key: 'snoozed',
            title: 'Snoozed',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
        ];

        return baseColumns;
      }

      if (this.agentTableType === 'callOverview') {
        const baseColumns = [
          {
            field: 'agent',
            key: 'agent',
            title: this.type,
            fixed: 'left',
            align: this.isRTLView ? 'right' : 'left',
            width: 25,
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <div class="user-block">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                    {row.name}
                  </h6>
                </div>
              </div>
            ),
          },
          {
            field: 'totalCallingNudgedConversations',
            key: 'totalCallingNudgedConversations',
            title: 'Total Calls',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'scheduledCallConversations',
            key: 'scheduledCallConversations',
            title: 'Scheduled',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'notPickedUpCallConversations',
            key: 'notPickedUpCallConversations',
            title: 'Not Picked',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'followUpCallConversations',
            key: 'followUpCallConversations',
            title: 'Follow-Up',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'convertedCallConversations',
            key: 'convertedCallConversations',
            title: 'Converted',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'droppedCallConversations',
            key: 'droppedCallConversations',
            title: 'Dropped',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgTimeToCallAfterNudge',
            key: 'avgTimeToCallAfterNudge',
            title: 'Avg. Time to Call after nudge',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgTimeToConvert',
            key: 'avgTimeToConvert',
            title: 'Avg. Time to Convert',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgTimeToDrop',
            key: 'avgTimeToDrop',
            title: 'Avg. Time to Drop',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgFollowUpCalls',
            key: 'avgFollowUpCalls',
            title: 'Avg. Follow-Up Calls',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
        ];

        return baseColumns;
      }

      if (this.agentTableType === 'inboundCallOverview') {
        const baseColumns = [
          {
            field: 'agent',
            key: 'agent',
            title: this.type,
            fixed: 'left',
            align: this.isRTLView ? 'right' : 'left',
            width: 25,
            renderBodyCell: ({ row }) => (
              <div class="row-user-block">
                <div class="user-block">
                  <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                    {row.name}
                  </h6>
                </div>
              </div>
            ),
          },
          {
            field: 'totalInboundCallsHandled',
            key: 'totalInboundCallsHandled',
            title: 'Total Calls Handled',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'totalCallsConnected',
            key: 'totalCallsConnected',
            title: 'Calls Connected',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'totalCallsMissed',
            key: 'totalCallsMissed',
            title: 'Calls Missed',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'inboundCallsResolved',
            key: 'inboundCallsResolved',
            title: 'Resolved',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgCallHandlingTime',
            key: 'avgCallHandlingTime',
            title: 'AHT(Avg. Handling Time)',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'avgCallWaitTime',
            key: 'avgCallWaitTime',
            title: 'Avg. Wait Time',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
        ];

        return baseColumns;
      }

      const baseColumns = [
        {
          field: 'agent',
          key: 'agent',
          title: this.type,
          fixed: 'left',
          align: this.isRTLView ? 'right' : 'left',
          width: 25,
          renderBodyCell: ({ row }) => (
            <div class="row-user-block">
              <div class="user-block">
                <h6 class="title overflow-hidden whitespace-nowrap text-ellipsis text-sm capitalize">
                  {row.name}
                </h6>
              </div>
            </div>
          ),
        },
        {
          field: 'conversationsCount',
          key: 'conversationsCount',
          title: 'Assigned',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'resolutionsCount',
          key: 'resolutionsCount',
          title: 'Resolved',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgFirstResponseTime',
          key: 'avgFirstResponseTime',
          title: 'Avg. first response time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
        {
          field: 'avgResolutionTime',
          key: 'avgResolutionTime',
          title: 'Avg. resolution time',
          align: this.isRTLView ? 'right' : 'left',
          width: 20,
        },
      ];

      if (this.type === 'agent') {
        baseColumns.push(
          {
            field: 'onlineTime',
            key: 'onlineTime',
            title: 'Online Time',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          },
          {
            field: 'busyTime',
            key: 'busyTime',
            title: 'Busy Time',
            align: this.isRTLView ? 'right' : 'left',
            width: 20,
          }
        );
      }

      return baseColumns;
    },
    tableData() {
      const bitespeedTeam = this.filterItemsList.find(team =>
        team.name.toLowerCase().includes('bitespeed')
      );
      const otherTeams = this.filterItemsList.filter(
        team => !team.name.toLowerCase().includes('bitespeed')
      );
      let combinedTeams = otherTeams;

      if (bitespeedTeam) {
        if (this.agentTableType === 'inboundCallOverview') {
          // For inbound call overview, rename Bitespeed to Unassigned
          const unassignedTeam = { ...bitespeedTeam, name: 'Unassigned' };
          combinedTeams = [unassignedTeam, ...otherTeams];
        } else if (this.agentTableType !== 'callOverview') {
          // For all other tables except callOverview, include Bitespeed team as is
          combinedTeams = [bitespeedTeam, ...otherTeams];
        }
      }

      if (this.agentTableType === 'overview') {
        // if have "Bitespeed" in the name, then it should be top of the array.
        return combinedTeams.map(team => {
          const typeMetrics = this.getMetrics(team.id);
          return {
            id: team.id,
            name: team.name,
            resolutionsCount: typeMetrics.resolved || '--',
            avgFirstResponseTime:
              this.renderContent(typeMetrics.avg_first_response_time) || '--',
            avgResolutionTime:
              this.renderContent(typeMetrics.avg_resolution_time) || '--',
            avgResolutionTimeOfNewAssignedConversations:
              this.renderContent(
                typeMetrics.avg_resolution_time_of_new_assigned_conversations
              ) || '--',
            avgResolutionTimeOfCarryForwardedConversations:
              this.renderContent(
                typeMetrics.avg_resolution_time_of_carry_forwarded_conversations
              ) || '--',
            avgResolutionTimeOfReopenedConversations:
              this.renderContent(
                typeMetrics.avg_resolution_time_of_reopened_conversations
              ) || '--',
            avgResponseTime:
              this.renderContent(typeMetrics.avg_response_time) || '--',
            avgCsatScore:
              this.renderContent(typeMetrics.avg_csat_score) || '--',
            medianFirstResponseTime:
              this.renderContent(typeMetrics.median_first_response_time) ||
              '--',
            medianResolutionTime:
              this.renderContent(typeMetrics.median_resolution_time) || '--',
            medianResolutionTimeOfNewAssignedConversations:
              this.renderContent(
                typeMetrics.median_resolution_time_of_new_assigned_conversations
              ) || '--',
            medianResolutionTimeOfCarryForwardedConversations:
              this.renderContent(
                typeMetrics.median_resolution_time_of_carry_forwarded_conversations
              ) || '--',
            medianResolutionTimeOfReopenedConversations:
              this.renderContent(
                typeMetrics.median_resolution_time_of_reopened_conversations
              ) || '--',
            medianResponseTime:
              this.renderContent(typeMetrics.median_response_time) || '--',
            medianCsatScore:
              this.renderContent(typeMetrics.median_csat_score) || '--',
          };
        });
      }

      if (this.agentTableType === 'conversationStates') {
        return combinedTeams.map(team => {
          const typeMetrics = this.getMetrics(team.id);
          return {
            name: team.name,
            handled: typeMetrics.handled || '--',
            newAssigned: typeMetrics.new_assigned || '--',
            open: typeMetrics.open || '--',
            reopened: typeMetrics.reopened || '--',
            carryForwarded: typeMetrics.carry_forwarded || '--',
            resolved: typeMetrics.resolved || '--',
            waitingCustomerResponse:
              typeMetrics.waiting_customer_response || '--',
            waitingAgentResponse: typeMetrics.waiting_agent_response || '--',
            snoozed: typeMetrics.snoozed || '--',
          };
        });
      }

      if (this.agentTableType === 'callOverview') {
        return combinedTeams.map(team => {
          const typeMetrics = this.getMetrics(team.id);
          return {
            name: team.name,
            totalCallingNudgedConversations:
              typeMetrics.total_calling_nudged_conversations || '--',
            scheduledCallConversations:
              typeMetrics.scheduled_call_conversations || '--',
            notPickedUpCallConversations:
              typeMetrics.not_picked_up_call_conversations || '--',
            followUpCallConversations:
              typeMetrics.follow_up_call_conversations || '--',
            convertedCallConversations:
              typeMetrics.converted_call_conversations || '--',
            droppedCallConversations:
              typeMetrics.dropped_call_conversations || '--',
            avgTimeToCallAfterNudge:
              this.renderContent(typeMetrics.avg_time_to_call_after_nudge) ||
              '--',
            avgTimeToConvert:
              this.renderContent(typeMetrics.avg_time_to_convert) || '--',
            avgTimeToDrop:
              this.renderContent(typeMetrics.avg_time_to_drop) || '--',
            avgFollowUpCalls: typeMetrics.avg_follow_up_calls || '--',
          };
        });
      }

      if (this.agentTableType === 'inboundCallOverview') {
        return combinedTeams.map(team => {
          const typeMetrics = this.getMetrics(team.id);
          return {
            name: team.name,
            totalInboundCallsHandled:
              typeMetrics.total_inbound_calls_handled || '--',
            totalCallsConnected:
              typeMetrics.total_inbound_calls_handled -
                typeMetrics.total_calls_missed || '--',
            totalCallsMissed: typeMetrics.total_calls_missed || '--',
            inboundCallsResolved:
              this.renderPercentage(
                typeMetrics.inbound_calls_resolved,
                typeMetrics.total_inbound_call_conversations
              ) || '--',
            avgCallHandlingTime:
              this.renderContent(typeMetrics.avg_call_handling_time) || '--',
            avgCallWaitTime:
              this.renderContent(typeMetrics.avg_call_wait_time) || '--',
          };
        });
      }

      return combinedTeams.map(team => {
        const typeMetrics = this.getMetrics(team.id);
        return {
          name: team.name,
          conversationsCount: typeMetrics.conversations_count || '--',
          avgFirstResponseTime:
            this.renderContent(typeMetrics.avg_first_response_time) || '--',
          avgResolutionTime:
            this.renderContent(typeMetrics.avg_resolution_time) || '--',
          onlineTime: this.renderContent(typeMetrics.online_time) || '--',
          busyTime: this.renderContent(typeMetrics.busy_time) || '--',
          resolutionsCount: typeMetrics.resolved_conversations_count || '--',
        };
      });
    },
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    typeMetrics() {
      return this.$store.getters[this.summaryKey] || [];
    },
  },
  mounted() {
    this.fetchAllData();
    document.addEventListener('click', () => {
      this.activeDropdownId = null;
    });
  },
  beforeDestroy() {
    document.removeEventListener('click', () => {
      this.activeDropdownId = null;
    });
  },
  methods: {
    renderContent(value) {
      return value ? formatTime(value) : '--';
    },
    renderPercentage(value, total) {
      if (total && value) {
        const percentage = ((value / total) * 100).toFixed(1);
        return `${percentage}%`;
      }
      return value;
    },
    getMetrics(id) {
      return this.typeMetrics.find(metrics => metrics.id === Number(id)) || {};
    },
    emitFilterChange() {
      this.$emit('filter-change', {
        since: this.from,
        until: this.to,
        businessHours: this.businessHours,
        selectedLabel: this.selectedLabel,
        selectedInbox: this.selectedInbox,
        metricType: this.selectedMetricType,
      });
    },
    fetchAllData() {
      const { from, to, businessHours, selectedLabel, selectedInbox } = this;
      this.emitFilterChange();
      this.$store.dispatch(this.actionKey, {
        since: from,
        until: to,
        businessHours,
        selectedLabel,
        selectedInbox,
      });
    },
    downloadReports() {
      const { from, to, type, businessHours } = this;
      const dispatchMethods = {
        agent: 'downloadAgentReports',
        label: 'downloadLabelReports',
        inbox: 'downloadInboxReports',
        team: 'downloadTeamReports',
      };
      if (dispatchMethods[type]) {
        const fileName = generateFileName({ type, to, businessHours });
        const params = { from, to, fileName, businessHours };
        this.$store.dispatch(dispatchMethods[type], params);
        if (type === 'agent') {
          this.showAlert(
            'The report will soon be available in all administrator email inboxes.'
          );
        }
      }
    },
    onMetricTypeChange(value) {
      this.selectedMetricType = value;
      this.fetchAllData();
    },
    onFilterChange({ from, to, businessHours, selectedLabel, selectedInbox }) {
      this.from = from;
      this.to = to;
      this.businessHours = businessHours;
      this.selectedLabel = selectedLabel;
      this.selectedInbox = selectedInbox;
      this.fetchAllData();
    },
    toggleDropdown(id) {
      this.activeDropdownId = this.activeDropdownId === id ? null : id;
    },
  },
};
</script>
