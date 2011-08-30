root = this
$ = jQuery
$.fn.extend({
  taggable: (data, options) ->
    $(this).each((input_field) ->
      new Taggable(this, data, options)
    )
})

class Taggable
  constructor: (field) ->
    @_id = this.generate_random_id()
    @_tags = []
    @field = $ field
    @delimiter = @field.data 'delimiter'
    this.setup()
    this.setup_observers()

  setup: ->
    styles = [
      'font-size',
      'font-style',
      'font-weight',
      'font-family',
      'line-height',
      'text-transform',
      'letter-spacing',
      'padding-top',
      'padding-right',
      'padding-bottom',
      'padding-left'
    ]

    border_top  = parseInt @field.css('borderTopWidth'), 10
    border_left = parseInt @field.css('borderLeftWidth'), 10

    computed_styles = {
      position: 'absolute',
      top: @field.offset().top + border_top,
      left: @field.offset().left + border_left,
      'max-width': "#{@field.width()}px",
      'box-sizing': 'content-box'
    }

    for style in styles
      computed_styles[style] = @field.css(style)

    @container = ($ '<div />', {
      id: @_id,
      class: "taggable_container"
    }).css(computed_styles)
    @container.appendTo 'body'

  setup_observers: ->
    @field.keydown (event) => this.keydown_checker(event)
    @field.keyup (event) => this.keyup_checker(event)
    @field.keypress (event) => this.keypress_checker(event)
    @field.blur (event) => this.add_tag()
    @container.delegate('a', 'click', (event) =>
      tag_id = $(event.currentTarget).parent('span').attr('id')
      this.remove_tag(tag_id)
    )

  scale: ->
    if @_tags.length > 0
      tag      = this.last_tag()
      position = tag.position()
      left     = position.left + tag.outerWidth() + parseInt(tag.css('margin-right'), 10)
      top      = position.top

      if left >= @field.innerWidth() - 20
        left = parseInt @container.css('padding-left'), 10
        top += tag.outerHeight()

    else
      top  = parseInt @container.css('padding-top'), 10
      left = parseInt @container.css('padding-left'), 10

    @field.css({
      'padding-top': "#{top}px",
      'padding-left': "#{left}px"
    })

  keydown_checker: (event) ->
    stroke = event.which ? event.keyCode
    switch stroke
      when 8
        @backstroke_length = @field.val().length
        break
      when 9
        break
      when 13, 27
        event.preventDefault()
        this.add_tag()
        break
      when 38
        event.preventDefault()
        break
      when 40
        break

  keyup_checker: (event) ->
    stroke = event.which ? event.keyCode
    this.clear_backstroke() if stroke != 8
    switch stroke
      when 8
        if @backstroke_length < 1 and @_tags.length > 0
          this.backstroke()
      else
        if @delimiter_inserted
          value = @field.val().replace(new RegExp(@delimiter, 'g'), '')
          @field.val(value)
          if value != ''
            this.add_tag()

  keypress_checker: (event) ->
    if String.fromCharCode(event.charCode) == @delimiter
      @delimiter_inserted = true
    else
      @delimiter_inserted = false
    true

  backstroke: ->
    if @pending_removal
      this.clear_backstroke()
      this.pop_tag()
    else
      @pending_removal = true
      this.last_tag().addClass('focused')

  clear_backstroke: ->
    this.last_tag().removeClass('focused')
    @pending_removal = null

  add_tag: ->
    value = @field.val()
    if value != ''
      tag = $('<span />', {
        class: 'tag',
        id: "#{@_id}_tag_#{@_tags.length}"
      }).text(value).append($('<a href="#">x</a>'))
      @container.append tag
      @_tags.push tag.attr('id')
      @field.val ''
      this.scale()

  remove_tag: (id) ->
    @_tags.splice @_tags.indexOf(id), 1
    $("##{id}").remove()
    this.scale()

  pop_tag: ->
    id = @_tags[@_tags.length - 1]
    this.remove_tag id

  last_tag: ->
    $("##{@_tags[@_tags.length-1]}")

  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string

  generate_random_char: ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ";
    rand = Math.floor(Math.random() * chars.length)
    newchar = chars.substring rand, rand+1