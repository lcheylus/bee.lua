local function parse(folder)
    local version
    local export = {}
    for line in io.lines(folder.."/lua.h") do
        local verstr = line:match "^%s*#%s*define%s*LUA_VERSION_NUM%s*([0-9]+)%s*$"
        if verstr then
            version = tostring(tonumber(verstr:sub(1, -3))) .. tostring(tonumber(verstr:sub(-2, -1)))
        end
        local api = line:match "^%s*LUA_API[%w%s%*_]+%(([%w_]+)%)"
        if api then
            export[#export+1] = api
        end
    end
    for line in io.lines(folder.."/lauxlib.h") do
        local api = line:match "^%s*LUALIB_API[%w%s%*_]+%(([%w_]+)%)"
        if api then
            export[#export+1] = api
        end
    end
    for line in io.lines(folder.."/lualib.h") do
        local api = line:match "^%s*LUALIB_API[%w%s%*_]+%(([%w_]+)%)"
        if api then
            export[#export+1] = api
        end
    end
    table.sort(export)
    return version, export
end

local input, output, dllname = ...
local version, export = parse(input)
local s = {}
for _, api in ipairs(export) do
    s[#s+1] = ([[#pragma comment(linker, "/export:%s=%s.%s")]]):format(api, dllname, api)
end
local f <close> = assert(io.open(output, "w"))
f:write(table.concat(s, "\n"))
