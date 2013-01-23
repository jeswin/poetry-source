console.log "Poe3 content server started at #{new Date}"
console.log "NODE_ENV is #{process.env.NODE_ENV}"
console.log '---------------------'

express = require 'express'

conf = require '../conf'
models = new (require '../models').Models(conf.db)
database = new (require '../common/database').Database(conf.db)

controllers = require './controllers'
utils = require '../common/utils'
ApplicationCache = require('../common/cache').ApplicationCache
validator = require('validator')

app = express()
app.set("view engine", "hbs");
app.set('view options', { layout: 'layouts/default' })

app.use(express.cookieParser())

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
            when 'home' then new controllers.HomeController()
            when 'users' then new controllers.UsersController()
            when 'auth' then new controllers.AuthController()
            else throw new Error "Cannot find controller."
        getHandler(controller)(req, res, next)


app.get '/', findHandler('home', (c) -> c.index)
app.get '/:uid', findHandler('home', (c) -> c.showPost)

for domain in ['fb', 'tw', 'poets']
    do (domain) ->
        app.get "/#{domain}/:username", (req, res, next) -> 
            req.params.domain = domain
            findHandler('users', (c) -> c.showUser)(req, res, next)
    
app.get '/auth/twitter', findHandler('auth', (c) -> c.twitter)
app.get '/auth/twitter/callback', findHandler('auth', (c) -> c.twitterCallback)


#ERROR HANDLING
app.use(app.router)

#handle errors
app.use (err, req, res, next) ->
    console.log err
    res.send(500, 'Something broke.')

#This is the standard 404 handler. But we use this to render index.hbs all the time.
app.use (req, res, next) ->
    res.render 'index.hbs', { title: 'Write Poetry. Together.'}
    #res.send(404, { error: 'HTTP 404. There is no water here.' })

    
host = process.argv[2]
port = process.argv[3]

            
app.listen(port, host ? '')
