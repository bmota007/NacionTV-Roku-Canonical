' main.brs — extract roInputEvent.GetInfo() and pass AA to scene

sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port   = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("HomeScene")
    screen.Show()

    input = CreateObject("roInput")
    if input <> invalid then
        input.SetMessagePort(port)
        print "MAIN: roInput created + port set"
    else
        print "MAIN: roInput FAILED to create"
    end if

    ' COLD deep link
    if args <> invalid and args.contentId <> invalid then
        print "MAIN: COLD deeplink contentId="; args.contentId; " mediaType="; args.mediaType
        if scene <> invalid then
            scene.callFunc("requestDeepLink", args.contentId)
        else
            print "MAIN: scene is invalid"
        end if
    else
        print "MAIN: COLD deeplink: none"
    end if

    while true
        msg = wait(0, port)
        mt = type(msg)

        if mt = "roSGScreenEvent" then
            if msg.IsScreenClosed() then return

        else if mt = "roInputEvent" then
            ' Convert to plain AA so SG can receive it
            di = invalid
            if GetInterface(msg, "ifInputEvent") <> invalid then
                if msg.IsInput() then di = msg.GetInfo()
            else
                di = msg.GetInfo()
            end if

            print "MAIN: roInputEvent -> di="; di
            if di <> invalid and scene <> invalid then
                ' New handler that accepts the assocarray directly
                scene.callFunc("OnInputAssoc", di)
            end if
        end if
    end while
end sub