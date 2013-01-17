console.log "Poe3 api services started at #{new Date}"
console.log "NODE_ENV is #{process.env.NODE_ENV}"
console.log '---------------------'

express = require 'express'
conf = require '../conf'
database = new (require '../common/database').Database(conf.db)
models = new (require '../models').Models(conf.db)
apicontrollers = require './controllers'
utils = require '../common/utils'
ApplicationCache = require('../common/cache').ApplicationCache
validator = require('validator')

app = express()

app.use express.bodyParser({
    uploadDir:'../../www-user/temp',
    limit: '6mb'
})
app.use(express.limit('6mb'));


#session
#app.use express.cookieParser()
#app.use cookieSessions('sid')
#app.use express.session({secret:'345fdgerf', store: new MongoStore({ db: 'mayawebsessions', native: false })})

#check for cross site scripting
app.use (req,res,next) =>
    for inputs in [req.params, req.query, req.body]
        if inputs
            for key, val of inputs
                val = inputs[key]
                val = val.replace '<', '('
                val = val.replace '>', ')'
                inputs[key] = validator.sanitize(val).xss()
    
        if req.files
            for file in req.files
                val = req.files[file]
                val.name = val.name.replace '<', ''
                val.name = val.name.replace '>', ''
                val.name = val.name.replace '"', ''
                val.name = validator.sanitize(val).xss()
    next()

#a channel factory
findHandler = (name, getHandler) ->
    return (req, res, next) ->
        controller = switch name.toLowerCase()
            when 'api/v1/sessions' then new apicontrollers.SessionsController()
            when 'api/v1/posts' then new apicontrollers.PostsController()
            when 'api/v1/users' then new apicontrollers.UsersController()
            when 'api/v1/tokens' then new apicontrollers.TokensController()
            when 'api/v1/admin' then new apicontrollers.AdminController()
            else throw new Error "Cannot find controller."
        getHandler(controller)(req, res, next)


# Sessions Controller
app.post '/api/v1/sessions', findHandler('api/v1/sessions', (c) -> c.createSession)

# Posts Controller
app.get '/api/v1/posts', findHandler('api/v1/posts', (c) -> c.getPosts)
app.post '/api/v1/posts', findHandler('api/v1/posts', (c) -> c.createPost)
app.put '/api/v1/posts/:id', findHandler('api/v1/posts', (c) -> c.updatePost)
app.del '/api/v1/posts/:id', findHandler('api/v1/posts', (c) -> c.deletePost)
app.get '/api/v1/posts/:id', findHandler('api/v1/posts', (c) -> c.getById)
app.post '/api/v1/files', findHandler('api/v1/posts', (c) -> c.upload)
app.get '/api/v1/files/processurl', findHandler('api/v1/posts', (c) -> c.processAttachmentUrl)
app.post '/api/v1/posts/:id/parts', findHandler('api/v1/posts', (c) -> c.addPart)
app.post '/api/v1/posts/:id/selectedparts', findHandler('api/v1/posts', (c) -> c.selectPart)
app.del '/api/v1/posts/:id/selectedparts/:partid', findHandler('api/v1/posts', (c) -> c.unselectPart)
app.put '/api/v1/posts/:id/state', findHandler('api/v1/posts', (c) -> c.setState)
app.put '/api/v1/posts/:id/like', findHandler('api/v1/posts', (c) -> c.like)
app.del '/api/v1/posts/:id/like', findHandler('api/v1/posts', (c) -> c.unlike)
app.get '/api/v1/posts/:id/comments', findHandler('api/v1/posts', (c) -> c.getComments)
app.post '/api/v1/posts/:id/comments', findHandler('api/v1/posts', (c) -> c.addComment)
app.del '/api/v1/posts/:id/comments/:commentid', findHandler('api/v1/posts', (c) -> c.deleteComment)
app.post '/api/v1/posts/:id/fb/shares', findHandler('api/v1/posts', (c) -> c.addFacebookShare)

