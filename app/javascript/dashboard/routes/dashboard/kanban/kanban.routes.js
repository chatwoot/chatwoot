// app/javascript/dashboard/routes/custom/custom.routes.js
import { frontendURL } from 'dashboard/helper/URLHelper';

export const routes = [
    {
        path: frontendURL('accounts/:accountId/kanban'),
        name: 'kanban',
        meta: {
            requiresAuth: true,
            permissions: ['administrator', 'agent', 'custom_role'],
        },
        component: () =>
            import(/* webpackChunkName: "route-custom-tool" */ './Kanban.vue'),
    },
];
