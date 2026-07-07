import { actions, defaultFilters } from '../../crmKanban';
import types from '../../../mutation-types';
import CrmKanbanAPI from '../../../../api/crmKanban';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

vi.mock('../../../../api/crmKanban', () => ({
  default: {
    getPipelineInboxes: vi.fn(),
    createPipelineInbox: vi.fn(),
    deletePipelineInbox: vi.fn(),
    getInboxSettings: vi.fn(),
    updateInboxSetting: vi.fn(),
    getStages: vi.fn(),
    showCard: vi.fn(),
    getBoard: vi.fn(),
    getCards: vi.fn(),
    getFollowUps: vi.fn(),
    createFollowUp: vi.fn(),
    completeFollowUp: vi.fn(),
    cancelFollowUp: vi.fn(),
    getCalendarEvents: vi.fn(),
  },
}));

vi.mock('shared/helpers/mitt', () => ({
  emitter: { emit: vi.fn() },
}));

describe('#crmKanban pipeline inbox actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('fetches linked inboxes and toggles the loading flag', async () => {
    const commit = vi.fn();
    const links = [{ id: 1, inbox_id: 12 }];
    CrmKanbanAPI.getPipelineInboxes.mockResolvedValue({
      data: { payload: links },
    });

    const result = await actions.fetchPipelineInboxes({ commit }, 7);

    expect(result).toEqual(links);
    expect(CrmKanbanAPI.getPipelineInboxes).toHaveBeenCalledWith(7);
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingPipelineInboxes: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingPipelineInboxes: false,
    });
  });

  it('creates a pipeline inbox link with the selected entry stage', async () => {
    const commit = vi.fn();
    const link = {
      id: 1,
      inbox_id: 12,
      default_stage_id: 3,
      auto_create_card: true,
    };
    CrmKanbanAPI.createPipelineInbox.mockResolvedValue({
      data: { payload: link },
    });

    const result = await actions.createPipelineInbox(
      { commit },
      {
        pipelineId: 7,
        inbox_id: 12,
        default_stage_id: 3,
        auto_create_card: true,
      }
    );

    expect(result).toEqual(link);
    expect(CrmKanbanAPI.createPipelineInbox).toHaveBeenCalledWith(7, {
      inbox_id: 12,
      default_stage_id: 3,
      auto_create_card: true,
    });
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isSavingPipelineInbox: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isSavingPipelineInbox: false,
    });
  });

  it('removes a pipeline inbox link by inbox id', async () => {
    const commit = vi.fn();
    CrmKanbanAPI.deletePipelineInbox.mockResolvedValue({});

    await actions.deletePipelineInbox(
      { commit },
      { pipelineId: 7, inboxId: 12 }
    );

    expect(CrmKanbanAPI.deletePipelineInbox).toHaveBeenCalledWith(7, 12);
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isRemovingPipelineInbox: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isRemovingPipelineInbox: false,
    });
  });

  it('fetches CRM inbox settings and toggles the loading flag', async () => {
    const commit = vi.fn();
    const settings = [{ id: 1, inbox_id: 12, crm_enabled: true }];
    CrmKanbanAPI.getInboxSettings.mockResolvedValue({
      data: { payload: settings },
    });

    const result = await actions.fetchInboxSettings({ commit });

    expect(result).toEqual(settings);
    expect(CrmKanbanAPI.getInboxSettings).toHaveBeenCalled();
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingInboxSettings: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingInboxSettings: false,
    });
  });

  it('updates a CRM inbox setting by inbox id', async () => {
    const commit = vi.fn();
    const setting = {
      id: 1,
      inbox_id: 12,
      visibility_mode: 'assigned_only',
    };
    CrmKanbanAPI.updateInboxSetting.mockResolvedValue({
      data: { payload: setting },
    });

    const result = await actions.updateInboxSetting(
      { commit },
      {
        inboxId: 12,
        crm_enabled: true,
        visibility_mode: 'assigned_only',
        auto_create_card: true,
      }
    );

    expect(result).toEqual(setting);
    expect(CrmKanbanAPI.updateInboxSetting).toHaveBeenCalledWith(12, {
      crm_enabled: true,
      visibility_mode: 'assigned_only',
      auto_create_card: true,
    });
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isSavingInboxSetting: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isSavingInboxSetting: false,
    });
  });

  it('fetches stages for the selected settings pipeline', async () => {
    const commit = vi.fn();
    const stages = [{ id: 3, name: 'Entrada' }];
    CrmKanbanAPI.getStages.mockResolvedValue({ data: { payload: stages } });

    const result = await actions.fetchPipelineStages({ commit }, 7);

    expect(result).toEqual(stages);
    expect(CrmKanbanAPI.getStages).toHaveBeenCalledWith(7);
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingPipelineStages: true,
    });
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingPipelineStages: false,
    });
  });

  it('fetches one card detail and upserts it into the board', async () => {
    const commit = vi.fn();
    const card = {
      id: 10,
      title: 'Lead detalhado',
      linked_conversations: [{ id: 3, display_id: 42 }],
      activities: [{ id: 7, event_type: 'update' }],
    };
    CrmKanbanAPI.showCard.mockResolvedValue({ data: { payload: card } });

    const result = await actions.fetchCard({ commit }, 10);

    expect(result).toEqual(card);
    expect(CrmKanbanAPI.showCard).toHaveBeenCalledWith(10);
    expect(commit).toHaveBeenNthCalledWith(1, types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingCard: true,
    });
    expect(commit).toHaveBeenNthCalledWith(
      2,
      types.UPSERT_CRM_KANBAN_CARD,
      card
    );
    expect(commit).toHaveBeenLastCalledWith(types.SET_CRM_KANBAN_UI_FLAG, {
      isFetchingCard: false,
    });
  });

  it('fetches the CRM cards list with current filters', async () => {
    const commit = vi.fn();
    const cards = [{ id: 10, title: 'Lead' }];
    CrmKanbanAPI.getCards.mockResolvedValue({
      data: { payload: cards, meta: { count: 1 } },
    });

    const result = await actions.fetchCardsList(
      {
        commit,
        state: {
          filters: {
            search: 'Lead',
            inboxId: '12',
            ownerId: '',
            priority: '',
            standalone: '',
            followUpStatus: 'pending',
          },
        },
      },
      { pipelineId: 7, page: 2, perPage: 25 }
    );

    expect(result).toEqual(cards);
    expect(CrmKanbanAPI.getCards).toHaveBeenCalledWith({
      search: 'Lead',
      inbox_id: '12',
      follow_up_status: 'pending',
      pipeline_id: 7,
      page: 2,
      per_page: 25,
    });
    expect(commit).toHaveBeenCalledWith(types.SET_CRM_CARDS_LIST, {
      cards,
      meta: { count: 1 },
    });
  });

  it('creates and completes follow-ups through the CRM API', async () => {
    const commit = vi.fn();
    const followUp = { id: 5, title: 'Retornar', status: 'pending' };
    const completed = { ...followUp, status: 'done' };
    CrmKanbanAPI.createFollowUp.mockResolvedValue({
      data: { payload: followUp },
    });
    CrmKanbanAPI.completeFollowUp.mockResolvedValue({
      data: { payload: completed },
    });

    const created = await actions.createFollowUp({ commit }, { card_id: 10 });
    const result = await actions.completeFollowUp({ commit }, 5);

    expect(created).toEqual(followUp);
    expect(result).toEqual(completed);
    expect(CrmKanbanAPI.createFollowUp).toHaveBeenCalledWith({ card_id: 10 });
    expect(CrmKanbanAPI.completeFollowUp).toHaveBeenCalledWith(5);
    expect(commit).toHaveBeenCalledWith(types.UPSERT_CRM_FOLLOW_UP, followUp);
    expect(commit).toHaveBeenCalledWith(types.UPSERT_CRM_FOLLOW_UP, completed);
  });

  it('fetches calendar events with filters', async () => {
    const commit = vi.fn();
    const events = [
      { id: 'follow_up_1', event_type: 'follow_up_reminder_only' },
    ];
    CrmKanbanAPI.getCalendarEvents.mockResolvedValue({
      data: { payload: events },
    });

    const result = await actions.fetchCalendarEvents(
      {
        commit,
        state: {
          filters: {
            search: '',
            inboxId: '12',
            ownerId: '',
            priority: '',
            standalone: '',
            status: '',
            followUpStatus: '',
          },
        },
      },
      { pipeline_id: 7 }
    );

    expect(result).toEqual(events);
    expect(CrmKanbanAPI.getCalendarEvents).toHaveBeenCalledWith({
      inbox_id: '12',
      pipeline_id: 7,
    });
    expect(commit).toHaveBeenCalledWith(types.SET_CRM_CALENDAR_EVENTS, events);
  });
});

