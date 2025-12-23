package com.gsamokovarov.skiptrace;

import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.Binding;
import org.jruby.runtime.Frame;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.backtrace.BacktraceElement;
import java.util.Iterator;
import java.util.NoSuchElementException;

class CurrentBindingsIterator implements Iterator<Binding> {
    private Frame[] frameStack;
    private int frameIndex;

    private DynamicScope[] scopeStack;
    private int scopeIndex;

    private BacktraceElement[] backtrace;
    private int backtraceIndex;

    CurrentBindingsIterator(ThreadContext context) {
        ThreadContextInternals contextInternals = new ThreadContextInternals(context);

        this.frameStack = contextInternals.getFrameStack();
        this.frameIndex = contextInternals.getFrameIndex();

        this.scopeStack = contextInternals.getScopeStack();
        this.scopeIndex = contextInternals.getScopeIndex();

        this.backtrace = contextInternals.getBacktrace();
        this.backtraceIndex = contextInternals.getBacktraceIndex();
    }

    public boolean hasNext() {
        return frameIndex >= 0 && scopeIndex >= 0 && backtraceIndex >= 0;
    }

    public Binding next() {
        if (!hasNext()) {
            throw new NoSuchElementException();
        }

        Frame frame = frameStack[frameIndex--];
        DynamicScope scope = scopeStack[scopeIndex--];
        BacktraceElement element = backtrace[backtraceIndex--];

        return BindingBuilder.build(frame, scope, element);
    }

    public void remove() {
        throw new UnsupportedOperationException();
    }
}
