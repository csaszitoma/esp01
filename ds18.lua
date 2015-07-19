-- DS18B20 one wire module for ESP8266 NodeMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- 2015-06-14 WG
--
-- Example:
-- dofile("ds18.lua").temp(4, function(r) for k,v in pairs(r) do print(k,v) end end)

local M
do
-- locals
local pin = 4
-- addr to string
local function addr2str(a)
    return string.format("%02x-%02x%02x%02x%02x%02x%02x", a:byte(1), 
	a:byte(7), a:byte(6), a:byte(5), a:byte(4), a:byte(3), a:byte(2))
end
-- table of devices reads
local function temp(callback)
    -- get devices list
    local d = { }
    local a
    ow.setup(pin)
    ow.reset_search(pin)
    repeat
	a = ow.search(pin)
	if a ~= nil and ow.crc8(a) == 0 then
	    d[#d + 1] = a
	end
	tmr.wdclr()
    until a == nil
    -- start conversion
    ow.reset(pin)
    --ow.skip(pin)
    ow.write(pin, 0xCC, 1)
    ow.write(pin, 0x44, 1)
    tmr.alarm(3, 800, 0, function()
	-- read all temperatures
	local r = { }
	local t, x
	for i=1,#d do
	    ow.reset(pin)
	    --ow.select(pin, d[i])
	    ow.write(pin, 0x55, 1)
	    for j=1,8 do
		ow.write(pin, d[i]:byte(j), 1)
	    end
	    ow.write(pin, 0xBE, 1)
	    x = ow.read_bytes(pin, 9)
	    if ow.crc8(x) == 0 then
		 t = x:byte(2) * 256 + x:byte(1)
		if t > 32767 then
		    t = t - 65536
		end
		t = t * 625 / 10
	    else
		t = 0
	    end
	    if t ~= 85000 then r[addr2str(d[i])] = t end
	    tmr.wdclr()
	end
	if callback ~= nil then callback(r) end
    end)
end
-- table of devices addresses
local function addr()
    -- get devices list
    local d = { }
    local a
    ow.setup(pin)
    ow.reset_search(pin)
    repeat
	a = ow.search(pin)
	if a ~= nil and ow.crc8(a) == 0 then
	    d[#d + 1] = addr2str(a)
	end
	tmr.wdclr()
    until a == nil
    return d
end
-- export functions
M = { temp = temp, addr = addr }
end
return M