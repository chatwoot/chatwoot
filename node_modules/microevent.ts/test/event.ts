/// <reference path="../typings/index.d.ts"/>

import Event from '../lib/Event';
import * as assert from 'assert';

suite('Event handling', function() {

    let event: Event<string>;

    setup(function() {
        event = new Event();
    });

    test('no handlers', function() {
        assert(!event.hasHandlers, 'event should report any registered handlers');
        assert.doesNotThrow(function() {
            event.dispatch('');
        }, 'dispatch should not throw');
    });

    suite('one handler', function() {
        test('no context', function() {
            let called = false;

            event.addHandler(function(payload: string) {
                assert.equal(payload, 'foo');
                called = true;
            });

            assert(event.hasHandlers, 'event should report registered handlers');

            event.dispatch('foo');
            assert(called, 'the handler should have been called');
        });

        test('with context', function() {
            let foo = 0;

            function handler(payload: string, context: number) {
                assert.equal(payload, 'foo');
                foo = context;
            };

            event.addHandler(handler, 5).dispatch('foo');

            assert.equal(foo, 5, 'context was not transferred correctly');

            assert(event.removeHandler(handler).hasHandlers, 'handler should only be remvoved if contet matches');
            assert(!event.removeHandler(handler, 5).hasHandlers, 'handler should be remvoved if contet matches');
        });

        test('one handler, no context, multiple attachments', function() {
            let i = 0;

            function handler(): void {
                i++;
            }

            event.addHandler(handler).addHandler(handler).dispatch('foo');

            assert.equal(i, 1, 'handler should have been called once');
            assert(event.isHandlerAttached(handler), 'handler should be reported as attached');

            event.removeHandler(handler);
            assert(!event.isHandlerAttached(handler), 'handler should be reported as not attached after removal');
        });

        test('one handler, different contexts, multiple attachments', function() {
            let i = 0;

            function handler(): void {
                i++;
            }

            event.addHandler(handler, 1).addHandler(handler, 2).dispatch('foo');

            assert.equal(i, 2, 'handler should have been called twice');
            assert(!event.isHandlerAttached(handler), 'handler should be reported as not attached w/o context');
            assert(event.isHandlerAttached(handler, 1), 'handler should be reported as attached with proper context');
        });

    });

    suite('two handlers', function() {
        let called1: boolean, called2: boolean,
            contexts: Array<number>;

        function handler1(payload: string) {
            assert.equal(payload, 'foo');
            called1 = true;
        };

        function handler2(payload: string) {
            assert.equal(payload, 'foo');
            called2 = true;
        };

        function ctxHandler(payload: string, context: any) {
            contexts[context] = context;
            assert.equal(payload, 'foo');
        }

        setup(function() {
            called1 = called2 = false;

            contexts = [0, 0, 0];

            event
                .addHandler(handler1)
                .addHandler(handler2);
        });

        test('both attached', function() {
            event.dispatch('foo');

            assert(called1, 'handler 1 should have been called');
            assert(called2, 'handler 2 should have been called');
        });

        test('handler 1 detached', function() {
            event.removeHandler(handler1);

            event.dispatch('foo');

            assert(!called1, 'handler 1 should not have been called');
            assert(called2, 'handler 2 should have been called');
        });

        test('handler 2 detached', function() {
            event.removeHandler(handler2);

            event.dispatch('foo');

            assert(called1, 'handler 1 should have been called');
            assert(!called2, 'handler 2 should not have been called');
        });

        test('context, both attached', function() {
            event
                .addHandler(ctxHandler, 1)
                .addHandler(ctxHandler, 2)
                .dispatch('foo');

            assert.equal(contexts[1], 1, 'context 1 was not transferred correctly');
            assert.equal(contexts[2], 2, 'context 2 was not transferred correctly');
        });

        test('context, handler 1 detached', function() {
            event
                .addHandler(ctxHandler, 1)
                .addHandler(ctxHandler, 2)
                .removeHandler(ctxHandler, 1)
                .dispatch('foo');

            assert.equal(contexts[1], 0, 'handler was not detached');
            assert.equal(contexts[2], 2, 'context 2 was not transferred correctly');
        });

        test('context, handler 2 detached', function() {
            event
                .addHandler(ctxHandler, 1)
                .addHandler(ctxHandler, 2)
                .removeHandler(ctxHandler, 2)
                .dispatch('foo');

            assert.equal(contexts[1], 1, 'context 1 was not transferred correctly');
            assert.equal(contexts[2], 0, 'handler was not detached');
        });
    });
});
