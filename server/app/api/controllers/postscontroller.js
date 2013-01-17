// Generated by CoffeeScript 1.4.0
(function() {
  var AppError, PostsController, conf, controller, exec, fs, gm, http, models, spawn, url, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controller = require('./controller');

  conf = require('../../conf');

  models = new (require('../../models')).Models(conf.db);

  utils = require('../../common/utils');

  AppError = require('../../common/apperror').AppError;

  fs = require('fs-extra');

  gm = require('gm');

  url = require('url');

  http = require('http');

  exec = require('child_process').exec;

  spawn = require('child_process').spawn;

  PostsController = (function(_super) {

    __extends(PostsController, _super);

    function PostsController() {
      this.createDirectories = __bind(this.createDirectories, this);

      this.resizeImage = __bind(this.resizeImage, this);

      this.downloadTempImage = __bind(this.downloadTempImage, this);

      this.getPartFromRequest = __bind(this.getPartFromRequest, this);

      this.getPostFromRequest = __bind(this.getPostFromRequest, this);

      this.processAttachmentUrl = __bind(this.processAttachmentUrl, this);

      this.upload = __bind(this.upload, this);

      this.addFacebookShare = __bind(this.addFacebookShare, this);

      this.deleteComment = __bind(this.deleteComment, this);

      this.addComment = __bind(this.addComment, this);

      this.getComments = __bind(this.getComments, this);

      this.unlike = __bind(this.unlike, this);

      this.like = __bind(this.like, this);

      this.setState = __bind(this.setState, this);

      this.unselectPart = __bind(this.unselectPart, this);

      this.selectPart = __bind(this.selectPart, this);

      this.addPartToPost = __bind(this.addPartToPost, this);

      this.addPart = __bind(this.addPart, this);

      this.deletePost = __bind(this.deletePost, this);

      this.updatePost = __bind(this.updatePost, this);

      this.createPost = __bind(this.createPost, this);

      this.getById = __bind(this.getById, this);

      this.getPosts = __bind(this.getPosts, this);
      return PostsController.__super__.constructor.apply(this, arguments);
    }

    PostsController.prototype.getPosts = function(req, res, next) {
      var _this = this;
      return this.attachUser(arguments, function() {
        var params, sendResponse, settings;
        if (req.query.filter === 'uid') {
          return models.Post.get({
            uid: parseInt(req.query.uid)
          }, {
            user: req.user
          }, function(err, post) {
            if (!err) {
              return res.send(post);
            } else {
              return next(err);
            }
          });
        } else {
          sendResponse = function(err, posts) {
            if (!err) {
              return res.send(posts);
            } else {
              return next(err);
            }
          };
          params = {};
          settings = {};
          if ((req.query.username != null) && (req.query.domain != null)) {
            settings.sort = {
              uid: -1
            };
            if (req.query.state) {
              params.$or = [
                {
                  'createdBy.domain': req.query.domain,
                  'createdBy.username': req.query.username
                }, {
                  'coauthors.domain': req.query.domain,
                  'coauthors.username': req.query.username
                }
              ];
              if (req.query.state === 'incomplete') {
                params.state = {
                  $in: ['open', 'open-unmodifiable']
                };
              } else {
                params.state = req.query.state;
              }
              return models.Post.search(params, settings, {
                user: req.user
              }, sendResponse);
            } else if (req.query.category === 'likes') {
              params['likes.domain'] = req.query.domain;
              params['likes.username'] = req.query.username;
              return models.Post.search(params, settings, {
                user: req.user
              }, sendResponse);
            }
          } else if (req.query.category != null) {
            if (req.query.limit) {
              settings.limit = parseInt(req.query.limit);
            }
            if (req.query.tag) {
              params.tags = req.query.tag;
            }
            if (req.query.type) {
              params.type = req.query.type;
            }
            if (req.query.attachmentType != null) {
              params.attachmentType = req.query.attachmentType;
            }
            switch (req.query.category) {
              case 'popular':
                params.state = 'complete';
                params.$or = [
                  {
                    likeCount: {
                      $gte: 1
                    }
                  }, {
                    meta: 'featured'
                  }
                ];
                params.meta = {
                  $ne: 'bp'
                };
                break;
              case 'all':
                params.state = 'complete';
                break;
              case 'open':
                params.state = 'open';
            }
            if (params.state === 'complete') {
              if (req.query.before) {
                params.publishedAt = {
                  $lte: parseInt(req.query.before)
                };
                settings.sort = {
                  publishedAt: -1,
                  uid: -1
                };
                if (req.query.maxuid) {
                  params.uid = {
                    $lt: parseInt(req.query.maxuid)
                  };
                }
              } else if (req.query.after) {
                params.publishedAt = {
                  $gte: parseInt(req.query.after)
                };
                settings.sort = {
                  publishedAt: 1,
                  uid: 1
                };
                if (req.query.minuid) {
                  params.uid = {
                    $gt: parseInt(req.query.minuid)
                  };
                }
              } else {
                settings.sort = {
                  publishedAt: -1,
                  uid: -1
                };
              }
              return models.Post.search(params, settings, {
                user: req.user
              }, function(err, posts) {
                if (req.query.after) {
                  return sendResponse(err, posts.reverse());
                } else {
                  return sendResponse(err, posts);
                }
              });
            } else if (params.state === 'open') {
              if (req.query.maxuid) {
                params.uid = {
                  $lt: parseInt(req.query.maxuid)
                };
                settings.sort = {
                  uid: -1
                };
              } else if (req.query.minuid) {
                params.uid = {
                  $gt: parseInt(req.query.minuid)
                };
                settings.sort = {
                  uid: 1
                };
              } else {
                settings.sort = {
                  uid: -1
                };
              }
              return models.Post.search(params, settings, {
                user: req.user
              }, function(err, posts) {
                if (req.query.minuid) {
                  return sendResponse(err, posts.reverse());
                } else {
                  return sendResponse(err, posts);
                }
              });
            }
          } else {
            return next(new AppError('Criteria was not mentioned.', "POST_CRITERIA_MISSING_IN_QUERY"));
          }
        }
      });
    };

    PostsController.prototype.getById = function(req, res, next) {
      var _this = this;
      return this.attachUser(arguments, function() {
        return models.Post.getById(req.params.id, {
          user: req.user
        }, function(err, post) {
          if (!err) {
            return res.send(post);
          } else {
            return next(err);
          }
        });
      });
    };

    PostsController.prototype.createPost = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return _this.getPostFromRequest(req, res, next, _handleError(function(err, post) {
          var part;
          part = _this.getPartFromRequest(req);
          if (post && part && post.validateFirstPart(part).isValid) {
            post.createdBy = req.user;
            return post.save({
              user: req.user
            }, _handleError(function(err, post) {
              return post.addPart(part, {
                user: req.user
              }, _handleError(function(err, post) {
                var message;
                res.send(post);
                if (post.attachmentType === 'image') {
                  _this.downloadTempImage(post.attachment, _handleError(function(err, path) {
                    if (path) {
                      return _this.resizeImage(path, _handleError(function(err, imageInfo) {
                        return models.Post.getById(post._id, {
                          user: req.user
                        }, _handleError(function(err, post) {
                          post.attachment = "" + imageInfo.imagesDirUrl + "/" + imageInfo.filename;
                          post.attachmentThumbnail = "" + imageInfo.thumbnailsDirUrl + "/" + imageInfo.filename;
                          return post.save({
                            user: req.user
                          }, function(err) {
                            if (err) {
                              return next(err);
                            }
                          });
                        }));
                      }));
                    }
                  }));
                }
                message = new models.Message({
                  userid: '0',
                  type: "global-notification",
                  reason: 'new-post',
                  data: {
                    post: post.summarize()
                  }
                });
                return message.save({}, function(err, msg) {});
              }));
            }));
          } else {
            return next(new AppError("Post had incorrect data.", "POST_DATA_INCORRECT"));
          }
        }));
      });
    };

    PostsController.prototype.updatePost = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return models.Post.getById(req.params.id, {
          user: req.user
        }, _handleError(function(err, post) {
          if (post.createdBy.id === req.user.id) {
            return _this.getPostFromRequest(req, res, next, _handleError(function(err, newPost) {
              var mustProcessImage;
              post.tags = newPost.tags;
              post.notes = newPost.notes;
              post.attachmentType = newPost.attachmentType;
              if (post.attachmentType === 'image' && post.attachment !== newPost.attachment) {
                mustProcessImage = true;
                post.attachment = newPost.attachment;
                post.attachmentThumbnail = newPost.attachment;
              }
              if (post.attachmentType) {
                if (post.attachmentCreditsName !== newPost.attachmentCreditsName) {
                  post.attachmentCreditsName = newPost.attachmentCreditsName;
                  if (post.attachmentCreditsWebsite !== newPost.attachmentCreditsWebsite) {
                    post.attachmentCreditsWebsite = newPost.attachmentCreditsWebsite;
                  }
                }
              }
              return post.save({
                user: req.user
              }, _handleError(function(err, post) {
                res.send(post);
                if (mustProcessImage) {
                  return _this.downloadTempImage(post.attachment, _handleError(function(err, path) {
                    if (path) {
                      return _this.resizeImage(path, _handleError(function(err, imageInfo) {
                        return models.Post.getById(post._id, {
                          user: req.user
                        }, _handleError(function(err, post) {
                          post.attachment = "" + imageInfo.imagesDirUrl + "/" + imageInfo.filename;
                          post.attachmentThumbnail = "" + imageInfo.thumbnailsDirUrl + "/" + imageInfo.filename;
                          return post.save({
                            user: req.user
                          }, function(err) {
                            if (err) {
                              return next(err);
                            }
                          });
                        }));
                      }));
                    }
                  }));
                }
              }));
            }));
          } else {
            return next(new AppError("Access denied.", "ACCESS_DENIED"));
          }
        }));
      });
    };

    PostsController.prototype.deletePost = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return models.Post.getById(req.params.id, {
          user: req.user
        }, _handleError(function(err, post) {
          if (post.createdBy.id === req.user.id) {
            return post.destroy({
              user: req.user
            }, _handleError(function(err, post) {
              return res.send(post);
            }));
          } else {
            return next(new AppError("Access denied.", "ACCESS_DENIED"));
          }
        }));
      });
    };

    PostsController.prototype.addPart = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return models.Post.getById(req.params.id, {
          user: req.user
        }, _handleError(function(err, post) {
          return _this.addPartToPost(post, req, _handleError(function(err, post) {
            return res.send(post);
          }));
        }));
      });
    };

    PostsController.prototype.addPartToPost = function(post, req, cb) {
      var part,
        _this = this;
      part = this.getPartFromRequest(req);
      if (part) {
        return post.addPart(part, {
          user: req.user
        }, function(err, post) {
          var message;
          if (!err) {
            cb(null, post);
            if (!post.isOwner(req.user.id)) {
              message = new models.Message({
                userid: post.createdBy.id,
                type: 'user-notification',
                reason: 'part-contribution',
                to: post.createdBy,
                from: part.createdBy,
                data: {
                  post: post.summarize(),
                  part: part
                }
              });
              message.save({}, function() {});
              message = new models.Message({
                userid: 0,
                type: 'global-notification',
                reason: 'part-contribution',
                data: {
                  post: post.summarize(),
                  part: part
                }
              });
              return message.save({}, function() {});
            }
          } else {
            return cb(err);
          }
        });
      } else {
        return cb(new AppError('Part data was incorrect', 'PART_DATA_INCORRECT'));
      }
    };

    PostsController.prototype.selectPart = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        return models.Post.getById(req.params.id, {
          user: req.user
        }, function(err, post) {
          return post.selectPart(req.body.id, {
            user: req.user
          }, function(err, post) {
            if (!err) {
              return res.send(post);
            } else {
              return next(err);
            }
          });
        });
      });
    };

    PostsController.prototype.unselectPart = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        return models.Post.getById(req.params.id, {
          user: req.user
        }, function(err, post) {
          return post.unselectPart(req.params.partid, {
            user: req.user
          }, function(err, post) {
            if (!err) {
              return res.send(post);
            } else {
              return next(err);
            }
          });
        });
      });
    };

    PostsController.prototype.setState = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return models.Post.getById(req.params.id, {
          user: req.user
        }, _handleError(function(err, post) {
          if ((post.state === 'open' || post.state === 'open-unmodifiable') && req.body.value === 'complete') {
            return post.publish({
              user: req.user
            }, _handleError(function(err, post) {
              return res.send(post);
            }));
          } else if (post.state === 'complete' && req.body.value === 'open') {
            return post.unpublish({
              user: req.user
            }, _handleError(function(err, post) {
              return res.send(post);
            }));
          } else {
            return next(new AppError("Cannot change state.", "CANNOT_CHANGE_STATE"));
          }
        }));
      });
    };

    PostsController.prototype.like = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        return models.Post.getById(req.params.id, {
          user: req.user
        }, function(err, post) {
          if (!err) {
            return post != null ? post.like({
              user: req.user
            }, function(err) {
              var message;
              if (!err) {
                res.send(post);
                if (!post.isOwner(req.user.id)) {
                  message = new models.Message({
                    userid: post.createdBy.id,
                    type: 'user-notification',
                    reason: 'liked-post',
                    to: post.createdBy,
                    from: req.user,
                    data: {
                      post: post.summarize()
                    }
                  });
                  return message.save({}, function() {});
                }
              } else {
                return next(err);
              }
            }) : void 0;
          } else {
            return next(err);
          }
        });
      });
    };

    PostsController.prototype.unlike = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        return models.Post.getById(req.params.id, {
          user: req.user
        }, function(err, post) {
          if (!err) {
            return post != null ? post.unlike({
              user: req.user
            }, function(err) {
              if (!err) {
                return res.send(post);
              } else {
                return next(err);
              }
            }) : void 0;
          } else {
            return next(err);
          }
        });
      });
    };

    PostsController.prototype.getComments = function(req, res, next) {
      var _this = this;
      return this.attachUser(arguments, function() {
        return models.Comment.getAll({
          postid: req.params.id
        }, {
          user: req.user
        }, function(err, comments) {
          if (!err) {
            return res.send(comments);
          } else {
            return next(err);
          }
        });
      });
    };

    PostsController.prototype.addComment = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var comment;
        comment = new models.Comment({
          postid: req.params.id,
          content: req.body.content,
          createdBy: req.user
        });
        return comment.save({
          user: req.user
        }, function(err, comment) {
          if (!err) {
            res.send(comment);
            return models.Post.getById(req.params.id, {
              user: req.user
            }, function(err, post) {
              var message;
              if (!post.isOwner(req.user.id)) {
                message = new models.Message({
                  userid: post.createdBy.id,
                  type: 'user-notification',
                  reason: 'added-comment',
                  to: post.createdBy,
                  from: req.user,
                  data: {
                    post: post.summarize(),
                    comment: comment
                  }
                });
                return message.save({}, function() {});
              }
            });
          } else {
            return next(err);
          }
        });
      });
    };

    PostsController.prototype.deleteComment = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return models.Post.getById(req.params.id, {
          user: req.user
        }, _handleError(function(err, post) {
          if (post.createdBy.id === req.user.id) {
            return models.Comment.getById(req.params.commentid, {
              user: req.user
            }, _handleError(function(err, comment) {
              return comment.destroy({
                user: req.user
              }, _handleError(function(err, comment) {
                return res.send(comment);
              }));
            }));
          } else {
            return next(new AppError("Access denied.", "ACCESS_DENIED"));
          }
        }));
      });
    };

    PostsController.prototype.addFacebookShare = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var context, message;
        message = req.body.message;
        message = message.replace(/\"/g, "");
        context = {
          user: req.user
        };
        return models.Session.get({
          passkey: req.query.passkey
        }, {}, function(err, session) {
          return models.Post.getById(req.params.id, context, function(err, post) {
            var child, filename, localFile, uploadBaseDir, urlFragments, _curl;
            if (post.attachmentType === 'image') {
              urlFragments = post.attachment.split('/');
              filename = urlFragments[urlFragments.length - 1];
              uploadBaseDir = urlFragments[urlFragments.length - 2];
              if (!/\.\./.test(uploadBaseDir)) {
                res.send({
                  success: true
                });
                localFile = "../../www-user/images/" + uploadBaseDir + "/" + filename;
                _curl = "curl -F 'access_token=" + session.accessToken + "' -F 'source=@" + localFile + "' -F \"message=" + message + "\" https://graph.facebook.com/me/photos";
                console.log(_curl);
                return child = exec(_curl, function(err, stdout, stderr) {
                  if (!err) {
                    return console.log("" + req.user.username + " shared an image " + localFile + " on Facebook.");
                  } else {
                    return console.log("Failed to share on Facebook: user=" + req.user.username + " file=" + localFile);
                  }
                });
              }
            } else {
              res.send({
                success: true
              });
              _curl = "curl -F 'access_token=" + session.accessToken + "' -F \"message=" + message + "\" https://graph.facebook.com/me/feed";
              return child = exec(_curl, function(err, stdout, stderr) {
                if (!err) {
                  return console.log("" + req.user.username + " shared a post with uid " + post.uid + " on Facebook.");
                } else {
                  return console.log("Failed to share on Facebook: user " + req.user.username + ", post uid was " + post.uid);
                }
              });
            }
          });
        });
      });
    };

    PostsController.prototype.upload = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var extension, filename, timestamp;
        if (req.files) {
          timestamp = Date.now();
          extension = req.files.file.name.split('.').pop();
          filename = "" + (utils.uniqueId(8)) + "_" + timestamp + "." + extension;
          return fs.rename(req.files.file.path, "../../www-user/temp/" + filename, function(err) {
            if (!err) {
              return _this.resizeImage("../../www-user/temp/" + filename, function(err, imageInfo) {
                if (!err) {
                  res.set('Content-Type', 'text/html');
                  return res.send({
                    attachment: "" + imageInfo.imagesDirUrl + "/" + imageInfo.filename,
                    attachmentThumbnail: "" + imageInfo.thumbnailsDirUrl + "/" + imageInfo.filename
                  });
                } else {
                  return next(err);
                }
              });
            } else {
              return next(err);
            }
          });
        }
      });
    };

    PostsController.prototype.processAttachmentUrl = function(req, res, next) {
      var _this = this;
      return this.ensureSession(arguments, function() {
        var _handleError;
        _handleError = _this.handleError(next);
        return _this.downloadTempImage(req.query.url, _handleError(function(err, path) {
          if (path) {
            return _this.resizeImage(path, _handleError(function(err, imageInfo) {
              return res.send({
                attachment: "" + imageInfo.imagesDirUrl + "/" + imageInfo.filename,
                attachmentThumbnail: "" + imageInfo.thumbnailsDirUrl + "/" + imageInfo.filename
              });
            }));
          } else {
            return next(new AppError("Invalid url", "INVALID_URL"));
          }
        }));
      });
    };

    PostsController.prototype.getPostFromRequest = function(req, res, next, cb) {
      var buf, data, filePath, fnAddAttachmentDetails, post, randomFileName, _handleError, _ref,
        _this = this;
      _handleError = this.handleError(next);
      post = new models.Post({
        type: req.body.type,
        attachmentType: (_ref = req.body.attachmentType) != null ? _ref : '',
        authoringMode: req.body.authoringMode,
        createdBy: req.user,
        notes: req.body.notes,
        tags: req.body.tags ? req.body.tags.split(/[\s,]+/) : []
      });
      if (post.type === 'free-verse' && req.body.title) {
        post.title = req.body.title;
      }
      if (post.attachmentType) {
        fnAddAttachmentDetails = function() {
          post.attachment = encodeURI(req.body.attachment);
          post.attachmentThumbnail = encodeURI(req.body.attachmentThumbnail);
          if (req.body.attachmentCreditsName) {
            post.attachmentCreditsName = req.body.attachmentCreditsName;
            if (req.body.attachmentCreditsWebsite) {
              return post.attachmentCreditsWebsite = utils.fixUrl(req.body.attachmentCreditsWebsite);
            }
          }
        };
        if (req.body.attachmentSourceFormat === 'binary') {
          data = req.body.attachment.replace(/^data:image\/\w+;base64,/, "");
          buf = new Buffer(data, 'base64');
          randomFileName = "" + (utils.uniqueId(16)) + ".jpg";
          filePath = "../../www-user/temp/" + randomFileName;
          return fs.writeFile(filePath, buf, _handleError(function(err) {
            var fileUrl;
            fileUrl = "/user/temp/" + randomFileName;
            post.attachment = fileUrl;
            post.attachmentThumbnail = fileUrl;
            req.body.attachment = fileUrl;
            req.body.attachmentThumbnail = fileUrl;
            fnAddAttachmentDetails();
            return cb(null, post);
          }));
        } else {
          fnAddAttachmentDetails();
          return cb(null, post);
        }
      } else {
        return cb(null, post);
      }
    };

    PostsController.prototype.getPartFromRequest = function(req) {
      if (req.body.content) {
        return {
          content: req.body.content,
          createdBy: req.user
        };
      }
    };

    /*
            Here's the plan:
            1. If the file starts with a local relative path (/user/..), don't download.
            2. Once we do CDN, check those domains here.      
            
            Note:
            cb is called with a path argument only if the image needs to be further processed. Otherwise, we just cb()
    */


    PostsController.prototype.downloadTempImage = function(fileUrl, cb) {
      var child, extension, filename, hostArr, parseResult, _curl, _ref,
        _this = this;
      if (fileUrl) {
        parseResult = url.parse(fileUrl);
        hostArr = (_ref = parseResult.hostname) != null ? _ref.split('.') : void 0;
        if (!/^\/user\//.test(fileUrl)) {
          extension = parseResult.pathname.split('/').pop().split('.').pop();
          filename = "" + (utils.uniqueId(8)) + "_" + (Date.now()) + "." + extension;
          _curl = "curl --max-filesize 5000000 " + fileUrl + (" > ../../www-user/temp/" + filename);
          return child = exec(_curl, function(err, stdout, stderr) {
            if (!err) {
              console.log("Downloaded " + fileUrl + " to " + filename + ".");
              return cb(null, "../../www-user/temp/" + filename);
            } else {
              console.log("Could not download " + fileUrl + ".");
              return cb(err);
            }
          });
        } else {
          console.log("Download not required for " + fileUrl + ".");
          if (/^\/user\/temp\//.test(fileUrl)) {
            filename = url.parse(fileUrl).pathname.split('/').pop();
            return cb(null, "../../www-user/temp/" + filename);
          } else {
            return cb();
          }
        }
      }
    };

    PostsController.prototype.resizeImage = function(src, cb) {
      var _this = this;
      console.log("Resizing " + src + "...");
      return this.createDirectories(function(err, imagesDir, thumbnailsDir, originalsDir, imagesDirUrl, thumbnailsDirUrl) {
        var filename, image, original, thumbnail;
        filename = src.split('/').pop();
        image = "" + imagesDir + "/" + filename;
        thumbnail = "" + thumbnailsDir + "/" + filename;
        original = "" + originalsDir + "/" + filename;
        return gm(src).size(function(err, size) {
          var newSize;
          if (!err) {
            newSize = size.width > 960 ? 960 : size.width;
            return gm(src).resize(newSize).write(image, function(err) {
              if (!err) {
                console.log("Resized " + src + " to " + image);
                return gm(src).resize(480).write(thumbnail, function(err) {
                  if (!err) {
                    console.log("Resized " + src + " to " + thumbnail);
                    return fs.rename(src, original, function(err) {
                      if (!err) {
                        console.log("Moved " + src + " to " + original);
                        return cb(null, {
                          filename: filename,
                          imagesDirUrl: imagesDirUrl,
                          thumbnailsDirUrl: thumbnailsDirUrl
                        });
                      }
                    });
                  }
                });
              }
            });
          }
        });
      });
    };

    PostsController.prototype.createDirectories = function(cb) {
      var BASE_DIR, d, imagesDir, originalsDir, suffix, thumbnailsDir,
        _this = this;
      BASE_DIR = "../../www-user";
      d = new Date();
      suffix = "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
      imagesDir = "" + BASE_DIR + "/images/" + suffix;
      thumbnailsDir = "" + BASE_DIR + "/thumbnails/" + suffix;
      originalsDir = "" + BASE_DIR + "/originals/" + suffix;
      return fs.exists(imagesDir, function(exists) {
        if (exists) {
          return cb(null, imagesDir, thumbnailsDir, originalsDir, "/user/images/" + suffix, "/user/thumbnails/" + suffix);
        } else {
          return fs.mkdir(imagesDir, function() {
            return fs.mkdir(thumbnailsDir, function() {
              return fs.mkdir(originalsDir, function() {
                return cb(null, imagesDir, thumbnailsDir, originalsDir, "/user/images/" + suffix, "/user/thumbnails/" + suffix);
              });
            });
          });
        }
      });
    };

    return PostsController;

  })(controller.Controller);

  exports.PostsController = PostsController;

}).call(this);