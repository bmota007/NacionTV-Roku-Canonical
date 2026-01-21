'===========================================================
' HomeScene.brs - TWO STATIC TILES (CERT + MAX COMPAT)
' - Supports Direct-to-Play reliably (fixes race condition)
' - Queues deep link until streams are loaded and scene ready
' - Fires AppLaunchComplete once
'===========================================================

sub init()
  print "HomeScene: init"

  ' --- Nodes ---
  m.Video     = m.top.findNode("Video")
  m.Menu      = m.top.findNode("Menu")
  m.Bg        = m.top.findNode("Bg")
  m.BgDim     = m.top.findNode("BgDim")

  m.IntlTile  = m.top.findNode("IntlTile")
  m.HouTile   = m.top.findNode("HouTile")

  m.IntlFocus = m.top.findNode("IntlFocus")
  m.HouFocus  = m.top.findNode("HouFocus")

  m.IntlDot   = m.top.findNode("IntlLiveDot")
  m.HouDot    = m.top.findNode("HouLiveDot")

  ' --- State ---
  m.isPlaying          = false
  m.focusIndex         = 0   ' 0=Internacional, 1=Houston
  m.launchBeaconFired  = false

  ' NEW: readiness + pending deep link (critical for harness)
  m.sceneReady         = false
  m.pendingDeepLink    = invalid
  m.deepLinkHandled    = false

  ' Timer to safely run deep link after init finishes
  m.dlTimer = CreateObject("roSGNode", "Timer")
  if m.dlTimer <> invalid then
    m.dlTimer.repeat = false
    m.dlTimer.duration = 0.10
    m.dlTimer.observeField("fire", "tryProcessPendingDeepLink")
  end if

  ' --- Video setup ---
  if m.Video <> invalid then
    m.Video.enableUI = false
    m.Video.visible  = false
    m.Video.observeField("state", "onVideoStateChanged")
  end if

  ' --- Load streams from loadConfig() ---
  cfg = loadConfig()
  if cfg = invalid then cfg = []

  m.streamIntl = invalid
  m.streamHou  = invalid

  for each it in cfg
    if it <> invalid and it.Title <> invalid then
      t = UCase(it.Title)
      if t = "INTERNACIONAL" then m.streamIntl = it
      if t = "HOUSTON" then m.streamHou = it
    end if
  end for

  print "HomeScene: streamIntl valid? "; (m.streamIntl <> invalid)
  print "HomeScene: streamHou  valid? "; (m.streamHou  <> invalid)

  ' --- Home visible by default ---
  if m.Menu <> invalid then m.Menu.visible = true
  if m.Bg <> invalid then m.Bg.visible = true
  if m.BgDim <> invalid then m.BgDim.visible = true

  updateFocus()

  ' Ensure focus
  if m.Menu <> invalid then m.Menu.setFocus(true)
  m.top.setFocus(true)

  ' CERT 3.2: AppLaunchComplete beacon (fire once)
  if m.launchBeaconFired = false then
    m.top.signalBeacon("AppLaunchComplete")
    m.launchBeaconFired = true
    print "HomeScene: AppLaunchComplete fired"
  end if

  ' Mark ready AFTER config is loaded and UI is set
  m.sceneReady = true

  ' If a deep link arrived early, process it now (via timer)
  if m.pendingDeepLink <> invalid and m.dlTimer <> invalid then
    m.dlTimer.control = "start"
  end if

  print "HomeScene: init done"
end sub


sub tryProcessPendingDeepLink()
  if m.deepLinkHandled = true then return
  if m.pendingDeepLink = invalid then return

  ' Wait until streams exist
  if m.streamIntl = invalid or m.streamHou = invalid then
    print "HomeScene: still waiting for streams, retrying deep link..."
    if m.dlTimer <> invalid then m.dlTimer.control = "start"
    return
  end if

  print "HomeScene: processing pending deep link now"
  dl = m.pendingDeepLink
  m.pendingDeepLink = invalid
  m.deepLinkHandled = true

  ' Run it
  OnInputAssoc(dl)
end sub


