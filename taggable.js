(function() {
  var $, Taggable, root;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = this;
  $ = jQuery;
  $.fn.extend({
    taggable: function(data, options) {
      return $(this).each(function(input_field) {
        return new Taggable(this, data, options);
      });
    }
  });
  Taggable = (function() {
    function Taggable(field) {
      this._id = this.generate_random_id();
      this._tags = [];
      this.field = $(field);
      this.delimiter = this.field.data('delimiter');
      this.setup();
      this.setup_observers();
    }
    Taggable.prototype.setup = function() {
      var border_left, border_top, computed_styles, style, styles, _i, _len;
      styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left'];
      border_top = parseInt(this.field.css('borderTopWidth'), 10);
      border_left = parseInt(this.field.css('borderLeftWidth'), 10);
      computed_styles = {
        position: 'absolute',
        top: this.field.offset().top + border_top,
        left: this.field.offset().left + border_left,
        'max-width': "" + (this.field.width()) + "px",
        'box-sizing': 'content-box'
      };
      for (_i = 0, _len = styles.length; _i < _len; _i++) {
        style = styles[_i];
        computed_styles[style] = this.field.css(style);
      }
      this.container = ($('<div />', {
        id: this._id,
        "class": "taggable_container"
      })).css(computed_styles);
      return this.container.appendTo('body');
    };
    Taggable.prototype.setup_observers = function() {
      this.field.keydown(__bind(function(event) {
        return this.keydown_checker(event);
      }, this));
      this.field.keyup(__bind(function(event) {
        return this.keyup_checker(event);
      }, this));
      this.field.keypress(__bind(function(event) {
        return this.keypress_checker(event);
      }, this));
      this.field.blur(__bind(function(event) {
        return this.add_tag();
      }, this));
      return this.container.delegate('a', 'click', __bind(function(event) {
        var tag_id;
        tag_id = $(event.currentTarget).parent('span').attr('id');
        return this.remove_tag(tag_id);
      }, this));
    };
    Taggable.prototype.scale = function() {
      var left, position, tag, top;
      if (this._tags.length > 0) {
        tag = this.last_tag();
        position = tag.position();
        left = position.left + tag.outerWidth() + parseInt(tag.css('margin-right'), 10);
        top = position.top;
        if (left >= this.field.innerWidth() - 20) {
          left = parseInt(this.container.css('padding-left'), 10);
          top += tag.outerHeight();
        }
      } else {
        top = parseInt(this.container.css('padding-top'), 10);
        left = parseInt(this.container.css('padding-left'), 10);
      }
      return this.field.css({
        'padding-top': "" + top + "px",
        'padding-left': "" + left + "px"
      });
    };
    Taggable.prototype.keydown_checker = function(event) {
      var stroke, _ref;
      stroke = (_ref = event.which) != null ? _ref : event.keyCode;
      switch (stroke) {
        case 8:
          this.backstroke_length = this.field.val().length;
          break;
        case 9:
          break;
        case 13:
        case 27:
          event.preventDefault();
          this.add_tag();
          break;
        case 38:
          event.preventDefault();
          break;
        case 40:
          break;
      }
    };
    Taggable.prototype.keyup_checker = function(event) {
      var stroke, value, _ref;
      stroke = (_ref = event.which) != null ? _ref : event.keyCode;
      if (stroke !== 8) {
        this.clear_backstroke();
      }
      switch (stroke) {
        case 8:
          if (this.backstroke_length < 1 && this._tags.length > 0) {
            return this.backstroke();
          }
          break;
        default:
          if (this.delimiter_inserted) {
            value = this.field.val().replace(new RegExp(this.delimiter, 'g'), '');
            this.field.val(value);
            if (value !== '') {
              return this.add_tag();
            }
          }
      }
    };
    Taggable.prototype.keypress_checker = function(event) {
      if (String.fromCharCode(event.charCode) === this.delimiter) {
        this.delimiter_inserted = true;
      } else {
        this.delimiter_inserted = false;
      }
      return true;
    };
    Taggable.prototype.backstroke = function() {
      if (this.pending_removal) {
        this.clear_backstroke();
        return this.pop_tag();
      } else {
        this.pending_removal = true;
        return this.last_tag().addClass('focused');
      }
    };
    Taggable.prototype.clear_backstroke = function() {
      this.last_tag().removeClass('focused');
      return this.pending_removal = null;
    };
    Taggable.prototype.add_tag = function() {
      var tag, value;
      value = this.field.val();
      if (value !== '') {
        tag = $('<span />', {
          "class": 'tag',
          id: "" + this._id + "_tag_" + this._tags.length
        }).text(value).append($('<a href="#">x</a>'));
        this.container.append(tag);
        this._tags.push(tag.attr('id'));
        this.field.val('');
        return this.scale();
      }
    };
    Taggable.prototype.remove_tag = function(id) {
      this._tags.splice(this._tags.indexOf(id), 1);
      $("#" + id).remove();
      return this.scale();
    };
    Taggable.prototype.pop_tag = function() {
      var id;
      id = this._tags[this._tags.length - 1];
      return this.remove_tag(id);
    };
    Taggable.prototype.last_tag = function() {
      return $("#" + this._tags[this._tags.length - 1]);
    };
    Taggable.prototype.generate_random_id = function() {
      var string;
      string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char();
      while ($("#" + string).length > 0) {
        string += this.generate_random_char();
      }
      return string;
    };
    Taggable.prototype.generate_random_char = function() {
      var chars, newchar, rand;
      chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ";
      rand = Math.floor(Math.random() * chars.length);
      return newchar = chars.substring(rand, rand + 1);
    };
    return Taggable;
  })();
}).call(this);
