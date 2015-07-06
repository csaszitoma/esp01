-- DS18B20 one wire module for ESP8266 NodeMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- 2015-06-14 WG

local modname = ...
local M = {}
_G[modname] = M

local table = table
local string = string
local tmr = tmr
local ow = ow
setfenv(1,M)

-- DS18B20 dq pin
M.pinDQ = 3
M.deltaT = 0
M.addrs = {}

-- get DS18B20 tempeature in 1/1000 C
function M.get(k)
    local a, data, crc, temp
    if k == nil then k = 1 end
    a = M.addrs[k]
    if a == nil then a = M.addrs[1] end
    ow.setup(pinDQ)
    if a~=nil and ow.reset(pinDQ) then
--	ow.select(pinDQ, a)
--	ow.write(pinDQ, 0x44, 1)	-- start conversion
--	tmr.delay(750000)
--	ow.reset(pinDQ)
	ow.select(pinDQ, a)
	ow.write(pinDQ, 0xBE, 1)	-- read command
	data = ow.read_bytes(pinDQ, 9)
	-- start next conversion
	ow.reset(pinDQ)
	ow.skip(pinDQ)
	ow.write(pinDQ, 0x44, 1)
	crc = ow.crc8(string.sub(data, 1, 8))
	if crc == data:byte(9) then
	    temp = data:byte(1) + data:byte(2) * 256
	    if temp > 32767 then
		temp = temp - 65536
	    end
	    temp = temp * 625
	    return temp/10 + deltaT
	end
    end
    return nil
end

function M.temp(k)
    local temp
    if k == nil then k = 1 end
    temp = M.get(k)
    if temp ~= nil then
	return string.format("%d.%03d", temp/1000, temp%1000)
    end
    return nil
end

function M.addr(k)
    local a
    if k == nil then k = 1 end
    a = M.addrs[k]
    if a ~= nil then
	return string.format("%02x-%02x%02x%02x%02x%02x%02x", a:byte(1), a:byte(7), a:byte(6), a:byte(5), a:byte(4), a:byte(3), a:byte(2))
    end
    return nil
end

function M.find()
    local a
    M.addrs = {}
    ow.setup(pinDQ)
    ow.reset_search(pinDQ)
    repeat
	a = ow.search(pinDQ)
	if a ~= nil and a:byte(8) == ow.crc8(string.sub(a,1,7)) then
	    table.insert(M.addrs, a)
	end
	tmr.wdclr()
    until a == nil
    ow.reset_search(pinDQ)
end

M.find()

return M
