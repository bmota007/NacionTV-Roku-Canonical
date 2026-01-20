sub TestDeepLink()
    ' This function demonstrates deep linking capability
    print "DeepLinkTest: Demonstrating deep linking support"
    
    ' Create test input event
    input = CreateObject("roInput")
    if input <> invalid
        print "DeepLinkTest: roInput object available for deep linking"
        
        ' Simulate a deep link event
        testEvent = {
            contentID: "test123",
            mediaType: "input",
            reason: "input"
        }
        
        print "DeepLinkTest: Would handle deep link: "; testEvent
    end if
end sub