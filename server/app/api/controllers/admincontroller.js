// Generated by CoffeeScript 1.6.2
(function() {
  var AdminController, AppError, conf, controller, fs, models, utils, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controller = require('./controller');

  conf = require('../../conf');

  models = new (require('../../models')).Models(conf.db);

  fs = require('fs');

  utils = require('../../common/utils');

  AppError = require('../../common/apperror').AppError;

  AdminController = (function(_super) {
    __extends(AdminController, _super);

    function AdminController() {
      this.deleteMessage = __bind(this.deleteMessage, this);
      this.addMessage = __bind(this.addMessage, this);
      this.impersonate = __bind(this.impersonate, this);
      this.deleteMeta = __bind(this.deleteMeta, this);
      this.addMeta = __bind(this.addMeta, this);
      this.ensureAdmin = __bind(this.ensureAdmin, this);      _ref = AdminController.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    AdminController.prototype.ensureAdmin = function(args, fn) {
      var next, req, res,
        _this = this;

      req = args[0], res = args[1], next = args[2];
      return this.getUserWithPasskey(req.query.passkey, function(err, user) {
        var admin, u, _ref1, _ref2;

        admin = (function() {
          var _i, _len, _ref1, _results;

          _ref1 = conf.admins;
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            u = _ref1[_i];
            if (u.username === (user != null ? user.username : void 0) && u.domain === (user != null ? user.domain : void 0)) {
              _results.push(u);
            }
          }
          return _results;
        })();
        if (admin.length) {
          req.user = user;
          return fn();
        } else {
          console.log("" + ((_ref1 = _this.user) != null ? _ref1.username : void 0) + "@" + ((_ref2 = _this.user) != null ? _ref2.domain : void 0));
          return next(new AppError("Well, you don't look much of an admin to me.", 'NOT_ADMIN'));
        }
      });
    };

    AdminController.prototype.addMeta = function(req, res, next) {
      var _this = this;

      return this.ensureAdmin(arguments, function() {
        return models.Post.get({
          uid: parseInt(req.query.uid)
        }, {
          user: req.user
        }, function(err, post) {
          if (post) {
            if (req.query.meta) {
              if (post.meta.indexOf(req.query.meta) === -1) {
                post.meta.push(req.query.meta);
                return post.save({}, function() {
                  return res.send(post);
                });
              } else {
                return res.send("" + req.query.meta + " exists in meta.");
              }
            } else {
              return res.send("Missing meta.");
            }
          } else {
            return res.send("Missing post.");
          }
        });
      });
    };

    AdminController.prototype.deleteMeta = function(req, res, next) {
      var _this = this;

      return this.ensureAdmin(arguments, function() {
        if (req.query.meta) {
          return models.Post.get({
            uid: parseInt(req.query.uid)
          }, {
            user: req.user
          }, function(err, post) {
            var i;

            if (post) {
              post.meta = (function() {
                var _i, _len, _ref1, _results;

                _ref1 = post.meta;
                _results = [];
                for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                  i = _ref1[_i];
                  if (i !== req.query.meta) {
                    _results.push(i);
                  }
                }
                return _results;
              })();
              return post.save({}, function() {
                return res.send(post);
              });
            } else {
              return res.send("Missing post.");
            }
          });
        } else {
          return res.send("Missing meta.");
        }
      });
    };

    AdminController.prototype.impersonate = function(req, res, next) {
      var _this = this;

      return this.ensureAdmin(arguments, function() {
        return models.User.get({
          domain: req.query.domain,
          username: req.query.username
        }, {}, function(err, user) {
          if (user && !err) {
            return models.Session.find({
              userid: user._id.toString()
            }, (function(cursor) {
              return cursor.sort({
                timestamp: -1
              }).limit(1);
            }), {
              user: req.user
            }, function(err, sessions) {
              var session;

              session = sessions[0];
              if (!err) {
                return res.send({
                  userid: user._id,
                  domain: user.domain,
                  username: user.username,
                  name: user.name,
                  passkey: session.passkey
                });
              }
            });
          }
        });
      });
    };

    AdminController.prototype.addMessage = function(req, res, next) {
      var _this = this;

      return this.ensureAdmin(arguments, function() {
        var msg;

        msg = new models.Message();
        msg.userid = '0';
        msg.type = req.body.type;
        msg.reason = req.body.reason;
        msg.data = req.body.data;
        msg.data = msg.data.replace(/\_\(/g, '<');
        msg.data = msg.data.replace(/\)\_/g, '>');
        msg.data = msg.data.replace(/js\:/g, 'javascript:');
        msg.timestamp = parseInt(req.body.timestamp);
        return msg.save({}, function(err, msg) {
          if (!err) {
            return res.send(msg);
          } else {
            return res.send("Error adding message.");
          }
        });
      });
    };

    AdminController.prototype.deleteMessage = function(req, res, next) {
      var _this = this;

      return this.ensureAdmin(arguments, function() {
        return models.Message.getById(req.query.id, {}, function(err, message) {
          if (!err) {
            return message.destroy({}, function(err) {
              if (!err) {
                return res.send("Deleted");
              } else {
                return next(err);
              }
            });
          } else {
            return next(err);
          }
        });
      });
    };

    return AdminController;

  })(controller.Controller);

  exports.AdminController = AdminController;

}).call(this);
