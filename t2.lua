local h
h=node.heap()
for i=0,6 do
    tmr.stop(i)
end
if srv then 
    srv:close()
    srv=nil
    print("-WWW")
end
if ds then
    ds=nil
    package.loaded["ds"]=nil
    print("-DS")
end
if ntp then
    ntp=nil
    package.loaded["ntp"]=nil
    print("-NTP")
end
if rtc then
    rtc=nil
    package.loaded["rtc"]=nil
    print("-RTC")
end
if ee then
    ee=nil
    package.loaded["ee"]=nil
    print("-EE")
end
collectgarbage()
print("-: ", h, node.heap(), node.heap()-h)
h=nil
collectgarbage()
