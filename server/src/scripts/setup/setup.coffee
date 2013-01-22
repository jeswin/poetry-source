async = require('../../common/async')
utils = require('../../common/utils')
querystring = require('querystring')
http = require('http')
data = require './data'
conf = require '../../conf'

dbconf = { db: { name: 'poetry-db-dev', host: '127.0.0.1' } }
database = new (require '../../common/database').Database(dbconf.db)

console.log "Setup started at #{new Date}"
console.log "NODE_ENV is #{process.env.NODE_ENV}"
console.log "Setup will connect to database #{dbconf.db.name} on #{dbconf.db.host}"

HOST = 'scribble.poe3.com'
PORT = '80'

if process.env.NODE_ENV isnt 'development'
    console.log 'Setup can only be run in development.'
    process.exit()
    
if HOST isnt 'scribble.poe3.com'
    console.log 'HOST should be local.'
    process.exit()
    

init = () ->
    _globals = {}

    if '--delete' in process.argv        
        database.getDb (err, db) ->
            console.log 'Deleting main database.'
            db.dropDatabase (err, result) ->
                console.log 'Everything is gone now.'
                process.exit()
    else if '--create' in process.argv
        console.log 'This script will setup basic data. Calls the latest HTTP API.'

        getPostName = (post) ->
            post.parts[0].content.split('\n')[0]
            
        getPartName = (part) ->
            part.content.split('\n')[0]

        #Create Users
        _globals.sessions = {}

        createUser = (user, cb) ->
            console.log "Creating #{user.username}..." 
            user.domain = 'poets'
            user.secret = conf.auth.adminkeys.default
            doHttpRequest '/api/v1/sessions', querystring.stringify(user), 'post', (err, resp) ->                
                console.log "Created #{resp.username}"
                _globals.sessions[user.username] = resp
                cb()
        
        createUserTasks = []
        for user in data.users
            do (user) ->
                createUserTasks.push (cb) ->
                    createUser user, cb
                
        #Create Posts
        _globals.posts = []
        
        createPost = (_post, cb) ->
            passkey = _globals.sessions[_post.user].passkey
            console.log "Creating a new post with passkey(#{passkey})...." 

            post = utils.clone _post
            post.content = _post.parts[0].content
            post.attachmentType ?= ''
            post.authoringMode = if _post.parts.length > 1 then 'collaborative' else 'solo'
            delete post.user
            delete post.parts
            
            doHttpRequest "/api/v1/posts/?passkey=#{passkey}", querystring.stringify(post), 'post', (err, savedPost) ->                    
                console.log "Created post: #{getPostName savedPost}..."
                _globals.posts.push savedPost
                if post.authoringMode is 'collaborative'
                    otherParts = _post.parts[1..]
                    addPartTasks = []
                    for part in otherParts
                        do (part) ->
                            addPartTasks.push (cb) ->    
                                createPart part, savedPost._id, (err, post) ->
                                    selectPart savedPost._id, post.parts.pop().id, passkey, cb
                    async.series addPartTasks, cb
                else
                    cb()

        createPart = (_part, postid, cb) ->
            passkey = _globals.sessions[_part.user].passkey
            part = utils.clone _part
            delete part.user
            console.log "Creating part(#{getPartName part}) for post #{postid} with passkey(#{passkey})...."
            doHttpRequest "/api/v1/posts/#{postid}/parts?passkey=#{passkey}", querystring.stringify(part), 'post', (err, resp) ->
               console.log "Added part."
               cb err, resp
        
        
        selectPart = (postid, partid, passkey, cb) ->
            console.log "Selecting part(#{partid}) in post(#{postid})."
            doHttpRequest "/api/v1/posts/#{postid}/selectedParts?passkey=#{passkey}", querystring.stringify({id:partid}), 'post', (err, resp) ->
               console.log "Selected part."
               cb()               
            
        
        createPostTasks = []
        for post in data.posts
            do (post) ->
                createPostTasks.push (cb) ->                        
                    createPost post, cb


        #Complete those posts.
        completePost = (passkey, postid, cb) ->
            console.log "Completing post(#{postid})."
            doHttpRequest "/api/v1/posts/#{postid}/state?passkey=#{passkey}", querystring.stringify({ value: 'complete' }), 'put', (err, _r) ->            
                console.log "Completed post."
                cb()
    

        completePostTasks = []
        completePostTasks.push (cb) ->
            tasks = []        
            for post in _globals.posts                
                do (post) ->
                    if post.state isnt 'complete'
                        passkey = _globals.sessions[post.createdBy.username].passkey                    
                        tasks.push (cb) ->
                            completePost passkey, post._id, cb
            async.series tasks, cb


        #Follow and Unfollow
        followUsers = (list, user, cb) ->
            passkey = _globals.sessions[user].passkey
            tasks = []
            for following in list
                do (following) ->
                    followingid = _globals.sessions[following].userid                    
                    tasks.push (cb) ->
                        console.log "Following #{following}(#{followingid}) with passkey(#{passkey})...."
                        doHttpRequest "/api/v1/users/#{followingid}/followers?passkey=#{passkey}", null, 'post', (err, resp) ->
                           console.log "#{user} followed #{following}"
                           cb()
            async.series tasks, cb
               
        unfollowUsers = (list, user, cb) ->
            passkey = _globals.sessions[user].passkey
            userid = _globals.sessions[user].userid
            tasks = []
            for following in list
                do (following) ->
                    followingid = _globals.sessions[following].userid                                        
                    tasks.push (cb) ->                        
                        console.log "Unfollowing #{following}(#{followingid}) with passkey(#{passkey})...."
                        doHttpRequest "/api/v1/users/#{followingid}/followers/#{userid}?passkey=#{passkey}", null, 'delete', (err, resp) ->
                           console.log "#{user} unfollowed #{following}"
                           cb()
            async.series tasks, cb


        followUsersTasks = []
        followUsersTasks.push (cb) ->
            followUsers ['buson', 'issa', 'shiki', 'hemingway'], 'basho', cb
        followUsersTasks.push (cb) ->
            followUsers ['basho', 'issa', 'shiki'], 'buson', cb
        followUsersTasks.push (cb) ->
            followUsers ['basho', 'buson', 'shiki'], 'issa', cb
        followUsersTasks.push (cb) ->
            followUsers ['basho', 'buson', 'issa'], 'shiki', cb
        followUsersTasks.push (cb) ->
            followUsers ['basho', 'buson', 'issa', 'shiki'], 'hemingway', cb
                
        unfollowUsersTasks = []
        unfollowUsersTasks.push (cb) ->
            unfollowUsers ['buson', 'issa'], 'shiki', cb

        
        #Like and unlike posts...
        likePosts = (list, user, cb) ->
            userid = _globals.sessions[user].userid
            passkey = _globals.sessions[user].passkey
            tasks = []
            for postid in list                
                do (postid) ->            
                    tasks.push (cb) ->
                        console.log "#{user}(#{userid}) liking post(#{postid})...."
                        doHttpRequest "/api/v1/posts/#{postid}/like?passkey=#{passkey}", null, 'put', (err, resp) -> 
                           console.log "#{user} liked #{postid}"
                           cb()
            async.series tasks, cb


        unlikePosts = (list, user, cb) ->
            userid = _globals.sessions[user].userid
            passkey = _globals.sessions[user].passkey
            tasks = []
            for postid in list                
                do (postid) ->            
                    tasks.push (cb) ->
                        console.log "#{user}(#{userid}) unliking post(#{postid})...."
                        doHttpRequest "/api/v1/posts/#{postid}/like?passkey=#{passkey}", null, 'delete', (err, resp) ->
                           console.log "#{user} unliked #{postid}"
                           cb()
            async.series tasks, cb
            
        
        likePostsTasks = []
        likePostsTasks.push (cb) ->
            postids = []                
            for post in _globals.posts            
                if post.createdBy.username is 'basho' or post.createdBy.username is 'hemingway'
                    postids.push post._id        
            likePosts postids, 'shiki', cb    
            
        
        unlikePostsTasks = []
        unlikePostsTasks.push (cb) ->
            postids = []                
            for post, i in _globals.posts            
                if post.createdBy.username is 'basho' and (i % 3 is 0)
                    postids.push post._id        
            unlikePosts postids, 'shiki', cb    

            
        tasks = ->
            async.series createUserTasks, ->
                console.log 'Created users.'
                async.series createPostTasks, ->
                    console.log 'Created posts.'
                    async.series completePostTasks, ->
                        console.log 'Completed posts.'
                        async.series followUsersTasks, ->
                            console.log 'Followed users.'
                            async.series unfollowUsersTasks, ->
                                console.log 'Unfollowed users.'
                                async.series likePostsTasks, ->
                                    console.log 'Liked posts.'
                                    async.series unlikePostsTasks, ->
                                        console.log 'Unliked posts.'
                                        console.log 'Setup complete.'
        
        console.log 'Setup will begin in 3 seconds.'
        setTimeout tasks, 1000
    else
        console.log 'Invalid option.'
        process.exit()  
            


doHttpRequest = (url, data, method, cb) ->
    options = {
        host: HOST,
        port: PORT,
        path: url,
        method: method,
        headers: if data then { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': data.length } else { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': 0 }            
    }

    response = ''
    
    req = http.request options, (res) ->
        res.setEncoding('utf8')
        res.on 'data', (chunk) ->
            response += chunk
            
        res.on 'end', () ->
            cb null, JSON.parse response

    if data
        req.write(data)

    req.end()        

init()
