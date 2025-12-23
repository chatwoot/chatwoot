package com.gsamokovarov.skiptrace;

import org.jruby.runtime.EventHook;
import org.jruby.runtime.RubyEvent;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubyArray;
import org.jruby.RubyException;

public class SetExceptionBindingsEventHook extends EventHook {
    public boolean isInterestedInEvent(RubyEvent event) {
        return event == RubyEvent.RAISE;
    }

    public void eventHandler(ThreadContext context, String eventName, String file, int line, String name, IRubyObject type) {
        RubyArray bindings = RubyBindingsCollector.collectCurrentFor(context);
        RubyException exception = (RubyException) context.runtime.getGlobalVariables().get("$!");

        IRubyObject exceptionBindings = exception.getInstanceVariable("@bindings");
        if (exceptionBindings == null || exceptionBindings.isNil()) {
            exception.setInstanceVariable("@bindings", bindings);
        }
    }
}
