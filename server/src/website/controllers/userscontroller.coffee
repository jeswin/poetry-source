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
                res.render 'users/showuser.hbs', { title, user }
            else
                res.render 'index.hbs', { title: 'Write Poetry. Together.'}
        
            
exports.UsersController = UsersController
