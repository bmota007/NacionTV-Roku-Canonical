'===========================================================
' main.brs - Roku Deep Linking 5.1/5.2 + Behavior Harness safe
' - supports_input_launch=1 in manifest
' - Handles cold-launch deep links (launch/dev?contentId=...&mediaType=...)
' - Handles in-app deep links (roInputEvent)
' - ALWAYS forwards deep link AA to HomeScene.OnInputAssoc()
'===========================================================

sub Main(args as Dynamic)
  print "MAIN: start"

  port = CreateObject("roMessagePort")

  ' roInput (required for 5.2 while running)
  input = CreateObject("roInput")
  if input <> invalid then
    input.SetMessagePort(port)
    print "MAIN: roInput created"
  else
    print "MAIN: roInput FAILED"
  end if

  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)

  scene = screen.CreateScene("HomeScene")
  screen.Show()

  ' ------------------------------------------------------------
  ' COLD LAUNCH deep link handling (ECP launch/dev?contentId=... )
  ' Roku often sends keys as: contentid + mediatype (lowercase)
  ' ------------------------------------------------------------
  if args <> invalid then
    print "MAIN: launch args = "; FormatJson(args)

    cid = ""
    mt  = ""

    ' Accept ALL casing variants
    if args.DoesExist("contentid") and args.contentid <> invalid then cid = "" + args.contentid
    if args.DoesExist("contentId") and args.contentId <> invalid then cid = "" + args.contentId
    if args.DoesExist("contentID") and args.contentID <> invalid then cid = "" + args.contentID

    if args.DoesExist("mediatype") and args.mediatype <> invalid then mt = "" + args.mediatype
    if args.DoesExist("mediaType") and args.mediaType <> invalid then mt = "" + args.mediaType
    if args.DoesExist("MediaType") and args.MediaType <> invalid then mt = "" + args.MediaType

    ' If we got a contentId, force a normalized AA and forward to scene
    if cid <> "" then
      dl = {
        contentid: cid
        contentId: cid
        mediatype: mt
        mediaType: mt
        reason: "input"
      }

      print "MAIN: forwarding cold deep link -> "; FormatJson(dl)

      if scene <> invalid then
        scene.callFunc("OnInputAssoc", dl)
      end if
    else
      print "MAIN: no contentId in launch args (normal launch)"
    end if
  end if

  ' ------------------------------------------------------------
  ' MAIN LOOP: roInputEvent deep links while app is running
  ' ------------------------------------------------------------
  while true
    msg = wait(0, port)

    if msg <> invalid then
      t = type(msg)

      if t = "roSGScreenEvent" then
        if msg.IsScreenClosed() then
          print "MAIN: screen closed"
          return
        end if

      else if t = "roInputEvent" then
        if msg.IsInput() then
          info = msg.GetInfo()
          print "MAIN: roInputEvent GetInfo = "; FormatJson(info)

          cid2 = ""
          mt2  = ""

          if info.DoesExist("contentid") then cid2 = "" + info.contentid
          if info.DoesExist("contentId") then cid2 = "" + info.contentId
          if info.DoesExist("contentID") then cid2 = "" + info.contentID

          if info.DoesExist("mediatype") then mt2 = "" + info.mediatype
          if info.DoesExist("mediaType") then mt2 = "" + info.mediaType
          if info.DoesExist("MediaType") then mt2 = "" + info.MediaType

          if cid2 <> "" then
            dl2 = {
              contentid: cid2
              contentId: cid2
              mediatype: mt2
              mediaType: mt2
              reason: "input"
            }

            print "MAIN: forwarding roInput deep link -> "; FormatJson(dl2)

            if scene <> invalid then
              scene.callFunc("OnInputAssoc", dl2)
            end if
          else
            print "MAIN: roInputEvent had no contentId"
          end if
        end if
      end if
    end if
  end while
end sub