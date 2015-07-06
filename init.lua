--wifi.setmode(wifi.STATION)
--wifi.sleeptype(wifi.LIGHT_SLEEP)
--wifi.sta.config("WG","voytek66",1)
dofile("www.lc")
ds.get()
ntp.tz=2
ntp.sync()
tmr.alarm(1, 15000, 0, function() ntp.sync() end )

