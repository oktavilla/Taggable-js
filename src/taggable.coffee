root = this
$ = jQuery
$.fn.extend({
  taggable: (options) ->
    $(this).each((input_field) ->
      new Taggable(this, options)
    )
})

class Taggable
  constructor: (field, options = {}) ->
    @options = $.extend {
      onChange: ->
    }, options
    @_id = this.generate_random_id()
    @_tags = []
    @original = $(field).css({
      position: 'absolute'
      left: '-100000px',
      top: '0px',
      visibility: 'hidden'
    })
    @delimiter = @original.data 'delimiter'
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
      'box-sizing'
    ]

    computed_styles = {}

    for style in styles
      computed_styles[style] = @original.css(style)

    @target = ($ '<input />',
      type:  'hidden',
      name:  @original.attr('name'),
      value: @original.val()
    )
    @target.insertBefore @original

    @container = ($ '<div />',
      id: @_id,
      class: "taggable_container"
    ).css
      'max-width':  "#{@original.width()}px",
      'min-height': "#{@original.height()}px",
      position: 'relative'

    @input = ($ '<input />',
      type: 'text',
      name: 'taggable',
      autocomplete: 'off'
    ).css(computed_styles).css(
      width: "#{@original.width()}px",
      background: 'transparent',
      position: 'absolute',
      top: @container.css('paddingTop'),
      left: @container.css('paddingLeft'),
      border: 'none',
      outline: 'none'
    ).appendTo @container

    @container.insertAfter @original
    @original.hide

  setup_observers: ->
    @input.keydown (event) => this.keydown_checker(event)
    @input.keyup (event) => this.keyup_checker(event)
    @input.keypress (event) => this.keypress_checker(event)
    @input.blur (event) => this.add_tag()
    @container.delegate('a', 'click', (event) =>
      event.preventDefault()
      tag_id = $(event.currentTarget).parent('span').attr('id')
      matched_tags = @_tags.filter (tag) -> tag.id == tag_id
      if matched_tags.length > 0
        this.remove_tag(matched_tags[0])
    ).bind 'click', =>
      @input.focus()

  scale: ->
    if @_tags.length > 0
      tag_element = this.last_tag().element()
      position = tag_element.position()
      left     = position.left + tag_element.outerWidth() + parseInt(tag_element.css('margin-right'), 10)
      top      = position.top

      if left >= (@container.innerWidth() - 30)
        left = parseInt(@container.css('paddingLeft'), 10)
        top += tag_element.outerHeight() + parseInt(tag_element.css('marginBottom'), 10)

    else
      top  = 0
      left = 0

    @input.css
      top: "#{top}px",
      left: "#{left}px"

  keydown_checker: (event) ->
    stroke = event.which ? event.keyCode
    switch stroke
      when 8
        @backstroke_length = @input.val().length
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
      else
        # Make the thing get bigger! But with real code.
        # if @input.position().left > (@container.width() - parseInt(@container.css('paddingRight'), 10))
        #   added_height = @input.position().top + this.last_tag().element().outerHeight()
        #   container.css
        #     'min-height': @container.innerHeight() + added_height
        #   @input.css
        #     top: "#{added_height}px"

  keyup_checker: (event) ->
    stroke = event.which ? event.keyCode
    this.clear_backstroke() if stroke != 8
    switch stroke
      when 8
        if @backstroke_length < 1 and @_tags.length > 0
          this.backstroke()
      else
        if @delimiter_inserted
          value = @input.val().replace(new RegExp(@delimiter, 'g'), '')
          @input.val(value)
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
      this.remove_tag @_tags[@_tags.length - 1]
    else
      @pending_removal = true
      this.last_tag().element().addClass 'focused'

  clear_backstroke: ->
    if last_tag = this.last_tag()
      last_tag.element().removeClass 'focused'
    @pending_removal = null

  add_tag: ->
    value = @input.val()
    if value isnt ''
      tag =
        id: "#{@_id}_tag_#{@_tags.length}",
        value: value,
        element: ->
          $ "##{this.id}"

      @_tags.push tag

      @container.append $('<span />', {
        class: 'tag',
        id: tag.id
      }).text(value).append $('<a href="#">x</a>')

      @input.val ''

      this.scale()
      @input.focus()
      this.write()

      this.options.onChange.call this

  remove_tag: (tag) ->
    @_tags.splice @_tags.indexOf(tag), 1
    $("##{tag.id}").remove()
    this.scale()
    this.write()
    this.options.onChange.call this

  last_tag: ->
    @_tags[@_tags.length-1]

  write: ->
    @target.val (tag.value for tag in @_tags).join(@delimiter)

  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string

  generate_random_char: ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ";
    rand = Math.floor(Math.random() * chars.length)
    newchar = chars.substring rand, rand+1