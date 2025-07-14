import { M as MockedModuleType } from './types-DZOqTgiN.js';
export { A as AutomockedModule, d as AutomockedModuleSerialized, a as AutospiedModule, e as AutospiedModuleSerialized, b as ManualMockedModule, f as ManualMockedModuleSerialized, g as MockedModule, h as MockedModuleSerialized, c as MockerRegistry, j as ModuleMockFactory, k as ModuleMockFactoryWithHelper, l as ModuleMockOptions, R as RedirectedModule, i as RedirectedModuleSerialized } from './types-DZOqTgiN.js';

type Key = string | symbol;
interface MockObjectOptions {
    type: MockedModuleType;
    globalConstructors: GlobalConstructors;
    spyOn: (obj: any, prop: Key) => any;
}
declare function mockObject(options: MockObjectOptions, object: Record<Key, any>, mockExports?: Record<Key, any>): Record<Key, any>;
interface GlobalConstructors {
    Object: ObjectConstructor;
    Function: FunctionConstructor;
    RegExp: RegExpConstructor;
    Array: ArrayConstructor;
    Map: MapConstructor;
}

export { type GlobalConstructors, type MockObjectOptions, MockedModuleType, mockObject };
