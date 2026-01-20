sub init()
    print "========================================"
    print "HomeScene: INITIALIZING"
    print "========================================"
    
    ' ==================== FIRE ALL REQUIRED BEACONS ====================
    ' AppLaunchComplete - REQUIRED
    m.top.signalBeacon("AppLaunchComplete")
    
    ' AppDialogInitiate/Complete - Fire ONCE since we have no dialogs
    ' This satisfies the certification requirement
    m.top.signalBeacon("AppDialogInitiate")
    m.top.signalBeacon("AppDialogComplete")
    
    print "HomeScene: All beacons fired"
    
    ' ==================== NODE REFERENCES ====================
    m.Video = m.top.findNode("Video")
    m.Menu = m.top.findNode("Menu")
    m.Bg = m.top.findNode("Bg")
    m.BgDim = m.top.findNode("BgDim")
    
    m.IntlTile = m.top.findNode("IntlTile")
    m.HouTile = m.top.findNode("HouTile")
    m.IntlFocus = m.top.findNode("IntlFocus")
    m.HouFocus = m.top.findNode("HouFocus")
    m.IntlDot = m.top.findNode("IntlLiveDot")
    m.HouDot = m.top.findNode("HouLiveDot")
    
    ' ==================== STATE VARIABLES ====================
    m.isPlaying = false
    m.focusIndex = 0  ' 0 = Internacional, 1 = Houston
    m.pendingDeepLink = invalid
    
    ' ==================== VIDEO SETUP ====================
    if m.Video <> invalid
        m.Video.enableUI = false
        m.Video.visible = false
        m.Video.observeField("state", "onVideoStateChanged")
    end if
    
    ' ==================== LOAD CONFIG ====================
    cfg = loadConfig()
    m.streamIntl = invalid
    m.streamHou = invalid
    
    if cfg <> invalid
        for each item in cfg
            if item <> invalid and item.Title <> invalid
                titleUpper = UCase(item.Title)
                if titleUpper = "INTERNACIONAL"
                    m.streamIntl = item
                    print "HomeScene: Loaded Internacional stream"
                else if titleUpper = "HOUSTON"
                    m.streamHou = item
                    print "HomeScene: Loaded Houston stream"
                end if
            end if
        end for
    end if
    
    ' ==================== INITIAL UI ====================
    if m.Menu <> invalid then m.Menu.visible = true
    updateFocus()
    
    ' ==================== FOCUS TIMER ====================
    m.focusTimer = CreateObject("roSGNode", "Timer")
    m.focusTimer.duration = 0.1
    m.focusTimer.repeat = false
    m.focusTimer.observeField("fire", "forceFocus")
    m.focusTimer.control = "start"
    
    print "HomeScene: Initialization complete"
end sub

sub forceFocus()
    print "HomeScene: Setting focus"
    m.top.setFocus(true)
end sub

sub updateFocus()
    ' Reset all focus
    if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.0
    if m.HouFocus <> invalid then m.HouFocus.opacity = 0.0
    if m.IntlTile <> invalid then m.IntlTile.scale = [0.95, 0.95]
    if m.HouTile <> invalid then m.HouTile.scale = [0.95, 0.95]
    if m.IntlDot <> invalid then m.IntlDot.opacity = 0.0
    if m.HouDot <> invalid then m.HouDot.opacity = 0.0
    
    ' Apply focus based on index
    if m.focusIndex = 0
        if m.IntlFocus <> invalid then m.IntlFocus.opacity = 0.25
        if m.IntlTile <> invalid then m.IntlTile.scale = [1.05, 1.05]
        if m.IntlDot <> invalid then m.IntlDot.opacity = 1.0
    else
        if m.HouFocus <> invalid then m.HouFocus.opacity = 0.25
        if m.HouTile <> invalid then m.HouTile.scale = [1.05, 1.05]
        if m.HouDot <> invalid then m.HouDot.opacity = 1.0
    end if
end sub

sub playSelected()
    ' Get selected stream
    selectedStream = invalid
    if m.focusIndex = 0
        selectedStream = m.streamIntl
    else
        selectedStream = m.streamHou
    end if
    
    if selectedStream = invalid or selectedStream.Stream = invalid
        print "HomeScene: No valid stream selected"
        return
    end if
    
    print "HomeScene: Playing "; selectedStream.Title
    
    ' Create content node
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Title = selectedStream.Title
    contentNode.Url = selectedStream.Stream
    contentNode.streamFormat = selectedStream.streamFormat
    contentNode.live = true
    
    ' Update UI
    m.isPlaying = true
    if m.Menu <> invalid then m.Menu.visible = false
    if m.Bg <> invalid then m.Bg.visible = false
    if m.BgDim <> invalid then m.BgDim.visible = false
    
    ' Play video
    if m.Video <> invalid
        m.Video.visible = true
        m.Video.content = contentNode
        m.Video.control = "play"
    end if
    
    m.top.setFocus(true)
end sub

sub stopPlaybackToHome()
    if m.Video <> invalid
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
    if not press then return false
    
    print "HomeScene: Key pressed: "; key
    
    if m.isPlaying
        if key = "back"
            stopPlaybackToHome()
            return true
        end if
        return true
    end if
    
    if key = "left"
        m.focusIndex = 0
        updateFocus()
        return true
    else if key = "right"
        m.focusIndex = 1
        updateFocus()
        return true
    else if key = "OK" or key = "Select"
        playSelected()
        return true
    end if
    
    return false
end function

sub onVideoStateChanged()
    if m.Video = invalid then return
    
    state = m.Video.state
    print "HomeScene: Video state: "; state
    
    if state = "error"
        errorMsg = m.Video.errorMsg
        errorCode = m.Video.errorCode
        print "HomeScene: Video ERROR - Msg: "; errorMsg; ", Code: "; errorCode
        stopPlaybackToHome()
    end if
end sub

' ==================== CRITICAL: DEEP LINKING HANDLER ====================
sub OnInputAssoc(info)
    print "========================================"
    print "HomeScene: OnInputAssoc CALLED"
    print "========================================"
    
    if info = invalid
        print "HomeScene: No deep link info provided"
        return
    end if
    
    ' Log ALL deep link information
    print "HomeScene: Deep link details:"
    for each key in info
        print "  DL["; key; "] = "; info[key]
    end for
    
    ' Store for potential use
    m.pendingDeepLink = info
    
    ' Check for specific content to play
    if info.contentID <> invalid
        print "HomeScene: Deep link contentID: "; info.contentID
        
        ' You could implement logic to play specific content based on contentID
        ' For example:
        ' if info.contentID = "internacional" then m.focusIndex = 0
        ' if info.contentID = "houston" then m.focusIndex = 1
        ' playSelected()
    end if
    
    print "HomeScene: Deep link processing complete"
end sub

' ==================== MEMORY EVENT HANDLER ====================
sub onLowMemory(info)
    print "HomeScene: LOW MEMORY EVENT"
    
    ' Stop video if playing
    if m.isPlaying
        print "HomeScene: Stopping video due to low memory"
        stopPlaybackToHome()
    end if
    
    ' Clear cached data
    m.streamIntl = invalid
    m.streamHou = invalid
    m.pendingDeepLink = invalid
    
    print "HomeScene: Memory cleanup complete"
end sub

' ==================== OTHER REQUIRED FUNCTIONS ====================
sub requestDeepLink(contentId)
    print "HomeScene: requestDeepLink: "; contentId
end sub

sub launchContent(item)
    print "HomeScene: launchContent"
end sub