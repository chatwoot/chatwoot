package com.gsamokovarov.skiptrace;

class ThreadContextInterfaceException extends RuntimeException {
    private static final String MESSAGE_TEMPLATE =
        "Expected private field %s in ThreadContext is missing";

    ThreadContextInterfaceException(String fieldName) {
        super(String.format(MESSAGE_TEMPLATE, fieldName));
    }

    ThreadContextInterfaceException(String fieldName, Throwable cause) {
        super(String.format(MESSAGE_TEMPLATE, fieldName), cause);
    }
}
