-- periodic data recording
-- 2015.06.15 WG

-- globals
_rec = 15	-- record interval in minutes

recordData=nil
function recordData()
    collectgarbage()
    ntp.sync()
    if file.fsinfo()>128 then
	file.open("data.csv","a")
	file.writeline(ntp.date() .. ";" .. ntp.time() .. ";" .. ds.temp(1) .. ";" .. ds.temp(2))
	file.close()
    end
end

playData=nil
function playData()
    local l
    collectgarbage()
    file.open("data.csv","r")
    l = file.readline()
    while l ~= nil do
	print(string.sub(l, 1, -2))
	l = file.readline()
    end
    file.close()
end

if ntp.timestamp() > 1420000000 then
    recordData()
end

tmr.stop(0)
tmr.alarm(0, _rec*60000, 1, recordData)
