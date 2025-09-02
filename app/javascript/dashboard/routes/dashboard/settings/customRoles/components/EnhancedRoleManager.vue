<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useI18n } from 'dashboard/composables/useI18n';
import ButtonV4 from 'next/button/Button.vue';

const { t } = useI18n();
const store = useStore();

const loading = ref(false);
const roles = ref([]);
const selectedRole = ref(null);
const showRoleModal = ref(false);
const showPermissionMatrix = ref(false);

const roleForm = reactive({
  name: '',
  description: '',
  roleType: 'custom',
  permissions: [],
  roleColor: '#6B7280',
  isSystemRole: false
});

const permissionCategories = reactive({
  'Conversations': [
    'conversation_view_all',
    'conversation_view_assigned', 
    'conversation_view_participating',
    'conversation_manage_all',
    'conversation_manage_assigned',
    'conversation_assign',
    'conversation_transfer',
    'conversation_resolve',
    'conversation_reopen',
    'conversation_private_notes',
    'conversation_export'
  ],
  'Contacts': [
    'contact_view',
    'contact_create',
    'contact_update',
    'contact_delete',
    'contact_merge',
    'contact_export',
    'contact_import',
    'contact_custom_attributes'
  ],
  'Team Management': [
    'team_view',
    'team_invite',
    'team_manage',
    'user_profile_update',
    'role_assign',
    'role_create',
    'role_manage'
  ],
  'Reporting': [
    'report_view',
    'report_advanced',
    'report_export',
    'report_custom',
    'analytics_view',
    'analytics_export'
  ],
  'Billing': [
    'billing_view',
    'billing_manage',
    'invoice_view',
    'invoice_download',
    'payment_methods',
    'subscription_manage',
    'usage_view'
  ],
  'Settings': [
    'settings_account',
    'settings_channels',
    'settings_integrations',
    'settings_webhooks',
    'settings_automation',
    'settings_security',
    'settings_advanced'
  ],
  'Knowledge Base': [
    'kb_view',
    'kb_article_create',
    'kb_article_edit',
    'kb_article_delete',
    'kb_category_manage',
    'kb_portal_manage',
    'kb_publish'
  ],
  'Channels': [
    'channel_view',
    'channel_create',
    'channel_configure',
    'channel_delete',
    'integration_manage',
    'webhook_manage'
  ],
  'System': [
    'audit_log_view',
    'system_info_view',
    'feature_flags_view',
    'feature_flags_manage'
  ]
});

const systemRoles = [
  { key: 'owner', name: 'Owner', color: '#8127E8', hierarchy: 150 },
  { key: 'admin', name: 'Admin', color: '#FF6600', hierarchy: 100 },
  { key: 'finance', name: 'Finance', color: '#10B981', hierarchy: 75 },
  { key: 'agent', name: 'Agent', color: '#3B82F6', hierarchy: 50 },
  { key: 'support', name: 'Support', color: '#8B5CF6', hierarchy: 25 }
];

const currentUser = useMapGetter('getCurrentUser');
const currentAccountUser = computed(() => {
  return currentUser.value?.account_users?.find(au => au.account_id === store.getters.getCurrentAccountId);
});

const userCanCreateRoles = computed(() => {
  return currentAccountUser.value?.role === 'owner' || 
         currentAccountUser.value?.role === 'administrator' ||
         (currentAccountUser.value?.custom_role?.permissions || []).includes('role_create');
});

const userCanManageRoles = computed(() => {
  return currentAccountUser.value?.role === 'owner' || 
         currentAccountUser.value?.role === 'administrator' ||
         (currentAccountUser.value?.custom_role?.permissions || []).includes('role_manage');
});

const loadRoles = async () => {
  loading.value = true;
  try {
    await store.dispatch('customRole/get');
    roles.value = store.getters['customRole/getCustomRoles'];
  } catch (error) {
    console.error('Failed to load roles:', error);
  } finally {
    loading.value = false;
  }
};

const openCreateRoleModal = () => {
  resetForm();
  selectedRole.value = null;
  showRoleModal.value = true;
};

const openEditRoleModal = (role) => {
  selectedRole.value = role;
  roleForm.name = role.name;
  roleForm.description = role.description;
  roleForm.roleType = role.role_type || 'custom';
  roleForm.permissions = [...(role.permissions || [])];
  roleForm.roleColor = role.role_color || '#6B7280';
  roleForm.isSystemRole = role.is_system_role || false;
  showRoleModal.value = true;
};

