<script setup>
import { useRouter } from 'vue-router';
import { useConfig } from 'dashboard/composables/useConfig';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const router = useRouter();
const { isEnterprise } = useConfig();

const settingItems = [
  {
    name: 'assignment_policies',
    title: 'Assignment Policies',
    description: 'Configure how conversations are assigned to agents',
    icon: 'arrow-shuffle',
    route: 'assignment_policies_list',
    color: 'text-violet-800',
    bgColor: 'bg-violet-100',
  },
  {
    name: 'leave_management',
    title: 'Leave Management',
    description: 'Manage agent leaves and time off requests',
    icon: 'calendar-event',
    route: 'assignment_leaves_list',
    color: 'text-orange-800',
    bgColor: 'bg-orange-100',
  },
  {
    name: 'agent_capacity',
    title: 'Agent Capacity',
    description: 'Set conversation limits and workload management',
    icon: 'gauge',
    route: 'assignment_capacity_list',
    color: 'text-cyan-800',
    bgColor: 'bg-cyan-100',
    enterprise: true,
  },
];

const visibleSettings = settingItems.filter(
  item => !item.enterprise || isEnterprise
);

const navigateTo = route => {
  router.push({ name: route });
};
</script>

<template>
  <div>
    <BaseSettingsHeader
      title="Assignment Management"
      description="Configure assignment policies, manage agent leaves, and set capacity limits"
    />

    <div class="grid grid-cols-1 gap-6 p-8 md:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="item in visibleSettings"
        :key="item.name"
        class="relative p-6 bg-white rounded-xl shadow-sm border border-slate-200 hover:shadow-md transition-all duration-200 cursor-pointer group"
        @click="navigateTo(item.route)"
      >
        <div class="flex items-start gap-4">
          <div
            class="p-3 rounded-lg flex items-center justify-center"
            :class="[item.bgColor]"
          >
            <Icon :icon="item.icon" class="h-6 w-6" :class="[item.color]" />
          </div>
          <div class="flex-1">
            <h3 class="text-lg font-medium text-slate-900 mb-1">
              {{ item.title }}
            </h3>
            <p class="text-sm text-slate-600">
              {{ item.description }}
            </p>
            <span
              v-if="item.enterprise"
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-800 mt-2"
            >
              Enterprise
            </span>
          </div>
        </div>
        <div
          class="absolute top-6 right-6 text-slate-400 group-hover:text-slate-600 transition-colors"
        >
          <Icon icon="chevron-right" class="h-5 w-5" />
        </div>
      </div>
    </div>
  </div>
</template>
