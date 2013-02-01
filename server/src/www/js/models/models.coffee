class BaseModel extends Backbone.Model

    toTemplateParam: () =>
        result = @toJSON()
        result._model = @
        result.isAutheticated = app.isAuthenticated()
        result


###
    The Post Model
###
class Post extends BaseModel

    idAttribute: "_id"
    
    
    url: =>
        if @id
            Poe3.apiUrl "posts/#{@id}"
        else if @get('uid')
            Poe3.apiUrl "posts", { filter: 'uid', uid: @get('uid') }
        else
            Poe3.apiUrl "posts"
            
  
  
    format: (viewType = 'full') =>
        @formatParts @get('type'), @get('selectedParts'), viewType
  
  
  
    formatParts: (type, parts, viewType = 'full') =>
        try
            #if the post is incomplete and this is the owner, we put additional tags inline for editing.
            if @isOpen() and (viewType is 'full') and @get('createdBy').id is app.getUser().id
                lastPart = parts[-1..][0]
                switch type
                    when 'haiku'
                        content = ''
                        for part in parts
                            if parts.length is 1
                                content = part.content                            
                            else
                                if part is lastPart
                                    content += "<div class=\"last\"><span class=\"remove-part\" data-partid=\"#{part.id}\">Remove</span>#{part.content}</div>"
                                else
                                    content += "<div>#{part.content}</div>"
                        content = content.replace /\n/g, "<br />"                                
                        '<div class="post-text haiku">' + content + "</div>"
                    when 'six-word-story'
                        content = ''
                        for part in parts
                            if parts.length is 1
                                content = part.content                            
                            else
                                if part is lastPart
                                    content += "<span class=\"last\"><span class=\"remove-part\" data-partid=\"#{part.id}\">Remove</span>#{part.content}</span>"
                                else
                                    content += "#{part.content} "
                        '<p class="post-text six-word-story">' + content + "</p>"
                    when 'quote'
                        content = parts[0].content
                        '<p class="post-text quote">' + content + "</p>"
                    when 'free-verse'
                        content = ''
                        for part in parts
                            if parts.length is 1
                                content = "<p>#{part.content}</p>"
                            else
                                if part is lastPart
                                    content += "<div class=\"last\"><span class=\"remove-part\" data-partid=\"#{part.id}\">Remove</span><p>#{part.content}</p></div>"
                                else
                                    content += "<p>#{part.content}</p>"
                        content = content.replace /\n\n/g, "</p><p>" #that was an easy hack. :)
                        content = content.replace /\n/g, "<br />"
                        if viewType is 'full' and @get('title')
                            '<div class="post-text free-verse"><h3 class="title">' + @get('title') + '</h3>' + content + "</div>"                         
                        else                        
                            '<div class="post-text free-verse">' + content + "</div>"                         
            else
                switch type
                    when 'haiku'
                        content = (part.content for part in parts).join '\n'
                        content = content.replace /\n/g, "<br />"
                        '<p class="post-text haiku">' + content + "</p>"
                    when 'six-word-story'
                        content = (part.content for part in parts).join ' '
                        '<p class="post-text six-word-story">' + content + "</p>"
                    when 'quote'
                        content = parts[0].content
                        '<p class="post-text quote">' + content + "</p>"
                    when 'free-verse'
                        content = ("<p>#{part.content}</p>" for part in parts).join ''
                        content = content.replace /\n\n/g, "</p><p>" #that was an easy hack. :)
                        content = content.replace /\n/g, "<br />"
                        if (viewType is 'full' or viewType is 'condensed') and @get('title')
                            '<div class="post-text free-verse"><h3 class="title">' + @get('title') + '</h3>' + content + "</div>"            
                        else
                            '<div class="post-text free-verse">' + content + "</div>"            
        catch error
            ''

    getFreeVerseTitle: =>
        @get('title') ? @get('selectedParts')[0].content.split('\n')[0]
            

    formatAsIcon: =>
        if @get('attachmentType') is 'image'
            "<div class=\"with-image\">
                <div class=\"container\" style=\"background-image: url('#{@get('attachment')}')\">
                </div>
            </div>"
        else
            parts = @get('selectedParts')
            text = switch @get('type')
                when 'haiku'
                    content = (part.content for part in parts).join '\n'
                    content = content.replace /\n/g, "<br />"
                    '<p class="post-text haiku">' + content + "</p>"
                when 'six-word-story'
                    content = (part.content for part in parts).join '\n'
                    content = content.replace /\n/g, "<br />"
                    '<p class="post-text six-word-story">' + content + "</p>"
                when 'quote'
                    content = parts[0].content
                    '<p class="post-text quote">' + content + "</p>"
                when 'free-verse'
                    if @get('title')
                        '<p class="post-text free-verse">' + @get('title') + "</p>"
                    else
                        '<p class="post-text free-verse">' + @getFreeVerseTitle() + "</p>"
            index = Poe3.getHashCode(text.slice(0,10)) % 6
            bgcolor = ['#789','#798','#879','#897','#987','#978'][index]
            forecolor = ['#013','#031','#103','#130','#310','#301'][index]
            "<div class=\"just-text\" style=\"background-color:#{bgcolor};color:#{forecolor}\">
                #{text}
            </div>"
            

         
    formatNotes: =>
        notes = @get('notes')
        if notes
            notes = notes.replace /\n\n/g, "</p><p>" #that was an easy hack. :)
            notes.replace /\n/g, "<br />"
            

    
    formatType: =>
        if @get('type') isnt 'free-verse'
            @get('type').replace('-', ' ')
        else
            'poem'
    


    getPostName: (maxLength, prefixType) =>
        name = switch @get('type')
            when 'haiku'
                type = if prefixType then 'Haiku ' else ''
                name = @shorten(@get('selectedParts')[0].content, maxLength)
                "#{type}#{name}"
            when 'six-word-story'
                type = if prefixType then 'Six Word Story ' else ''
                text = (part.content for part in @get('selectedParts')).join ' '
                name = @shorten text, maxLength
                "#{type}#{name}"
            when 'quote'
                type = if prefixType then 'Quote ' else ''
                name = @shorten @get('selectedParts')[0].content, maxLength
                "#{type}#{name}"
            when 'free-verse'
                type = if prefixType then 'Free Verse ' else ''
                name = @shorten (@title ? @get('selectedParts')[0].content), maxLength
                "#{type}#{name}"
        name.replace(/,*$/, '') 



    summarizeContent: (type) =>        
        parts = @get('selectedParts')

        text = switch @get('type')
            when 'haiku'
                if type is "short"
                    parts[0].content.split('\n')[0] + " ..."
                else if type is "full"
                    lines = []
                    for part in parts
                        lines = lines.concat part.content.split '\n'
                    lines.join '\n'                    
            when 'six-word-story'
                (part.content for part in parts).join ' '
            when 'quote'
                parts[0].content
            when 'free-verse'
                lines = []
                for part in parts
                    lines = lines.concat part.content.split '\n'

                if lines.length > 5                
                    lines = lines.slice(0, 5)
                    lines.push " ..."
                    
                lines.join '\n'                        


    
    getPartEditor: =>
        if @canAddContent()       
            editor = if @isOwner() and @hasContribs()
                partSelection = if @hasContribs() then @getPartSelector() else ''
                "#{partSelection}
                <div class=\"section add-part\" style=\"display:none\">
                    #{@getContribForm()}                            
                </div>"
            else
                "<div class=\"section add-part\">
                    #{@getContribForm()}
                 </div>"

            editor
         else
            ''
        


    getContribForm: =>
        form = switch @get('type')
            when 'haiku'
                '<p>' + @getContribMessage() + '<br /><textarea class="content" placeholder="Write here."></textarea></p>
                 <p class="content-error hidden"></p>
                 <div class="actions"><button class="submit"><i class="icon-ok"></i>Add Lines</button></div>'
            when 'six-word-story'
                '<p>' + @getContribMessage() + '<br /><textarea class="content" placeholder="Write here."></textarea></p>
                 <p class="content-error hidden"></p>
                 <div class="actions"><button class="submit"><i class="icon-ok"></i>Add Words</button></div>'
            when 'free-verse'          
                '<p>' + @getContribMessage() + '<br /><textarea class="content" placeholder="Write here."></textarea></p>
                 <p class="content-error hidden"></p>
                 <div class="actions"><button class="submit"><i class="icon-ok"></i>Add Lines</button></div>'

        
        #List existing contributions
        parts = (part for part in @get('parts') when part.sequence is @get('selectedParts').length)
        if parts.length
            partsHtml = ''
            for part in parts
                partsHtml += '<li>
                            <img class="profile-pic" src="' + part.createdBy.thumbnail + '" alt="' + part.createdBy.name + '" />' +
                            @formatParts(@get('type'), [part], 'partial') +
                        '   <div style="clear:both"></div>
                        </li>'            
            form += "
                <div class=\"section part-listing\">
                    <p>Contributions awaiting approval:</p>
                    <ul>#{partsHtml}</ul>
                </div>"        
        form
        


    getContribMessage: =>
        message = switch @get('type')
            when 'haiku'
                remaining = 3 - @countTotalLines()
                if remaining is 1 then 'You can add the last line' else 'You can add one or two lines'
            when 'six-word-story'                
                remaining = 6 - @countTotalWords()
                if remaining is 1 then 'You can add the last word' else "You can add up to #{remaining} words"
            when 'free-verse'
                'Add more lines to the poem'

        if @isOwner() and @hasContribs() 
            message + ', or <a href="#" class="select-contrib-link">select a contribution</a>.' 
        else
            "#{message}."


    
    getCompletionMessage: =>
        if @isOpen() and @isOwner()
            message = switch @get('type')
                when 'haiku'
                    remaining = 3 - @countTotalLines()
                    if remaining is 0
                        canPublish = true
                        'This haiku is ready. Make it visible by publishing it.'
                    else
                        if remaining is 1 then 'One more line is required to publish this.' else 'Two more lines are required to publish this.'
                when 'six-word-story'                            
                    remaining = 6 - @countTotalWords()
                    if remaining is 0
                        canPublish = true
                        'This story is ready. Make it visible by publishing it.'
                    else
                        if remaining is 1 then 'One more word is required to publish this.' else "Add #{remaining} words to publish this."
                when 'free-verse'
                    canPublish = true
                    'If this poem is complete, publish it to make it visible to others.'
            
            if canPublish
                { text : '<p class="text">' + message + '</p><p class="actions"><button class="publish"><i class="icon-ok"></i>Publish</button></p>', type: 'success' }
            else
                { text: '<p class="text">' + message + '</p>' }


    
    getPartSelector: () =>        
        parts = (part for part in @get('parts') when part.sequence is @get('selectedParts').length)
        
        html = ''
        for part in parts        
            html += '<li class="part-select-item" data-partid="' + part.id + '">
                        <img class="profile-pic" src="' + part.createdBy.thumbnail + '" alt="' + part.createdBy.name + '" />' +
                        @formatParts(@get('type'), [part], 'partial') +
                    '   <div style="clear:both"></div>
                    </li>'
                
        '<div class="section part-select-container">
            <p>Choose a contribution below or <a href="#" class="write-part-link">write your own</a>.</p>
            <ul>' + html + '</ul>
            <div style="clear:both"></div>
        </div>'

            
    
    hasContribs: () =>        
        (part for part in @get('parts') when part.sequence is @get('selectedParts').length).length != 0
    
    
    
    isOwner: () =>
        @get('createdBy').id is app.getUser().id
        
        
    
    isOpen: () =>
        @get('state') is 'open' or @get('state') is 'open-unmodifiable'
        
                
    
    canAddContent: () =>
        @isOpen() and
            switch @get('type')
                when 'haiku'
                    @countTotalLines() < 3                
                when 'six-word-story'                            
                    @countTotalWords() < 6
                when 'quote'
                    false
                when 'free-verse'
                    true

  
    sanitize: (text) =>
        #trim the content (spaces and newlines and beginning and end)
        text = text.replace(/^\s+|\s+$/g, '')
        #replace multiple spaces with a single space
        text = text.replace(/[ \t]{2,}/g, ' ')
        text        
  
  
    isLoadedAsync: =>
        @get('attachmentType') is 'image'
  
  
    countLines: (text) =>
        text.split("\n").length        
        
    
    countTotalLines: =>
        sum = (a, b) -> a + b
        (@countLines part.content for part in @get('selectedParts')).reduce(sum, 0)
        
       
    countWords: (text) =>
        text.split(" ").length
        
        
    countTotalWords: =>
        sum = (a, b) -> a + b
        (@countWords part.content for part in @get('selectedParts')).reduce(sum, 0)  
  
  
    validateNewPart: (content) =>
        content = @sanitize content
        if not content
            return { isValid: false, error: "You haven't written anything." }
        else
            if @get('type') is 'haiku'        
                remaining = 3 - @countTotalLines()    
                newLines = @countLines content
                if not(newLines <= remaining)
                    if remaining is 1
                        return { isValid: false, error: "A Haiku has three lines, and two lines have already been written. You may only write the last." }        
                    else
                        return { isValid: false, error: "A Haiku has three lines, and one line has already been written. You may write the last two." }        
            else if @get('type') is 'six-word-story'
                remaining = 6 - @countTotalWords()
                newWords = @countWords content
                if not(newWords <= remaining)
                    if remaining is 1
                        return { isValid: false, error: "A Six Word Story has six words, and five words have already been written. You may only write the last word." }        
                    else if remaining is 5
                        return { isValid: false, error: "A Six Word Story has six words, and one word has already been written. You may only write five words." }        
                    else
                        return { isValid: false, error: "A Six Word Story has six words, and #{toWords @countTotalWords()} words have already been written. You may only write #{remaining} words." }        
            return { isValid: true }        
        
    
  
    getFontSize: (containerSize) =>  
        maxLength = 0      
        lineCount = 0
        charCount = 0
        for part in @get('selectedParts')
            for line in part.content.split('\n')
                lineCount++
                charCount += line.length
                if line.length > maxLength
                    maxLength = line.length
        
        if lineCount > 10 or charCount > 180
            16
        
        if @get('type') is 'quote'
            24
        
        if lineCount > 8
            14        
        else if lineCount > 3
            if maxLength > 50
                16
            else if maxLength > 30
                18
            else
                20 
        else
            if maxLength > 50
                18
            else if maxLength > 30
                20
            else
                22


                        
    shorten: (text, length) =>
        lines = text.split '\n'
        if length and lines[0].length > length
            lines[0].substring(0, length) + "..."
        else
            lines[0]        
    
    
  