const resetForm = () => {
  roleForm.name = '';
  roleForm.description = '';
  roleForm.roleType = 'custom';
  roleForm.permissions = [];
  roleForm.roleColor = '#6B7280';
  roleForm.isSystemRole = false;
};

const togglePermission = (permission) => {
  const index = roleForm.permissions.indexOf(permission);
  if (index > -1) {
    roleForm.permissions.splice(index, 1);
  } else {
    roleForm.permissions.push(permission);
  }
};

const selectAllInCategory = (category) => {
  const categoryPermissions = permissionCategories[category];
  const allSelected = categoryPermissions.every(p => roleForm.permissions.includes(p));
  
  if (allSelected) {
    // Deselect all
    categoryPermissions.forEach(p => {
      const index = roleForm.permissions.indexOf(p);
      if (index > -1) roleForm.permissions.splice(index, 1);
    });
  } else {
    // Select all
    categoryPermissions.forEach(p => {
      if (!roleForm.permissions.includes(p)) {
        roleForm.permissions.push(p);
      }
    });
  }
};

const applyRoleTemplate = (roleKey) => {
  const templates = {
    owner: Object.values(permissionCategories).flat(),
    admin: Object.values(permissionCategories).flat().filter(p => p !== 'feature_flags_manage'),
    agent: [
      'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_assigned', 'conversation_resolve', 'conversation_reopen',
      'conversation_private_notes', 'contact_view', 'contact_update',
      'contact_custom_attributes', 'team_view', 'user_profile_update',
      'report_view', 'kb_view', 'kb_article_create', 'kb_article_edit', 'channel_view'
    ],
    finance: [
      'team_view', 'report_view', 'report_advanced', 'report_export', 'report_custom',
      'analytics_view', 'analytics_export', 'billing_view', 'billing_manage',
      'invoice_view', 'invoice_download', 'payment_methods', 'subscription_manage',
      'usage_view', 'settings_account'
    ],
    support: [
      'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_assigned', 'conversation_resolve', 'contact_view',
      'team_view', 'user_profile_update', 'report_view', 'kb_view',
      'kb_article_create', 'kb_article_edit', 'channel_view'
    ]
  };
  
  roleForm.permissions = templates[roleKey] || [];
};

const saveRole = async () => {
  try {
    const roleData = {
      name: roleForm.name,
      description: roleForm.description,
      permissions: roleForm.permissions,
      role_type: roleForm.roleType,
      role_color: roleForm.roleColor,
      is_system_role: roleForm.isSystemRole
    };

    if (selectedRole.value) {
      await store.dispatch('customRole/update', { id: selectedRole.value.id, ...roleData });
    } else {
      await store.dispatch('customRole/create', roleData);
    }

    showRoleModal.value = false;
    await loadRoles();
  } catch (error) {
    console.error('Failed to save role:', error);
  }
};

const deleteRole = async (role) => {
  if (confirm(`Are you sure you want to delete the role "${role.name}"?`)) {
    try {
      await store.dispatch('customRole/delete', role.id);
      await loadRoles();
    } catch (error) {
      console.error('Failed to delete role:', error);
    }
  }
};

