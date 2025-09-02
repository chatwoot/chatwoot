<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { format } from 'date-fns';
import { enGB } from 'date-fns/locale';

// State
const loading = ref(false);
const tenants = ref([]);
const alerts = ref([]);
const systemSummary = ref({});
const selectedTenant = ref(null);
const pagination = reactive({
  page: 1,
  itemsPerPage: 25,
  totalItems: 0
});

// Filters
const filters = reactive({
  search: '',
  status: 'all',
  plan: 'all'
});

// Modal states
const suspendDialog = ref(false);
const upgradeDialog = ref(false);
const benefitDialog = ref(false);
const tenantDetailsDialog = ref(false);

// Form data
const suspendForm = reactive({
  reason: '',
  loading: false
});

const upgradeForm = reactive({
  planType: '',
  reason: '',
  loading: false
});

const benefitForm = reactive({
  type: '',
  value: '',
  description: '',
  expiresAt: '',
  reason: '',
  loading: false
});

// Computed
const filteredTenants = computed(() => {
  let result = tenants.value;
  
  if (filters.search) {
    result = result.filter(tenant => 
      tenant.name.toLowerCase().includes(filters.search.toLowerCase())
    );
  }
  
  if (filters.status !== 'all') {
    result = result.filter(tenant => tenant.status === filters.status);
  }
  
  if (filters.plan !== 'all') {
    result = result.filter(tenant => 
      tenant.subscription?.plan_type === filters.plan
    );
  }
  
  return result;
});

const statusColor = (status) => {
  switch (status) {
    case 'active': return 'success';
    case 'trial': return 'warning';
    case 'suspended': return 'error';
    default: return 'grey';
  }
};

const severityColor = (severity) => {
  switch (severity) {
    case 'critical': return 'error';
    case 'high': return 'warning';
    case 'medium': return 'info';
    case 'low': return 'success';
    default: return 'grey';
  }
};

// Methods
const loadTenants = async () => {
  loading.value = true;
  try {
    const response = await fetch('/wsc/api/master_admin/tenants', {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) throw new Error('Failed to load tenants');
    
    const data = await response.json();
    tenants.value = data.tenants || [];
    systemSummary.value = data.summary || {};
    pagination.totalItems = data.pagination?.total_count || 0;
  } catch (error) {
    console.error('Failed to load tenants:', error);
  } finally {
    loading.value = false;
  }
};

const loadAlerts = async () => {
  try {
    const response = await fetch('/wsc/api/master_admin/alerts', {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) throw new Error('Failed to load alerts');
    
    const data = await response.json();
    alerts.value = data.alerts || [];
  } catch (error) {
    console.error('Failed to load alerts:', error);
  }
};

const suspendTenant = async () => {
  if (!selectedTenant.value) return;
  
  suspendForm.loading = true;
  try {
    const response = await fetch(`/wsc/api/master_admin/tenants/${selectedTenant.value.id}/suspend`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ reason: suspendForm.reason })
    });
    
    if (!response.ok) throw new Error('Failed to suspend tenant');
    
    await loadTenants();
    suspendDialog.value = false;
    suspendForm.reason = '';
  } catch (error) {
    console.error('Failed to suspend tenant:', error);
  } finally {
    suspendForm.loading = false;
  }
};

const forceUpgrade = async () => {
  if (!selectedTenant.value) return;
  
  upgradeForm.loading = true;
  try {
    const response = await fetch(`/wsc/api/master_admin/tenants/${selectedTenant.value.id}/force_upgrade`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        plan_type: upgradeForm.planType,
        reason: upgradeForm.reason 
      })
    });
    
    if (!response.ok) throw new Error('Failed to upgrade tenant');
    
    await loadTenants();
    upgradeDialog.value = false;
    upgradeForm.planType = '';
    upgradeForm.reason = '';
  } catch (error) {
    console.error('Failed to upgrade tenant:', error);
  } finally {
    upgradeForm.loading = false;
  }
};

