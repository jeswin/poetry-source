controller = require('./controller')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
utils = require '../../common/utils'
AppError = require('../../common/apperror').AppError
fs = require 'fs-extra'
gm = require 'gm'

url = require('url')
http = require('http')
exec = require('child_process').exec
spawn = require('child_process').spawn

class PostsController extends controller.Controller
            
    getPosts: (req, res, next) =>
        @attachUser arguments, =>
            #Returns a single post.
            if req.query.filter is 'uid'
                models.Post.get { uid: parseInt req.query.uid }, { user: req.user }, (err, post) =>
                    if not err
                        res.send post
                    else
                        next err                                           
            else
                sendResponse = (err, posts) =>
                    if not err
                        res.send posts
                    else
                        next err
                        
                params = {}
                settings = {}
                
                if req.query.username? and req.query.domain?                                  
                    #Sort by uid
                    settings.sort = { uid: -1 }
                
                    if req.query.state
                        params.$or = [ 
                            { 'createdBy.domain': req.query.domain, 'createdBy.username': req.query.username }, 
                            { 'coauthors.domain': req.query.domain, 'coauthors.username': req.query.username } 
                        ]
                        if req.query.state is 'incomplete'
                            params.state = { $in: ['open', 'open-unmodifiable'] }
                        else
                            params.state = req.query.state
                        models.Post.search params, settings, { user: req.user }, sendResponse
                    else if req.query.category is 'likes'
                        params['likes.domain'] = req.query.domain
                        params['likes.username'] = req.query.username
                        models.Post.search params, settings, { user: req.user }, sendResponse
                                                
                else if req.query.category?
                    #For completed posts, we have to sort by publishedAt and then by uid.
                    #All requests will have these two params (except the first, which will be empty).
                    
                    if req.query.limit
                        settings.limit = parseInt req.query.limit                      

                    if req.query.tag
                        params.tags = req.query.tag
                        
                    if req.query.type
                        params.type = req.query.type
                        
                    if req.query.attachmentType?
                        params.attachmentType = req.query.attachmentType

                    switch req.query.category
                        when 'popular'
                            params.state = 'complete'
                            params.$or = [{ likeCount: { $gte: 1 } }, { meta: 'featured' }]
                            params.meta = { $ne: 'bp' } #bypass popular
                        when 'all'
                            params.state = 'complete'

                        when 'open'
                            params.state = 'open'
                            
                    #For completed posts, we order by publishedAt
                    if params.state is 'complete'
                        if req.query.before
                            params.publishedAt = { $lte: parseInt req.query.before }
                            settings.sort = { publishedAt: -1, uid: -1 }
                            if req.query.maxuid
                                params.uid = { $lt: parseInt(req.query.maxuid) }
                        else if req.query.after
                            params.publishedAt = { $gte: parseInt req.query.after }
                            settings.sort = { publishedAt: 1, uid: 1 }
                            if req.query.minuid
                                params.uid = { $gt: parseInt(req.query.minuid) }
                        else
                            settings.sort = { publishedAt: -1, uid: -1 }

                        models.Post.search params, settings, { user: req.user }, (err, posts) =>
                            if req.query.after
                                sendResponse err, posts.reverse()
                            else
                                sendResponse err, posts                        
                    
                    #For open posts, we order by uid
                    else if params.state is 'open'
                        if req.query.maxuid
                                params.uid = { $lt: parseInt(req.query.maxuid) }
                                settings.sort = { uid: -1 }
                            else if req.query.minuid
                                params.uid = { $gt: parseInt(req.query.minuid) }
                                settings.sort = { uid: 1 }
                            else
                                settings.sort = { uid: -1 }
                                
                            models.Post.search params, settings, { user: req.user }, (err, posts) =>
                                if req.query.minuid
                                    sendResponse err, posts.reverse()
                                else
                                    sendResponse err, posts

                else
                    next new AppError 'Criteria was not mentioned.', "POST_CRITERIA_MISSING_IN_QUERY"
                            


    getById: (req, res, next) =>
        @attachUser arguments, =>
            models.Post.getById req.params.id, { user: req.user }, (err, post) =>
                if not err
                    res.send post
                else
                    next err
            
    
    
    createPost: (req, res, next) =>        
        @ensureSession arguments, =>
            _handleError = @handleError next            
            @getPostFromRequest req, res, next, _handleError (err, post) =>
                part = @getPartFromRequest req     
                if post and part and post.validateFirstPart(part).isValid
                    post.createdBy = req.user
                    post.save { user: req.user }, _handleError (err, post) =>
                        post.addPart part, { user: req.user }, _handleError (err, post) =>                                
                            res.send post                        
                            if post.attachmentType is 'image'
                                @downloadTempImage post.attachment, _handleError (err, path) =>
                                    if path
                                        @resizeImage path, _handleError (err, imageInfo) =>                                 
                                            models.Post.getById post._id, { user: req.user }, _handleError (err, post) =>
                                                post.attachment = "#{imageInfo.imagesDirUrl}/#{imageInfo.filename}"
                                                post.attachmentThumbnail = "#{imageInfo.thumbnailsDirUrl}/#{imageInfo.filename}"
                                                post.save { user: req.user }, (err) =>
                                                    if err
                                                        next err

                            message = new models.Message {
                                userid: '0',
                                type: "global-notification",
                                reason: 'new-post',
                                data: { post: post.summarize() }
                            }
                            message.save {}, (err, msg) =>                
                else
                    next new AppError "Post had incorrect data.", "POST_DATA_INCORRECT"



    updatePost: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            models.Post.getById req.params.id, { user: req.user }, _handleError (err, post) =>
                if post.createdBy.id is req.user.id
                    @getPostFromRequest req, res, next, _handleError (err, newPost) =>
                        #Right now we only allow updating certain parts of a post.
                        post.tags = newPost.tags
                        post.notes = newPost.notes
                        post.attachmentType = newPost.attachmentType

                        #see if we need to trigger image processsing
                        if post.attachmentType is 'image' and post.attachment isnt newPost.attachment
                            mustProcessImage = true
                            post.attachment = newPost.attachment
                            post.attachmentThumbnail = newPost.attachment
                            
                        if post.attachmentType
                            if post.attachmentCreditsName isnt newPost.attachmentCreditsName 
                                post.attachmentCreditsName = newPost.attachmentCreditsName
                                if post.attachmentCreditsWebsite isnt newPost.attachmentCreditsWebsite
                                    post.attachmentCreditsWebsite = newPost.attachmentCreditsWebsite                            
                        
                        post.save { user : req.user }, _handleError (err, post) =>
                            res.send post
                            if mustProcessImage
                                @downloadTempImage post.attachment, _handleError (err, path) =>
                                    if path
                                        @resizeImage path, _handleError (err, imageInfo) =>                                            
                                            models.Post.getById post._id, { user: req.user }, _handleError (err, post) =>
                                                post.attachment = "#{imageInfo.imagesDirUrl}/#{imageInfo.filename}"
                                                post.attachmentThumbnail = "#{imageInfo.thumbnailsDirUrl}/#{imageInfo.filename}"
                                                post.save { user: req.user }, (err) =>
                                                    if err
                                                        next err
                else
                    next new AppError "Access denied.", "ACCESS_DENIED"                        
                    


    deletePost: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            models.Post.getById req.params.id, { user: req.user }, _handleError (err, post) =>
                if post.createdBy.id is req.user.id
                    post.destroy { user : req.user }, _handleError (err, post) =>
                        res.send post
                else
                    next new AppError "Access denied.", "ACCESS_DENIED"                        

                    

    addPart: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            models.Post.getById req.params.id, { user: req.user }, _handleError (err, post) =>
                @addPartToPost post, req, _handleError (err, post) =>
                    res.send post                            
        
        
                
    addPartToPost: (post, req, cb) =>         
        part = @getPartFromRequest req
        if part
            post.addPart part, { user: req.user }, (err, post) =>
                if not err                
                    cb null, post
                    
                    #Send a message to the owner
                    if not post.isOwner(req.user.id)
                        message = new models.Message { 
                            userid: post.createdBy.id,
                            type: 'user-notification',
                            reason: 'part-contribution',
                            to: post.createdBy,
                            from: part.createdBy,
                            data: { post: post.summarize(), part }
                        }
                        message.save {}, =>
                        
                        message = new models.Message { 
                            userid: 0,
                            type: 'global-notification',
                            reason: 'part-contribution',
                            data: { post: post.summarize(), part }
                        }
                        message.save {}, =>
                    
                else
                    cb err
        else
            cb new AppError 'Part data was incorrect', 'PART_DATA_INCORRECT'



    selectPart: (req, res, next) =>
        @ensureSession arguments, () =>
            models.Post.getById req.params.id, { user: req.user }, (err, post) =>
                post.selectPart req.body.id, { user: req.user }, (err, post) =>
                    if not err
                        res.send post                                                
                    else
                        next err
                    
                    
    
    unselectPart: (req, res, next) =>
        @ensureSession arguments, =>
            models.Post.getById req.params.id, { user: req.user }, (err, post) =>
                post.unselectPart req.params.partid, { user: req.user }, (err, post) =>
                    if not err
                        res.send post
                    else
                        next err
        
        
        
    setState: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            models.Post.getById req.params.id, { user: req.user }, _handleError (err, post) =>
                if (post.state is 'open' or post.state is 'open-unmodifiable') and req.body.value is 'complete'
                    post.publish { user: req.user }, _handleError (err, post) =>
                        res.send post
                else if post.state is 'complete' and req.body.value is 'open'
                    post.unpublish { user: req.user }, _handleError (err, post) =>
                        res.send post
                else
                    next new AppError "Cannot change state.", "CANNOT_CHANGE_STATE"                                                                      
        

    
    like: (req, res, next) =>
        @ensureSession arguments, =>
            models.Post.getById req.params.id, { user: req.user }, (err, post) =>
                if not err
                    post?.like { user: req.user }, (err) =>
                        if not err
                            res.send post

                            if not post.isOwner(req.user.id)
                                message = new models.Message { 
                                    userid: post.createdBy.id,
                                    type: 'user-notification',
                                    reason: 'liked-post',
                                    to: post.createdBy,
                                    from: req.user,
                                    data: { post: post.summarize() }
                                }
                                message.save {}, =>
                        else
                            next err
                else
                    next err        
        
        

    unlike: (req, res, next) =>
        @ensureSession arguments, =>
            models.Post.getById req.params.id, { user: req.user }, (err, post) =>
                if not err
                    post?.unlike { user: req.user }, (err) =>
                        if not err
                            res.send post
                        else
                            next err
                else
                    next err
    


    getComments: (req, res, next) =>
        @attachUser arguments, =>
            models.Comment.getAll { postid: req.params.id }, {user: req.user}, (err, comments) =>
                if not err
                    res.send comments
                else
                    next err



    addComment: (req, res, next) =>
        @ensureSession arguments, =>
            comment = new models.Comment {
                postid: req.params.id,
                content: req.body.content,
                createdBy: req.user
            }
            comment.save { user: req.user }, (err, comment) =>
                if not err
                    res.send comment
                    
                    models.Post.getById req.params.id, { user: req.user }, (err, post) =>                        
                        if not post.isOwner(req.user.id)
                            message = new models.Message { 
                                userid: post.createdBy.id,
                                type: 'user-notification',
                                reason: 'added-comment',
                                to: post.createdBy,
                                from: req.user,
                                data: { post: post.summarize(), comment }
                            }
                            message.save {}, =>                    
                else
                    next err

                    
                    
    deleteComment: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            models.Post.getById req.params.id, { user: req.user }, _handleError (err, post) =>
                if post.createdBy.id is req.user.id
                    models.Comment.getById req.params.commentid, { user: req.user }, _handleError (err, comment) =>
                        comment.destroy { user: req.user}, _handleError (err, comment) =>
                            res.send comment
                else
                    next new AppError "Access denied.", "ACCESS_DENIED"                        
            

    
    addFacebookShare: (req, res, next) =>
        @ensureSession arguments, =>
            message = req.body.message
            message = message.replace(/\"/g, "")
            context = { user: req.user }
            models.Session.get { passkey: req.query.passkey }, {}, (err, session) =>
                models.Post.getById req.params.id, context, (err, post) =>
                    #if there is an image, we do an image upload. Else we do a boring text post.
                    if post.attachmentType is 'image'
                        urlFragments = post.attachment.split('/')
                        filename = urlFragments[urlFragments.length - 1]
                        uploadBaseDir = urlFragments[urlFragments.length - 2]

                        if not /\.\./.test(uploadBaseDir) #Minor security check. Make sure there aren't any '..'s since we are about the access the local file system.                            
                            res.send { success: true }                                                                
                            localFile = "../../www-user/images/#{uploadBaseDir}/#{filename}"            
                            _curl = "curl -F 'access_token=#{session.accessToken}' -F 'source=@#{localFile}' -F \"message=#{message}\" https://graph.facebook.com/me/photos"
                            console.log _curl
                            child = exec _curl, (err, stdout, stderr) =>
                                #TODO: Check if there is an error.
                                if not err
                                    console.log "#{req.user.username} shared an image #{localFile} on Facebook."
                                else
                                    console.log "Failed to share on Facebook: user=#{req.user.username} file=#{localFile}"

                    else
                        res.send { success: true }
                        _curl = "curl -F 'access_token=#{session.accessToken}' -F \"message=#{message}\" https://graph.facebook.com/me/feed"
                        child = exec _curl, (err, stdout, stderr) =>
                            #TODO: Check if there is an error.                            
                            if not err
                                console.log "#{req.user.username} shared a post with uid #{post.uid} on Facebook."
                            else
                                console.log "Failed to share on Facebook: user #{req.user.username}, post uid was #{post.uid}"


    upload: (req, res, next) =>
        @ensureSession arguments, =>
            if req.files
                timestamp = Date.now()
                extension = req.files.file.name.split('.').pop()
                filename = "#{utils.uniqueId(8)}_#{timestamp}.#{extension}"
                fs.rename req.files.file.path, "../../www-user/temp/#{filename}", (err) =>
                    if not err
                        @resizeImage "../../www-user/temp/#{filename}", (err, imageInfo) =>
                            if not err
                                res.set 'Content-Type', 'text/html'
                                res.send { attachment: "#{imageInfo.imagesDirUrl}/#{imageInfo.filename}", attachmentThumbnail: "#{imageInfo.thumbnailsDirUrl}/#{imageInfo.filename}" }
                            else
                                next err
                    else
                        next err



    processAttachmentUrl: (req, res, next) =>
        @ensureSession arguments, =>
            _handleError = @handleError next
            @downloadTempImage req.query.url, _handleError (err, path) =>
                if path            
                    @resizeImage path, _handleError (err, imageInfo) =>
                        res.send { attachment: "#{imageInfo.imagesDirUrl}/#{imageInfo.filename}", attachmentThumbnail: "#{imageInfo.thumbnailsDirUrl}/#{imageInfo.filename}" }
                else                    
                    next new AppError "Invalid url", "INVALID_URL"



    getPostFromRequest: (req, res, next, cb) =>    
        _handleError = @handleError next
        
        post = new models.Post { 
            type: req.body.type, 
            attachmentType: req.body.attachmentType ? '', 
            authoringMode: req.body.authoringMode, 
            createdBy: req.user,
            notes: req.body.notes,
            tags: if req.body.tags then req.body.tags.split(/[\s,]+/) else []            
        }   
        
        if post.type is 'free-verse' and req.body.title
            post.title = req.body.title
        
        if post.attachmentType
            fnAddAttachmentDetails = =>
                post.attachment = encodeURI req.body.attachment
                post.attachmentThumbnail = encodeURI req.body.attachmentThumbnail
                if req.body.attachmentCreditsName
                    post.attachmentCreditsName = req.body.attachmentCreditsName
                    if req.body.attachmentCreditsWebsite
                        post.attachmentCreditsWebsite = utils.fixUrl req.body.attachmentCreditsWebsite

            #If attachmentSourceFormat is binary, we need to save it first.
            if req.body.attachmentSourceFormat is 'binary'
                data = req.body.attachment.replace(/^data:image\/\w+;base64,/, "");
                buf = new Buffer(data, 'base64');
                randomFileName = "#{utils.uniqueId(16)}.jpg"
                filePath = "../../www-user/temp/#{randomFileName}"
                fs.writeFile filePath, buf, _handleError (err) =>
                    fileUrl = "/user/temp/#{randomFileName}"

                    #We have no thumbnail yet. So save the attachment as thumbnail for now.
                    post.attachment = fileUrl
                    post.attachmentThumbnail = fileUrl

                    #fixup request body.
                    req.body.attachment = fileUrl
                    req.body.attachmentThumbnail = fileUrl

                    fnAddAttachmentDetails()
                    cb null, post
            else
                fnAddAttachmentDetails()
                cb null, post
        else
            cb null, post
        
    
        
    getPartFromRequest: (req) =>
        if req.body.content
            { content: req.body.content, createdBy: req.user }
    
    
    
    ###
        Here's the plan:
        1. If the file starts with a local relative path (/user/..), don't download.
        2. Once we do CDN, check those domains here.      
        
        Note:
        cb is called with a path argument only if the image needs to be further processed. Otherwise, we just cb()  
    ###    
    downloadTempImage: (fileUrl, cb) =>    
        if fileUrl            
            parseResult = url.parse(fileUrl)
            hostArr = parseResult.hostname?.split('.')

            #If the url does not start with a local relative path...
            if not /^\/user\//.test(fileUrl)
                extension = parseResult.pathname.split('/').pop().split('.').pop()
                filename = "#{utils.uniqueId(8)}_#{Date.now()}.#{extension}"
                _curl = "curl --max-filesize 5000000 " + fileUrl + " > ../../www-user/temp/#{filename}"
                child = exec _curl, (err, stdout, stderr) =>
                    if not err
                        console.log "Downloaded #{fileUrl} to #{filename}."
                        cb null, "../../www-user/temp/#{filename}"
                    else
                        console.log "Could not download #{fileUrl}."        
                        cb err
            #So we have alocal file.
            else
                console.log "Download not required for #{fileUrl}."
                #Among local images, we only need to handle /user/temp for now.
                if /^\/user\/temp\//.test fileUrl
                    filename = url.parse(fileUrl).pathname.split('/').pop()
                    cb null, "../../www-user/temp/#{filename}"
                else
                    #Images under /user/images and /user/thumbnails are considered 'processed'. 
                    cb()
    
    
    
    resizeImage: (src, cb) =>
        console.log "Resizing #{src}..."
        @createDirectories (err, imagesDir, thumbnailsDir, originalsDir, imagesDirUrl, thumbnailsDirUrl) =>
            filename = src.split('/').pop()
            image = "#{imagesDir}/#{filename}"
            thumbnail = "#{thumbnailsDir}/#{filename}"
            original = "#{originalsDir}/#{filename}"    
        
            gm(src).size (err, size) =>
                if not err
                    newSize = if size.width > 960 then 960 else size.width
                    gm(src).resize(newSize).write image, (err) =>
                        if not err
                            console.log "Resized #{src} to #{image}"
                            gm(src).resize(480).write thumbnail, (err) =>
                                if not err
                                    console.log "Resized #{src} to #{thumbnail}"
                                    fs.rename src, original, (err) =>
                                        if not err
                                            console.log "Moved #{src} to #{original}"
                                            cb null, { filename, imagesDirUrl, thumbnailsDirUrl }
                                
                            
    
    createDirectories: (cb) =>
        BASE_DIR = "../../www-user"    
        d = new Date()
        suffix = "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
        imagesDir = "#{BASE_DIR}/images/#{suffix}"
        thumbnailsDir = "#{BASE_DIR}/thumbnails/#{suffix}"
        originalsDir = "#{BASE_DIR}/originals/#{suffix}"
        fs.exists imagesDir, (exists) =>
            if exists
                cb null, imagesDir, thumbnailsDir, originalsDir, "/user/images/#{suffix}", "/user/thumbnails/#{suffix}"
            else
                fs.mkdir imagesDir, =>
                    fs.mkdir thumbnailsDir, =>
                        fs.mkdir originalsDir, =>
                            cb null, imagesDir, thumbnailsDir, originalsDir, "/user/images/#{suffix}", "/user/thumbnails/#{suffix}"
        
                
exports.PostsController = PostsController
