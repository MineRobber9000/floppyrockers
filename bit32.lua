-- Bit32 shiv
-- Just need the functions AUKit uses
-- Uses bitwise operators since versions before bitwise operators have this builtin

local M = {}

local function normalize(n)
    return (n&0xFFFFFFFF)
end

function M.band(...)
    local arg={...}
    local acc=0xFFFFFFFF
    for i=1,#arg do
        acc=acc&normalize(arg[i])
    end
    return normalize(acc)
end

function M.rshift(x,disp)
    return normalize(normalize(x)>>disp)
end

function M.btest(...)
    return M.band(...)~=0
end

return M