const getPermissionDescription = (permission) => {
  const descriptions = {
    'conversation_view_all': 'View all conversations',
    'conversation_view_assigned': 'View assigned conversations',
    'conversation_view_participating': 'View participating conversations',
    'conversation_manage_all': 'Manage all conversations',
    'conversation_manage_assigned': 'Manage assigned conversations',
    'conversation_assign': 'Assign conversations',
    'conversation_transfer': 'Transfer conversations',
    'conversation_resolve': 'Resolve conversations',
    'conversation_reopen': 'Reopen conversations',
    'conversation_private_notes': 'Add private notes',
    'conversation_export': 'Export conversations',
    
    'contact_view': 'View contacts',
    'contact_create': 'Create contacts',
    'contact_update': 'Update contacts',
    'contact_delete': 'Delete contacts',
    'contact_merge': 'Merge contacts',
    'contact_export': 'Export contacts',
    'contact_import': 'Import contacts',
    'contact_custom_attributes': 'Manage contact attributes',
    
    'team_view': 'View team members',
    'team_invite': 'Invite team members',
    'team_manage': 'Manage team',
    'user_profile_update': 'Update profiles',
    'role_assign': 'Assign roles',
    'role_create': 'Create roles',
    'role_manage': 'Manage roles',
    
    'report_view': 'View reports',
    'report_advanced': 'Advanced reports',
    'report_export': 'Export reports',
    'report_custom': 'Custom reports',
    'analytics_view': 'View analytics',
    'analytics_export': 'Export analytics',
    
    'billing_view': 'View billing',
    'billing_manage': 'Manage billing',
    'invoice_view': 'View invoices',
    'invoice_download': 'Download invoices',
    'payment_methods': 'Payment methods',
    'subscription_manage': 'Manage subscription',
    'usage_view': 'View usage',
    
    'settings_account': 'Account settings',
    'settings_channels': 'Channel settings',
    'settings_integrations': 'Integration settings',
    'settings_webhooks': 'Webhook settings',
    'settings_automation': 'Automation settings',
    'settings_security': 'Security settings',
    'settings_advanced': 'Advanced settings',
    
    'kb_view': 'View knowledge base',
    'kb_article_create': 'Create articles',
    'kb_article_edit': 'Edit articles',
    'kb_article_delete': 'Delete articles',
    'kb_category_manage': 'Manage categories',
    'kb_portal_manage': 'Manage portals',
    'kb_publish': 'Publish content',
    
    'channel_view': 'View channels',
    'channel_create': 'Create channels',
    'channel_configure': 'Configure channels',
    'channel_delete': 'Delete channels',
    'integration_manage': 'Manage integrations',
    'webhook_manage': 'Manage webhooks',
    
    'audit_log_view': 'View audit logs',
    'system_info_view': 'System information',
    'feature_flags_view': 'View feature flags',
    'feature_flags_manage': 'Manage feature flags'
  };
  
  return descriptions[permission] || permission.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const getCategoryProgress = (category) => {
  const categoryPermissions = permissionCategories[category];
  const selectedCount = categoryPermissions.filter(p => roleForm.permissions.includes(p)).length;
  return {
    selected: selectedCount,
    total: categoryPermissions.length,
    percentage: Math.round((selectedCount / categoryPermissions.length) * 100)
  };
};

onMounted(() => {
  loadRoles();
});
</script>

<template>
  <div class="enhanced-role-manager">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h2 class="text-2xl font-bold text-slate-900">Role Management</h2>
        <p class="text-slate-600 mt-1">Manage roles and permissions for your team</p>
      </div>
      <div class="flex space-x-3">
        <ButtonV4 
          v-if="userCanCreateRoles"
          solid 
          blue
          icon="i-lucide-plus"
          @click="openCreateRoleModal"
        >
          Create Role
        </ButtonV4>
        <ButtonV4 
          outline 
          slate
          icon="i-lucide-shield-check"
          @click="showPermissionMatrix = true"
        >
          Permission Matrix
        </ButtonV4>
      </div>
    </div>

    <!-- System Roles Overview -->
    <div class="bg-white rounded-lg shadow mb-6">
      <div class="px-6 py-4 border-b">
        <h3 class="text-lg font-semibold">System Roles</h3>
        <p class="text-sm text-slate-600">Built-in roles with predefined permissions</p>
      </div>
      <div class="p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div 
            v-for="role in systemRoles" 
            :key="role.key"
            class="border rounded-lg p-4 text-center"
          >
            <div 
              class="w-12 h-12 rounded-full mx-auto mb-3 flex items-center justify-center text-white font-bold"
              :style="{ backgroundColor: role.color }"
            >
              {{ role.name.charAt(0) }}
            </div>
            <h4 class="font-semibold text-slate-900">{{ role.name }}</h4>
            <p class="text-xs text-slate-500 mt-1">Level {{ role.hierarchy }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Roles Table -->
    <div class="bg-white rounded-lg shadow">
      <div class="px-6 py-4 border-b">
        <h3 class="text-lg font-semibold">Custom Roles</h3>
      </div>
      
      <div v-if="loading" class="p-8 text-center">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
        <p class="mt-2 text-slate-600">Loading roles...</p>
      </div>
      
      <div v-else-if="roles.length === 0" class="p-8 text-center text-slate-500">
        <div class="text-4xl mb-3">🛡️</div>
        <p class="text-lg">No custom roles created yet</p>
        <p class="text-sm">Create your first custom role to get started</p>
      </div>
      
      <div v-else class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-slate-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Role</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Type</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Permissions</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Users</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-slate-200">
            <tr v-for="role in roles" :key="role.id">
              <td class="px-6 py-4">
                <div class="flex items-center">
                  <div 
                    class="w-8 h-8 rounded-full mr-3 flex items-center justify-center text-white text-sm font-bold"
                    :style="{ backgroundColor: role.role_color || '#6B7280' }"
                  >
                    {{ role.name.charAt(0) }}
                  </div>
                  <div>
                    <div class="text-sm font-medium text-slate-900">{{ role.name }}</div>
                    <div class="text-sm text-slate-500">{{ role.description }}</div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span 
                  v-if="role.is_system_role"
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                >
                  System
                </span>
                <span 
                  v-else
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
                >
                  Custom
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                {{ (role.permissions || []).length }} permissions
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                {{ role.account_users_count || 0 }} users
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <ButtonV4 
                  v-if="userCanManageRoles && !role.is_system_role"
                  sm outline slate
                  icon="i-lucide-edit"
                  @click="openEditRoleModal(role)"
                  class="mr-2"
                >
                  Edit
                </ButtonV4>
                <ButtonV4 
                  v-if="userCanManageRoles && !role.is_system_role"
                  sm outline red
                  icon="i-lucide-trash-2"
                  @click="deleteRole(role)"
                >
                  Delete
                </ButtonV4>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Role Creation/Edit Modal -->
    <div v-if="showRoleModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto mx-4">
        <div class="px-6 py-4 border-b">
          <h3 class="text-lg font-semibold">
            {{ selectedRole ? 'Edit Role' : 'Create New Role' }}
          </h3>
        </div>
        
        <div class="p-6">
          <!-- Basic Info -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Role Name</label>
              <input 
                v-model="roleForm.name"
                type="text" 
                class="w-full border border-slate-300 rounded-md px-3 py-2"
                placeholder="Enter role name"
              >
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Role Color</label>
              <input 
                v-model="roleForm.roleColor"
                type="color" 
                class="w-full border border-slate-300 rounded-md px-3 py-2 h-10"
              >
            </div>
          </div>
          
          <div class="mb-6">
            <label class="block text-sm font-medium text-slate-700 mb-2">Description</label>
            <textarea 
              v-model="roleForm.description"
              class="w-full border border-slate-300 rounded-md px-3 py-2"
              rows="3"
              placeholder="Describe this role and its purpose"
            ></textarea>
          </div>

          <!-- Role Templates -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-slate-700 mb-3">Quick Templates</label>
            <div class="flex flex-wrap gap-2">
              <button 
                v-for="role in systemRoles"
                :key="role.key"
                @click="applyRoleTemplate(role.key)"
                class="px-3 py-1 text-sm border border-slate-300 rounded-md hover:bg-slate-50"
              >
                {{ role.name }} Template
              </button>
            </div>
          </div>

          <!-- Permissions -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-slate-700 mb-3">Permissions</label>
            
            <div class="space-y-6">
              <div v-for="(permissions, category) in permissionCategories" :key="category" class="border border-slate-200 rounded-lg">
                <div 
                  class="px-4 py-3 bg-slate-50 border-b border-slate-200 flex items-center justify-between cursor-pointer"
                  @click="selectAllInCategory(category)"
                >
                  <div class="flex items-center">
                    <h4 class="font-medium text-slate-900">{{ category }}</h4>
                    <span class="ml-2 text-sm text-slate-500">
                      ({{ getCategoryProgress(category).selected }}/{{ getCategoryProgress(category).total }})
                    </span>
                  </div>
                  <div class="flex items-center">
                    <div class="w-16 bg-slate-200 rounded-full h-2 mr-3">
                      <div 
                        class="bg-blue-600 h-2 rounded-full"
                        :style="{ width: getCategoryProgress(category).percentage + '%' }"
                      ></div>
                    </div>
                    <ButtonV4 sm outline slate>
                      {{ getCategoryProgress(category).percentage === 100 ? 'Deselect All' : 'Select All' }}
                    </ButtonV4>
                  </div>
                </div>
                
                <div class="p-4 grid grid-cols-1 md:grid-cols-2 gap-3">
                  <label 
                    v-for="permission in permissions" 
                    :key="permission"
                    class="flex items-center cursor-pointer hover:bg-slate-50 p-2 rounded"
                  >
                    <input 
                      type="checkbox"
                      :checked="roleForm.permissions.includes(permission)"
                      @change="togglePermission(permission)"
                      class="mr-3 rounded border-slate-300"
                    >
                    <div>
                      <div class="text-sm font-medium text-slate-900">
                        {{ getPermissionDescription(permission) }}
                      </div>
                      <div class="text-xs text-slate-500">{{ permission }}</div>
                    </div>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="px-6 py-4 border-t bg-slate-50 flex justify-end space-x-3">
          <ButtonV4 outline slate @click="showRoleModal = false">
            Cancel
          </ButtonV4>
          <ButtonV4 solid blue @click="saveRole">
            {{ selectedRole ? 'Update Role' : 'Create Role' }}
          </ButtonV4>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.enhanced-role-manager {
  @apply p-6;
}
</style>