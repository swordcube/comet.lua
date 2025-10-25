local Native = {}

local ffi = require("ffi")

ffi.cdef [[
    typedef unsigned int mach_msg_type_number_t;
    typedef struct { int32_t port; } mach_port_t;
    typedef int kern_return_t;

    mach_port_t mach_task_self();

    kern_return_t task_info(
        mach_port_t target_task,
        int flavor,
        int *task_info_out,
        mach_msg_type_number_t *task_info_outCnt
    );

    enum { TASK_BASIC_INFO = 20 };

    typedef struct task_basic_info {
        int suspend_count;
        int virtual_size;
        int resident_size;

        // google ai integers:
        int max_resident_size;
        int user_time;
        int system_time;
        int policy;
        int power_status;
        int all_faults;
        int system_faults;
        int user_faults;
        int pageins;
        int copy_on_write_faults;
        int zero_fill_faults;
        int reactivations;
        int pageouts;
        int wired_size;
        int resident_size_ext;
    } task_basic_info_data_t;
]]

function Native.getProcessMemory()
    local task = ffi.C.mach_task_self()

    local info_data = ffi.new("struct task_basic_info")
    local info_size = ffi.new("mach_msg_type_number_t[1]", ffi.sizeof(info_data) / 4)

    local result = ffi.C.task_info(
        task,
        ffi.C.TASK_BASIC_INFO,
        ffi.cast("int*", info_data),
        info_size
    )

    if result ~= 0 then
        error("task_info() failed with result: " .. result)
    end

    return tonumber(info_data.resident_size)
end

local peak = 0
function Native.getPeakProcessMemory()
    local cur = Native.getProcessMemory()
    if cur > peak then
        peak = cur
    end
    return peak
end

return Native