describe('#crmKanban board filters', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('maps the high-value filters to params and strips the list-only result', async () => {
    const commit = vi.fn();
    CrmKanbanAPI.getBoard.mockResolvedValue({
      data: { payload: { pipeline: { id: 7 }, stages: [] } },
    });

    await actions.fetchBoard(
      {
        commit,
        state: {
          filters: {
            ...defaultFilters(),
            stageIds: [3, 4],
            teamId: '9',
            valueMin: 100,
            valueMax: 500,
            staleDays: '7',
            responsibleKind: 'bot',
            aiPending: true,
            result: 'won',
          },
        },
      },
      { pipelineId: 7 }
    );

    const sentParams = CrmKanbanAPI.getBoard.mock.calls[0][0];
    expect(sentParams).toMatchObject({
      stage_ids: '3,4',
      team_id: '9',
      value_min: 10000,
      value_max: 50000,
      stale_days: '7',
      responsible_kind: 'bot',
      ai_pending: true,
    });
    // The board is strictly open-only: the list-only `result` param must not leak.
    expect(sentParams.result).toBeUndefined();
  });

  it('maps labelIds and campaignSourceIds to comma-joined params on board fetch', async () => {
    const commit = vi.fn();
    CrmKanbanAPI.getBoard.mockResolvedValue({
      data: { payload: { pipeline: { id: 7 }, stages: [] } },
    });

    await actions.fetchBoard(
      {
        commit,
        state: {
          filters: {
            ...defaultFilters(),
            labelIds: [4, 9],
            // Meta ad ids overflow Number.MAX_SAFE_INTEGER: the csv must keep
            // them as intact strings, never Number-coerced.
            campaignSourceIds: ['120247112194560621', '99'],
          },
        },
      },
      { pipelineId: 7 }
    );

    expect(CrmKanbanAPI.getBoard.mock.calls[0][0]).toMatchObject({
      label_ids: '4,9',
      campaign_source_ids: '120247112194560621,99',
    });
  });

  it('omits label_ids and campaign_source_ids params when those filters are empty', async () => {
    const commit = vi.fn();
    CrmKanbanAPI.getCards.mockResolvedValue({
      data: { payload: [], meta: { count: 0 } },
    });

    await actions.fetchCardsList(
      { commit, state: { filters: defaultFilters() } },
      { pipelineId: 7 }
    );

    const sentParams = CrmKanbanAPI.getCards.mock.calls[0][0];
    expect(sentParams.label_ids).toBeUndefined();
    expect(sentParams.campaign_source_ids).toBeUndefined();
  });

  it('propagates label_ids and campaign_source_ids to the cards list fetch', async () => {
    const commit = vi.fn();
    CrmKanbanAPI.getCards.mockResolvedValue({
      data: { payload: [], meta: { count: 0 } },
    });

    await actions.fetchCardsList(
      {
        commit,
        state: {
          filters: {
            ...defaultFilters(),
            labelIds: [4],
            campaignSourceIds: ['120247112194560621'],
          },
        },
      },
      { pipelineId: 7 }
    );

    expect(CrmKanbanAPI.getCards.mock.calls[0][0]).toMatchObject({
      label_ids: '4',
      campaign_source_ids: '120247112194560621',
    });
  });

  it('refetches (emits CRM_BOARD_REFETCH) instead of upserting when the label filter is active', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          // Label add/remove never broadcasts a card upsert, so labelIds is
          // server-only: any realtime event must defer to a refetch.
          filters: { ...defaultFilters(), labelIds: [4] },
        },
      },
      { event: 'crm.card.updated', card: { id: 1, pipeline_id: 7 } }
    );

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.CRM_BOARD_REFETCH);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_KANBAN_CARD,
      expect.anything()
    );
  });

  it('upserts a card whose campaigns include a selected source_id in any touch position', () => {
    const commit = vi.fn();
    const card = {
      id: 1,
      pipeline_id: 7,
      campaigns: [
        { source_id: '111', headline: 'Primeiro anúncio' },
        { source_id: '120247112194560621', headline: 'Anúncio filtrado' },
      ],
    };
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: {
            ...defaultFilters(),
            campaignSourceIds: ['120247112194560621'],
          },
        },
      },
      { event: 'crm.card.updated', card }
    );

    expect(emitter.emit).not.toHaveBeenCalled();
    expect(commit).toHaveBeenCalledWith(types.UPSERT_CRM_KANBAN_CARD, card);
  });

  it('removes a card whose campaigns miss every selected source_id', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: {
            ...defaultFilters(),
            campaignSourceIds: ['120247112194560621'],
          },
        },
      },
      {
        event: 'crm.card.updated',
        card: { id: 1, pipeline_id: 7, campaigns: [{ source_id: '111' }] },
      }
    );

    expect(commit).toHaveBeenCalledWith(types.REMOVE_CRM_KANBAN_CARD, 1);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_KANBAN_CARD,
      expect.anything()
    );
  });

  it('removes a card without a campaigns payload when the campaign filter is active', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: {
            ...defaultFilters(),
            campaignSourceIds: ['120247112194560621'],
          },
        },
      },
      { event: 'crm.card.updated', card: { id: 1, pipeline_id: 7 } }
    );

    expect(commit).toHaveBeenCalledWith(types.REMOVE_CRM_KANBAN_CARD, 1);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_KANBAN_CARD,
      expect.anything()
    );
  });

  it('refetches (emits CRM_BOARD_REFETCH) instead of upserting when a server-only filter is active', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: { ...defaultFilters(), responsibleKind: 'bot' },
        },
      },
      { event: 'crm.card.updated', card: { id: 1, pipeline_id: 7 } }
    );

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.CRM_BOARD_REFETCH);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_KANBAN_CARD,
      expect.anything()
    );
  });

  it('refetches when a status change no longer matches the active result filter', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: { ...defaultFilters(), result: 'open' },
        },
      },
      // card just marked won while the List shows the "Em andamento" (open) tab
      {
        event: 'crm.card.updated',
        card: { id: 1, pipeline_id: 7, status: 'won' },
      }
    );

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.CRM_BOARD_REFETCH);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_CARD_IN_LIST,
      expect.anything()
    );
  });

  it('upserts without refetching when the card status matches the result filter', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: { ...defaultFilters(), result: 'open' },
        },
      },
      {
        event: 'crm.card.updated',
        card: { id: 1, pipeline_id: 7, status: 'open' },
      }
    );

    expect(emitter.emit).not.toHaveBeenCalled();
    expect(commit).toHaveBeenCalledWith(types.UPSERT_CRM_CARD_IN_LIST, {
      id: 1,
      pipeline_id: 7,
      status: 'open',
    });
  });

  it('refetches a non-open card even when it matches result, since the board is open-only', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: { ...defaultFilters(), result: 'won' },
        },
      },
      {
        event: 'crm.card.updated',
        card: { id: 1, pipeline_id: 7, status: 'won' },
      }
    );

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.CRM_BOARD_REFETCH);
    expect(commit).not.toHaveBeenCalledWith(
      types.UPSERT_CRM_KANBAN_CARD,
      expect.anything()
    );
  });

  it('upserts client-evaluable cards on realtime without refetching', () => {
    const commit = vi.fn();
    actions.handleRealtimeCardEvent(
      {
        commit,
        state: {
          board: { pipeline: { id: 7 } },
          filters: { ...defaultFilters(), stageIds: [3] },
        },
      },
      {
        event: 'crm.card.updated',
        card: { id: 1, pipeline_id: 7, stage_id: 3 },
      }
    );

    expect(emitter.emit).not.toHaveBeenCalled();
    expect(commit).toHaveBeenCalledWith(types.UPSERT_CRM_KANBAN_CARD, {
      id: 1,
      pipeline_id: 7,
      stage_id: 3,
    });
  });
});
