class App extends Backbone.Router

    constructor: ->
        #@clearCookies()
        @activeView = null
        @activeModals = []
        super



    initialize: =>
        @route "", "home", (=> @posts { category: 'popular'}), 'page'

        for domain in ['poets', 'fb', 'tw']            
            do (domain) =>
                @route "#{domain}/:username", "userView", ((username) => @userView(domain, username)), 'page'
                @route "#{domain}/:username/:section", "userTagsView", ((username, section) => @userView(domain, username, section)), 'page'
                @route "#{domain}/:username/edit", "editUser", ((username) => @editUser(domain, username)), 'modal'
                @route "#{domain}/:username/tagged/:tag", "taggedUserView", ((username, tag) => @taggedUserView(domain, username, tag)), 'page'

        @route "posts", "posts", @posts, 'page'
        @route "posts/:category", "categoryPosts", ((category) => @posts { category }), 'page'
        @route "posts/:category/:subcategory", "categoryAndSubCategoryPosts", ((category, subCategory) => @posts { category, subCategory }), 'page'
        @route "posts/:category/:subcategory/tagged/:tag", "categoryAndSubCategoryPostsAndTag", ((category, subCategory, tag) => @posts { category, subCategory, tag }), 'page'
        @route "posts/:category/tagged/:tag", "taggedPostsViewWithCat", ((category, tag) => @posts { tag, category }), 'page'        
        @route "posts/tagged/:tag", "taggedPostsView", ((tag) => @posts { tag }), 'page'        

        @route "posts/new", "newPost", @newPost, 'page'
        
        @route /^([0-9]+)$/, "postView", @postView, 'modal'

        $(document).ready @onInit
        
        
    
    route: (url, name, handler, type) =>
        if type is 'page'
            super url, name, @definePageRoute handler
        else if type is 'modal'
            super url, name, @defineModalRoute handler
    

    posts: (params) =>
        new Poe3.PostsView params, {}

            
    newPost: =>
        @requiresLogin '/posts/new', =>
            new Poe3.NewPostView
            
            
    postView: (uid) =>
        new Poe3.PostView uid


    userView: (domain, username, section = "completed") =>
        new Poe3.UserView domain, username, section
        

    editUser: (domain, username) =>
        view = new Poe3.EditUserView domain, username


    taggedUserView: (domain, username, tag) =>
        posts = new Poe3.Posts
        posts.fetch {
            data: { domain, username, state: 'complete' },
            success: =>
                _posts = posts.toArray()
                tagged = (p for p in _posts when p.get('tags').indexOf(tag) isnt -1)
                new Poe3.PostView { mode: 'gallery', data: { posts: tagged } }
        }
        

    definePageRoute: (fn) =>
        =>
            if @activeView?.href is window.location.href
                #The user pressed back. We have to close all modals that exist.
                #   Ask the modal not to do history.back()
                if $('.modal-popup').length
                    $('.modal-popup').trigger 'close', { navigateBack: false }  
                    @activeModals = []       

                #Modal called history.back(), when it closed.
                else if @activeView?.modalClosed
                    @activeView.modalClosed = false
            
                #Don't worry about modals. There aren't any.
                else
                    fn.apply this, arguments              
            
            #url changed. Ignore modals and such.
            else
                fn.apply this, arguments              
            
    
    
    defineModalRoute: (fn) =>
        =>
            fn.apply this, arguments
            
            
    
    requiresLogin: (url, loggedInAction) =>
        if @isAuthenticated()
            loggedInAction()
        else
            if @fbAuthResponseReceived
                loginView = new Poe3.LoginView loggedInAction, (-> history.back())
            else
                @navigate '/', true
            

    
    processFBAuthResponse: (response, userInitiated) =>
        @fbAuthResponseReceived = true
        
        ###
            If the user initiated the login, we will have to logout the existing user in any case.
            OTOH, if this was an automatic status check:
                - Ignore this if the cookie/domain isn't facebook                
        ###
        if userInitiated or app.getUser()?.domain is 'fb'
            if response.status is 'connected'                                
                @login 'fb', response.authResponse.accessToken
            else
                @logout()        
                


    onFBLoad: =>
        console.log 'FB API loaded.'
        FB.getLoginStatus (resp) =>
            if not @fbAuthResponseReceived
                @processFBAuthResponse resp, false
                
    
    
    getUser: =>
        {
            id: $.cookie('userid'),
            domain: $.cookie('domain'),
            username: $.cookie('username'),
            name: $.cookie('fullName'),
            passkey: $.cookie('passkey')
        }
            
            

    isAuthenticated: =>
        @getUser().id
        


    login: (domain, accessToken) =>
        currentUser = app.getUser()
        $.post Poe3.apiUrl('sessions'), { domain, accessToken }, (resp) =>    
            options = {} #{ path: '/' }
            $.cookie 'userid', resp.userid, options
            $.cookie 'domain', resp.domain, options
            $.cookie 'username', resp.username, options
            $.cookie 'fullName', resp.name, options
            $.cookie 'passkey', resp.passkey, options
            @refreshApp { skipNotifications: currentUser.passkey is resp.passkey }
        

    
    logout: =>
        @clearCookies()
        @refreshApp()



    #Debug only
    _loginEx: (resp) =>
        options = {} #{ path: '/' }
        $.cookie 'userid', resp.userid, options
        $.cookie 'domain', resp.domain, options
        $.cookie 'username', resp.username, options
        $.cookie 'fullName', resp.name, options
        $.cookie 'passkey', resp.passkey, options
        @refreshApp()        



    refreshApp: (options={}) =>
        @topMenu.refresh()
        if not options.skipNotifications
            @notifications.clear()
            @notifications.sync()
        
        

    clearCookies: =>
        $.removeCookie('userid')
        $.removeCookie('domain')
        $.removeCookie('username')
        $.removeCookie('fullName')
        $.removeCookie('passkey')



    navigate: (url, options) =>
        super    
        _gaq?.push ['_trackPageview', url]    
        
    
    
    setAppMode: (mode) ->
        options = {} #{ path: '/' }
        $.cookie 'appMode', mode, options

    getAppMode: ->
        $.cookie 'appMode'

    resetAppMode: ->
        $.removeCookie 'appMode'


    
    shareOnFacebook: =>
        FB.ui {
                method: 'apprequests',
                display: "popup",
                message: "Write Poetry. Together."
            }, (resp) => 
                    if resp
                        $.ajax {
                            url: Poe3.apiUrl("tokens"),
                            data: { type: 'facebook-friend-invite', key: resp.request, value: window.location.href },
                            type: 'post',
                            success: (token) =>
                        }                
        false    



    loadScript: (src) =>
        $('head').append "<script src=\"#{src}\"></script>"


        
    pathToUrl: (path) =>
        if /http:\/\//.test(path) or /https:\/\//.test(path)
            return path

        if /^\//.test(path)
            path = path.substring(1)

        if window.location.hostname is 'poe3.com'
            "http://www.poe3.com/#{path}"
        else
            "http://#{window.location.hostname}/#{path}"



    onInit: =>    
        Poe3.templateLoader.load 'Poe3', [
                "NewPostView",
                "PostListView",
                "PostListViewItem", 
                "PostsView",
                "TagListView",
                "TagListViewItem",  
                { view: "PostView", templates: { template: "PostView", commentsTemplate: "PostComments" } },
                "UserListView",
                { view: "UserView", templates: { container: "UserView", userInfo: "UserInfo" } },
                "EditUserView"
            ], =>
                #Check if we are here due to an app request.
                queryString = Poe3.getQueryString window.location.href
                if queryString.request_ids
                    key = queryString.request_ids.split(',').pop()
                    #This is a facebook app request.
                    #   See if there is a corresponding token. If so, redirect.
                    $.get Poe3.apiUrl("tokens/facebook-app-request/#{key}"), (resp) =>
                        if resp?.value
                            window.location.href = "/#{resp.value}"
                
                $(window).resize =>
                    if @activeView?.resizeOnRefresh?()
                        if @lastResizedWidth
                            #Resize if the change is more than 32        
                            if Math.abs($(document).width() - @lastResizedWidth) > 32
                                @lastResizedWidth = $(document).width()
                                window.location.reload()        
                        else
                            @lastResizedWidth = $(document).width()

                Backbone.history = Backbone.history || new Backbone.History {}
                Backbone.history.start { pushState:true, root: '/' }
        
                $('.sidebar')
                    .mouseover(=>
                        $('.sidebar .menu').css('opacity', '1.0'))
                    .mouseout(=>
                        $('.sidebar .menu').css('opacity', '0.5'))
        
                @topMenu = new TopMenu
                @topMenu.refresh()
                
                window.Poe3.initFB()                
                window.Poe3.fixAnchors '.logo'

                @notifications = new Poe3.Notifications
                @notifications.sync()

