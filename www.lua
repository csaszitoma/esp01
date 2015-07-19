--- WWW HTTP server for DS18B20 on NodeMCU ESP-07 (ESP8266)
--- Licence MIT
--- 2015-07-02 WG
-- globals
_file = ""
_head = ""
-- locals
if srv then
    srv:close()
    srv = nil
end
-- large file send thread routine based on https://github.com/marcoskirsch/nodemcu-httpserver
sendFile = nil
function sendFile(conn)
    local cont = true
    local pos = 0
    local chunk = ""
    conn:send(_head)
    _head = nil
    while cont and #_file > 0 do
	collectgarbage()
	file.open(_file, "r")
	file.seek("set", pos)
	chunk = file.read(1400)
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
srv=net.createServer(net.TCP, 10)
srv:listen(80, function(conn)
    local connTh
    conn:on("receive", function(client, request)
	collectgarbage()
	local buf = ""
	if string.find(request, "/cfg", 1, true) then
	    file.open("config", "r")
	    buf = file.read(1400)
	    file.close()
	    buf = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
	    .. buf
	    conn:send(buf)
	elseif string.find(request, "/json", 1, true) then
	    buf = "\"t\":[" .. string.format("%d.%d", (_temp[1]+50)/1000, (_temp[1]+50)%1000/100)
	    for i=2,#_temp do
		buf = buf .. "," .. string.format("%d.%d", (_temp[i]+50)/1000, (_temp[i]+50)%1000/100)
	    end
	    buf = buf .. "],\"a\":" .. cjson.encode(_addr)
--	    buf = buf .. "],\"a\":[\"" .. _addr[1] .. "\""
--	    for i=2,#_addr do
--		buf = buf .. ",\"" .. _addr[i] .. "\""
--	    end
--	    buf = buf .. "]"
	    buf = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
	    .. "{" .. buf .. ",\"date\":\"" .. dofile("ntp.lc").date()  .. "\",\"time\":\"" .. dofile("ntp.lc").time()
	    .. "\",\"node\":\"" .. node.chipid() .. "\",\"mac\":\"" .. wifi.sta.getmac()
	    .. "\",\"mem\":" .. node.heap() .. ", \"disk\":" .. (_eesize-_ee) .. ",\"uptime\":" .. tmr.time()
	    .. ",\"ver\":\"" .. _ver .. "\"}"
	    conn:send(buf)
	elseif string.find(request, "favicon", 1, true) then
	    buf = "HTTP/1.1 404 Not Found\r\n\r\n"
	    conn:send(buf)
	elseif string.find(request, "/ee", 1, true) then
	    local a = _ee - 1024
	    if a < 0 then a = 0 end
	    buf = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"  .. crypto.toBase64(dofile("ee.lc").read(a, 1024))
	    a = nil
	    conn:send(buf)
	elseif string.find(request, "/config", 1, true) then
	    _file = "config.html"
	    _head = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
	    connTh = coroutine.create(sendFile)
	elseif string.find(request, "/csv", 1, true) then
	    _file = "data.csv"
	    _head = "HTTP/1.1 200 OK\r\nContent-Type: text/csv\r\nContent-disposition: attachment;filename=data.csv\r\n\r\n"
	    connTh = coroutine.create(sendFile)
	else
--	    if string.find(request, "ncoding:.*gzip") then
--		_file = "index.html.gz"
--		_head = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Encoding: gzip\r\n\r\n"
--	    else
		_file = "index.html"
		_head = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
--	    end
	    connTh = coroutine.create(sendFile)
	end
	-- parse parameters
	if string.find(request, "\?") then
	    dofile("config.lc").decode(request)
	end
	-- large file send
	if connTh then coroutine.resume(connTh, client) end
	buf = nil
    end)
    conn:on("sent", function(conn) 
	if connTh then
	    local connThStatus = coroutine.status(connTh)
	    if connThStatus == "suspended" then
		coroutine.resume(connTh)
	    elseif connThStatus == "dead" then
		conn:close()
		connTh = nil
	    end
	else
	    conn:close() 
	end
    end)
end)