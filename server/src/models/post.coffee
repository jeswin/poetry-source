async = require '../common/async'
utils = require '../common/utils'
AppError = require('../common/apperror').AppError
BaseModel = require('./basemodel').BaseModel


class Post extends BaseModel

    ###
        Fields
            - uid (integer; sequential and unique)
            - type (string; 'haiku', 'six-word-story', 'quote', 'free-verse')
            - state (string; 'open' or 'complete' or 'open-unmodifiable')
            - attachmentType (string; 'image')
            - attachment (string; for attachmentType = image this is the url)
            - attachmentThumbnail (string; url)
            - attachmentCreditsName (string)
            - attachmentCreditsWebsite (string)
            - authoringMode (string; 'collaborative' or 'solo')
            - createdBy (summarized user)
            - notes (string)
            - tags (array of string)
            - title (string; exists if type is 'free-verse')
            - coauthors (array of summarized user)
            - likes (array of summarized user)
            - likeCount (integer)
            - meta (array of string)
            - rating (integer)
            - timestamp (integer)
            - publishedAt (integer)
        }   
    ###        
    
    @_meta: {
        type: Post,
        collection: 'posts',
        concurrency: 'optimistic',
        logging: {
            isLogged: true,
            onInsert: 'NEW_POST'
        }
    }
    
    
    constructor: (params) ->
        @parts = []
        @selectedParts = []
        @coauthors = []        
        @likes = []
        @likeCount = 0
        @meta = []
        @tags = []
        @rating = 1
        super        
                                    
    
    @getLimit: (limit, _default, max) ->
        result = _default
        if limit
            result = limit
            if result > max
                result = max
        result
            
            
    @search: (criteria, settings, context, cb) ->      
        limit = @getLimit settings.limit, 100, 1000
                
        params = {}
        for k, v of criteria
            params[k] = v
        
        Post.find params, ((cursor) -> cursor.sort(settings.sort).limit limit), context, cb
        
            

    save: (context, cb) =>
        @tags = (tag.replace(/^\s+|\s+$/g, '') for tag in @tags)
        @tags = (tag.replace(/^#/, '') for tag in @tags)
        @tags = (tag for tag in @tags when tag isnt '')
    
        #Check if basic information is there
        if not @type? or not @authoringMode? or (@attachmentType is 'image' and not @attachment?)            
            cb new AppError 'Post has fields missing.', 'FIELDS_MISSING_IN_POST'
        else        
            #This is a new Post.
            if not @_id?
                @timestamp = Date.now()            
                @state = 'open'          
                appSettings.getNewPostUID (err, @uid) =>                    
                    if @createdBy.id is context.user.id #Silly check. But looks legitimate.
                        #Create the post
                        super context, cb
            else
                #Updating and existing post
                super context, cb
                    


    unpublish: (context, cb) =>
        if @state is 'complete'
            #if the post has all the required lines/words, it goes to a state called 'open-unmodifiable'
            if @type is 'haiku' or @type is 'six-word-story' or @type is 'quote'
                @state = 'open-unmodifiable'
            else
                @state = 'open'

            @save context, cb
        else
            cb new AppError 'Post isn\'t published.', 'POST_NOT_PUBLISHED'



    destroy: (context, cb) =>
        #Delete all the associated comments.
        Post._models.Comment.destroyAll { postid: @_id.toString() }, =>
        super context, cb



    addPart: (part, context, cb) =>
        part.id = utils.uniqueId(24)
        part.sequence = @selectedParts.length

        if @state isnt 'open'
            cb new AppError 'Post is not open.', "POST_NOT_OPEN"        
        else        
            part.content = @fixPartContent part.content        
            if part.content
                result = switch @type
                    when 'haiku'
                        @addHaikuPart part, context
                    when 'six-word-story'
                        @addSixWordStoryPart part, context
                    when 'quote'
                        @addQuotePart part, context
                    when 'free-verse'
                        @addFreeVersePart part, context
                    else
                        { valid: false, message: 'Unsupported post type.', name: 'UNSUPPORTED_POST_TYPE' }
                
                if result.valid
                    if result.state is 'complete'
                        @publish context, cb
                    else
                        @state = result.state
                        @save context, cb
                else
                    cb new AppError(result.message, result.name)
                
            else
                cb new AppError 'An empty part cannot be added.', 'PART_IS_EMPTY'
            


    #Because front-end fuckers are lazy :)
    fixPartContent: (content) =>
        #replace more than three newlines with a double newline
        content = content.replace(/[\n]{3,}/g, "\n\n")

        lines = content.split '\n'
        validParas = []
        para = []

        for line in lines
            
            #trim the content (spaces and newlines and beginning and end)
            line = line.replace(/^\s+|\s+$/g, '')
            #replace multiple spaces with a single space
            line = line.replace(/[ \t]{2,}/g, ' ')
            
            if line
                para.push line
            
            #An empty line is a new paragraph.
            if not line and para.length isnt 0
                validParas.push para
                para = []
                
        if para.length isnt 0
            validParas.push para
        
        paras = (para.join('\n') for para in validParas)
        paras.join('\n\n')
                
    
    
    addHaikuPart: (part, context) =>
        valid = if @authoringMode is 'collaborative'
                    #if this is the first part, the author may write one or two lines.
                    if not @selectedParts.length
                        (@countLines part.content) <= 2
                    else
                        @countTotalLines() + (@countLines part.content) <= 3
        
                else if @authoringMode is 'solo'
                    @countTotalLines() + (@countLines part.content) is 3
        
        if valid                               
            @parts.push part
            if context.user.id is @createdBy.id
                @selectedParts.push part
    
            if @authoringMode is 'solo'
                state = 'complete'
            else if @countTotalLines() is 3
                state = 'open-unmodifiable'
            else
                state = 'open'    

            { valid: true, state }            
        else
            { valid: false, message: "Invalid number of lines in part.", name: 'INVALID_LINE_COUNT' }
            


    addSixWordStoryPart: (part, context) =>                
        valid = if @authoringMode is 'collaborative'
                    #if this is the first part, the author may write up to five words.
                    if not @selectedParts.length
                        (@countWords part.content) <= 5
                    else
                        @countTotalWords() <= 6
        
                else if @authoringMode is 'solo'
                    (@countWords part.content) is 6
        
        if valid                               
            @parts.push part
            if context.user.id is @createdBy.id
                @selectedParts.push part
        
            if @authoringMode is 'solo'
                state = 'complete'
            else if @countTotalWords() is 6
                state = 'open-unmodifiable'
            else
                state = 'open'

            { valid: true, state }            
        else
            { valid: false, message: "Invalid number of words in part.", name: 'INVALID_WORD_COUNT' }



    addQuotePart: (part, context) =>                
        @parts.push part
        @selectedParts.push part
        { valid: true, state: 'complete' }            
        
        
    
    addFreeVersePart: (part, context) =>
        @parts.push part
        if context.user.id is @createdBy.id
            @selectedParts.push part
        if @authoringMode is 'solo'
            { valid: true, state: 'complete' }
        else
            { valid: true, state: 'open' }
    

    
    selectPart: (partid, context, cb) =>
        if @state isnt 'open'
            cb new AppError 'Post is not open.', "POST_NOT_OPEN"
        else if context.user.id isnt @createdBy.id
            cb new AppError "Access denied.", "ACCESS_DENIED"
        else
            parts = (part for part in @parts when part.id is partid)
            if parts.length
                @selectedParts.push parts[0]

                #Content-complete haikus and six-word-stories should go to 'open-unmodifiable' state
                if (@type is 'haiku' and @countTotalLines() is 3) or (@type is 'six-word-story' and @countTotalWords() is 6)
                    @state = 'open-unmodifiable'
                
                @save context, cb                                
            else
                cb new AppError "Cannot find a part with id #{partid}.", "CANNOT_FIND_PART"



    unselectPart: (partid, context, cb) =>
        if @state is 'complete'
            cb new AppError 'Post is published.', "POST_IS_PUBLISHED"
        else if context.user.id isnt @createdBy.id
            cb new AppError "Access denied.", "ACCESS_DENIED"
        else            
            if @selectedParts.length isnt 1            
            #Only the last part can be unselected.
                lastPart = @selectedParts[-1..][0]
                if @selectedParts.length and lastPart.id is partid
                    #Unselecting any part will change the type to open.
                    #Valid in the case of haikus and six word stories.
                    if @state isnt 'open'
                        @state = 'open'
                    @selectedParts.pop()
                    @save context, cb
                else
                    cb new AppError 'Only the last part can be unselected.', "CAN_ONLY_UNSELECT_LAST_PART"
            else
                cb new AppError 'The first part cannot be unselected.', "CANNOT_UNSELECT_FIRST_PART"



    publish: (context, cb) =>                                
        if @createdBy.id isnt context.user.id
            cb new AppError 'Access denied.', 'ACCESS_DENIED'
        else if @state is 'complete'
            cb new AppError 'Post is published.', 'POST_IS_PUBLISHED'
        else if @type is 'haiku' and @countTotalLines() isnt 3
            cb new AppError 'Haiku needs to have three lines.', 'INVALID_LINE_COUNT'
        else if @type is 'six-word-story' and @countTotalWords() isnt 6
            cb new AppError 'Six word story needs to have six words.', 'INVALID_WORD_COUNT'
        else
            if not @publishedAt
                @publishedAt = Date.now()
            @state = 'complete'
            for part in @selectedParts
                if part.createdBy.id isnt @createdBy.id #Owner isn't a coauthor.
                    found = (a for a in @coauthors when a.id is part.createdBy.id).length > 0
                    if not found
                        @coauthors.push part.createdBy
            @save context, cb



    like: (context, cb) =>
        notFound = (u for u in @likes when u.id is context.user.id).length is 0
        
        if notFound            
            @likes.push context.user
            @likeCount = @likes.length
            @save context, cb
        else
            cb()
            


    unlike: (context, cb) =>
        found = (u for u in @likes when u.id is context.user.id).length > 0
        
        if found
            @likes = (user for user in @likes when user.id isnt context.user.id)
            @likeCount = @likes.length
            @save context, cb
        else
            cb()



    getPostType: () =>
        switch @type
            when 'haiku'
                'Haiku'
            when 'six-word-story'
                'Six Word Story'
            when 'quote'
                'Quote'
            when 'free-verse'
                'Free Verse'
            else
                'Unknown type'
                

    sanitize: (text) =>
        #trim the content (spaces and newlines and beginning and end)
        text = text.replace(/^\s+|\s+$/g, '')
        #replace multiple spaces with a single space
        text = text.replace(/[ \t]{2,}/g, ' ')
        text          
    
    
    countLines: (text) =>
        text.split("\n").length        
        
    
    countTotalLines: () =>
        sum = (a, b) -> a + b
        (@countLines part.content for part in @selectedParts).reduce(sum, 0)
        
       
    countWords: (text) =>
        text.split(" ").length
        
        
    countTotalWords: () =>
        sum = (a, b) -> a + b
        (@countWords part.content for part in @selectedParts).reduce(sum, 0)


    isOwner: (userid) =>
        @createdBy.id is userid
        
        
        
    getPostName: (maxLength, prefixType) =>
        switch @type
            when 'haiku'
                type = if prefixType then 'Haiku ' else ''
                "#{type}#{@shorten @selectedParts[0].content, maxLength}"
            when 'six-word-story'
                type = if prefixType then 'Six Word Story ' else ''
                text = (part.content for part in @selectedParts).join ' '
                "#{type}#{@shorten text, maxLength}"
            when 'quote'
                type = if prefixType then 'Quote ' else ''
                "#{type}#{@shorten @selectedParts[0].content, maxLength}"
            when 'free-verse'
                type = if prefixType then 'Free Verse ' else ''
                "#{type}#{@shorten (@title ? @selectedParts[0].content), maxLength}"
                
                
        
    shorten: (text, length) =>
        lines = text.split '\n'
        if length and lines[0].length > length
            lines[0].substring(0, length) + "..."
        else
            lines[0]
        
        
        
    validateFirstPart: (part) =>
        content = @sanitize part.content
        
        if not content
            { isValid: false, message: "You haven't written anything.", name: "PART_IS_EMPTY" }
        else
            #solo
            if @authoringMode is 'solo'
                if @type is 'haiku'
                    if @countLines(content) isnt 3
                        return { isValid: false, message: "A Haiku needs three lines.", name: 'INVALID_LINE_COUNT' }
                else if @type is 'six-word-story'
                    if @countWords(content) isnt 6
                        return { isValid: false, message: "A Six Word Story needs six words.", name: 'INVALID_WORD_COUNT' }
            
            #collaborative
            else if @authoringMode is 'collaborative'
                if @type is 'haiku'
                    if @countLines(content) >= 3
                        return { isValid: false, message: 'In a collaborative Haiku, you cannot write more than two lines.', name: 'INVALID_LINE_COUNT' }
                else if @type is 'six-word-story'
                    if @countWords(content) >= 6
                        return { isValid: false, message: 'In a collaborative Six Word Story, you cannot write more than five words.', name: 'INVALID_WORD_COUNT' }

            { isValid: true }    
    
    
    
    summarize: (fields = []) =>
        fields = fields.concat ['type', 'authoringMode', 'uid', 'timestamp', 'createdBy', 'coauthors', 'selectedParts', 'publishedAt', 'state', 'tags', 'attachmentType', 'attachment', 'attachmentThumbnail']
        result = super fields
        result.id = @_id.toString()
        result



    validate: =>
        errors = []

        if isNaN @uid
            errors.push 'Invalid uid.'
    
        if @type isnt 'haiku' and @type isnt 'six-word-story' and @type isnt 'quote' and @type isnt 'free-verse'
            errors.push 'Invalid type.'
        
        if @type is 'haiku' and @countTotalLines() > 3
            errors.push 'A haiku can have up to 3 lines.'

        if @type is 'six-word-story' and @countTotalWords() > 6
            errors.push 'A Six Word Story can have up to 6 words.'    
    
        if @state isnt 'open' and @state isnt 'complete' and @state isnt 'open-unmodifiable'
            errors.push 'Invalid state.'
            
        if @state is 'open'
            if (@type is 'six-word-story' and @countTotalWords() is 6) or (@type is 'haiku' and @countTotalLines() is 3)
                errors.push 'Open post cannot be content-complete.'                    

        if @state is 'open-unmodifiable'
            if @type is 'free-verse'
                errors.push 'Free verse cannot be in complete state.'
            if (@type is 'six-word-story' and @countTotalWords() isnt 6) or (@type is 'haiku' and @countTotalLines() isnt 3)
                errors.push 'Unmodifiable post must be content-complete.'            
            
        if @state is 'complete'
            if (@type is 'six-word-story' and @countTotalWords() isnt 6) or (@type is 'haiku' and @countTotalLines() isnt 3)
                errors.push 'Completed post must be content complete.'                    
            
        if @attachmentType
            if @attachmentType isnt 'image'
                errors.push 'Invalid attachmentType.'
            if @attachmentType is 'image' 
                if not @attachment
                    errors.push 'Invalid attachment.'
                if not @attachmentThumbnail
                    errors.push 'Invalid attachmentThumbnail.'
        
        if @authoringMode isnt 'collaborative' and @authoringMode isnt 'solo'
            errors.push 'Invalid authoringMode.'
        
        _errors = Post._models.User.validateSummary(@createdBy)
        if _errors.length            
            errors.push 'Invalid createdBy.'
            errors = errors.concat _errors
            
        for user in @coauthors
            _errors = Post._models.User.validateSummary(user)
            if _errors.length                 
                errors.push 'Invalid coauthor.'
                errors = errors.concat _errors

        for user in @likes
            _errors = Post._models.User.validateSummary(user)
            if _errors.length                 
                errors.push 'Invalid like.'
                errors = errors.concat _errors

        if isNaN(@timestamp)
            errors.push 'Invalid timestamp.'
            
        if @publishedAt
            if isNaN(@publishedAt)
                errors.push 'Invalid publishedAt.'

        { isValid: errors.length is 0, errors }

exports.Post = Post
