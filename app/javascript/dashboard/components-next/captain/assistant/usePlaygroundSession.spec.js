import { effectScope, ref } from 'vue';
import { usePlaygroundSession } from './usePlaygroundSession';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getFaqStats: vi.fn(),
  useAlert: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({ useAlert: mocks.useAlert }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mocks.dispatch }),
}));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: ref(true) }),
}));
vi.mock('dashboard/api/captain/assistant', () => ({
  default: { getFaqStats: mocks.getFaqStats },
}));
const assistant = {
  id: 7,
  response_guidelines: ['Be concise'],
  guardrails: ['Do not expose secrets'],
};

const scenarios = [
  { id: 1, title: 'Enabled', description: 'Enabled', enabled: true },
  { id: 2, title: 'Disabled', description: 'Disabled', enabled: false },
];

const deferred = () => {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
};

const createSession = (assistantId = ref(7)) => {
  const scope = effectScope();
  const session = scope.run(() =>
    usePlaygroundSession({
      assistantId,
    })
  );
  return { assistantId, scope, session };
};

describe('usePlaygroundSession', () => {
  beforeEach(() => {
    mocks.getFaqStats.mockResolvedValue({
      data: { documents: 12, approved: 72, faqs: 48 },
    });
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action === 'captainAssistants/show')
        return Promise.resolve(assistant);
      if (action === 'captainScenarios/get') {
        expect(payload).toEqual({ assistantId: 7 });
        return Promise.resolve(scenarios);
      }
      return Promise.resolve();
    });
  });

  it('starts context-free with enabled scenarios and all saved rules included', async () => {
    const { scope, session } = createSession();
    await session.initialize();

    expect(session.includedScenarioIds.value).toEqual([1]);
    expect(mocks.dispatch).toHaveBeenCalledWith('captainTools/getTools');
    expect(session.playgroundConfig.value).toMatchObject({
      scenario_ids: [1],
      temporary_scenarios: [],
      response_guidelines: ['Be concise'],
      guardrails: ['Do not expose secrets'],
      knowledge_text: '',
    });
    expect(session.playgroundConfig.value).not.toHaveProperty('context');
    expect(session.knowledgeStats.value).toEqual({ documents: 12, faqs: 48 });
    scope.stop();
  });

  it('excludes temporary knowledge when its test checkbox is cleared', async () => {
    const { scope, session } = createSession();
    await session.initialize();
    session.setKnowledgeText('Temporary reference text');

    expect(session.playgroundConfig.value.knowledge_text).toBe(
      'Temporary reference text'
    );

    session.isKnowledgeIncluded.value = false;

    expect(session.playgroundConfig.value.knowledge_text).toBe('');
    expect(session.configurationSummary().hasKnowledge).toBe(false);
    scope.stop();
  });

  it('saves temporary knowledge as a Markdown document', async () => {
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action === 'captainAssistants/show')
        return Promise.resolve(assistant);
      if (action === 'captainScenarios/get') return Promise.resolve(scenarios);
      if (action === 'captainDocuments/create') {
        expect(payload).toEqual({
          document: {
            assistant_id: 7,
            name: expect.stringMatching(/^playground-knowledge-.*\.md$/),
            markdown_content: '# Refund policy',
          },
        });
        return Promise.resolve({ id: 13 });
      }
      return Promise.resolve();
    });
    const { scope, session } = createSession();
    await session.initialize();
    session.setKnowledgeText('# Refund policy');

    await session.saveKnowledgeAsDocument();

    expect(session.knowledgeStats.value.documents).toBe(13);
    expect(session.knowledgeText.value).toBe('# Refund policy');
    expect(mocks.useAlert).toHaveBeenCalledWith(
      'CAPTAIN.PLAYGROUND.SETUP.SAVE_KNOWLEDGE_SUCCESS'
    );
    scope.stop();
  });

  it('allows disabled and temporary scenarios to be included without persistence', async () => {
    const { scope, session } = createSession();
    await session.initialize();
    session.toggleScenario(2);
    session.addTemporaryScenario();
    Object.assign(session.temporaryScenarios.value[0], {
      title: 'Refund request',
      description: 'Handle refunds',
      instruction: 'Follow the refund policy',
    });

    expect(session.playgroundConfig.value.scenario_ids).toEqual([1, 2]);
    expect(session.playgroundConfig.value.temporary_scenarios).toEqual([
      expect.objectContaining({
        title: 'Refund request',
        description: 'Handle refunds',
        instruction: 'Follow the refund policy',
      }),
    ]);
    expect(mocks.dispatch).not.toHaveBeenCalledWith(
      'captainScenarios/update',
      expect.anything()
    );
    scope.stop();
  });

  it('saves one temporary scenario as enabled and keeps it included', async () => {
    const savedScenario = {
      id: 3,
      title: 'Refund request',
      description: 'Handle refunds',
      instruction: 'Follow policy',
      enabled: true,
    };
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action === 'captainAssistants/show')
        return Promise.resolve(assistant);
      if (action === 'captainScenarios/get') return Promise.resolve(scenarios);
      if (action === 'captainScenarios/create') {
        expect(payload).toMatchObject({ assistantId: 7, enabled: true });
        return Promise.resolve(savedScenario);
      }
      return Promise.resolve();
    });
    const { scope, session } = createSession();
    await session.initialize();
    session.addTemporaryScenario();
    const temporary = session.temporaryScenarios.value[0];
    Object.assign(temporary, {
      title: savedScenario.title,
      description: savedScenario.description,
      instruction: savedScenario.instruction,
    });

    await session.saveTemporaryScenario(temporary);

    expect(session.temporaryScenarios.value).toHaveLength(0);
    expect(session.includedScenarioIds.value).toContain(3);
    scope.stop();
  });

  it('refetches the assistant before saving one rule and avoids exact duplicates', async () => {
    const latestAssistant = {
      ...assistant,
      response_guidelines: ['Be concise', 'Already saved'],
    };
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action === 'captainAssistants/show')
        return Promise.resolve(latestAssistant);
      if (action === 'captainScenarios/get') return Promise.resolve(scenarios);
      if (action === 'captainAssistants/update') {
        expect(payload).toEqual({
          id: 7,
          assistant: {
            response_guidelines: [
              'Be concise',
              'Already saved',
              'Use short paragraphs',
            ],
          },
        });
        return Promise.resolve();
      }
      return Promise.resolve();
    });
    const { scope, session } = createSession();
    await session.initialize();
    session.addTemporaryRule('guideline');
    session.temporaryGuidelines.value[0].content = 'Use short paragraphs';

    await session.saveTemporaryRule(
      'guideline',
      session.temporaryGuidelines.value[0]
    );

    session.addTemporaryRule('guideline');
    session.temporaryGuidelines.value[0].content = 'Already saved';
    await session.saveTemporaryRule(
      'guideline',
      session.temporaryGuidelines.value[0]
    );

    expect(
      mocks.dispatch.mock.calls.filter(
        ([action]) => action === 'captainAssistants/update'
      )
    ).toHaveLength(1);
    scope.stop();
  });

  it('resets temporary state and restores the latest saved defaults', async () => {
    const { scope, session } = createSession();
    await session.initialize();
    session.toggleScenario(2);
    session.addTemporaryRule('guardrail');
    session.temporaryGuardrails.value[0].content = 'Temporary';
    session.knowledgeText.value = 'Temporary knowledge';

    await session.reset();

    expect(session.includedScenarioIds.value).toEqual([1]);
    expect(session.temporaryGuardrails.value).toEqual([]);
    expect(session.knowledgeText.value).toBe('');
    expect(session.isKnowledgeIncluded.value).toBe(true);
    scope.stop();
  });

  it('ignores an older initialization that finishes after assistants change', async () => {
    const oldAssistantRequest = deferred();
    const oldScenariosRequest = deferred();
    const nextAssistant = {
      id: 8,
      response_guidelines: ['Next guideline'],
      guardrails: ['Next guardrail'],
    };
    const nextScenarios = [
      { id: 8, title: 'Next scenario', description: 'Next', enabled: true },
    ];
    mocks.dispatch.mockImplementation((action, payload) => {
      if (action === 'captainAssistants/show') {
        return payload === 7
          ? oldAssistantRequest.promise
          : Promise.resolve(nextAssistant);
      }
      if (action === 'captainScenarios/get') {
        return payload.assistantId === 7
          ? oldScenariosRequest.promise
          : Promise.resolve(nextScenarios);
      }
      return Promise.resolve();
    });
    const assistantId = ref(7);
    const { scope, session } = createSession(assistantId);

    const oldInitialization = session.initialize();
    assistantId.value = 8;
    await session.reset();
    oldAssistantRequest.resolve(assistant);
    oldScenariosRequest.resolve(scenarios);
    await oldInitialization;

    expect(session.savedScenarios.value).toEqual(nextScenarios);
    expect(session.savedGuidelines.value.map(rule => rule.content)).toEqual([
      'Next guideline',
    ]);
    expect(session.isInitializing.value).toBe(false);
    scope.stop();
  });

  it('keeps an in-flight rule save scoped to the assistant it started on', async () => {
    const latestAssistantRequest = deferred();
    mocks.dispatch.mockImplementation(action => {
      if (action === 'captainAssistants/show')
        return latestAssistantRequest.promise;
      if (action === 'captainAssistants/update') return Promise.resolve();
      return Promise.resolve();
    });
    const assistantId = ref(7);
    const { scope, session } = createSession(assistantId);
    session.addTemporaryRule('guideline');
    const temporaryRule = session.temporaryGuidelines.value[0];
    temporaryRule.content = 'Save this rule';

    const saveRequest = session.saveTemporaryRule('guideline', temporaryRule);
    assistantId.value = 8;
    latestAssistantRequest.resolve(assistant);
    await saveRequest;

    expect(mocks.dispatch).toHaveBeenCalledWith('captainAssistants/update', {
      id: 7,
      assistant: {
        response_guidelines: ['Be concise', 'Save this rule'],
      },
    });
    expect(session.temporaryGuidelines.value).toContain(temporaryRule);
    scope.stop();
  });
});
