net.Receive("goldfish.actor.operations", function()
    local operations = net.ReadUInt(16)
    local len = net.ReadUInt(16)
    local data = net.ReadData(len)

    local cursor = 1
    for _ = 1, operations do
        local operation, size = goldfish.actor.DeserializeOperation(data, cursor)
        cursor = cursor + size
        local status, msg = goldfish.actor.PerformOperation(operation)
        if not status then
            print("could not perform actor operation: " .. msg)
        end
    end
end)

function HOOKS:Think()
    local queue = goldfish.actor.queue
    goldfish.actor.queue = {}

    if queue[1] == nil then return end
    net.Start("goldfish.actor.operations")
    net.WriteUInt(#queue, 16)

    local stream = ""
    for _, operation in ipairs(queue) do
        stream = stream .. goldfish.actor.SerializeOperation(operation)
    end

    local len = #stream

    net.WriteUInt(len, 16)
    net.WriteData(stream, len)
    net.SendToServer()
end
