local ffi = require("ffi")

if love.system.getOS() == "Windows" then
    ffi.cdef[[
        int _putenv(const char *envstring);
    ]]
    --- Sets an environment variable in the current process
    --- @param name string
    --- @param value string
    os.setenv = function(name, value)
        ffi.C._putenv(name .. "=" .. value)
    end
else
    ffi.cdef[[
      int setenv(const char *name, const char *value, int overwrite);
    ]]
    --- Sets an environment variable in the current process
    --- @param name string
    --- @param value string
    os.setenv = function(name, value)
        ffi.C.setenv(name, value, 1)
    end
end