window.app = new App


class TopMenu

    constructor: ->
        $('.menu-container').html '
            <ul class="menu">
                <li class="new-poem"><a href="/posts/new">New Poem</a></li>
                <li class="login hidden">
                    <span class="txt">Login</span>
                    <img class="facebook" src="/images/facebook.png" />
                    <img class="twitter" src="/images/twitter.png" />
                </li>
                <li class="profile hidden">
                    <p class="main-message-alert" style="display:none"><i class="icon-comment"></i><span class="msg-count"></span></p>                    
                    <a href="#" class="name"></a>
                </li>
                <li class="logout hidden"><i class="icon-signout"></i><a id="logout" href="#">Logout</a></li>
            </ul>'

        $('.topbar .menu .profile .main-message-alert').click =>
            app.navigate "/#{app.getUser().domain}/#{app.getUser().username}/messages", true 
            false

    refresh: =>
        if app.isAuthenticated()
            $('.topbar .menu .login').hide()            
            $('.topbar .menu .profile .name').html app.getUser().name
            $('.topbar .menu .profile, .topbar .menu .logout').show()
            
            profileIcon = switch app.getUser().domain
                when 'fb'
                    '/images/facebook.png'
                when 'tw'
                    '/images/twitter.png'

            if profileIcon
                 $('.topbar .menu .profile .name').css 'background', "url(#{profileIcon}) no-repeat 0px 0px"   
                 $('.topbar .menu .profile .name').css 'background-size', '16px 16px'
                 
            $('.topbar .menu .profile span.icon').html profileIcon
            
            @positionMessageAlert()
        else        
            $('.topbar .menu .profile, .topbar .menu .logout').hide()            
            $('.topbar .menu .login').show()

        Poe3.fixAnchors '.topbar'        
        @attachHandlers()
                
    
    positionMessageAlert: =>
        #position the message alert.
        alertPos = $('.topbar .menu .profile .name').position().left + $('.topbar .menu .profile .name').width()
        $('.main-message-alert').css 'left', "#{alertPos}px"    
            
                
    attachHandlers: =>
        $(document).bindNew 'click', '.topbar .menu .profile', =>
            if app.isAuthenticated()
                app.navigate "/#{app.getUser().domain}/#{app.getUser().username}", true
                false
                
        
        $(document).bindNew 'click', '.topbar .menu .login .facebook', =>
            FB.login ((response) => app.processFBAuthResponse(response, true)), { scope: 'email,publish_actions' }
            false
            
            
        $(document).bindNew 'click', '.topbar .menu .login .twitter', =>
            window.location.href = "/auth/twitter"
            false
                        
            
        $(document).bindNew 'click', '#logout', =>
            if app.getUser().domain is 'fb'
                app.logout()                
                FB.logout (resp) =>
                    app.navigate '/', true
            else
                app.logout()
            false
                

    shortenName: (name) =>
        if name?.length >= 14
            name.substring(0,12) + ".."
        else
            name
            
            

