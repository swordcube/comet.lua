local Native = {}

local _PAGE_SIZE = io.popen('getconf PAGE_SIZE'):read('*number')
function Native.getProcessMemory()
    local statmf = io.open('/proc/self/statm', 'r')
    local _ = statmf:read('*number') -- Ignore VmSize
    local cpuMemory = statmf:read('*number') * _PAGE_SIZE
    statmf:close()
    return cpuMemory
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