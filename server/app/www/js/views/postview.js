// Generated by CoffeeScript 1.6.2
(function() {
  var PostView,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  PostView = (function(_super) {
    __extends(PostView, _super);

    function PostView(params, options) {
      this.getModalSize = __bind(this.getModalSize, this);
      this.setupModal = __bind(this.setupModal, this);
      this.deleteParentPost = __bind(this.deleteParentPost, this);
      this.updateParentPost = __bind(this.updateParentPost, this);
      this.hideContentError = __bind(this.hideContentError, this);
      this.showContentError = __bind(this.showContentError, this);
      this.onSettingsClick = __bind(this.onSettingsClick, this);
      this.onLikeClick = __bind(this.onLikeClick, this);
      this.onSelectPartClick = __bind(this.onSelectPartClick, this);
      this.onRemovePartClick = __bind(this.onRemovePartClick, this);
      this.onSubmitPartClick = __bind(this.onSubmitPartClick, this);
      this.onPublishClick = __bind(this.onPublishClick, this);
      this.onSaveComment = __bind(this.onSaveComment, this);
      this.onPin = __bind(this.onPin, this);
      this.onTweet = __bind(this.onTweet, this);
      this.onFacebookShare = __bind(this.onFacebookShare, this);
      this.attachEvents = __bind(this.attachEvents, this);
      this.galleryNext = __bind(this.galleryNext, this);
      this.galleryPrevious = __bind(this.galleryPrevious, this);
      this.addGalleryNavigation = __bind(this.addGalleryNavigation, this);
      this.addSettingsButton = __bind(this.addSettingsButton, this);
      this.addLikeButton = __bind(this.addLikeButton, this);
      this.addCompletionMessage = __bind(this.addCompletionMessage, this);
      this.displayComments = __bind(this.displayComments, this);
      this.addComments = __bind(this.addComments, this);
      this.render = __bind(this.render, this);
      var post, _ref, _ref1;

      this.tagPrefix = (_ref = options != null ? options.tagPrefix : void 0) != null ? _ref : '/posts';
      if (typeof params === 'string' || typeof params === 'number') {
        this.uid = params;
        if ((((_ref1 = app.activeView) != null ? _ref1.getPostByUID : void 0) != null) && (post = app.activeView.getPostByUID(parseInt(this.uid)))) {
          PostView.__super__.constructor.call(this, {
            model: post
          });
          this.model.bind('change', this.render, this);
          this.render();
        } else {
          PostView.__super__.constructor.call(this, {
            model: new Poe3.Post({
              uid: this.uid
            })
          });
          this.model.bind('change', this.render, this);
          this.model.fetch();
        }
      } else {
        this.gallery = params.data;
        post = this.gallery.posts[0];
        PostView.__super__.constructor.call(this, {
          model: post
        });
        this.model.bind('change', this.render, this);
        this.render();
      }
      if (options != null ? options.returnUrl : void 0) {
        this.modalConfig.returnUrl = options.returnUrl;
      }
    }

    PostView.prototype.render = function() {
      var authors, k, onModalReady, params, part, post, postedAt, v, _i, _len, _ref, _ref1,
        _this = this;

      this.setTitle(this.model.getPostName(50));
      post = this.model.toTemplateParam();
      this.createModalContainer("post-view-container");
      authors = {};
      _ref = post.selectedParts;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        part = _ref[_i];
        authors[part.createdBy.id] = part.createdBy;
      }
      params = {};
      params.post = post;
      params.authors = (function() {
        var _results;

        _results = [];
        for (k in authors) {
          v = authors[k];
          _results.push(v);
        }
        return _results;
      })();
      params.formattedParts = this.model.format();
      params.partEditor = this.model.getPartEditor();
      postedAt = (_ref1 = this.model.get('publishedAt')) != null ? _ref1 : this.model.get('timestamp');
      params.postedAt = moment(new Date(postedAt)).fromNow();
      params.notes = this.model.formatNotes();
      params.hasLikes = this.model.get('likes').length > 0;
      params.tagPrefix = this.tagPrefix;
      params.isComplete = post.state === 'complete';
      if (this.model.get('attachmentType') === 'image') {
        params.displayClass = 'with-image';
        params.attachmentIsImage = true;
        if (this.model.get('attachmentCreditsName')) {
          if (this.model.get('attachmentCreditsWebsite')) {
            params.attachmentCredits = "<p class=\"attachment-credits\"><i class=\"icon-picture\"></i> <a href=\"" + (this.model.get('attachmentCreditsWebsite')) + "\">" + (this.model.get('attachmentCreditsName')) + "</a></p>";
          } else {
            params.attachmentCredits = "<p class=\"attachment-credits\"><i class=\"icon-picture\"></i> " + (this.model.get('attachmentCreditsName')) + "</p>";
          }
        }
      } else {
        params.displayClass = 'just-text';
      }
      if (this.gallery) {
        params.isGallery = true;
      }
      $(this.el).html(this.template(params));
      $('.post-view-container').html(this.el);
      $('.social-share .social-action').html(this.model.get('state') === 'complete' ? 'Share on' : 'Invite contributors');
      if (this.model.get('attachmentType') === 'image') {
        $('.social-share .pinterest').show();
      } else {
        $('.social-share .pinterest').hide();
      }
      this.addComments();
      this.addCompletionMessage();
      this.addLikeButton();
      this.addSettingsButton();
      if (this.gallery) {
        this.addGalleryNavigation();
      }
      this.attachEvents();
      onModalReady = function() {
        var fontSize, lineHeight, modalSize;

        modalSize = _this.getModalSize();
        fontSize = _this.model.getFontSize(modalSize);
        $('.post-view-container .parts').css('font-size', "" + fontSize + "px");
        lineHeight = fontSize <= 18 ? "1.3" : "1.2";
        $('.post-view-container .parts').css('line-height', "" + lineHeight);
        _this.setupModal(modalSize);
        $('.post-view .notes, .post-view .post-details').show();
        $('.post-view .notes, .post-view .social-share').show();
        return $('.post-view .notes, .post-view .comments-container').show();
      };
      if (this.model.get('attachmentType') === 'image') {
        $('.post-view .post-box .background').imagesLoaded(onModalReady);
      } else {
        onModalReady();
      }
      return this.onRenderComplete('.post-view-container');
    };

    PostView.prototype.addComments = function() {
      var comments;

      comments = new Poe3.Comments;
      comments.bind('reset', this.displayComments, this);
      comments.postid = this.model.id;
      return comments.fetch();
    };

    PostView.prototype.displayComments = function(commentsModel) {
      return $('.post-view .comments-container').html(this.commentsTemplate({
        comments: commentsModel.toJSON()
      }));
    };

    PostView.prototype.addCompletionMessage = function() {
      var completionMessage;

      completionMessage = this.model.getCompletionMessage();
      if (completionMessage) {
        return this.showMessage(completionMessage.text, completionMessage.type);
      }
    };

    PostView.prototype.addLikeButton = function() {
      var like, likeButton, yourLikes;

      likeButton = $('.post-view .post-buttons i.like-button');
      likeButton.removeClass('icon-heart');
      likeButton.removeClass('icon-heart-empty');
      yourLikes = (function() {
        var _i, _len, _ref, _results;

        _ref = this.model.get('likes');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          like = _ref[_i];
          if (like.id === app.getUser().id) {
            _results.push(like);
          }
        }
        return _results;
      }).call(this);
      if (yourLikes.length) {
        return likeButton.addClass('icon-heart');
      } else {
        return likeButton.addClass('icon-heart-empty');
      }
    };

    PostView.prototype.addSettingsButton = function() {
      if (this.model.get('createdBy').id === app.getUser().id) {
        return $('.post-view .post-buttons .settings-button').show();
      }
    };

    PostView.prototype.addGalleryNavigation = function() {
      var i, li, list, post, self, _results;

      self = this;
      if (!this.galleryCursor) {
        this.galleryCursor = 0;
      }
      $(document).bindNew('click', '.gallery-nav .left-cursor', this.galleryPrevious);
      $(document).bindNew('click', '.gallery-nav .right-cursor', this.galleryNext);
      $(document).bind('keyup', 'left', this.galleryPrevious);
      $(document).bind('keyup', 'right', this.galleryNext);
      $('.post-view .gallery').html('\
            <div class="container">\
                <ul></ul>\
            </div>\
            <div class="overlay"></div>');
      list = $('.post-view .gallery').find('ul');
      i = 0;
      _results = [];
      while (i < this.gallery.posts.length) {
        post = this.gallery.posts[i];
        li = $('<li></li>');
        li.html(post.formatAsIcon());
        li.data('post', post);
        li.data('cursor', i);
        li.appendTo(list);
        li.click(function() {
          self.model = $(this).data('post');
          self.galleryCursor = $(this).data('cursor');
          return self.render();
        });
        if (this.galleryCursor === i) {
          li.addClass('selected');
        }
        _results.push(i++);
      }
      return _results;
    };

    PostView.prototype.galleryPrevious = function() {
      var _this = this;

      if (this.cancelKeyPress) {
        return;
      }
      this.cancelKeyPress = true;
      return setTimeout((function() {
        _this.cancelKeyPress = false;
        if (_this.galleryCursor > 0) {
          _this.galleryCursor--;
          _this.model = _this.gallery.posts[_this.galleryCursor];
          return _this.render();
        }
      }), 100);
    };

    PostView.prototype.galleryNext = function() {
      var _this = this;

      if (this.cancelKeyPress) {
        return;
      }
      this.cancelKeyPress = true;
      return setTimeout((function() {
        _this.cancelKeyPress = false;
        if (_this.galleryCursor < (_this.gallery.posts.length - 1)) {
          _this.galleryCursor++;
          _this.model = _this.gallery.posts[_this.galleryCursor];
          return _this.render();
        }
      }), 100);
    };

    PostView.prototype.attachEvents = function() {
      var _this = this;

      $(document).bindNew('click', '.post-view .part-select-item', this.onSelectPartClick());
      $(document).bindNew('click', '.post-view .parts .remove-part', this.onRemovePartClick());
      $(document).bindNew('click', '.post-view button.publish', this.onPublishClick);
      $(document).bindNew('click', '.post-view button.submit', this.onSubmitPartClick);
      $(document).bindNew('click', '.post-view .post-buttons i.like-button', this.onLikeClick);
      $(document).bindNew('click', '.post-view .post-buttons i.settings-button', this.onSettingsClick);
      $(document).bindNew('mouseenter', '.post-view .parts .last span.remove-part', function() {
        return $(this).parent().addClass('selected');
      });
      $(document).bindNew('mouseleave', '.post-view .parts .last span.remove-part', function() {
        return $(this).parent().removeClass('selected');
      });
      $(document).bindNew('click', '.post-view .authors li', function() {
        return app.navigate("/" + ($(this).data('domain')) + "/" + ($(this).data('username')), true);
      });
      $(document).bindNew('click', '.post-view .write-part-link', function() {
        $('.part-select-container').hide();
        $('.add-part').show();
        return false;
      });
      $(document).bindNew('click', '.post-view .select-contrib-link', function() {
        $('.add-part').hide();
        $('.part-select-container').show();
        return false;
      });
      $(document).bindNew('click', '.post-view .comments a.new-comment', function() {
        var loginView;

        if (app.isAuthenticated()) {
          $('.post-view .comments .comment-form').show();
          $('.post-view .comments .comment-form textarea').focus();
          $('.post-view .comments .add-comment-link').hide();
          _this._hack_overlayHeightRefresh();
        } else {
          loginView = new Poe3.LoginView;
        }
        return false;
      });
      $(document).bindNew('click', '.post-view .comments button.save', this.onSaveComment);
      $(document).bindNew('click', '.post-view .social-share .facebook img, .post-view .social-share .facebook a', this.onFacebookShare);
      $(document).bindNew('click', '.post-view .social-share .twitter img, .post-view .social-share .twitter a', this.onTweet);
      return $(document).bindNew('click', '.post-view .social-share .pinterest img, .post-view .social-share .pinterest a', this.onPin);
    };

    PostView.prototype.onFacebookShare = function() {
      var collaborative, message, params, picture, postName, postUrl, url, _ref,
        _this = this;

      if (this.model.get('state') === 'complete') {
        collaborative = this.model.get('authoringMode') === 'collaborative' ? 'collaborative ' : '';
        postUrl = app.pathToUrl(this.model.get('uid'));
        if (app.isAuthenticated() && app.getUser().domain === 'fb') {
          message = "" + postUrl + "\n\n" + (this.model.summarizeContent('full'));
          picture = this.model.get('attachment') ? app.pathToUrl(this.model.get('attachment')) : void 0;
          new Poe3.FacebookSharePostView(message, picture, this.model.id, (function() {
            return $('.post-view .social-share .facebook').html('<i class="icon-ok"><i> Shared on Facebook.');
          }));
          return false;
        } else {
          params = {
            method: 'feed',
            name: this.model.getPostName(),
            picture: (_ref = app.pathToUrl(this.model.get('attachment'))) != null ? _ref : this.model.get('createdBy').picture,
            link: app.pathToUrl(this.model.get('uid')),
            description: this.model.summarizeContent("short")
          };
          FB.ui(params, function(resp) {
            var published;

            published = resp && resp.post_id;
            if (published) {
              return $('.post-view .social-share .facebook').html('<i class="icon-ok"></i> Shared on Facebook.');
            }
          });
          return false;
        }
      } else {
        postName = this.model.getPostName(100).substring(0, 50);
        if (!/\.$/.test(postName)) {
          postName += '...';
        }
        url = window.location.hostname + ("/" + (this.model.get('uid')));
        FB.ui({
          method: 'apprequests',
          display: "popup",
          message: "Complete the " + (this.model.formatType()) + " (" + postName + ") at " + url,
          data: "redirect_to_post:" + (this.model.get('uid'))
        }, function(resp) {
          if (resp) {
            return $.ajax({
              url: Poe3.apiUrl("tokens"),
              data: {
                type: 'facebook-app-request',
                key: resp.request,
                value: _this.model.get('uid')
              },
              type: 'post',
              success: function(token) {}
            });
          }
        });
        return false;
      }
    };

    PostView.prototype.onTweet = function(e) {
      var hashtag, newwindow, text;

      text = this.model.summarizeContent('full');
      if (text.length > 92) {
        text = text.slice(0, 92) + '...';
      }
      text = encodeURIComponent(text) + '\n  ';
      text += window.location.hostname + ("/" + (this.model.get('uid')));
      hashtag = (function() {
        switch (this.model.get('type')) {
          case 'haiku':
            return 'haiku';
          case 'quote':
            return 'quote';
          case 'free-verse':
            return 'poetry';
          case 'six-word-story':
            return 'sixwordstory';
        }
      }).call(this);
      newwindow = window.open("https://twitter.com/share?url=''&text=" + text + "&hashtags=" + hashtag, 'name', 'height=250,width=400');
      if (window.focus) {
        newwindow.focus();
      }
      return false;
    };

    PostView.prototype.onPin = function(e) {
      var description, img, loc, media, summary, url;

      url = "url=" + encodeURIComponent(window.location.href);
      if (this.model.get('attachmentType') === 'image') {
        img = this.model.get('attachment');
        if (/^\//.test(img)) {
          img = "http://" + window.location.hostname + img;
        }
        media = "&media=" + (encodeURIComponent(img));
      } else {
        media = "";
      }
      summary = this.model.summarizeContent('full');
      if (summary.length > 200) {
        summary = summary.slice(0, 200) + "...";
      }
      summary += "\n" + window.location.href;
      description = "&description=" + (encodeURIComponent(summary));
      loc = "http://pinterest.com/pin/create/button/?" + url + media + description;
      window.open(loc, 'pinterest_popup', 'width=580,height=280');
      return false;
    };

    PostView.prototype.onSaveComment = function() {
      var _this = this;

      $.ajax({
        url: Poe3.apiUrl("posts/" + this.model.id + "/comments"),
        data: {
          content: $('.post-view .comments textarea').val()
        },
        type: 'post',
        success: function(comment) {
          return _this.addComments();
        }
      });
      return false;
    };

    PostView.prototype.onPublishClick = function() {
      var _this = this;

      return $.ajax({
        url: Poe3.apiUrl("posts/" + this.model.id + "/state"),
        data: {
          value: 'complete'
        },
        type: 'PUT',
        success: function(post) {
          _this.updateParentPost(new Poe3.Post(post));
          _this.model.set(post);
          return _this.showMessage('<p class="text"><i class="icon-ok"></i> Congratulations. You have published it.</p>', 'success');
        }
      });
    };

    PostView.prototype.onSubmitPartClick = function() {
      var content, validation,
        _this = this;

      content = $('.post-view textarea.content').val();
      validation = this.model.validateNewPart(content);
      if (validation.isValid) {
        this.hideContentError();
        return $.post(Poe3.apiUrl("posts/" + this.model.id + "/parts"), {
          content: content
        }, function(post) {
          _this.updateParentPost(new Poe3.Post(post));
          return _this.model.set(post);
        });
      } else {
        return this.showContentError(validation.error);
      }
    };

    PostView.prototype.onRemovePartClick = function() {
      var self;

      self = this;
      return function() {
        var _this = this;

        return $.ajax({
          url: Poe3.apiUrl("posts/" + self.model.id + "/selectedparts/" + ($(this).data('partid'))),
          type: 'DELETE',
          success: function(post) {
            self.updateParentPost(new Poe3.Post(post));
            return self.model.set(post);
          }
        });
      };
    };

    PostView.prototype.onSelectPartClick = function() {
      var self;

      self = this;
      return function() {
        var _this = this;

        return $.post(Poe3.apiUrl("posts/" + self.model.id + "/selectedparts"), {
          id: $(this).data('partid')
        }, function(post) {
          self.updateParentPost(new Poe3.Post(post));
          return self.model.set(post);
        });
      };
    };

    PostView.prototype.onLikeClick = function() {
      var likeButton, loginView,
        _this = this;

      if (app.isAuthenticated()) {
        likeButton = $('.post-view .post-buttons i.like-button');
        if (likeButton.hasClass('icon-heart')) {
          return $.ajax({
            url: Poe3.apiUrl("posts/" + this.model.id + "/like"),
            type: 'DELETE',
            success: function(post) {
              var _post;

              likeButton.removeClass('icon-heart');
              likeButton.removeClass('icon-heart-empty');
              likeButton.addClass('icon-heart-empty');
              _post = new Poe3.Post(post);
              return _this.updateParentPost(_post);
            }
          });
        } else {
          return $.ajax({
            url: Poe3.apiUrl("posts/" + this.model.id + "/like"),
            type: 'PUT',
            success: function(post) {
              var _post;

              likeButton.removeClass('icon-heart');
              likeButton.removeClass('icon-heart-empty');
              likeButton.addClass('icon-heart');
              _post = new Poe3.Post(post);
              return _this.updateParentPost(_post);
            }
          });
        }
      } else {
        return loginView = new Poe3.LoginView;
      }
    };

    PostView.prototype.onSettingsClick = function() {
      var $settings, deleteOrUnpublish, form, formContent, imageUrl, _ref, _ref1, _ref2, _ref3,
        _this = this;

      formContent = '';
      formContent += '\
            <p>\
                Tags: <br />\
                <input type="text" placeholder="eg: nature,rains" class="tags" value="' + this.model.get('tags').join(',') + '" />\
            </p>\
            <p>\
                Notes: <br />\
                <textarea class="notes">' + ((_ref = this.model.get('notes')) != null ? _ref : '') + '</textarea>                        \
            </p>';
      imageUrl = (_ref1 = this.model.get('attachment')) != null ? _ref1 : '';
      formContent += '\
            <p class="show-image-edit-form">\
                Do you want to <a href="#">change the image</a>?\
            </p>\
            <div class="image-edit-form hidden">\
                <p>\
                    Image (optional): <br />\
                    <input type="text" class="image-url" value="' + imageUrl + '" />\
                </p>\
                <p>\
                    Image Credits (optional):<br />\
                    <input type="text" class="credits-name" placeholder="eg: John Doe" value="' + ((_ref2 = this.model.get('attachmentCreditsName')) != null ? _ref2 : '') + '" /> \
                    <input type="text" class="credits-website" placeholder="eg: http://www.website.com" value="' + ((_ref3 = this.model.get('attachmentCreditsWebsite')) != null ? _ref3 : '') + '" />\
                </p>\
            </div>';
      form = '\
            <form class="post-settings">' + formContent + '\
                <p>\
                    <button class="save"><i class="icon-ok"></i>Save</button> or <a class="cancel" href="#">cancel</a>\
                </p>\
            </form>';
      if (this.model.get('state') === 'complete') {
        deleteOrUnpublish = '\
                <div class="delete-unpublish">\
                    <p>\
                        Do you want to <a class="unpublish-post" href="#">unpublish</a> or <a class="delete-post" href="#">delete</a> this post?\
                    </p>\
                    <p class="unpublish-post-option" style="display:none">\
                        <button class="unpublish-post"><i class="icon-ban-circle"></i>Unpublish</button>\
                    </p>                        \
                    <p class="delete-post-option" style="display:none">\
                        <button class="delete-post"><i class="icon-remove"></i>Delete forever</button>\
                    </p>\
                </div>';
      } else {
        deleteOrUnpublish = '\
                <div class="delete-unpublish">\
                    <p>\
                        Do you want to <a class="delete-post" href="#">delete</a> this post?\
                    </p>\
                    <p class="delete-post-option" style="display:none">\
                        <button class="delete-post"><i class="icon-remove"></i>Delete forever</button>\
                    </p>\
                </div>';
      }
      this.displayModalModal($('.post-view .post-box'), form + deleteOrUnpublish);
      $settings = $('.post-view .modal-modal .post-settings');
      $(document).bindNew('click', '.post-view .modal-modal .post-settings .show-image-edit-form a', function() {
        $settings.find('.show-image-edit-form').hide();
        return $settings.find('.image-edit-form').show();
      });
      $(document).bindNew('click', '.post-settings button.save', function() {
        var attachmentUrl, data, ext;

        data = {
          tags: $settings.find('input.tags').val(),
          notes: $settings.find('textarea.notes').val()
        };
        attachmentUrl = $settings.find('input.image-url').val();
        if (attachmentUrl) {
          ext = attachmentUrl.split('/').pop().split('.').pop().toLowerCase();
          if (ext === 'png' || ext === 'jpg' || ext === 'jpeg' || ext === 'gif' || ext === 'bmp') {
            data.attachmentType = 'image';
            data.attachment = attachmentUrl;
            if ($settings.find('input.credits-name').val()) {
              data.attachmentCreditsName = $settings.find('input.credits-name').val();
              if ($settings.find('input.credits-website').val()) {
                data.attachmentCreditsWebsite = $settings.find('input.credits-website').val();
              }
            }
          } else {
            alert('Image url should end with .jpg, .jpeg or .png.');
            return;
          }
        } else {
          data.attachmentType = '';
        }
        return $.ajax({
          url: Poe3.apiUrl("posts/" + _this.model.id),
          data: data,
          type: 'PUT',
          success: function(post) {
            _this.closeModalModal();
            _this.updateParentPost(new Poe3.Post(post));
            _this.model.set(post);
            return _this.showMessage('<p class="text"><i class="icon-ok"></i> Saved.</p>', 'success');
          }
        });
      });
      $(document).bindNew('click', '.post-view .modal-modal .post-settings a.cancel', function() {
        return _this.closeModalModal();
      });
      $(document).bindNew('click', '.post-view .modal-modal .delete-unpublish button.delete-post', function() {
        return $.ajax({
          url: Poe3.apiUrl("posts/" + _this.model.id),
          type: 'DELETE',
          success: function() {
            _this.closeModalModal();
            _this.deleteParentPost(_this.model);
            return _this.showMessage('<p class="text"><i class="icon-ok"></i> Deleted. You will never see it again.</p>', 'alert');
          }
        });
      });
      $(document).bindNew('click', '.post-view .modal-modal .delete-unpublish button.unpublish-post', function() {
        return $.ajax({
          url: Poe3.apiUrl("posts/" + _this.model.id + "/state"),
          data: {
            value: 'open'
          },
          type: 'PUT',
          success: function(post) {
            _this.closeModalModal();
            _this.updateParentPost(new Poe3.Post(post));
            _this.model.set(post);
            return _this.showMessage('<p class="text"><i class="icon-ok"></i> You have unpublished it.</p>', 'alert');
          }
        });
      });
      $(document).bindNew('click', '.post-view .post-box .unpublish-post', function() {
        $('.post-view .post-box .delete-post-option').hide();
        $('.post-view .post-box .unpublish-post-option').show();
        return false;
      });
      return $(document).bindNew('click', '.post-view .post-box .delete-post', function() {
        $('.post-view .post-box .unpublish-post-option').hide();
        $('.post-view .post-box .delete-post-option').show();
        return false;
      });
    };

    PostView.prototype.showContentError = function(error) {
      $('.content-error').html('<i class="icon-remove-sign"></i> ' + error);
      return $('.content-error').show();
    };

    PostView.prototype.hideContentError = function() {
      return $('.content-error').hide();
    };

    PostView.prototype.updateParentPost = function(post) {
      var index, p, _ref, _ref1;

      if ((_ref = app.activeView) != null) {
        if (typeof _ref.updatePost === "function") {
          _ref.updatePost(post);
        }
      }
      if ((_ref1 = this.gallery) != null ? _ref1.posts.length : void 0) {
        index = ((function() {
          var _i, _len, _ref2, _results;

          _ref2 = this.gallery.posts;
          _results = [];
          for (index = _i = 0, _len = _ref2.length; _i < _len; index = ++_i) {
            p = _ref2[index];
            if (p.id === post.id) {
              _results.push(index);
            }
          }
          return _results;
        }).call(this))[0];
        return this.gallery.posts.splice(index, 1, post);
      }
    };

    PostView.prototype.deleteParentPost = function(post) {
      var _ref;

      return (_ref = app.activeView) != null ? typeof _ref.deletePost === "function" ? _ref.deletePost(post) : void 0 : void 0;
    };

    PostView.prototype.setupModal = function(size) {
      $('.post-view .post-frame').css('width', "" + size + "px");
      $('.post-view .post-box').css('width', "" + size + "px");
      $('.post-view .post-box').show();
      $('.post-view .post-details').css('width', "" + (size - 16) + "px");
      $('.post-view .post-details').show();
      $('.post-view .gallery').show();
      $('.post-view .gallery-nav').show();
      return this.displayModal();
    };

    PostView.prototype.getModalSize = function() {
      var height, maxWidth, minWidth, scaledWidth, width, windowHeight;

      minWidth = 480;
      maxWidth = this.gallery ? 800 : 920;
      if (this.model.get('attachmentType') === 'image') {
        height = $('.post-view .post-box').height();
        width = $('.post-view .post-box .background img')[0].naturalWidth;
        if ($(window).width() < (width + 32)) {
          width = $(window).width() - 32;
        }
        windowHeight = $(window).height() - 160;
        scaledWidth = parseInt(width * (windowHeight / height));
        if (width < scaledWidth) {
          scaledWidth = width;
        }
        if (scaledWidth > maxWidth) {
          scaledWidth = maxWidth;
        }
        if (scaledWidth < minWidth) {
          scaledWidth = minWidth;
        }
        return scaledWidth;
      } else {
        return 520;
      }
    };

    return PostView;

  })(Poe3.ModalView);

  window.Poe3.PostView = PostView;

}).call(this);
