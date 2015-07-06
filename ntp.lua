-- Nodemcu ESP8266 NTP implementation
-- LICENCE: http://opensource.org/licenses/MIT
-- based on https://github.com/annejan/nodemcu-lua-watch/blob/master/ntp.lua
-- 2015-06-12 WG

-- This module uses NodeMCU timer 2 in :sync()
local moduleName = ...
local M = {}
_G[moduleName] = M

local string = string
local tmr = tmr
local wifi = wifi
local net = net
setfenv(1,M)

M.server = "153.19.250.123"	-- IP address of NTP server
M.tz = 1			-- Local Timezone in hours
M.start = 0			-- timestamp of last NodeMCU restart
local sk = nil

-- set time from NTP server
function M.sync()
    if wifi.sta.status() < 5 then
	return nil
    end
    local request=string.char(227, 0, 6, 236, 0,0,0,0,0,0,0,0, 49, 78, 49, 52, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    local hw, lw, utc
    sk=net.createConnection(net.UDP, 0)
    sk:on("receive", function(sck,payload) 
	sck:close()
	hw = payload:byte(41) * 256 + payload:byte(42)
	lw = payload:byte(43) * 256 + payload:byte(44)
	utc = hw * 65536 + lw - 1104494400 - 1104494400
	if utc > 1420000000 then
	    start = utc - tmr.time()
	end
	sk:close()
    end)
    sk:connect(123, M.server)
    sk:send(request)
    tmr.alarm(2, 3000, 0, function() sk:close() end)
end

-- set time from UTC timestamp
function M.setT(ts)
    start = ts - tmr.time()
end

-- get UTC Unix epoch timestamp
function M.timestamp()
    return tmr.time() + start
end

-- get local time string
function M.time(t)
    if t == nil then
	t = tmr.time() + start + tz*3600
    end
    return string.format("%02d:%02d:%02d", t % 86400 / 3600, t % 3600 / 60, t % 60)
end

-- converts Unix timestamp to date string
function M.date(t)
    local a,b,c,d,e,y,m
    -- timestamp to JulianDay
    if t == nil then
	y = (tmr.time() + start + tz*3600) / 86400 + 2440588
    else
	y = t / 86400 + 2440588
    end
    -- JulianDay to date and time
    a = (100 * y - 186721625) / 3652425
    a = y + 1 + a - a / 4
    b = a + 1524
    c = (100 * b - 12210) / 36525
    d = 36525 * c / 100
    e = 10000 * (b - d) / 306001
    -- day
    d = b - d - 306001 * e / 10000
    -- month
    if e<14 then
	m = e - 1
    else
	m = e - 13
    end
    -- year
    if m>2 then
	y = c - 4716
    else
	y = c - 4715
    end
    return string.format("%d-%02d-%02d", y, m, d)
end

return M