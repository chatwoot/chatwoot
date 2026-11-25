import { describe, it, expect, vi } from 'vitest';

vi.mock('../InternalChatLayout.vue', () => ({ default: {} }));
vi.mock('../DraftsList.vue', () => ({ default: {} }));

const { default: internalChatRoutes } = await import('../internalChat.routes');

const allRoutes = routes =>
  routes.flatMap(route => [route, ...allRoutes(route.children || [])]);

describe('internal chat routes', () => {
  // A member with a custom role carries `custom_role` where an agent carries `agent`, and the
  // backend lets that member into the internal chat; a route that asked for `agent` only would
  // hide the chat from them.
  it('let every role that can use the chat reach each of its pages', () => {
    const routes = allRoutes(internalChatRoutes.routes);

    expect(routes.length).toBeGreaterThan(1);
    routes.forEach(route => {
      expect(route.meta.permissions).toEqual(
        expect.arrayContaining(['administrator', 'agent', 'custom_role'])
      );
    });
  });
});
