https = require 'https'

conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
controller = require('./controller')
AppError = require('../../common/apperror').AppError

class UsersController extends controller.Controller

    showUser: (req, res, next) =>
        models.User.get { domain: req.params.domain, username: req.params.username }, {}, (err, user) =>
            if user
                title = user.name                

                params = {}
                params.$or = [ 
                    { 'createdBy.domain': user.domain, 'createdBy.username': user.username }, 
                    { 'coauthors.domain': user.domain, 'coauthors.username': user.username } 
                ]
                params.state = "complete"
                settings = { sort: { uid: -1 } }        
                models.Post.search params, settings, { user: req.user }, (err, posts) =>           
                    for post in posts
                        post.authors = [post.createdBy]
                        for coauthor in post.coauthors
                            post.authors.push coauthor
                                                 
                    res.render 'users/showuser.hbs', { title, user, posts }
            else
                res.render 'index.hbs', { title: 'Write Poetry. Together.'}
        
            
exports.UsersController = UsersController