sub updateFocus()
  if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.0
  if m.HouFocus  <> invalid then m.HouFocus.opacity  = 0.0

  if m.IntlTile <> invalid then m.IntlTile.scale = [0.95, 0.95]
  if m.HouTile  <> invalid then m.HouTile.scale  = [0.95, 0.95]

  if m.IntlDot <> invalid then m.IntlDot.opacity = 0.0
  if m.HouDot  <> invalid then m.HouDot.opacity  = 0.0

  if m.focusIndex = 0 then
    if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.25
    if m.IntlTile  <> invalid then m.IntlTile.scale   = [1.05, 1.05]
    if m.IntlDot   <> invalid then m.IntlDot.opacity  = 1.0
  else
    if m.HouFocus <> invalid then m.HouFocus.opacity = 0.25
    if m.HouTile  <> invalid then m.HouTile.scale    = [1.05, 1.05]
    if m.HouDot   <> invalid then m.HouDot.opacity   = 1.0
  end if
end sub


sub playSelected()
  item = invalid
  if m.focusIndex = 0 then item = m.streamIntl else item = m.streamHou

  if item = invalid then
    print "HomeScene: playSelected item invalid"
    return
  end if

  if item.Stream = invalid or item.Stream = "" then
    print "HomeScene: playSelected Stream missing"
    return
  end if

  print "HomeScene: PLAY "; item.Title; " -> "; item.Stream

  cn = CreateObject("roSGNode", "ContentNode")
  cn.Title        = item.Title
  cn.Url          = item.Stream
  cn.streamFormat = item.streamFormat
  cn.live         = true

  m.isPlaying = true

  if m.Menu <> invalid then m.Menu.visible = false
  if m.Bg <> invalid then m.Bg.visible = false
  if m.BgDim <> invalid then m.BgDim.visible = false

  if m.Video <> invalid then
    m.Video.visible = true
    m.Video.content = cn
    m.Video.control = "play"
  end if

  m.top.setFocus(true)
end sub


sub stopPlaybackToHome()
  if m.Video <> invalid then
    m.Video.control = "stop"
    m.Video.visible = false
    m.Video.content = invalid
  end if

  if m.Menu <> invalid then m.Menu.visible = true
  if m.Bg <> invalid then m.Bg.visible = true
  if m.BgDim <> invalid then m.BgDim.visible = true

  m.isPlaying = false
  updateFocus()
  m.top.setFocus(true)
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
  if press <> true then return false

  if m.isPlaying = true then
    if key = "back" then
      stopPlaybackToHome()
      return true
    end if
    return true
  end if

  if key = "left" then
    m.focusIndex = 0
    updateFocus()
    return true
  else if key = "right" then
    m.focusIndex = 1
    updateFocus()
    return true
  else if key = "OK" or key = "Select" or key = "select" then
    playSelected()
    return true
  end if

  return false
end function


sub onVideoStateChanged()
  if m.Video = invalid then return

  s = m.Video.state
  print "HomeScene: Video state="; s

  if s = "error" then
    print "VIDEO ERROR:"; m.Video.errorMsg
    stopPlaybackToHome()
  end if
end sub


'===========================================================
' Deep linking / Direct-to-Play handler (robust)
'===========================================================
sub OnInputAssoc(info as Dynamic)
  print "HomeScene: OnInputAssoc "; info
  if info = invalid then return

  ' If harness calls us before init finishes, queue it.
  if m.sceneReady = false or m.streamIntl = invalid or m.streamHou = invalid then
    print "HomeScene: NOT READY yet -> queue deep link"
    m.pendingDeepLink = info
    if m.dlTimer <> invalid then m.dlTimer.control = "start"
    return
  end if

  contentId = ""
  mediaType = ""

  if type(info) = "roAssociativeArray" then
    if info.DoesExist("contentId") then contentId = LCase("" + info.contentId)
    if info.DoesExist("contentID") then contentId = LCase("" + info.contentID)
    if info.DoesExist("contentid") then contentId = LCase("" + info.contentid)

    if info.DoesExist("mediaType") then mediaType = LCase("" + info.mediaType)
    if info.DoesExist("mediatype") then mediaType = LCase("" + info.mediatype)
    if info.DoesExist("MediaType") then mediaType = LCase("" + info.MediaType)
  end if

  print "HomeScene: DTP contentId="; contentId; " mediaType="; mediaType
  if contentId = "" then return

  if Instr(contentId, "hou") > 0 then
    m.focusIndex = 1
  else if Instr(contentId, "int") > 0 then
    m.focusIndex = 0
  else
    return
  end if

  updateFocus()
  playSelected()
end sub


sub requestDeepLink(contentId as Dynamic)
  info = { contentId: contentId, mediaType: "live", reason: "input" }
  OnInputAssoc(info)
end sub


sub launchContent(item as Dynamic)
  ' not used
end sub