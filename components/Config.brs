Function loadConfig()
    return [
        {
            Title: "HOUSTON",
            streamFormat: "hls",
            Logo: "pkg:/images/houston_poster.png",
            Stream: "https://live.naciontv.org:3334/houston/live/llhls.m3u8"
        },
        {
            Title: "INTERNACIONAL",
            streamFormat: "hls",
            Logo: "pkg:/images/internacional_poster.png",
            Stream: "https://live.naciontv.org:3334/internacional/live/llhls.m3u8"
        }
    ]
End Function