package com.gsamokovarov.skiptrace;

import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Binding;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubyBinding;
import org.jruby.RubyArray;
import org.jruby.Ruby;
import java.util.Iterator;

public class RubyBindingsCollector {
    private final Ruby runtime;
    private Iterator<Binding> iterator;

    public static RubyArray collectCurrentFor(ThreadContext context) {
        return new RubyBindingsCollector(context).collectCurrent();
    }

    private RubyBindingsCollector(ThreadContext context) {
        this.iterator = new CurrentBindingsIterator(context);
        this.runtime = context.getRuntime();
    }

    private RubyArray collectCurrent() {
        RubyArray bindings = RubyArray.newArray(runtime);

        while (iterator.hasNext()) {
            bindings.append(((IRubyObject) RubyBinding.newBinding(runtime, iterator.next())));
        }

        return bindings;
    }
}
