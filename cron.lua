-- periodic data recording for ESP-01
-- 2015.07.18 WG

-- globals
if _temp == nil then _temp = { } end
if _ee == nil then _ee = dofile("ee.lc").find() end

--recordData = nil
function recordData()
    local d
    pwm.setduty(3, 1000)
    if _debug then print("#record", dofile("ntp.lc").time()) end
    -- write data to EEPROM
    dofile("ee.lc").chunkWrite(_ee, _temp[1], _temp[2], dofile("ntp.lc").get())
    _ee = (_ee + 8) % _eesize
    -- record temp to monitoring station
    dofile("http.lc").post(_ee-768)
    -- wait time
    pwm.setduty(3, 16)
    if _cfg["slp"] > 0 or wifi.sta.status() ~= 5 then
	tmr.alarm(1, 1000, 0, node.restart)
    end
end

--recordStart = nil
function recordStart()
    local h, m, s
    pwm.setduty(3, 1000)
    if _debug then print("#start", dofile("ntp.lc").time()) end
    h, m, s = dofile("ntp.lc").get()
    if m % _cfg["rec"] == 0 then
--	ntpSync()
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
	    dofile("http.lc").post(_ee-1536)
	end)
	tmr.alarm(2, 1000, 0, function() recordData() end)
    end
    -- time to next record date
    tmr.alarm(1, (60-s)*1000, 0, recordStart)
    pwm.setduty(3, 16)
end

-- set NodeMCU start time from NTP server
--ntpSync = nil
function ntpSync()
    if wifi.sta.status() ~= 5 then
	tmr.alarm(4, 3000, 0, ntpSync)
	return
    end
    local request=string.char(227, 0, 6, 236, 0,0,0,0,0,0,0,0, 49, 78, 49, 52, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    if sk ~= nil then
	sk:close()
	sk = nil
    end
    sk=net.createConnection(net.UDP, 0)
    sk:on("receive", function(sck, payload)
	local hw, lw, utc
	sck:close()
	hw = payload:byte(41) * 256 + payload:byte(42)
	lw = payload:byte(43) * 256 + payload:byte(44)
	utc = hw * 65536 + lw - 1104494400 - 1104494400
	if utc > 1420000000 then
	    _start = utc - tmr.now()/1000000
	end
	sk:close()
    end)
    sk:connect(123, _cfg["ntpserver"])
    sk:send(request)
end

ntpSync()
-- wait for synchronization 
tmr.alarm(2, 5000, 0, recordStart)
-- led
pwm.setclock(3, 1)