const grantBenefit = async () => {
  if (!selectedTenant.value) return;
  
  benefitForm.loading = true;
  try {
    const response = await fetch(`/wsc/api/master_admin/tenants/${selectedTenant.value.id}/grant_benefit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        benefit: {
          type: benefitForm.type,
          value: benefitForm.value,
          description: benefitForm.description,
          expires_at: benefitForm.expiresAt,
          reason: benefitForm.reason
        }
      })
    });
    
    if (!response.ok) throw new Error('Failed to grant benefit');
    
    await loadTenants();
    benefitDialog.value = false;
    Object.keys(benefitForm).forEach(key => {
      if (key !== 'loading') benefitForm[key] = '';
    });
  } catch (error) {
    console.error('Failed to grant benefit:', error);
  } finally {
    benefitForm.loading = false;
  }
};

const acknowledgeAlert = async (alert) => {
  try {
    const response = await fetch(`/wsc/api/master_admin/alerts/${alert.id}/acknowledge`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) throw new Error('Failed to acknowledge alert');
    
    await loadAlerts();
  } catch (error) {
    console.error('Failed to acknowledge alert:', error);
  }
};

const resolveAlert = async (alert) => {
  try {
    const response = await fetch(`/wsc/api/master_admin/alerts/${alert.id}/resolve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('master_admin_token')}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) throw new Error('Failed to resolve alert');
    
    await loadAlerts();
  } catch (error) {
    console.error('Failed to resolve alert:', error);
  }
};

const formatDate = (dateString) => {
  if (!dateString) return 'Never';
  return format(new Date(dateString), 'dd/MM/yyyy HH:mm', { locale: enGB });
};

const openSuspendDialog = (tenant) => {
  selectedTenant.value = tenant;
  suspendDialog.value = true;
};

const openUpgradeDialog = (tenant) => {
  selectedTenant.value = tenant;
  upgradeDialog.value = true;
};

const openBenefitDialog = (tenant) => {
  selectedTenant.value = tenant;
  benefitDialog.value = true;
};

const openTenantDetails = (tenant) => {
  selectedTenant.value = tenant;
  tenantDetailsDialog.value = true;
};

// Lifecycle
onMounted(() => {
  loadTenants();
  loadAlerts();
});
</script>

