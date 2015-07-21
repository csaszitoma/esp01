-- DHT11 DHT22 humidity and temperature sensor for NodeMCU
-- LICENCE: http://opensource.org/MIT
-- 15.07.20 WG

local M
do
-- local cache speed up gpio.read
local gpio = gpio
local gpio_read = gpio.read

local function read(pin, dht22)
    -- subroutine wait for pin value
    local function w(b)
	local c = 0
	while c < 100 and gpio_read(pin) ~= b do c = c + 1 end
	return c
    end
    -- default GPIO2 (4)
    if pin == nil then pin = 4 end
    -- return values
    local t, h
    -- temporary buffer for 5-bytes result
    local b = { 0, 0, 0, 0, 0 }
    -- start the device
    gpio.mode(pin, gpio.INPUT, gpio.PULLUP)
    --tmr.delay(1000)
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, 0)
    tmr.delay(20000)
    gpio.write(pin, 1)
    gpio.mode(pin, gpio.INPUT, gpio.PULLUP)
    -- wait for device presence -1 means no answer from device
    if w(0) > 10 or w(1) > 10 then return -1, -1 end
    -- 5-bytes respone
    for i = 1, 5 do
	x = 0
	-- 8-bits per byte
	for j = 1, 8 do
	    x = x + x
	    -- long (70us) one means 1 short (28us) one means 0
	    if w(0) > 1 then x = x + 1 end
	    w(1)
	end
	b[i] = x
    end
    -- crc sum of bytes mod 256
    local crc = (b[1] + b[2] + b[3] + b[4]) % 256
    -- check CRC -2 means CRC Error
    if crc ~= b[5] then return -2, -2 end
    -- DHT-22 can negative temperatures and fractional parts
    if dht22 then
	t = 256 * b[3] + b[4]
	if t > 32767 then t = t - 65536 end
	t = 100 * t
	h = 100 * (256 * b[1] + b[2])
    -- DHT-11 only positive integers
    else
	t = 1000 * b[3]
	h = 1000 * b[1]
    end
    -- result in miliC and mili%
    return t, h
end
-- export
M = { read = read }
end
return M