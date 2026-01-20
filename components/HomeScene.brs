'===========================================================
' HomeScene.brs - FIXED & FULL CODE
'===========================================================

sub init()
  ' 1. Signal Dialog start immediately
  m.top.signalBeacon("AppDialogInitiate")

  ' 2. UI Node setup with findNode
  m.Video     = m.top.findNode("Video")
  m.Bg        = m.top.findNode("Bg")
  m.BgDim     = m.top.findNode("BgDim")
  m.Menu      = m.top.findNode("Menu")
  m.IntlTile  = m.top.findNode("IntlTile")
  m.HouTile   = m.top.findNode("HouTile")
  m.IntlFocus = m.top.findNode("IntlFocus")
  m.HouFocus  = m.top.findNode("HouFocus")
  m.IntlDot   = m.top.findNode("IntlLiveDot")
  m.HouDot    = m.top.findNode("HouLiveDot")
  m.IntlBadge = m.top.findNode("IntlBadge")
  m.HouBadge  = m.top.findNode("HouBadge")

  m.isPlaying = false
  m.focusIndex = 0 
  m.pulseOn = true

  ' 3. Load Config (Wrapped in safety check)
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

  ' 4. Video Observer setup
  if m.Video <> invalid then
    m.Video.enableUI = false
    m.Video.visible = false
    m.Video.observeField("state", "onVideoStateChanged")
  end if

  ' 5. Pulse Timer
  m.pulseTimer = CreateObject("roSGNode", "Timer")
  if m.pulseTimer <> invalid then
    m.pulseTimer.duration = 0.45
    m.pulseTimer.repeat = true
    m.pulseTimer.observeField("fire", "onPulseTick")
    m.pulseTimer.control = "start"
  end if

  ' 6. Initial UI State
  showHome()
  m.top.setFocus(true)
  updateFocus()

  ' 7. MANDATORY: Clear Splash Screen hang
  m.top.signalBeacon("AppDialogComplete")
  m.top.signalBeacon("AppLaunchComplete")
end sub

sub showHome()
  m.isPlaying = false
  if m.Menu <> invalid then m.Menu.visible = true
  if m.Bg <> invalid then m.Bg.visible = true
  if m.BgDim <> invalid then m.BgDim.visible = true
  if m.Video <> invalid then
    m.Video.control = "stop"
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
  if m.Video <> invalid then m.Video.visible = true
  m.top.setFocus(true)
end sub

sub updateFocus()
  if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.0
  if m.HouFocus <> invalid then m.HouFocus.opacity = 0.0
  if m.IntlTile <> invalid then m.IntlTile.scale = [0.96, 0.96]
  if m.HouTile <> invalid then m.HouTile.scale = [0.96, 0.96]

  if m.focusIndex = 0 then
    if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.22
    if m.IntlTile <> invalid then m.IntlTile.scale = [1.04, 1.04]
    if m.IntlDot <> invalid then m.IntlDot.opacity = 1.0
    if m.HouDot <> invalid then m.HouDot.opacity = 0.0
  else
    if m.HouFocus <> invalid then m.HouFocus.opacity = 0.22
    if m.HouTile <> invalid then m.HouTile.scale = [1.04, 1.04]
    if m.IntlDot <> invalid then m.IntlDot.opacity = 0.0
    if m.HouDot <> invalid then m.HouDot.opacity = 1.0
  end if
end sub

sub onPulseTick()
  if m.isPlaying then return
  m.pulseOn = not m.pulseOn
  
  target = invalid
  if m.focusIndex = 0 then target = m.IntlDot else target = m.HouDot

  if target <> invalid
    if m.pulseOn then target.opacity = 1.0 else target.opacity = 0.25
  end if
end sub

sub playSelected()
  item = invalid
  if m.focusIndex = 0 then item = m.streamIntl else item = m.streamHou
  
  if item <> invalid and item.Stream <> invalid and m.Video <> invalid
    cn = CreateObject("roSGNode", "ContentNode")
    cn.Title = item.Title
    cn.Url = item.Stream
    cn.streamFormat = item.streamFormat
    cn.live = true
    showPlayer()
    m.Video.content = cn
    m.Video.control = "play"
  end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  if m.isPlaying
    if key = "back" then 
        showHome()
        return true
    end if
    return true
  end if
  if key = "left" then 
    m.focusIndex = 0
    updateFocus()
  else if key = "right" then 
    m.focusIndex = 1
    updateFocus()
  else if key = "OK" or key = "select" then 
    playSelected()
  end if
  return true
end function

sub onVideoStateChanged()
  if m.Video <> invalid and m.Video.state = "error" then showHome()
end sub

sub requestDeepLink(contentId): end sub
sub OnInputAssoc(info): end sub
sub launchContent(item): end sub