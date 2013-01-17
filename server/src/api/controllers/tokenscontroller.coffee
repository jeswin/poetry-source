controller = require('./controller')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
fs = require 'fs'
AppError = require('../../common/apperror').AppError

class TokensController extends controller.Controller

    getToken: (req, res, next) =>
        @attachUser arguments, =>
            models.Token.get { type: req.params.type, key: req.params.key }, { user: req.user }, (err, token) =>
                if not err
                    res.send token
                else
                    next err


    createToken: (req, res, next) =>
        @attachUser arguments, =>
            token = new models.Token {
                type: req.body.type,
                key: req.body.key,
                value: req.body.value
            }        
            token.save { user: req.user }, (err, token) =>
                if not err
                    res.send token
                else
                    next err
        
exports.TokensController = TokensController