# Users Controller
app.get '/api/v1/users', findHandler('api/v1/users', (c) -> c.getUsers)
app.put '/api/v1/users/:id', findHandler('api/v1/users', (c) -> c.updateUser)
app.get '/api/v1/users/:id/tags', findHandler('api/v1/users', (c) -> c.getTags)
app.post '/api/v1/users/:id/followers', findHandler('api/v1/users', (c) -> c.follow)
app.del '/api/v1/users/:id/followers/:followerid', findHandler('api/v1/users', (c) -> c.unfollow)
app.get '/api/v1/users/:id/messages', findHandler('api/v1/users', (c) -> c.getMessages)
app.get '/api/v1/users/:id/status', findHandler('api/v1/users', (c) -> c.syncStatus)
app.get '/api/v1/users/0/broadcasts', findHandler('api/v1/users', (c) -> c.getBroadcasts)
#app.get '/api/v1/users/:id/preferences/links/unsubscribe', findHandler('api/v1/users', (c) -> c.unsubscribeLink)

#Tokens Controller
app.get '/api/v1/tokens/:type/:key', findHandler('api/v1/tokens', (c) -> c.getToken)
app.post '/api/v1/tokens', findHandler('api/v1/tokens', (c) -> c.createToken)

#Admin Controller
app.get '/api/v1/kitchen/addmeta', findHandler('api/v1/admin', (c) -> c.addMeta)
app.get '/api/v1/kitchen/deletemeta', findHandler('api/v1/admin', (c) -> c.deleteMeta)
app.get '/api/v1/kitchen/impersonate', findHandler('api/v1/admin', (c) -> c.impersonate)
app.post '/api/v1/kitchen/addmessage', findHandler('api/v1/admin', (c) -> c.addMessage)
app.get '/api/v1/kitchen/deletemessage', findHandler('api/v1/admin', (c) -> c.deleteMessage)

#ERROR HANDLING
app.use(app.router)

app.use (err, req, res, next) ->
    console.log err
    res.send(500, 'Something broke.')

# handle 404
app.use (req, res, next) ->
    res.send(404, { error: 'Well.. there is no water here.' })

    
host = process.argv[2]
port = process.argv[3]


###
    GLOBALS AND CACHING
###

global.appSettings = {}

#Load the cache
global.cachingWhale = new ApplicationCache()

#Ensure indexes.
database.getDb (err, db) ->
    db.collection 'sessions', (_, coll) ->
        coll.ensureIndex { passkey: 1 }, ->
        coll.ensureIndex { accessToken: 1 }, ->

    db.collection 'posts', (_, coll) ->
        coll.ensureIndex { uid: 1 }, ->
        coll.ensureIndex { uid: 1, state: 1 }, ->
        coll.ensureIndex { uid: -1, state: 1 }, ->
        coll.ensureIndex { tags: 1 }, ->
        coll.ensureIndex { publishedAt: 1 }, ->
        coll.ensureIndex { 'createdBy.id': 1 }, ->
        coll.ensureIndex { 'createdBy.username': 1, 'createdBy.domain': 1 }, ->
        coll.ensureIndex { 'createdBy.username': 1, 'createdBy.domain': 1, 'coauthors.username': 1, 'coauthors.domain': 1 }, ->
        
    db.collection 'messages', (_, coll) ->
        coll.ensureIndex { userid: 1 }, ->
        
    db.collection 'comments', (_, coll) ->
        coll.ensureIndex { postid: 1 }, ->

    db.collection 'tokens', (_, coll) ->
        coll.ensureIndex { type: 1, key: 1 }, ->


#if the counters don't exist, create it.
database.findOne '_counters', { key: 'postid' }, (err, kvp) =>
    if not kvp
        database.insert '_counters', { key: 'postid', value: 0}, (err, kvp) =>
           console.log 'Created postid counter.'
            
            
global.appSettings.getNewPostUID = (cb) ->
    database.incrementCounter 'postid', (err, counter) ->        
        cb err, counter
        

app.listen(port)
