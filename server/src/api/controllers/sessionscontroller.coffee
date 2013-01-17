controller = require('./controller')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
querystring = require 'querystring'
utils = require('../../common/utils')
FaceBookClient = require('../../common/facebookclient').FaceBookClient
AppError = require('../../common/apperror').AppError

class SessionsController extends controller.Controller
   
    createSession: (req, res, next) =>
        if req.body.domain == 'fb'        
            client = new FaceBookClient()            
            options = {
                path: '/me?' + querystring.stringify { 
                    fields: 'id,username,name,first_name,last_name,location,email', 
                    access_token: req.body.accessToken, 
                    client_id: conf.auth.facebook.FACEBOOK_APP_ID, 
                    client_secret: conf.auth.facebook.FACEBOOK_SECRET 
                }
            }
            
            client.secureGraphRequest options, (err, userDetails) =>
                _userDetails = @parseFBUserDetails(JSON.parse userDetails)
                if _userDetails.domainid and _userDetails.name
                    models.User.getOrCreateUser _userDetails, 'fb', req.body.accessToken, (err, user, session) =>
                        if not err
                            res.contentType 'json'
                            res.send { 
                                userid: user._id, 
                                domain: 'fb', 
                                username: user.username, 
                                name: user.name, 
                                passkey: session.passkey
                            }
                        else
                            next err
                else
                    next new AppError 'Invalid credentials', 'INVALID_CREDENTIALS'
                    
                    
        else if req.body.domain == 'poets'
            if req.body.secret is conf.auth.adminkeys.default
                accessToken = utils.uniqueId(24)
                models.User.getOrCreateUser req.body, 'poets', accessToken, (err, user, session) =>
                    if not err
                        res.contentType 'json'
                        res.send { userid: user._id, domain: 'poets', username: user.username, domainidType: user.domainidType, name: user.name, passkey: session.passkey }
                    else
                        next err
            else
                next new AppError 'Access denied', 'ACCESS_DENIED'
                    
                    
                    
    parseFBUserDetails: (userDetails) =>
        {
            domainid: userDetails.id,
            username: userDetails.username ? userDetails.id,
            name: userDetails.name,
            location: userDetails.location,
            email: userDetails.email,
            picture: "http://graph.facebook.com/#{userDetails.id}/picture?type=large",
            thumbnail: "http://graph.facebook.com/#{userDetails.id}/picture"
        }

    
exports.SessionsController = SessionsController