# Utility Functions
window.Poe3.apiUrl = (url, params = {}, options = { api: 'v1'}) ->
    if /^\//.test(url)
        url = url.substring(1)
    passkey = app.getUser().passkey
    if passkey
        params.passkey = passkey
    if Object.keys(params).length > 0
        paramArray = []    
        for key, val of params
            paramArray.push "#{key}=#{encodeURIComponent(val)}"    
        query = paramArray.join '&'
        if /\?/.test(url)
            url += "&#{query}"
        else
            url += "?#{query}"
                
    "/api/#{options.api}/#{url}"


window.Poe3.fixAnchors = (selector) ->
    #Fix links to support pushState
    anchors = $(selector).find('a')
    for _a in anchors
        a = $(_a)
        if a.attr('fixed-anchor') isnt 'true'
            a.attr 'fixed-anchor', 'true'
            a.click (e) ->
                #Check if an event handler already exists.
                if $(@).data('fix-anchors') isnt false
                    href = $(@).attr 'href'
                    if href != '#' and not /^http:\/\//.test(href) and not /^https:\/\//.test(href)
                        app.navigate href, true
                        false


window.Poe3.getQueryString = (url) ->
    dict = {}
    hashes = url.slice(url.indexOf('?') + 1).split('&')
    for val in hashes
        hash = val.split('=')
        dict[hash[0]] = decodeURIComponent hash[1]
    dict


window.Poe3.formatText = (text) ->
    if text
        paragraphs = text.split '\n\n'
        ("<p>#{item.replace(/\n/g, '<br />')}</p>" for item in paragraphs).join ''
    else
        ''


window.Poe3.getHashCode = (text) ->
	hash = 0
	if (text.length is 0) 
	    hash
    else
	    for i in [0...text.length] by 1
		    char = text.charCodeAt(i)
		    hash = ((hash<<5)-hash)+char
		    hash = hash & hash #Convert to 32bit integer
	    hash

window.Poe3.uniqueId = (length = 16) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length
    

window.Poe3.clone = (source) ->
    obj = {}
    Poe3.extend obj, source
    return obj
    

window.Poe3.extend = (target, source) ->
    for key, val of source
        if typeof val != "function"
            target[key] = val


#Some extensions to jQuery
$.fn.bindNew = (eventName, selector, fn) ->
    $(this).off eventName, selector
    $(this).on eventName, selector, fn
    
$.fn._hide = () ->
    $(this).removeClass 'visible'
    $(this).addClass 'hidden'
    
$.fn._show = () ->
    $(this).removeClass 'hidden'
    $(this).addClass 'visible'
        
