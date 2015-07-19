-- config
dofile("config.lc").load()

-- WiFi
wifi.setmode(wifi.STATIONAP)
wifi.sleeptype(wifi.LIGHT_SLEEP)
wifi.sta.config(_cfg["ssid"], _cfg["pwd"], 1)
wifi.sta.connect()

-- led
pwm.setup(3, 5, 16)
pwm.start(3)

-- globals
_ver = "ESP-01-150718"
_eesize = 8192
_ee = 0
_temp = { }
_addr = { }
if cfg == nil then cfg = { } end
if _cfg["rec"] == nil then _cfg["rec"] = 15 end	-- record interval in minutes
if _cfg["tz"] == nil then _cfg["tz"] = 2 end

-- modules
-- start RTC DS3231 time synchronization
dofile("ntp.lc").sync()
-- find first free EEPROM address
_ee = 0
_ee = dofile("ee.lc").find()

-- start
-- start DS18B20 temperature conversion
dofile("ds18.lc").temp(function(r)
    _temp = { }
    _addr = { }
    for k, v in pairs(r) do
	_temp[#_temp+1] = v
	_addr[#_addr+1] = k
    end
    if #_temp < 2 then
	_addr[2] = _addr[1]
	_temp[2] = _temp[1]
    end
--    _temp[#_temp+1] = dofile("ds32.lc").temp() + _cfg["dt"][1]
--    _addr[#_addr+1] = "DS3231-" .. node.chipid()
end)
-- start www server and periodic record
tmr.alarm(4, 2000, 0, function()
    dofile("www.lc")
    dofile("cron.lc")
end)