<template>
  <v-container fluid class="master-admin-dashboard">
    <!-- Page Header -->
    <v-row class="mb-6">
      <v-col>
        <h1 class="text-h3 font-weight-bold text-primary">Master Admin Console</h1>
        <p class="text-subtitle-1 text-medium-emphasis">Manage tenants without accessing private data</p>
      </v-col>
    </v-row>

    <!-- System Summary Cards -->
    <v-row class="mb-6">
      <v-col cols="12" md="3">
        <v-card>
          <v-card-text>
            <div class="d-flex align-center">
              <v-icon class="mr-3" color="primary" size="large">mdi-domain</v-icon>
              <div>
                <div class="text-h4 font-weight-bold">{{ systemSummary.total_tenants || 0 }}</div>
                <div class="text-caption text-medium-emphasis">Total Tenants</div>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
      
      <v-col cols="12" md="3">
        <v-card>
          <v-card-text>
            <div class="d-flex align-center">
              <v-icon class="mr-3" color="success" size="large">mdi-check-circle</v-icon>
              <div>
                <div class="text-h4 font-weight-bold">{{ systemSummary.active_subscriptions || 0 }}</div>
                <div class="text-caption text-medium-emphasis">Active Subscriptions</div>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
      
      <v-col cols="12" md="3">
        <v-card>
          <v-card-text>
            <div class="d-flex align-center">
              <v-icon class="mr-3" color="warning" size="large">mdi-timer-sand</v-icon>
              <div>
                <div class="text-h4 font-weight-bold">{{ systemSummary.trial_subscriptions || 0 }}</div>
                <div class="text-caption text-medium-emphasis">Trial Subscriptions</div>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
      
      <v-col cols="12" md="3">
        <v-card>
          <v-card-text>
            <div class="d-flex align-center">
              <v-icon class="mr-3" color="error" size="large">mdi-alert</v-icon>
              <div>
                <div class="text-h4 font-weight-bold">{{ systemSummary.critical_alerts || 0 }}</div>
                <div class="text-caption text-medium-emphasis">Critical Alerts</div>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Active Alerts -->
    <v-row class="mb-6" v-if="alerts.length > 0">
      <v-col>
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-alert-circle</v-icon>
            Active System Alerts
          </v-card-title>
          <v-card-text>
            <v-list>
              <v-list-item 
                v-for="alert in alerts.slice(0, 5)" 
                :key="alert.id"
                class="px-0"
              >
                <template #prepend>
                  <v-chip 
                    :color="severityColor(alert.severity)" 
                    size="small" 
                    variant="flat"
                  >
                    {{ alert.severity }}
                  </v-chip>
                </template>
                
                <v-list-item-title>{{ alert.title }}</v-list-item-title>
                <v-list-item-subtitle>{{ formatDate(alert.created_at) }}</v-list-item-subtitle>
                
                <template #append>
                  <v-btn 
                    icon="mdi-check" 
                    size="small" 
                    variant="text"
                    @click="acknowledgeAlert(alert)"
                  />
                  <v-btn 
                    icon="mdi-check-all" 
                    size="small" 
                    variant="text"
                    @click="resolveAlert(alert)"
                  />
                </template>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tenant Management -->
    <v-row>
      <v-col>
        <v-card>
          <v-card-title>
            <v-icon class="mr-2">mdi-account-multiple</v-icon>
            Tenant Management
          </v-card-title>
          
          <v-card-text>
            <!-- Filters -->
            <v-row class="mb-4">
              <v-col cols="12" md="4">
                <v-text-field
                  v-model="filters.search"
                  prepend-inner-icon="mdi-magnify"
                  label="Search tenants"
                  clearable
                  variant="outlined"
                  density="compact"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-select
                  v-model="filters.status"
                  :items="[
                    { value: 'all', title: 'All Statuses' },
                    { value: 'active', title: 'Active' },
                    { value: 'trial', title: 'Trial' },
                    { value: 'suspended', title: 'Suspended' }
                  ]"
                  label="Status"
                  variant="outlined"
                  density="compact"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-select
                  v-model="filters.plan"
                  :items="[
                    { value: 'all', title: 'All Plans' },
                    { value: 'basic', title: 'Basic' },
                    { value: 'pro', title: 'Pro' },
                    { value: 'premium', title: 'Premium' },
                    { value: 'app', title: 'App' },
                    { value: 'custom', title: 'Custom' }
                  ]"
                  label="Plan"
                  variant="outlined"
                  density="compact"
                />
              </v-col>
            </v-row>

            <!-- Tenant Table -->
            <v-data-table
              :items="filteredTenants"
              :loading="loading"
              :headers="[
                { title: 'Tenant', key: 'name', sortable: true },
                { title: 'Status', key: 'status', sortable: true },
                { title: 'Plan', key: 'subscription.plan_type', sortable: true },
                { title: 'Users', key: 'users_count', sortable: true },
                { title: 'Channels', key: 'channels.total', sortable: true },
                { title: 'Created', key: 'created_at', sortable: true },
                { title: 'Actions', key: 'actions', sortable: false }
              ]"
              item-key="id"
              class="elevation-0"
            >
              <template #item.name="{ item }">
                <div>
                  <div class="font-weight-medium">{{ item.name }}</div>
                  <div class="text-caption text-medium-emphasis">{{ item.domain || 'No domain' }}</div>
                </div>
              </template>
              
              <template #item.status="{ item }">
                <v-chip 
                  :color="statusColor(item.status)" 
                  size="small" 
                  variant="flat"
                >
                  {{ item.status }}
                </v-chip>
                <div v-if="item.subscription?.trial" class="text-caption text-warning mt-1">
                  Trial: {{ item.subscription.trial_days_remaining }} days left
                </div>
              </template>
              
              <template #item.subscription.plan_type="{ item }">
                {{ item.subscription?.plan_display_name || 'No plan' }}
              </template>
              
              <template #item.created_at="{ item }">
                {{ formatDate(item.created_at) }}
              </template>
              
              <template #item.actions="{ item }">
                <v-btn
                  icon="mdi-eye"
                  size="small"
                  variant="text"
                  @click="openTenantDetails(item)"
                />
                <v-btn
                  icon="mdi-account-cancel"
                  size="small"
                  variant="text"
                  color="error"
                  @click="openSuspendDialog(item)"
                  v-if="item.status !== 'suspended'"
                />
                <v-btn
                  icon="mdi-arrow-up-bold"
                  size="small"
                  variant="text"
                  color="primary"
                  @click="openUpgradeDialog(item)"
                />
                <v-btn
                  icon="mdi-gift"
                  size="small"
                  variant="text"
                  color="success"
                  @click="openBenefitDialog(item)"
                />
              </template>
            </v-data-table>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Suspend Dialog -->
    <v-dialog v-model="suspendDialog" max-width="500">
      <v-card>
        <v-card-title>Suspend Tenant</v-card-title>
        <v-card-text>
          <p class="mb-4">You are about to suspend <strong>{{ selectedTenant?.name }}</strong>.</p>
          <v-textarea
            v-model="suspendForm.reason"
            label="Reason for suspension"
            placeholder="Please provide a reason..."
            variant="outlined"
            required
          />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="suspendDialog = false">Cancel</v-btn>
          <v-btn 
            color="error" 
            :loading="suspendForm.loading"
            @click="suspendTenant"
          >
            Suspend
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Upgrade Dialog -->
    <v-dialog v-model="upgradeDialog" max-width="500">
      <v-card>
        <v-card-title>Force Upgrade Tenant</v-card-title>
        <v-card-text>
          <p class="mb-4">Force upgrade <strong>{{ selectedTenant?.name }}</strong> to:</p>
          <v-select
            v-model="upgradeForm.planType"
            :items="[
              { value: 'pro', title: 'Pro' },
              { value: 'premium', title: 'Premium' },
              { value: 'app', title: 'App' },
              { value: 'custom', title: 'Custom' }
            ]"
            label="Target Plan"
            variant="outlined"
            required
          />
          <v-textarea
            v-model="upgradeForm.reason"
            label="Reason for upgrade"
            placeholder="Please provide a reason..."
            variant="outlined"
            required
          />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="upgradeDialog = false">Cancel</v-btn>
          <v-btn 
            color="primary" 
            :loading="upgradeForm.loading"
            @click="forceUpgrade"
          >
            Upgrade
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Benefit Dialog -->
    <v-dialog v-model="benefitDialog" max-width="600">
      <v-card>
        <v-card-title>Grant Benefit</v-card-title>
        <v-card-text>
          <p class="mb-4">Grant benefit to <strong>{{ selectedTenant?.name }}</strong>:</p>
          <v-row>
            <v-col cols="12" md="6">
              <v-select
                v-model="benefitForm.type"
                :items="[
                  { value: 'extended_trial', title: 'Extended Trial' },
                  { value: 'free_upgrade', title: 'Free Upgrade' },
                  { value: 'feature_unlock', title: 'Feature Unlock' },
                  { value: 'custom_limit', title: 'Custom Limit' }
                ]"
                label="Benefit Type"
                variant="outlined"
                required
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="benefitForm.value"
                label="Benefit Value"
                placeholder="e.g., 30 (days), pro (plan), etc."
                variant="outlined"
              />
            </v-col>
          </v-row>
          <v-textarea
            v-model="benefitForm.description"
            label="Description"
            placeholder="Describe this benefit..."
            variant="outlined"
          />
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="benefitForm.expiresAt"
                label="Expires At"
                type="datetime-local"
                variant="outlined"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="benefitForm.reason"
                label="Grant Reason"
                placeholder="Reason for granting..."
                variant="outlined"
                required
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="benefitDialog = false">Cancel</v-btn>
          <v-btn 
            color="success" 
            :loading="benefitForm.loading"
            @click="grantBenefit"
          >
            Grant Benefit
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<style scoped>
.master-admin-dashboard {
  background-color: #f5f5f5;
  min-height: 100vh;
}

.text-primary {
  color: #8127E8 !important;
}
</style>