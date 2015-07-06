-- list all files
print("Memory: ", node.heap())
print("Disk: ", file.fsinfo())
l = file.list();
for k,v in pairs(l) do
  print(k, v)
end
l = nil
