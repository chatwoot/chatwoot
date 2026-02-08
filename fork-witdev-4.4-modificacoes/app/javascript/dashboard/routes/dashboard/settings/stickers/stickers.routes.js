import { frontendURL } from '../../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';

const StickerManagement = () => import('./Index.vue');
const StickerPackDetails = () => import('./PackDetails.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/stickers'),
      name: 'sticker_management',
      meta: {
        permissions: [ROLES.ADMINISTRATOR],
      },
      component: StickerManagement,
    },
    {
      path: frontendURL(
        'accounts/:accountId/settings/stickers/packs/:packName'
      ),
      name: 'sticker_pack_details',
      meta: {
        permissions: [ROLES.ADMINISTRATOR],
      },
      component: StickerPackDetails,
    },
  ],
};
