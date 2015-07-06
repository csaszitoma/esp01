--- WWW HTTP server for DS18B20 on NodeMCU ESP8266
--- Licence MIT
--- 2015-06-12 WG

_ver = "ESP-01-150705"
_file = ""
_head = ""

if ds == nil then
    require("ds")
    file.open("delta","a")
    file.close()
    file.open("delta","r")
    l = file.readline()
    file.close()
    if l then
	ds.deltaT = tonumber(l)
	l = nil
    end
end

if ntp == nil then
    require("ntp")
    ntp.tz = 2
    ntp.sync()
end

dofile("cron.lc")

if srv then
    srv:close()
    srv = nil
end

-- large file send thread routine based on https://github.com/marcoskirsch/nodemcu-httpserver
function sendFile(conn)
    local cont = true
    local pos = 0
    local chunk = ""
    conn:send(_head)
    while cont and #_file > 0 do
	collectgarbage()
	file.open(_file, "r")
	file.seek("set", pos)
	chunk = file.read(1000)
	file.close()
	if chunk == nil then
	    cont = false
	else
	    coroutine.yield()
	    conn:send(chunk)
	    pos = pos + #chunk
	    chunk = nil
	end
    end
end

-- http server
srv=net.createServer(net.TCP, 15)
srv:listen(80, function(conn)
    local connTh
    conn:on("receive", function(client,request)
	collectgarbage()
	local buf = ""
	if string.find(request, "json", 1, true) then
	    buf = "\"temp\":[" .. ds.temp() ..""
	    for i=2,#ds.addrs do
		buf = buf .. "," .. ds.temp(i) .. ""
	    end
	    buf = buf .. "],\"ds\":[\"" .. ds.addr() .. "\""
	    for i=2,#ds.addrs do
		buf = buf .. ",\"" .. ds.addr(i) .. "\""
	    end
	    buf = buf .. "]"
	    _head = "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
	    .. "{" .. buf .. ",\"date\":\"" .. ntp.date()  .. "\",\"time\":\"" .. ntp.time() 
	    .. "\",\"node\":\"" .. node.chipid() .. "\",\"mac\":\"" .. wifi.sta.getmac()
	    .. "\",\"mem\":" .. node.heap() .. ", \"disk\":" .. file.fsinfo() .. ",\"uptime\":" .. tmr.time()
	    .. ",\"ver\":\"" .. _ver .. "\"}"
	    _file = ""
	    connTh=coroutine.create(sendFile)
	elseif string.find(request, "favicon", 1, true) then
	    _head = "HTTP/1.0 404 Not Found\r\n\r\n"
	    _file = ""
	    connTh=coroutine.create(sendFile)
	elseif string.find(request, "csv", 1, true) then
	    _file = "data.csv"
	    _head = "HTTP/1.0 200 OK\r\nContent-Type: text/csv\r\nContent-disposition: attachment;filename=data.csv\r\n\r\nDate;Time;T1;T2\r\n"
	    connTh=coroutine.create(sendFile)
	else
	    _file = "index.html"
	    _head = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"
	    connTh=coroutine.create(sendFile)
	end
	coroutine.resume(connTh,client)
	-- parse parameters
	if string.find(request, "\?") then
	    if string.find(request, "sync=", 1, true) then
		ntp.sync()
	    end
	    if string.find(request, "rm=", 1 , true) then 
		file.remove("data.csv")
	    end
	    _, _, buf = string.find(request, "tz=(\-?%d+)") 
	    if buf ~= nil then
		ntp.tz = tonumber(buf)
	    end
	    _, _, buf = string.find(request, "ts=(%d+)") 
	    if buf ~= nil and tonumber(buf)>1420000000 then
		ntp.setT(tonumber(buf))
	    end
	    _, _, buf = string.find(request, "dt=(\-?%d+)") 
	    if buf ~= nil then
		ds.deltaT = tonumber(buf)
		file.open("delta","w")
		file.writeline(buf)
		file.close()
	    end
	    _, _, buf = string.find(request, "rec=(%d+)") 
	    if buf ~= nil and tonumber(buf) >= 1 then
		_rec = tonumber(buf)
		tmr.stop(0)
		tmr.alarm(0, _rec*60000, 1, recordData)
	    end
	    ds.find()
	end
	buf=nil
    end)
    conn:on("sent", function(conn) 
	collectgarbage()
	if connTh then
	    local connThStatus = coroutine.status(connTh)
	    if connThStatus=="suspended" then
		coroutine.resume(connTh)
	    elseif connThStatus=="dead" then
		conn:close()
		connTh=nil
	    end
	else
	    conn:close() 
	end
    end)
end)