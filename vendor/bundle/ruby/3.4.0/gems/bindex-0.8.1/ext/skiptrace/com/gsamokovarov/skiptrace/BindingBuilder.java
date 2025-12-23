package com.gsamokovarov.skiptrace;

import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.Binding;
import org.jruby.runtime.Frame;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.backtrace.BacktraceElement;

class BindingBuilder {
    public static Binding build(Frame frame, DynamicScope scope, BacktraceElement element) {
        return new Binding(frame, scope, element.method, element.filename, element.line);
    }
}
