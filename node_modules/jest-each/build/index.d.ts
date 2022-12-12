/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Global } from '@jest/types';
import bind from './bind';
declare type Global = Global.Global;
declare const install: (g: Global, table: Global.EachTable, ...data: Global.TemplateData) => {
    describe: {
        (title: string, suite: Global.EachTestFn<Global.BlockFn>, timeout?: number | undefined): void;
        skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    };
    fdescribe: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    fit: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    it: {
        (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
        skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        concurrent: {
            (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
            only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        };
    };
    test: {
        (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
        skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        concurrent: {
            (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
            only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        };
    };
    xdescribe: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    xit: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    xtest: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
};
declare const each: {
    (table: Global.EachTable, ...data: Global.TemplateData): ReturnType<typeof install>;
    withGlobal(g: Global): (table: Global.EachTable, ...data: Global.TemplateData) => {
        describe: {
            (title: string, suite: Global.EachTestFn<Global.BlockFn>, timeout?: number | undefined): void;
            skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        };
        fdescribe: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        fit: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        it: {
            (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
            skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            concurrent: {
                (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
                only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
                skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            };
        };
        test: {
            (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
            skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            concurrent: {
                (title: string, test: Global.EachTestFn<Global.TestFn>, timeout?: number | undefined): void;
                only: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
                skip: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
            };
        };
        xdescribe: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        xit: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
        xtest: (title: string, test: Global.EachTestFn<Global.TestCallback>, timeout?: number | undefined) => void;
    };
};
export { bind };
export default each;
