#include "blah.h"

static void NO_INLINE bar() {
    asm("");
}

void func() {
    // which bar?
    bar();
}
