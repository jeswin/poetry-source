https = require 'https'

conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
controller = require('./controller')
AppError = require('../../common/apperror').AppError

class HomeController extends controller.Controller


    index: (req, res, next) =>
        params = { meta: 'featured', state: 'complete', attachmentType: 'image' }
        settings = { sort: { publishedAt: -1, uid: -1 }, limit: 2 }
        
        models.Post.search params, settings, {}, (err, posts) =>
            if posts?.length
                post = posts[0]
                img = if post.attachmentType is 'image' then post.attachment
                authors = [post.createdBy] 
                for coauthor in post.coauthors
                    authors.push coauthor
                res.render 'home/index.hbs', { img, title: 'Write Poetry. Together.', authors, post }
            else
                res.render 'index.hbs', { title: 'Write Poetry. Together.'}



    showPost: (req, res, next) =>
        uid = parseInt req.params.uid
        if uid
            models.Post.get { uid }, {}, (err, post) =>
                if post
                    img = if post.attachmentType is 'image' then post.attachment
                    title = post.getPostName(30)
                    authors = [post.createdBy] 
                    for coauthor in post.coauthors
                        authors.push coauthor
                    res.render 'home/showpost.hbs', { img, title, authors, post }
                else
                    res.render 'index.hbs', { title: 'Write Poetry. Together.'}
        else
            res.render 'index.hbs', { title: 'Write Poetry. Together.'}

            
exports.HomeController = HomeController
