declare class MockerRegistry {
    private readonly registry;
    clear(): void;
    keys(): IterableIterator<string>;
    add(mock: MockedModule): void;
    register(json: MockedModuleSerialized): MockedModule;
    register(type: 'redirect', raw: string, url: string, redirect: string): RedirectedModule;
    register(type: 'manual', raw: string, url: string, factory: () => any): ManualMockedModule;
    register(type: 'automock', raw: string, url: string): AutomockedModule;
    register(type: 'autospy', raw: string, url: string): AutospiedModule;
    delete(id: string): void;
    get(id: string): MockedModule | undefined;
    has(id: string): boolean;
}
type MockedModule = AutomockedModule | AutospiedModule | ManualMockedModule | RedirectedModule;
type MockedModuleType = 'automock' | 'autospy' | 'manual' | 'redirect';
type MockedModuleSerialized = AutomockedModuleSerialized | AutospiedModuleSerialized | ManualMockedModuleSerialized | RedirectedModuleSerialized;
declare class AutomockedModule {
    raw: string;
    url: string;
    readonly type = "automock";
    constructor(raw: string, url: string);
    static fromJSON(data: AutomockedModuleSerialized): AutospiedModule;
    toJSON(): AutomockedModuleSerialized;
}
interface AutomockedModuleSerialized {
    type: 'automock';
    url: string;
    raw: string;
}
declare class AutospiedModule {
    raw: string;
    url: string;
    readonly type = "autospy";
    constructor(raw: string, url: string);
    static fromJSON(data: AutospiedModuleSerialized): AutospiedModule;
    toJSON(): AutospiedModuleSerialized;
}
interface AutospiedModuleSerialized {
    type: 'autospy';
    url: string;
    raw: string;
}
declare class RedirectedModule {
    raw: string;
    url: string;
    redirect: string;
    readonly type = "redirect";
    constructor(raw: string, url: string, redirect: string);
    static fromJSON(data: RedirectedModuleSerialized): RedirectedModule;
    toJSON(): RedirectedModuleSerialized;
}
interface RedirectedModuleSerialized {
    type: 'redirect';
    url: string;
    raw: string;
    redirect: string;
}
declare class ManualMockedModule {
    raw: string;
    url: string;
    factory: () => any;
    cache: Record<string | symbol, any> | undefined;
    readonly type = "manual";
    constructor(raw: string, url: string, factory: () => any);
    resolve(): Promise<Record<string | symbol, any>>;
    static fromJSON(data: ManualMockedModuleSerialized, factory: () => any): ManualMockedModule;
    toJSON(): ManualMockedModuleSerialized;
}
interface ManualMockedModuleSerialized {
    type: 'manual';
    url: string;
    raw: string;
}

type Awaitable<T> = T | PromiseLike<T>;
type ModuleMockFactoryWithHelper<M = unknown> = (importOriginal: <T extends M = M>() => Promise<T>) => Awaitable<Partial<M>>;
type ModuleMockFactory = () => any;
interface ModuleMockOptions {
    spy?: boolean;
}

export { AutomockedModule as A, type MockedModuleType as M, RedirectedModule as R, AutospiedModule as a, ManualMockedModule as b, MockerRegistry as c, type AutomockedModuleSerialized as d, type AutospiedModuleSerialized as e, type ManualMockedModuleSerialized as f, type MockedModule as g, type MockedModuleSerialized as h, type RedirectedModuleSerialized as i, type ModuleMockFactory as j, type ModuleMockFactoryWithHelper as k, type ModuleMockOptions as l };
