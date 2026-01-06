sub init()
    m.top.functionName = "loadContent"
end sub

sub loadContent()
    array = loadConfig()
    content = CreateObject("roSGNode", "ContentNode")
    
    ' Create row for live channels
    liveRow = CreateObject("roSGNode", "ContentNode")
    liveRow.Title = "Live Channels"
    
    ' Create row for Vimeo playlists
    vimeoRow = CreateObject("roSGNode", "ContentNode")
    vimeoRow.Title = "Vimeo Playlists"
    
    for each itemAA in array
        item = CreateObject("roSGNode", "ContentNode")
        item.Title = itemAA.Title
        item.HDPosterUrl = itemAA.Logo
        if itemAA.isLive = true
            item.streamFormat = itemAA.streamFormat
            item.Url = itemAA.Stream
            liveRow.appendChild(item)
        else
            if itemAA.vimeoShowcaseId <> invalid and itemAA.vimeoAccessToken <> invalid
                vimeoTask = CreateObject("roSGNode", "VimeoContentTask")
                vimeoTask.folderId = itemAA.vimeoShowcaseId ' Changed to vimeoShowcaseId
                vimeoTask.accessToken = itemAA.vimeoAccessToken
                vimeoTask.observeField("content", "onVimeoContentLoaded")
                vimeoTask.control = "RUN"
                item.vimeoTask = vimeoTask
                vimeoRow.appendChild(item)
            end if
        end if
    end for
    
    content.appendChild(liveRow)
    content.appendChild(vimeoRow)
    m.top.content = content
end sub

sub onVimeoContentLoaded(msg)
    vimeoTask = msg.getRoSGNode()
    vimeoContent = vimeoTask.content
    vimeoRow = m.top.content.getChild(1) ' Vimeo Playlists row
    for each item in vimeoRow.getChildren(-1, 0)
        if item.vimeoTask = vimeoTask
            item.removeChildIndex(0, item.getChildCount()) ' Clear existing children
            if vimeoContent <> invalid and vimeoContent.getChildCount() > 0
                for each video in vimeoContent.getChildren(-1, 0)
                    videoNode = CreateObject("roSGNode", "ContentNode")
                    videoNode.Title = video.Title
                    videoNode.streamFormat = video.streamFormat
                    videoNode.Url = video.Url
                    videoNode.HDPosterUrl = video.HDPosterUrl
                    item.appendChild(videoNode)
                end for
            else
                placeholder = CreateObject("roSGNode", "ContentNode")
                placeholder.Title = "No Videos Available"
                placeholder.HDPosterUrl = item.HDPosterUrl
                item.appendChild(placeholder)
            end if
            exit for
        end if
    end for
end sub