window.Poe3.Post = Post        


###
    The Posts Collection
###
class Posts extends Backbone.Collection
    model: Post
    
    url: => 
        Poe3.apiUrl 'posts'

Post.collection = Poe3.Posts
        
window.Poe3.Posts = Posts

###
    The User Model
###
class User extends BaseModel

    url: =>
        if @id
            Poe3.apiUrl "users/#{@id}"
        else if @get('domain') and @get('username') 
            Poe3.apiUrl "users", { domain:@get('domain'), username: @get('username') }
        

    isFollowedBy: (userid) =>
        matching = (follower for follower in @get('followers') when follower.id is userid)
        matching.length isnt 0
            
    
    
window.Poe3.User = User


###
    The Users Collection
###
class Users extends Backbone.Collection
    model: User
    
    url: => 
        Poe3.apiUrl 'users'

User.collection = Poe3.Users
        
window.Poe3.Users = Users


###
    The Comment Model
###
class Comment extends BaseModel
    
window.Poe3.Comment = Comment


###
    The Comments Collection
###
class Comments extends Backbone.Collection
    model: Comment

    url: =>
        if @postid
            Poe3.apiUrl "posts/#{@postid}/comments"
        else
            throw "The postid property is not defined for this Messages instance." 

window.Poe3.Comments = Comments


