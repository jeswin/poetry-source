User = require('./user').User
Post = require('./post').Post
Comment = require('./comment').Comment
Message = require('./message').Message
Session = require('./session').Session
Token = require('./token').Token
UserInfo = require('./userinfo').UserInfo

class Models
    constructor: (@dbconf) ->
        @User = User
        @Post = Post
        @Comment = Comment
        @Message = Message
        @Session = Session
        @Token = Token
        @UserInfo = UserInfo
        
        @initModel(model) for model in [User, Post, Comment, Message, Session, Token, UserInfo]

    initModel: (model) ->
        model._database = new (require '../common/database').Database(@dbconf)
        model._models = this

exports.Models = Models
