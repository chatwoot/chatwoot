package com.gsamokovarov.skiptrace;

import java.lang.reflect.Field;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.Frame;
import org.jruby.runtime.backtrace.BacktraceElement;
import org.jruby.runtime.builtin.IRubyObject;

public class ThreadContextInternals {
    private ThreadContext context;

    public ThreadContextInternals(ThreadContext context) {
        this.context = context;
    }

    public Frame[] getFrameStack() {
        return (Frame[]) getPrivateField("frameStack");
    }

    public int getFrameIndex() {
        return (Integer) getPrivateField("frameIndex");
    }

    public DynamicScope[] getScopeStack() {
        return (DynamicScope[]) getPrivateField("scopeStack");
    }

    public int getScopeIndex() {
        return (Integer) getPrivateField("scopeIndex");
    }

    public BacktraceElement[] getBacktrace() {
        return (BacktraceElement[]) getPrivateField("backtrace");
    }

    public int getBacktraceIndex() {
        return (Integer) getPrivateField("backtraceIndex");
    }

    private Object getPrivateField(String fieldName) {
        try {
            Field field = ThreadContext.class.getDeclaredField(fieldName);

            field.setAccessible(true);

            return field.get(context);
        } catch (NoSuchFieldException exc) {
            throw new ThreadContextInterfaceException(fieldName, exc);
        } catch (IllegalAccessException exc) {
            throw new ThreadContextInterfaceException(fieldName, exc);
        }
    }
}
