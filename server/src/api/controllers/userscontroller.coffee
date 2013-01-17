controller = require('./controller')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
fs = require 'fs'
AppError = require('../../common/apperror').AppError

class UsersController extends controller.Controller


    getUsers: (req, res, next) =>
        @attachUser arguments, =>
            if req.query.username? and req.query.domain?
                models.User.getByUsername req.query.domain, req.query.username, { user: req.user }, (err, user) =>
                    if user
                        res.send user.summarize ['about', 'facebookUsername', 'twitterUsername', 'website', 'followers', 'following']
                    else
                        next new AppError 'No such user.', 'USER_DOES_NOT_EXIST'
            else
                next new AppError 'Invalid query.', 'INVALID_QUERY'



    updateUser: (req, res, next) =>
        @ensureSession arguments, =>        
            if req.user.id is req.params.id
                models.User.getById req.user.id, { user: req.user }, (err, user) =>
                    if not err
                        user.about = req.body.about
                        user.twitterUsername = req.body.twitterUsername
                        user.website = req.body.website
                        if req.body.showFBUrl is "true"
                            user.showFBUrl = req.body.showFBUrl
                        user.save { user: req.user }, (err, user) =>
                            if not err
                                res.send user.summarize ['about', 'twitterUsername', 'website']
                            else
                                next err
                    else
                        next err
            else        
                next new AppError 'Access denied.', 'ACCESS_DENIED'
            
            
            
    follow: (req, res, next) =>
        @ensureSession arguments, =>        
            models.User.getById req.params.id, { user: req.user }, (err, user) =>
                if not err
                    user.follow req.user.id, { user: req.user }, (err, follower) =>
                        if not err
                            res.send follower

                            message = new models.Message { 
                                userid: req.params.id,
                                type: 'user-notification',
                                reason: 'new-follower',
                                to: user.summarize(),
                                from: req.user,
                                data: { }
                            }
                            message.save {}, =>                                
                            
                        else
                            next err
                else
                    next err            
        
        
        
    unfollow: (req, res, next) =>
        @ensureSession arguments, =>    
            models.User.getById req.params.id, { user: req.user }, (err, user) =>
                if not err
                    user.unfollow req.user.id, { user: req.user }, (err, follower) =>
                        if not err
                            res.send follower
                        else
                            next err
                else
                    next err          
                      
        
        
    getMessages: (req, res, next) =>
        @ensureSession arguments, =>
            if req.user.id is req.params.id
                models.User.getById req.user.id, { user: req.user }, (err, user) =>
                    if not err
                        criteria = {}
                        if req.query.since
                            criteria.since = parseInt req.query.since
                        user.getMessages criteria, { user: req.user }, (err, messages) =>
                            #update the last message accessed time
                            models.UserInfo.get { userid: req.user.id }, { user: req.user }, (err, userinfo) =>
                                if not err
                                    userinfo.lastAccessMessageTime = Date.now()
                                    userinfo.save { user: req.user }, =>
                            res.send messages
                    else
                        next err
            else        
                next new AppError 'Access denied.', 'ACCESS_DENIED'            

        
        
    syncStatus: (req, res, next) =>
        _handleError = @handleError next
        lastSyncTime = Date.now()
        @ensureSession arguments, =>
            if req.user.id is req.params.id
                models.User.getById req.user.id, { user: req.user }, _handleError (err, user) =>
                    models.UserInfo.get { userid: req.user.id }, { user: req.user }, _handleError (err, userinfo) =>
                        lastAccessMessageTime = userinfo.lastAccessMessageTime ? 0                            
                        user.getMessageCount lastAccessMessageTime, { user: req.user }, _handleError (err, count) =>
                            user.getBroadcasts parseInt(req.query.since), { user: req.user }, _handleError (err, broadcasts) =>
                                res.send { userid: req.user.id, broadcasts, messageCount: count, lastSyncTime }
            else
                next new AppError 'Access denied.', 'ACCESS_DENIED'
        
    
    
    getBroadcasts: (req, res, next) =>
        since = parseInt req.query.since
        lastSyncTime = Date.now()
        params = { userid: '0', type: 'showcase', timestamp: { $gt: since } }
        models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 5), {}, (err, showcase) =>
            params = { userid: '0', type: 'global-notification', timestamp: { $gt: since } }
            models.Message.find params, ((cursor) -> cursor.sort({ _id: -1 }).limit 20), {}, (err, globalNotifications) =>
                res.send { broadcasts: { showcase, globalNotifications }, lastSyncTime }
        

    
exports.UsersController = UsersController      
