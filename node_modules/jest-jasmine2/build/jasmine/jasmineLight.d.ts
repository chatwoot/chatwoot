/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Jasmine, SpecDefinitionsFn } from '../types';
import JsApiReporter from './JsApiReporter';
export declare const create: (createOptions: Record<string, any>) => Jasmine;
export declare const _interface: (jasmine: Jasmine, env: any) => {
    describe(description: string, specDefinitions: SpecDefinitionsFn): any;
    xdescribe(description: string, specDefinitions: SpecDefinitionsFn): any;
    fdescribe(description: string, specDefinitions: SpecDefinitionsFn): any;
    it(): any;
    xit(): any;
    fit(): any;
    beforeEach(): any;
    afterEach(): any;
    beforeAll(): any;
    afterAll(): any;
    pending(): any;
    fail(): any;
    spyOn(obj: Record<string, any>, methodName: string, accessType?: string | undefined): any;
    jsApiReporter: JsApiReporter;
    jasmine: Jasmine;
};
