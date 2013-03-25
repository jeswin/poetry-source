https = require 'https'

conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
controller = require('./controller')
AppError = require('../../common/apperror').AppError

class HomeController extends controller.Controller


    index: (req, res, next) =>
        params = { meta: 'featured', state: 'complete' }
        settings = { sort: { publishedAt: -1, uid: -1 }, limit: 50 }
        
        models.Post.search params, settings, {}, (err, posts) =>
            if posts?.length
            #Find the first poem with an image and place it at the beginning
                postWithImage = (p for p in posts when p.attachmentType is 'image')
                if postWithImage.length
                    postWithImage = postWithImage[0]                    
                    posts = [postWithImage].concat (p for p in posts when p.uid isnt postWithImage.uid)    
                    
                for post in posts
                    post.authors = [post.createdBy]
                    for coauthor in post.coauthors
                        post.authors.push coauthor
                    
                res.render 'home/index.hbs', { title: 'Write Poetry. Together.', posts }
            else
                res.render 'index.hbs', { title: 'Write Poetry. Together.'}



    showPost: (req, res, next) =>
        uid = parseInt req.params.uid
        if uid
            models.Post.get { uid }, {}, (err, post) =>
                if post
                    post.authors = [post.createdBy]
                    for coauthor in post.coauthors
                        post.authors.push coauthor
                    res.render 'home/showpost.hbs', { post }
                else
                    res.render 'index.hbs', { title: 'Write Poetry. Together.'}
        else
            res.render 'index.hbs', { title: 'Write Poetry. Together.'}

            
exports.HomeController = HomeController
