#include "microprofile.h"
#include "profiler.h"

#ifdef DF_USE_PROFILING

void profiler::initialize()
{
    MicroProfileSetEnableAllGroups(true);
    MicroProfileSetForceMetaCounters(true);
    MicroProfileStartContextSwitchTrace();
}
void profiler::shutdown()
{
    MicroProfileShutdown();
}
void profiler::register_thread(const char* name)
{
    MicroProfileOnThreadCreate(name);
}
void profiler::frame_tick()
{
    MicroProfileFlip(nullptr);
}
#endif