// Generated by CoffeeScript 1.4.0
(function() {
  var AppError, HomeController, conf, controller, https, models,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  https = require('https');

  conf = require('../../conf');

  models = new (require('../../models')).Models(conf.db);

  controller = require('./controller');

  AppError = require('../../common/apperror').AppError;

  HomeController = (function(_super) {

    __extends(HomeController, _super);

    function HomeController() {
      this.showPost = __bind(this.showPost, this);

      this.index = __bind(this.index, this);
      return HomeController.__super__.constructor.apply(this, arguments);
    }

    HomeController.prototype.index = function(req, res, next) {
      var params, settings,
        _this = this;
      params = {
        meta: 'featured',
        state: 'complete',
        attachmentType: 'image'
      };
      settings = {
        sort: {
          publishedAt: -1,
          uid: -1
        },
        limit: 2
      };
      return models.Post.search(params, settings, {}, function(err, posts) {
        var authors, coauthor, img, post, _i, _len, _ref;
        if (posts != null ? posts.length : void 0) {
          post = posts[0];
          img = post.attachmentType === 'image' ? post.attachment : void 0;
          authors = [post.createdBy];
          _ref = post.coauthors;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            coauthor = _ref[_i];
            authors.push(coauthor);
          }
          return res.render('home/index.hbs', {
            img: img,
            title: 'Write Poetry. Together.',
            authors: authors,
            post: post
          });
        } else {
          return res.render('index.hbs', {
            title: 'Write Poetry. Together.'
          });
        }
      });
    };

    HomeController.prototype.showPost = function(req, res, next) {
      var uid,
        _this = this;
      uid = parseInt(req.params.uid);
      if (uid) {
        return models.Post.get({
          uid: uid
        }, {}, function(err, post) {
          var authors, coauthor, img, title, _i, _len, _ref;
          if (post) {
            img = post.attachmentType === 'image' ? post.attachment : void 0;
            title = post.getPostName(30);
            authors = [post.createdBy];
            _ref = post.coauthors;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              coauthor = _ref[_i];
              authors.push(coauthor);
            }
            return res.render('home/showpost.hbs', {
              img: img,
              title: title,
              authors: authors,
              post: post
            });
          } else {
            return res.render('index.hbs', {
              title: 'Write Poetry. Together.'
            });
          }
        });
      } else {
        return res.render('index.hbs', {
          title: 'Write Poetry. Together.'
        });
      }
    };

    return HomeController;

  })(controller.Controller);

  exports.HomeController = HomeController;

}).call(this);