###
    The Message Model
###
class Message extends BaseModel

    idAttribute: "_id"


    toHtml: (viewType='full') =>        
        data = @get 'data'        

        switch @get 'reason'
            when 'new-user'
                user = new Poe3.User data.user
                switch @get 'type'
                    when 'global-notification'
                        joined = if data.location?.name then "joined from #{data.location.name}" else "joined"
                        "
                        <div class=\"message-body\">
                            <a href=\"/#{user.get('domain')}/#{user.get('username')}\"><img src=\"#{user.get('thumbnail')}\" alt=\"#{user.get('name')}\" /></a>
                            <p>
                                <a href=\"/#{user.get('domain')}/#{user.get('username')}\">#{user.get('name')}</a> #{joined}.
                            </p>
                        </div>"

            when 'new-post'
                post = new Poe3.Post data.post
                switch @get 'type'
                    when 'global-notification'
                        
                        if post.get('authoringMode') is 'collaborative'
                            what = "Started <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>."
                        else
                            what = "Completed <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>."            
                            
                        "
                        <div class=\"message-body\">
                            <a href=\"/#{post.get('createdBy').domain}/#{post.get('createdBy').username}\"><img src=\"#{post.get('createdBy').thumbnail}\" alt=\"#{post.get('createdBy').name}\" /></a>
                            <p>
                                #{what}
                            </p>
                        </div>"

            when 'part-contribution'
                post = new Poe3.Post data.post
                switch @get 'type'
                    when 'user-notification'                
                        switch viewType                
                            when 'full'                
                                "
                                <div class=\"message-body\">      
                                    <p>
                                        Contributed to <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                    <p class=\"subtext\">
                                        #{post.shorten data.part.content, 300}
                                    </p>
                                </div>"                                

                            when 'condensed'
                                "
                                <div class=\"message-body\">      
                                    <a href=\"/#{data.part.createdBy.domain}/#{data.part.createdBy.username}\"><img src=\"#{data.part.createdBy.thumbnail}\" alt=\"#{data.part.createdBy.name}\" /></a> 
                                    <p>
                                        contributed to <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                </div>"                                
                    when 'global-notification'
                        switch viewType                
                            when 'condensed' #There is only a condensed view.
                                "
                                <div class=\"message-body\">      
                                    <a href=\"/#{data.part.createdBy.domain}/#{data.part.createdBy.username}\"><img src=\"#{data.part.createdBy.thumbnail}\" alt=\"#{data.part.createdBy.name}\" /></a> 
                                    <p>
                                        contributed to <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                </div>"                                
            when 'liked-post'
                post = new Poe3.Post data.post
                
                switch @get 'type'
                    when 'user-notification'                
                        switch viewType                
                            when 'full'                
                                "
                                <div class=\"message-body\">      
                                    <p>
                                        Likes <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                </div>"
                            when 'condensed'
                                "
                                <div class=\"message-body\">      
                                    <a href=\"/#{@get('from').domain}/#{@get('from').username}\"><img src=\"#{@get('from').thumbnail}\" alt=\"#{@get('from').name}\" /></a> 
                                    <p>
                                        likes <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                </div>"
                    
                    
            when 'added-comment'
                post = new Poe3.Post data.post
                
                switch @get 'type'
                    when 'user-notification'                   
                        switch viewType
                            when 'full'
                                "
                                <div class=\"message-body\">      
                                    <p>
                                        Commented on <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                    <p class=\"subtext\">
                                        #{post.shorten data.comment.content, 300}
                                    </p>
                                </div>" 
                            when 'condensed'
                                "
                                <div class=\"message-body\">      
                                    <a href=\"/#{data.comment.createdBy.domain}/#{data.comment.createdBy.username}\"><img src=\"#{data.comment.createdBy.thumbnail}\" alt=\"#{data.comment.createdBy.name}\" /></a> 
                                    <p>
                                        commented on <a href=\"/#{post.get('uid')}\">#{post.getPostName(56, false)}</a>
                                    </p>
                                </div>" 
            
            when 'new-follower'    
                switch @get 'type'
                    when 'user-notification'                   
                        switch viewType
                            when 'full'
                                "
                                <div class=\"message-body\">      
                                    <p>
                                        Started following you.
                                    </p>
                                </div>"
                            when 'condensed'
                                "
                                <div class=\"message-body\">      
                                    <a href=\"/#{@get('from').domain}/#{@get('from').username}\"><img src=\"#{@get('from').thumbnail}\" alt=\"#{@get('from').name}\" /></a> 
                                    <p>
                                        started following you.
                                    </p>
                                </div>"
                
            when 'promo-internal'    
                data
            else
                ''
            
window.Poe3.Message = Message


###
    The Messages Collection
###
class Messages extends Backbone.Collection
    model: Message

    url: =>
        if @userid
            Poe3.apiUrl "users/#{@userid}/messages"
        else
            throw "The userid property is not defined for this Messages instance." 

User.collection = Poe3.Messages
        
window.Poe3.Messages = Messages



