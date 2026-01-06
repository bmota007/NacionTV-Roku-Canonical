' HomeScene.brs — add OnInputAssoc that accepts AA, keep your working logic

sub init()
  m.Bg      = m.top.findNode("Bg")
  m.BgDim   = m.top.findNode("BgDim")
  m.RowList = m.top.findNode("RowList")
  m.Video   = m.top.findNode("Video")

  m.pendingContentId = invalid
  m.isReady = false
  m.idIndex = {}
  m.titleIndex = {}

  if m.Video <> invalid then
    m.Video.enableUI = false
    m.Video.visible  = false
    m.Video.observeField("state", "onVideoStateChanged")
  end if

  m.configArray = loadConfig()

  content = createObject("roSGNode", "ContentNode")
  row = createObject("roSGNode", "ContentNode")
  if m.configArray <> invalid then
    for each item in m.configArray
      node = createObject("roSGNode", "ContentNode")
      node.title        = item.title
      node.HDPosterUrl  = item.logo
      node.url          = item.stream
      node.streamFormat = item.streamFormat
      node.live         = true
      ' Ensure id exists: use item.id or fallback to lowercase(title)
      if item.id <> invalid and item.id <> "" then
        node.id = item.id
      else
        node.id = LCase(item.title)
      end if
      row.appendChild(node)
    end for
  end if
  content.appendChild(row)

  if m.RowList <> invalid then
    m.RowList.content = content
    m.RowList.visible = true
    m.RowList.setFocus(true)
    m.RowList.observeField("rowItemSelected", "onChannelSelected")
  end if

  buildIndexes()

  m.isReady = true
  tryPlayPendingDeepLink()

  setIdleUI(true)
  m.top.signalBeacon("AppLaunchComplete")
end sub

sub buildIndexes()
  m.idIndex = {}
  m.titleIndex = {}

  if m.RowList = invalid then return
  row = m.RowList.content.getChild(0)
  if row = invalid then return

  for j = 0 to row.getChildCount()-1
    item = row.getChild(j)
    if item <> invalid
      if item.id <> invalid and item.id <> "" then
        m.idIndex[LCase(item.id)] = { row: 0, col: j }
      end if
      if item.title <> invalid and item.title <> "" then
        m.titleIndex[LCase(item.title)] = { row: 0, col: j }
      end if
    end if
  end for

  print "DL INDEX (ids):"; m.idIndex
  print "DL INDEX (titles):"; m.titleIndex
end sub

' NEW: warm deep link handler that receives AA from main.brs
function OnInputAssoc(di as Object) as Boolean
  print "SCENE: OnInputAssoc di="; di
  if di <> invalid and di.contentId <> invalid then
    ' Diagnostic helper
    if LCase(di.contentId) = "__list__" then
      printAvailableDeepLinks()
      return true
    end if
    requestDeepLink(di.contentId)
    return true
  end if
  return false
end function

sub printAvailableDeepLinks()
  if m.RowList = invalid then return
  row = m.RowList.content.getChild(0)
  if row = invalid then return
  print "====== Available Deep Links ======"
  for j = 0 to row.getChildCount()-1
    item = row.getChild(j)
    if item <> invalid then
      print " id="; item.id; "  title="; item.title
    end if
  end for
  print "=================================="
end sub

function requestDeepLink(contentId as String) as void
  print "SCENE: requestDeepLink contentId="; contentId
  m.pendingContentId = contentId
  tryPlayPendingDeepLink()
end function

sub tryPlayPendingDeepLink()
  if m.pendingContentId = invalid then return
  if m.isReady and launchContent(m.pendingContentId) then
    print "SCENE: pending deep link played"
    m.pendingContentId = invalid
  else
    timer = CreateObject("roSGNode", "Timer")
    timer.observeField("fire", "onRetryDeepLink")
    timer.duration = 0.15
    timer.control = "start"
    m.retryTimer = timer
  end if
end sub

sub onRetryDeepLink()
  if m.pendingContentId <> invalid then
    print "SCENE: retry deep link id="; m.pendingContentId
    if launchContent(m.pendingContentId) then
      m.pendingContentId = invalid
    end if
  end if
  if m.retryTimer <> invalid then m.retryTimer.control = "stop"
end sub

sub setIdleUI(isIdle as Boolean)
  if m.Bg      <> invalid then m.Bg.visible      = isIdle
  if m.BgDim   <> invalid then m.BgDim.visible   = isIdle
  if m.RowList <> invalid then m.RowList.visible = isIdle
  if m.Video   <> invalid then m.Video.visible   = not isIdle
end sub

function launchContent(contentId as String) as Boolean
  if m.Video = invalid or m.RowList = invalid then return false
  if contentId = invalid then return false

  row = m.RowList.content.getChild(0)
  if row = invalid then return false

  idLC = LCase(contentId)

  if m.idIndex.doesexist(idLC) then
    idx = m.idIndex[idLC]
    return playByIndex(idx.row, idx.col)
  end if

  if m.titleIndex.doesexist(idLC) then
    idx = m.titleIndex[idLC]
    return playByIndex(idx.row, idx.col)
  end if

  for j = 0 to row.getChildCount()-1
    item = row.getChild(j)
    if item <> invalid then
      if item.id <> invalid and LCase(item.id) = idLC then return playByIndex(0, j)
      if item.title <> invalid and LCase(item.title) = idLC then return playByIndex(0, j)
    end if
  end for

  print "SCENE: DeepLink no match contentId="; contentId
  printAvailableDeepLinks()
  return false
end function

function playByIndex(r as Integer, c as Integer) as Boolean
  row = m.RowList.content.getChild(r)
  if row = invalid then return false
  if c < 0 or c >= row.getChildCount() then return false

  item = row.getChild(c)
  print "SCENE: launching id="; item.id; "  title="; item.title
  m.Video.content = item
  m.Video.control = "play"
  setIdleUI(false)
  m.RowList.setFocus(false)
  m.Video.setFocus(true)
  return true
end function

sub onChannelSelected()
  if m.RowList = invalid or m.Video = invalid then return
  idx = m.RowList.rowItemSelected
  print "SCENE: rowItemSelected="; idx
  if type(idx) = "roArray" and idx.count() = 2 then
    playByIndex(idx[0], idx[1])
  end if
end sub

sub onVideoStateChanged()
  if m.Video = invalid then return
  print "SCENE: Video state="; m.Video.state
  if m.Video.state = "playing" then
    setIdleUI(false)
    m.Video.setFocus(true)
  else if m.Video.state = "stopped" or m.Video.state = "finished" or m.Video.state = "error" then
    m.Video.control = "stop"
    m.Video.content = invalid
    setIdleUI(true)
    if m.RowList <> invalid then m.RowList.setFocus(true)
  end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  if m.Video <> invalid and m.Video.state = "playing" then
    if key = "back" then
      m.Video.control = "stop"
      m.Video.content = invalid
      setIdleUI(true)
      if m.RowList <> invalid then m.RowList.setFocus(true)
      return true
    end if
    return false
  end if
  return false
end function