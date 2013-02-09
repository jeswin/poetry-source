controller = require('./controller')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
fs = require 'fs'
utils = require '../../common/utils'
AppError = require('../../common/apperror').AppError


class AdminController extends controller.Controller

    ensureAdmin: (args, fn) =>
        [req, res, next] = args 
        @getUserWithPasskey req.query.passkey, (err, user) =>
            admin = (u for u in conf.admins when u.username is user?.username and u.domain is user?.domain)
            if admin.length
                req.user = user
                fn()
            else
                console.log "#{@user?.username}@#{@user?.domain}"
                next new AppError "Well, you don't look much of an admin to me.", 'NOT_ADMIN'



    addMeta: (req, res, next) =>
        @ensureAdmin arguments, =>
            models.Post.get { uid: parseInt req.query.uid }, { user: req.user }, (err, post) =>
                if req.query.meta
                    if post.meta.indexOf(req.query.meta) is -1
                        post.meta.push req.query.meta
                        post.save {}, =>
                            res.send post
                    else
                        res.send "#{req.query.meta} exists in meta."
                else
                    res.send "Missing meta."                    
                    
                    
    deleteMeta: (req, res, next) =>
        @ensureAdmin arguments, =>
            if req.query.meta
                models.Post.get { uid: parseInt req.query.uid }, { user: req.user }, (err, post) =>
                    post.meta = (i for i in post.meta when i isnt req.query.meta)
                    post.save {}, =>
                        res.send post
            else
                res.send "Missing meta."                      

                    
    impersonate: (req, res, next) =>
        @ensureAdmin arguments, =>
            models.User.get { domain: req.query.domain, username: req.query.username }, {}, (err, user) =>
                if user and not err
                    #Always get the last session
                    models.Session.find { userid: user._id.toString() }, ((cursor) -> cursor.sort({ timestamp: -1 }).limit(1)), { user: req.user }, (err, sessions) =>
                        session = sessions[0]
                        if not err
                            res.send { userid: user._id, domain: user.domain, username: user.username, name: user.name, passkey: session.passkey }



    addMessage: (req, res, next) =>
        @ensureAdmin arguments, =>
            msg = new models.Message()

            msg.userid = '0' #Right now we can only send broadcasts
            msg.type = req.body.type
            msg.reason = req.body.reason
            msg.data = req.body.data
            msg.data = msg.data.replace /\_\(/g, '<'
            msg.data = msg.data.replace /\)\_/g, '>'
            msg.data = msg.data.replace /js\:/g, 'javascript:'            
            msg.timestamp = parseInt(req.body.timestamp) 
                            
            msg.save {}, (err, msg) =>
                if not err
                    res.send msg
                else
                    res.send "Error adding message."
                      
          
                                    
    deleteMessage: (req, res, next) =>
        @ensureAdmin arguments, =>
            models.Message.getById req.query.id, {}, (err, message) =>
                if not err
                    message.destroy {}, (err) =>
                        if not err
                            res.send "Deleted"
                        else
                            next err
                else
                    next err                
            
            
            
exports.AdminController = AdminController


