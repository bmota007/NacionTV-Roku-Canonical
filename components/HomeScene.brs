'===========================================================
' HomeScene.brs - TWO STATIC TILES (Samsung-like focus)
' - Charcoal glow behind focused tile
' - Focused tile zooms forward, other backs out slightly
' - EN VIVO dot pulses ONLY on focused tile
'===========================================================

sub init()
  print "HomeScene: init (two tiles + keys)"

  m.Video = m.top.findNode("Video")
  m.Bg = m.top.findNode("Bg")
  m.BgDim = m.top.findNode("BgDim")
  m.Menu = m.top.findNode("Menu")

  m.IntlTile = m.top.findNode("IntlTile")
  m.HouTile  = m.top.findNode("HouTile")

  m.IntlFocus = m.top.findNode("IntlFocus")
  m.HouFocus  = m.top.findNode("HouFocus")

  m.IntlDot = m.top.findNode("IntlLiveDot")
  m.HouDot  = m.top.findNode("HouLiveDot")

  ' Optional: badge groups (so we can slightly fade non-focused)
  m.IntlBadge = m.top.findNode("IntlBadge")
  m.HouBadge  = m.top.findNode("HouBadge")

  m.isPlaying = false
  m.focusIndex = 0 ' 0=Intl, 1=Houston
  m.pulseOn = true

  ' Load streams from Config.brs
  cfg = loadConfig()
  m.streamIntl = invalid
  m.streamHou  = invalid

  for each it in cfg
    if it <> invalid and it.Title <> invalid then
      t = UCase(it.Title)
      if t = "INTERNACIONAL" then m.streamIntl = it
      if t = "HOUSTON" then m.streamHou = it
    end if
  end for

  ' Video setup
  if m.Video <> invalid then
    m.Video.enableUI = false
    m.Video.visible = false
    m.Video.observeField("state", "onVideoStateChanged")
  end if

  ' Pulse timer for EN VIVO dot
  m.pulseTimer = CreateObject("roSGNode", "Timer")
  if m.pulseTimer <> invalid then
    m.pulseTimer.duration = 0.45
    m.pulseTimer.repeat = true
    m.pulseTimer.observeField("fire", "onPulseTick")
    m.pulseTimer.control = "start"
  end if

  showHome()

  ' Force focus so onKeyEvent always fires
  m.top.setFocus(true)

  updateFocus()

  print "HomeScene: init done"
end sub


' -------- Interface functions (safe) --------
sub requestDeepLink(contentId)
  print "HomeScene: requestDeepLink "; contentId
end sub

sub OnInputAssoc(info)
  print "HomeScene: OnInputAssoc "; info
end sub

sub launchContent(item)
  print "HomeScene: launchContent "; item
end sub


' -------- UI --------
sub showHome()
  m.isPlaying = false

  if m.Menu <> invalid then m.Menu.visible = true
  if m.Bg <> invalid then m.Bg.visible = true
  if m.BgDim <> invalid then m.BgDim.visible = true

  if m.Video <> invalid then
    m.Video.control = "stop"
    m.Video.content = invalid
    m.Video.visible = false
  end if

  updateFocus()
  m.top.setFocus(true)
end sub

sub showPlayer()
  m.isPlaying = true

  if m.Menu <> invalid then m.Menu.visible = false
  if m.Bg <> invalid then m.Bg.visible = false
  if m.BgDim <> invalid then m.BgDim.visible = false

  if m.Video <> invalid then
    m.Video.visible = true
  end if

  m.top.setFocus(true)
end sub


' Samsung-like focus:
' - charcoal glow BEHIND the focused tile (opacity ~0.20-0.25)
' - focused tile zooms forward slightly
' - non-focused tile backs out a little
sub updateFocus()
  ' If Roku steals focus, pull it back
  if m.top <> invalid and m.top.hasFocus() = false then
    m.top.setFocus(true)
  end if

  ' Reset glow
  if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.0
  if m.HouFocus <> invalid then m.HouFocus.opacity = 0.0

  ' Base scale for both = slightly backed out
  if m.IntlTile <> invalid then m.IntlTile.scale = [0.96, 0.96]
  if m.HouTile  <> invalid then m.HouTile.scale  = [0.96, 0.96]

  ' Slightly dim badge on non-focused (optional nice touch)
  if m.IntlBadge <> invalid then m.IntlBadge.opacity = 0.85
  if m.HouBadge  <> invalid then m.HouBadge.opacity  = 0.85

  ' Focused styling
  if m.focusIndex = 0 then
    if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.22
    if m.IntlTile  <> invalid then m.IntlTile.scale = [1.04, 1.04]
    if m.IntlBadge <> invalid then m.IntlBadge.opacity = 1.0
  else
    if m.HouFocus <> invalid then m.HouFocus.opacity = 0.22
    if m.HouTile  <> invalid then m.HouTile.scale = [1.04, 1.04]
    if m.HouBadge <> invalid then m.HouBadge.opacity = 1.0
  end if

  ' Only focused tile dot is visible (and will pulse)
  if m.IntlDot <> invalid then m.IntlDot.opacity = 0.0
  if m.HouDot  <> invalid then m.HouDot.opacity  = 0.0

  if m.focusIndex = 0 then
    if m.IntlDot <> invalid then m.IntlDot.opacity = 1.0
  else
    if m.HouDot <> invalid then m.HouDot.opacity = 1.0
  end if

  ' Reset pulse state so it looks crisp when switching focus
  m.pulseOn = true
end sub


' Pulse the dot ONLY on the focused tile
sub onPulseTick()
  if m.isPlaying then return

  m.pulseOn = not m.pulseOn

  dimOpacity = 0.25
  brightOpacity = 1.0

  target = invalid
  if m.focusIndex = 0 then
    target = m.IntlDot
  else
    target = m.HouDot
  end if

  if target <> invalid then
    if m.pulseOn then
      target.opacity = brightOpacity
    else
      target.opacity = dimOpacity
    end if
  end if
end sub


' -------- Playback --------
sub playSelected()
  item = invalid
  if m.focusIndex = 0 then item = m.streamIntl else item = m.streamHou

  if item = invalid then
    print "HomeScene: playSelected item invalid"
    return
  end if

  if item.Stream = invalid or item.Stream = "" then
    print "HomeScene: playSelected missing Stream URL"
    return
  end if

  cn = CreateObject("roSGNode", "ContentNode")
  cn.Title = item.Title
  cn.Url = item.Stream
  cn.streamFormat = item.streamFormat
  cn.live = true

  print "HomeScene: PLAY "; cn.Title; " -> "; cn.Url

  showPlayer()

  if m.Video <> invalid then
    m.Video.content = cn
    m.Video.control = "play"
  end if
end sub


' -------- Remote keys (MUST RETURN BOOLEAN) --------
function onKeyEvent(key as String, press as Boolean) as Boolean
  if press <> true then return false

  ' When playing: BACK returns home
  if m.isPlaying = true then
    if key = "back" then
      showHome()
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
  end if

  ' Some remotes send Play or OK
  if key = "OK" or key = "Select" or key = "select" or key = "play" then
    playSelected()
    return true
  end if

  return false
end function


' -------- Video state --------
sub onVideoStateChanged()
  if m.Video = invalid then return

  if m.Video.state = "error" then
    print "VIDEO ERROR:"; m.Video.errorMsg
    showHome()
  end if
end sub