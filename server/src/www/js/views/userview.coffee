class UserView extends Poe3.PageView
    
    constructor: (@domain, @username, @section) ->
        super { model: new Poe3.User { domain: @domain, @username } }
        
        
        
    initialize: =>
        $('#content').html @el
        @renderContainer()
        @model.bind 'change', @render, @
        @model.fetch()
        @loadSection()
                
                

    loadSection: =>
        switch @section
            when 'completed'
                @showCompleted()
            when 'open'
                @showOpen()
            when 'likes'
                @showLikes()
            when 'tags'
                @showTags()
            when 'messages'
                @showMessages()
        
        
    resizeOnRefresh: =>
        true
        
        
        
    renderContainer: =>
        $(@el).html @container { domain: @domain, username: @username }
        
        
        
    render: =>
        @setTitle @model.get('name')

        params = @model.toTemplateParam()
        params.followerCount = params.followers.length
        params.followers = params.followers[0..3]
        params.followingCount = params.following.length
        params.following = params.following[0..3]
        params.about = window.Poe3.formatText @model.get 'about'
        params.showLinks = @model.get('domain') isnt 'poe3'
        if not params.about
            params.about = "<p>#{@replaceWithHumor 'empty-profile'}</p>"
        params.pagename = @pagename
        params.self = @model.get('domain') is app.getUser().domain and @model.get('username') is app.getUser().username
        $(@el).find('.user-info').html @userInfo params
        
        if app.isAuthenticated()
            if @model.isFollowedBy app.getUser().id
                $('.user-view .actions .not-following').hide()
                $('.user-view .actions .following').show()
                $('.user-view .following-mark').show()
            else
                $('.user-view .actions .following').hide()
                $('.user-view .actions .not-following').show()            
                $('.user-view .following-mark').hide()        

            if @isOwnProfile()
                $('.user-view .std-menu li.messages').removeClass 'hidden'

        else
            $('.user-view .actions .following').hide()
            $('.user-view .actions .not-following').show()            
            $('.user-view .following-mark').hide()        
                    
        
        @attachEvents()

        @onRenderComplete '.user-view'
        
        
        
    renderPosts: =>
        $('.user-view .page-content').html ''

        if not @postsModel.length 
            empty = $("<div><p class=\"empty\">&quot;#{@replaceWithHumor 'empty'}&quot;</p></div>")
            if @isOwnProfile()
                if @section is 'completed'
                    empty.append '<p class="subtext">Just one way to fix this. Complete an <a href="/posts/open">open poem</a> or write a <a href="/posts/new">new one</a>.</p>'
                else if @section is 'open'
                    empty.append '<p class="subtext">Why not start a new <a href="/posts/new">collaborative poem</a>?</p>'
                else if @section is 'likes'
                    empty.append '<p class="subtext">Tip: Click the heart-shaped icon after opening a poem to \'like\' it.</p>'    
            empty.appendTo '.user-view .page-content'
                        
        else            
            if @pageContentType is 'POSTS'
                @postListView = new Poe3.PostListView '.user-view .page-content', "/#{@domain}/#{@username}", @postsModel.toArray()
                @postListView.render()
                
            else if @pageContentType is 'TAG-LIST'
                @tagListView = new Poe3.TagListView '.user-view .page-content', @postsModel.toArray()
                @tagListView.render()



    renderMessages: (messagesModel) =>
        #remove the global message alert, since we are already in messages.
        $('.topbar .main-message-alert').hide()        
        
        $('.user-view .page-content').html ''
        messages = messagesModel.toArray()
        
        if not messages.length
            $('.user-view .page-content').html "<p class=\"empty\">There are no messages to display.</p>"
        else
            $('.user-view .page-content').html '
                <div class="mailbox">
                    <ul class="threads"></ul>
                </div>'
            
            threadDict = _.groupBy messages, (m) -> m.get('from').id        
            mailbox = $('.user-view .page-content .mailbox')
            eThreads = mailbox.find('.threads')
            for senderid, thread of threadDict
                sender = thread[0].get('from')
                eThread = $ "
                    <li>
                        <a href=\"/#{sender.domain}/#{sender.username}\"><img src=\"#{sender.thumbnail}\" alt=\"#{sender.name}\" /></a>
                        <h3><a href=\"/#{sender.domain}/#{sender.username}\">#{sender.name}</a></h3>               
                        <ul class=\"messages\"></ul>
                        <div style=\"clear:both\"></div>
                    </li>"
                eThread.appendTo eThreads
                eMsgs = eThread.find('.messages')

                for msg, index in thread
                    if index < 3
                        eMsg = $ "<li></li>"
                    else
                        eMsg = $ "<li class=\"hidden\"></li>"
                    eMsg.appendTo eMsgs
                    eMsg.html msg.toHtml()
                    
                if thread.length > 3
                    eThread.append '<p class="show-all"><i class="icon-plus"></i> <span class="link">Show ' + thread.length + ' more</span></p>'
                    do (eThread) ->
                        eThread.find('.show-all').click ->
                            $(@).hide()
                            eThread.find('.messages li.hidden').show()
                            
            Poe3.fixAnchors eThreads
                        
            

    showCompleted: =>
        $('.user-view .std-menu li a').removeClass 'selected'
        $('.user-view .std-menu li a.completed').addClass 'selected'
        @pageContentType = 'POSTS'
        @postsModel = new Poe3.Posts
        @postsModel.bind 'reset', @renderPosts, @
        @postsModel.fetch { data: { @domain, @username, state: 'complete' } }
        

    showOpen: =>
        $('.user-view .std-menu li a').removeClass 'selected'
        $('.user-view .std-menu li a.open').addClass 'selected'            
        @pageContentType = 'POSTS'            
        @postsModel = new Poe3.Posts
        @postsModel.bind 'reset', @renderPosts, @
        @postsModel.fetch { data: { @domain, @username, state: 'incomplete' } } #incomplete = 'open' and 'open-unmodifiable'
    

    showLikes: =>
        $('.user-view .std-menu li a').removeClass 'selected'
        $('.user-view .std-menu li a.likes').addClass 'selected'            
        @pageContentType = 'POSTS'            
        @postsModel = new Poe3.Posts
        @postsModel.bind 'reset', @renderPosts, @
        @postsModel.fetch { data: { @domain, @username, category: 'likes' } }
    

    showTags: =>
        $('.user-view .std-menu li a').removeClass 'selected'
        $('.user-view .std-menu li a.tags').addClass 'selected'            
        @pageContentType = 'TAG-LIST'
        @postsModel = new Poe3.Posts
        @postsModel.bind 'reset', @renderPosts, @
        @postsModel.fetch { data: { @domain, @username, state: 'complete' } }
    
    
    showMessages: =>
        $('.user-view .std-menu li a').removeClass 'selected'
        $('.user-view .std-menu li a.messages').addClass 'selected'            
        @pageContentType = 'MESSAGES'
        messages = new Poe3.Messages
        messages.bind 'reset', @renderMessages, @
        messages.userid = app.getUser().id
        messages.fetch()


    attachEvents: () =>
        $(document).bindNew 'click', '.user-view .follow .all.following', =>
            users = @model.toJSON().following
            new Poe3.UserListView users, { heading: "Following #{users.length}" }
            false   

        $(document).bindNew 'click', '.user-view .follow .all.followers', =>
            users = @model.toJSON().followers
            new Poe3.UserListView users, { heading: "#{users.length} Followers" }
            false   
            
    
        $(document).bindNew 'click', '.user-view .actions .not-following button', =>
            $.post Poe3.apiUrl("users/#{@model.id}/followers"), { id: app.getUser().id }, (resp) =>
                @model.get('followers').push app.getUser().id
                $('.user-view .actions .not-following').hide()
                $('.user-view .actions .following').show()
                $('.user-view .following-mark').show()
            false
            
            
        $(document).bindNew 'click', '.user-view .actions .following button', =>
            $.ajax {
                url: Poe3.apiUrl("users/#{@model.id}/followers/#{app.getUser().id}"),
                type: 'DELETE',
                success: (resp) =>
                    @model.set 'following', (follower for follower in @model.get('followers') when follower.id isnt app.getUser().id)
                    $('.user-view .actions .following').hide()
                    $('.user-view .actions .not-following').show()
                    $('.user-view .following-mark').hide()
                }
            false
            
            
        $(document).bindNew 'click', '.user-view .std-menu .completed', =>
            app.navigate "/#{@domain}/#{@username}/completed", false
            @section = 'completed'
            @loadSection()
            false


        $(document).bindNew 'click', '.user-view .std-menu .open', =>
            app.navigate "/#{@domain}/#{@username}/open", false
            @section = 'open'                  
            @loadSection()
            false


        $(document).bindNew 'click', '.user-view .std-menu .likes', =>
            app.navigate "/#{@domain}/#{@username}/likes", false
            @section = 'likes'
            @loadSection()
            false


        $(document).bindNew 'click', '.user-view .std-menu .tags', =>
            app.navigate "/#{@domain}/#{@username}/tags", false
            @section = 'tags'
            @loadSection()
            false


        $(document).bindNew 'click', '.user-view .std-menu .messages', =>
            app.navigate "/#{@domain}/#{@username}/messages", false
            @section = 'messages'
            @loadSection()
            false

    
    isOwnProfile: () =>
        app.getUser().id is @model.id
         
        
    
    getPostByUID: (uid) =>
        posts = @postsModel?.toArray()
        if posts
            matches = (post for post in posts when post.get('uid') == uid)
            if matches.length
                matches[0]


window.Poe3.UserView = UserView
