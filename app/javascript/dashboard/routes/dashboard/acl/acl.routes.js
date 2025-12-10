// app/javascript/dashboard/routes/custom/custom.routes.js
import { frontendURL } from 'dashboard/helper/URLHelper';

export const routes = [
    {
        path: frontendURL('accounts/:accountId/acl'),
        name: 'acl',
        meta: {
            requiresAuth: true,
            permissions: ['administrator'],
        },
        component: () =>
            import(/* webpackChunkName: "route-custom-tool" */ './ACL.vue'),
    },
];
