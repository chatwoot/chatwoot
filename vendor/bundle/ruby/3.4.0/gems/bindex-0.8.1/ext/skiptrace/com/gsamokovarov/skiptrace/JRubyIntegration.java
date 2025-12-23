package com.gsamokovarov.skiptrace;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyModule;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.builtin.InstanceVariables;
import org.jruby.anno.JRubyMethod;

public class JRubyIntegration {
    public static void setup(Ruby runtime) {
        RubyModule skiptrace = runtime.defineModule("Skiptrace");
        skiptrace.defineAnnotatedMethods(SkiptraceMethods.class);

        RubyClass exception = runtime.getException();
        exception.defineAnnotatedMethods(ExceptionExtensionMethods.class);

        IRubyObject verbose = runtime.getVerbose();
        try {
            runtime.setVerbose(runtime.getNil());
            runtime.addEventHook(new SetExceptionBindingsEventHook());
        } finally {
            runtime.setVerbose(verbose);
        }
    }

    public static class SkiptraceMethods {
        @JRubyMethod(name = "current_bindings", meta = true)
        public static IRubyObject currentBindings(ThreadContext context, IRubyObject self) {
            return RubyBindingsCollector.collectCurrentFor(context);
        }
    }

    public static class ExceptionExtensionMethods {
        @JRubyMethod
        public static IRubyObject bindings(ThreadContext context, IRubyObject self) {
            InstanceVariables instanceVariables = self.getInstanceVariables();

            IRubyObject bindings = instanceVariables.getInstanceVariable("@bindings");
            if (bindings != null && !bindings.isNil()) {
                return bindings;
            }

            return RubyArray.newArray(context.getRuntime());
        }
    }
}
