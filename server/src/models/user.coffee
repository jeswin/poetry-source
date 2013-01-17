utils = require '../common/utils'

BaseModel = require('./basemodel').BaseModel
AppError = require('../common/apperror').AppError

class User extends BaseModel

    ###
        Fields
            - domain (string; 'fb' or 'poets')
            - domainid (string)
            - username (string)
            - domainidType (string; 'username' or 'domainid')
            - name (string)
            - location (string)
            - picture (string)
            - thumbnail (string)
            - email (string)
            - accessToken (string)
            - lastLogin (integer)
            - followers (array of summarized user)
            - following (array of summarized user)
            - about (string)
            - karma (integer)
            - facebookUsername (string)
            - twitterUsername (string)
            - website (string)
            - timestamp (integer)
    ###            
    
    @_meta: {
        type: User,
        collection: 'users',
        logging: {
            isLogged: true,
            onInsert: 'NEW_USER'
        }
    }
    
    
    #Called from controllers when a new session is created.
    @getOrCreateUser: (userDetails, domain, accessToken, cb) =>
        @_models.Session.get { accessToken }, {}, (err, session) =>
            if err
                cb err
            else
                session ?= new @_models.Session { passkey: utils.uniqueId(24), accessToken }
                    
                User.get { domain, username: userDetails.username }, {}, (err, user) =>
                    if user?
                        #Update some details
                        user.name = userDetails.name ? user.name
                        user.domainid = userDetails.domainid ? user.domainid
                        user.username = userDetails.username ? userDetails.domainid
                        user.domainidType = if userDetails.username then 'username' else 'domainid'
                        user.location = userDetails.location ? user.location
                        user.picture = userDetails.picture ? user.picture
                        user.thumbnail = userDetails.thumbnail ? user.thumbnail
                        user.email = userDetails.email ? 'unknown@poe3.com'
                        user.lastLogin = Date.now()
                        user.save {}, (err, u) =>
                            if not err
                                session.userid = u._id.toString()
                                session.timestamp = Date.now()
                                session.save {}, (err, session) =>
                                    if not err
                                        cb null, u, session
                                    else
                                        cb err
                            else
                                cb err
                        
                    else                            
                        #User doesn't exist. create.
                        user = new User()
                        user.domain = domain
                        user.domainid = userDetails.domainid
                        user.username = userDetails.username ? userDetails.domainid
                        user.domainidType = if userDetails.username then 'username' else 'domainid'
                        if domain is 'fb'
                            user.facebookUsername = userDetails.username
                        if domain is 'tw'
                            user.twitterUsername = userDetails.username
                        user.name = userDetails.name
                        user.location = userDetails.location
                        user.picture = userDetails.picture
                        user.thumbnail = userDetails.thumbnail
                        user.email = userDetails.email ? 'unknown@poe3.com'
                        user.lastLogin = Date.now()
                        user.preferences = { canEmail: true }
                        user.save {}, (err, u) =>
                            #also create the userinfo
                            if not err
                                userinfo = new @_models.UserInfo()
                                userinfo.userid = u._id.toString()
                                userinfo.save {}, (err, _uinfo) =>
                                    if not err
                                        session.userid = u._id.toString()
                                        session.timestamp = Date.now()
                                        session.save {}, (err, session) =>
                                            if not err
                                                cb null, u, session

                                                #Also put an entry in the notifications table.
                                                loc = if user.location?.name then " from #{user.location?.name}" else ""
                                                message = new @_models.Message {
                                                    userid: '0',
                                                    type: "global-notification",
                                                    reason: 'new-user',
                                                    data: { user: user.summarize(), location: user.location }
                                                }
                                                message.save {}, (err, msg) ->
                                            else
                                                cb err
                                    else
                                        cb err
                            else
                                cb err
    
    
    @getById: (id, context, cb) ->
        super id, context, cb

    

    @getByUsername: (domain, username, context, cb) ->
        User.get { domain, username }, context, (err, user) ->
            cb null, user


    
    @validateSummary: (user) =>
        errors = []
        if not user
            errors.push "Invalid user."
        
        required = ['id', 'domain', 'username', 'name', 'picture', 'thumbnail', 'domainidType']
        for field in required
            if not user[field]
                errors.push "Invalid #{field}"
                
        errors
        
        

    constructor: (params) ->
        @followers = []
        @following = []
        @about = ''
        @karma = 1
        @preferences = {}
        @timestamp = Date.now()
        super(params)
        


    follow: (followerid, context, cb) =>
        User.getById followerid, context, (err, user) =>
            if not err
                matching = (follower for follower in @followers when follower.id is followerid)
                if not matching.length #Not followed.
                    @followers.push user.summarize()
                    #make sure the user's following list is also updated.
                matching = (following for following in user.following when following.id is @_id.toString())
                if not matching.length #Not following
                    user.following.push @summarize()
                user.save context, (err, user) =>
                    if not err
                        @save context, (err, user) =>
                            if not err
                                cb err, { id: followerid }
                            else
                                cb err
                    else
                        cb err
            else
                cb err
            


    unfollow: (followerid, context, cb) =>
        User.getById followerid, context, (err, user) =>
            if not err
                @followers = (follower for follower in @followers when follower.id isnt followerid)
                user.following = (following for following in user.following when following.id isnt @_id.toString())                
                user.save context, (err, user) =>
                    if not err
                        @save context, (err, user) =>
                            if not err
                                cb err, { id: followerid }
                            else
                                cb err
                    else
                        cb err
            else
                cb err        



    getMessages: (criteria, context, cb) =>
        params = { userid: @_id.toString() }
        if criteria.since
            params.timestamp = { $gt: since }        
        User._models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 100), context, cb



    getMessageCount: (since, context, cb) =>
        params = { userid: @_id.toString(), timestamp: { $gt: since } }
        User._models.Message.getCursor params, context, (err, cursor) =>
            cursor.limit(100).count cb
        


    getBroadcasts: (since, context, cb) =>
        params = { userid: '0', type: 'showcase', timestamp: { $gt: since } }
        User._models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 5), context, (err, showcase) =>
            params = { userid: '0', type: 'global-notification', timestamp: { $gt: since } }
            User._models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 20), context, (err, globalNotifications) =>
                params = { userid: @_id.toString(), type: 'user-notification', timestamp: { $gt: since } }
                User._models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 20), context, (err, userNotifications) =>
                    cb err, { showcase, globalNotifications, userNotifications }



    summarize: (fields = []) =>
        fields = fields.concat ['domain', 'username', 'name', 'picture', 'thumbnail', 'domainidType']
        result = super fields
        result.id = @_id.toString()
        result
        


    validate: =>
        errors = []
        
        if @domain isnt 'fb' and @domain isnt 'poets' and @domain isnt 'tw'
            errors.push 'Invalid domain.'
        
        if not @domainid or not @username
            errors.push 'Invalid domainid.'
        
        if @domainidType isnt 'username' and @domainidType isnt 'domainid'
            errors.push 'Invalid domainidType.'
        
        if not @name 
            errors.push 'Invalid name.'
            
        if not @picture
            errors.push 'Invalid picture.'
        if not @thumbnail
            errors.push 'Invalid thumbnail.'

        if not @preferences
            errors.push 'Invalid preferences.'

        if isNaN(@lastLogin)            
            errors.push 'Invalid lastLogin.'
        
        for user in @followers
            _errors = User.validateSummary(user)
            if _errors.length
                errors.push 'Invalid follower.'
                errors = errors.concat _errors
            
        for user in @following
            _errors = User.validateSummary(user)
            if _errors.length
                errors.push 'Invalid following.'
                errors = errors.concat _errors

        if isNaN @timestamp
            errors.push 'Invalid timestamp.'
            
        { isValid: errors.length is 0, errors }
    

exports.User = User
