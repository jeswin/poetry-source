class Notifications

    constructor: ->
        @lastSyncTime = 0
        @disableSync = false
        setInterval @sync, 60000 #Every minute



    sync: =>
        if not @disableSync

            #Tidbit. We cant do -> app.isAuthenticated() isnt @showingUserNotifications, since isAuth() method doesn't return a boolean
            if (app.isAuthenticated() and not @showingUserNotifications) or (@showingUserNotifications and not app.isAuthenticated())
                @clear()                
        
            if app.isAuthenticated()
                @showingUserNotifications = true
                $.get Poe3.apiUrl("users/#{app.getUser().id}/status?since=#{@lastSyncTime}"), (resp) =>                    
                    if (resp.userid isnt app.getUser().id) or (resp.error is 'NO_SESSION')
                        app.clearCookies()
                        app.refreshApp()
                    
                    if resp.messageCount > 0                    
                        $('.main-message-alert .msg-count').html resp.messageCount
                        $('.main-message-alert').show()
                    else
                        $('.main-message-alert').hide()

                    @lastSyncTime = resp.lastSyncTime        
                    @displayBroadcasts resp.broadcasts
            else
                @showingUserNotifications = false
                $.get Poe3.apiUrl("users/0/broadcasts?since=#{@lastSyncTime}"), (resp) =>
                    @lastSyncTime = resp.lastSyncTime        
                    @displayBroadcasts resp.broadcasts          

    

    clear: =>
        @lastSyncTime = 0    
        $('.sidebar .messages').html '
            <div class="showcase"></div>
            <div class="notifications"></div>'

    
    ###
        Showcase:
        1. Just one item, at most.

        User broadcasts + Global broadcasts
        1. Comes after showcase.
        2. Ordered by timestamp.
        3. Max 20.
    ###    
    displayBroadcasts: (broadcasts) =>
        eMessages = $('.sidebar .messages')
        
        #Showcase. Always the first one.
        if broadcasts.showcase?.length
            eMessages.find('.showcase').show()
            eMessages.find('.showcase').html ''
            @showMessage broadcasts.showcase[0], '.showcase', eMessages
        else
            eMessages.find('.showcase').hide()
            
        all = [].concat broadcasts.userNotifications ? []
        all = all.concat broadcasts.globalNotifications ? []
        
        #sort descending
        comparer = (a, b) ->
            if a.timestamp > b.timestamp then -1 else if a.timestamp < b.timestamp then 1 else 0
        all.sort comparer
        
        if all.length > 32
            all = all.slice(0, 20)
        
        #Broadcasts come reverse ordered by timestamp. We want in order, since we use prepend.
        for item in all.reverse()
            @showMessage item, ".notifications", eMessages

        #Remove the old ones.        
        for elem, index in eMessages.find('.notification')
            if index > 32
                $(elem).remove()    

        

    showMessage: (item, type, parentElem) ->
        msg = new Poe3.Message item        
        html = msg.toHtml('condensed')
        if html
            typeElem = parentElem.find(type)
            list = typeElem.find('ul')
            if not list.length
                list = $('<ul></ul>')
                list.appendTo typeElem            
            eMsg = $("<li class=\"notification\"></li>")
            eMsg.attr 'message-id', msg.id
            eMsg.prependTo list
            eMsg.html html
            Poe3.fixAnchors eMsg
        
        
window.Poe3.Notifications = Notifications
