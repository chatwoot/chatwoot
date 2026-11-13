<script setup>
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Auth from 'dashboard/api/auth';

const { t } = useI18n();
const currentUser = useMapGetter('getCurrentUser');
const { isImpersonating } = useImpersonation();
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="isImpersonating"
    color="ruby"
    :action-label="t('APP_GLOBAL.IMPERSONATION.STOP')"
    class="!rounded-none !justify-center"
    @action="Auth.logout"
  >
    <span class="flex items-center gap-2 text-sm">
      <span class="i-lucide-venetian-mask size-4 shrink-0" />
      {{
        t('APP_GLOBAL.IMPERSONATION.MESSAGE', {
          name: currentUser.name,
          email: currentUser.email,
        })
      }}
    </span>
  </Banner>
</template>
