' main.brs — OLDER ROKU SAFE (no SignalBeacon)

sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("HomeScene")
    screen.Show()

    ' Create roInput and consume roInputEvent (optional)
    input = CreateObject("roInput")
    if input <> invalid then
        input.SetMessagePort(port)
        print "MAIN: roInput created + port set"
    else
        print "MAIN: roInput FAILED to create"
    end if

    ' Cold deep link (optional)
    if args <> invalid and args.contentId <> invalid then
        print "MAIN: COLD deeplink contentId="; args.contentId; " mediaType="; args.mediaType
        if scene <> invalid then scene.callFunc("requestDeepLink", args.contentId)
    else
        print "MAIN: COLD deeplink: none"
    end if

    while true
        msg = wait(0, port)
        if msg = invalid then
            ' no-op

        else if type(msg) = "roSGScreenEvent" then
            if msg.IsScreenClosed() then return

        else if type(msg) = "roInputEvent" then
            di = msg.GetInfo()
            print "MAIN: roInputEvent -> "; di
            if di <> invalid and scene <> invalid then
                scene.callFunc("OnInputAssoc", di)
            end if
        end if
    end while
end sub