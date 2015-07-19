-- periodic data recording for ESP-01
-- 2015.07.18 WG

-- globals
if _temp == nil then _temp = { } end
_ee = 0
if _ee == nil then _ee = dofile("ee.lc").find() end

recordData = nil
function recordData()
    local d
    pwm.setduty(3, 1000)
    -- write data to EEPROM
    dofile("ee.lc").chunkWrite(_ee, _temp[1], _temp[2], dofile("ntp.lc").get())
    _ee = (_ee + 8) % _eesize
    -- record temp to monitoring station
    dofile("http.lc").post(_ee-768)
    -- wait time
    local s = dofile("ntp.lc").timestamp()
    s = 60 * (_cfg["rec"] - s % 3600 / 60 % _cfg["rec"]) - 15
    tmr.alarm(1, s*1000, 0, recordStart)
    pwm.setduty(3, 16)
    if _debug then print("wait rec",s) end
    if _cfg["slp"] > 0 or wifi.sta.status() ~= 5 then
	tmr.alarm(1, 10000, 0, function() node.dsleep(s*1000000) end)
    end
end

recordStart = nil
function recordStart()
    pwm.setduty(3, 1000)
    dofile("ds18.lc").temp(function(r)
	_addr = {}
	_temp = {}
	for k, v in pairs(r) do 
	    _addr[#_addr+1] = k
	    _temp[#_temp+1] = v
	end
	if #_temp<2 then
	    _addr[2] = _addr[1]
	    _temp[2] = _temp[1]
	end
--	_temp[#_temp+1] = dofile("ds32.lc").temp() + _cfg["dt"][1]
--	_addr[#_addr+1] = "DS3231-" .. node.chipid()
	dofile("http.lc").post(_ee-1536)
    end)
    -- time to next record date
    local s = dofile("ntp.lc").timestamp()
    s = 60 * (_cfg["rec"] - s % 3600 / 60 % _cfg["rec"]) - s % 60
    tmr.alarm(1, s*1000, 0, recordData)
    pwm.setduty(3, 16)
    if _debug then print("wait sta",s) end
    -- deep sleep to save power
    if s > 30 and ( _cfg["slp"] > 0 or wifi.sta.status() ~= 5 ) then
	node.dsleep((s-29)*1000000)
    end
end

-- wait for synchronization 
tmr.alarm(1, 2000, 0, recordStart)
-- led
pwm.setclock(3,1)