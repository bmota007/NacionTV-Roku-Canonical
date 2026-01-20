sub Main(args as Dynamic)
    appMonitor = CreateObject("roAppMemoryMonitor")
    if appMonitor <> invalid
        appMonitor.GetChannelMemoryLimit()
    end if

    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")    
    screen.SetMessagePort(port)

    scene = screen.CreateScene("HomeScene")
    screen.Show()

    input = CreateObject("roInput")
    if input <> invalid then input.SetMessagePort(port)

    while true
        msg = wait(0, port)
        if msg = invalid
            ' no-op
        else if type(msg) = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if type(msg) = "roInputEvent"
            di = msg.GetInfo()
            if di <> invalid and scene <> invalid then scene.callFunc("OnInputAssoc", di)
        end if
    end while
end sub