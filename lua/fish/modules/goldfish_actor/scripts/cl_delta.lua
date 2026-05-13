net.Receive("goldfish.actor.operations", function()
    local operations = net.ReadUInt(32)
    local len = net.ReadUInt(16)
    local data = net.ReadData(len)

    local buf = serial.Buffer(data)
    for _ = 1, operations do
        local operation = goldfish.actor.DeserializeOperation(buf)
        local status, msg = goldfish.actor.PerformOperation(operation)
        if not status then
            print("could not perform actor operation: " .. msg)
        end
    end
end)
