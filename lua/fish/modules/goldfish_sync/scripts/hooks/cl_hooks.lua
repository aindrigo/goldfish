function HOOKS:InitPostEntity()
    net.Start("goldfish.sync.ready")
    net.SendToServer()
end