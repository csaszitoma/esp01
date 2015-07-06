-- show all data recorded
-- 2015.06.15 WG

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

playData()
playData = nil
collectGarbage()
