<template>
    <div class="flex flex-col">
        <simple-divider v-if="showSeparator" ref="divider" :label="$t('COMMON.OR')" class="uppercase" />
        <a :href="oidcLogin()"
            class="inline-flex w-full justify-center rounded-md bg-white py-3 px-4 shadow-sm ring-1 ring-inset ring-slate-200 dark:ring-slate-600 hover:bg-slate-50 focus:outline-offset-0 dark:bg-slate-700 dark:hover:bg-slate-700">
            <img src="/assets/images/auth/oidc.svg" alt="OIDC Logo" class="h-6" />
            <span class="text-base font-medium ml-2 text-slate-600 dark:text-white">
                {{ $t('LOGIN.OIDC.OIDC_LOGIN') }}
            </span>
        </a>
    </div>
</template>
  
<script>
import SimpleDivider from '../../Divider/SimpleDivider.vue';

export default {
    components: {
        SimpleDivider,
    },
    props: {
        showSeparator: {
            type: Boolean,
            default: true,
        },
    },
    methods: {
        oidcLogin() {
            const clientId= window.chatwootConfig.keycloakClientId;
            const redirectUri =  window.chatwootConfig.keycloakCallbackUrl

            const baseUrl = 'https://sso.onehash.ai/realms/OneHash/protocol/openid-connect/auth';
            const responseType = 'code';
            const scope = 'openid';

            const queryString = new URLSearchParams({
                client_id: clientId,
                redirect_uri: redirectUri,
                response_type: responseType,
                scope: scope,
            }).toString();

            return `${baseUrl}?${queryString}`;
        },
    },
};
</script>
  