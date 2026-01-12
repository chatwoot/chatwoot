<script setup>
import { ref } from 'vue';
import { BaseTable, BaseTableRow, BaseTableCell } from './index';
import Button from '../button/Button.vue';
import Avatar from '../avatar/Avatar.vue';
import ToggleSwitch from '../switch/Switch.vue';

const automationData = ref([
  {
    id: 1,
    name: 'Welcome Message',
    description: 'Send welcome message to new contacts',
    active: true,
    createdOn: 'Apr 21, 2022',
  },
  {
    id: 2,
    name: 'Auto-assign to Sales',
    description: 'Automatically assign sales conversations to sales team',
    active: false,
    createdOn: 'May 15, 2022',
  },
  {
    id: 3,
    name: 'Tag Premium Users',
    description: 'Add premium tag to conversations from premium users',
    active: true,
    createdOn: 'Jun 10, 2022',
  },
]);

const agentData = ref([
  {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    role: 'Administrator',
    verified: true,
    avatarUrl: '',
  },
  {
    id: 2,
    name: 'Jane Smith',
    email: 'jane@example.com',
    role: 'Agent',
    verified: true,
    avatarUrl: '',
  },
]);

const emptyData = ref([]);

const headers = ['Name', 'Active', 'Created on', 'Actions'];
const agentHeaders = ['Agent', 'Role', 'Verification', 'Actions'];
</script>

<template>
  <Story title="Components/Table" :layout="{ type: 'grid', width: '100%' }">
    <!-- Basic Table -->
    <Variant title="Basic Table">
      <div class="p-4 bg-n-surface-1">
        <BaseTable :headers="headers" :items="automationData">
          <template #row="{ items }">
            <BaseTableRow
              v-for="automation in items"
              :key="automation.id"
              :item="automation"
            >
              <template #default>
                <BaseTableCell>
                  <div class="flex items-center gap-2 min-w-0 max-w-full">
                    <span
                      class="text-body-main text-n-slate-12 truncate min-w-0 flex-1"
                    >
                      {{ automation.name }}
                    </span>
                    <div class="w-px h-3 rounded-lg bg-n-weak flex-shrink-0" />
                    <span
                      class="text-body-main text-n-slate-11 truncate min-w-0 flex-1"
                    >
                      {{ automation.description }}
                    </span>
                  </div>
                </BaseTableCell>

                <BaseTableCell>
                  <div class="flex justify-center">
                    <ToggleSwitch v-model="automation.active" />
                  </div>
                </BaseTableCell>

                <BaseTableCell>
                  <span
                    class="text-body-main text-n-slate-12 whitespace-nowrap"
                  >
                    {{ automation.createdOn }}
                  </span>
                </BaseTableCell>

                <BaseTableCell align="end" class="w-24">
                  <div class="flex gap-3 justify-end flex-shrink-0">
                    <Button icon="i-woot-edit-pen" slate sm />
                    <Button icon="i-woot-bin" slate sm />
                    <Button icon="i-woot-clone" slate sm />
                  </div>
                </BaseTableCell>
              </template>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
    </Variant>

    <!-- Table with Avatars -->
    <Variant title="Table with Avatars">
      <div class="p-4 bg-n-surface-1">
        <BaseTable :headers="agentHeaders" :items="agentData">
          <template #row="{ items }">
            <BaseTableRow v-for="agent in items" :key="agent.id" :item="agent">
              <template #default>
                <BaseTableCell>
                  <div class="flex items-center gap-3 min-w-0">
                    <Avatar :user="agent" :size="40" class="flex-shrink-0" />
                    <div class="flex flex-col min-w-0">
                      <span class="text-body-main text-n-slate-12 truncate">
                        {{ agent.name }}
                      </span>
                      <span class="text-body-main text-n-slate-11 truncate">
                        {{ agent.email }}
                      </span>
                    </div>
                  </div>
                </BaseTableCell>

                <BaseTableCell>
                  <span
                    class="text-body-main text-n-slate-12 whitespace-nowrap"
                  >
                    {{ agent.role }}
                  </span>
                </BaseTableCell>

                <BaseTableCell>
                  <span
                    class="text-body-main text-n-slate-12 whitespace-nowrap"
                  >
                    {{ agent.verified ? 'Verified' : 'Pending' }}
                  </span>
                </BaseTableCell>

                <BaseTableCell align="end" class="w-24">
                  <div class="flex gap-3 justify-end flex-shrink-0">
                    <Button icon="i-woot-edit-pen" slate sm />
                    <Button icon="i-woot-bin" slate sm />
                  </div>
                </BaseTableCell>
              </template>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
    </Variant>

    <!-- Empty State -->
    <Variant title="Empty State">
      <div class="p-4 bg-n-surface-1">
        <BaseTable
          :headers="headers"
          :items="emptyData"
          no-data-message="No automation rules found"
        />
      </div>
    </Variant>
  </Story>
</template>
