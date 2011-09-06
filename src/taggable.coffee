root = this
$ = jQuery

$.taggable =
  instances: new Array(),
  destroyAll: ->
    $.each $.taggable.instances, (i, element) ->
      element.taggable 'destroy'

methods =
  init: (options) ->
    settings =
      delimiter: ','
      string_wrap: null

    settings = $.extend settings, options

    return @each () ->
      element = $ this;
      taggable = element.data('taggable');
      if not taggable
        element.data 'taggable', new Taggable(element, settings)
        $.taggable.instances.push(element);

  destroy: ->
    return @each () ->
      element = $ this;
      taggable = element.data('taggable');
      instances = $.taggable.instances.map (thing) ->
        thing.get(0)
      index = $.inArray this, instances
      if index != -1
        taggable.destroy()
        delete $.taggable.instances[index];
        delete taggable;
        element.removeData('taggable');

$.fn.taggable = (method, options...) ->
  if typeof methods[method] == 'function'
    methods[method].apply this, options
  else if typeof method == 'object' or not method?
    methods.init.apply(this, arguments);
  else
    $.error('Method ' +  method + ' does not exist on jQuery.taggable');

class Taggable
  constructor: (field, options) ->
    @original = $ field
    @options = $.extend {
      delimiter: @original.data('delimiter') || ','
      onChange: ->
    }, options || {}
    @_id = this.generate_random_id()
    @_tags = []
    this.setup()
    this.setup_observers()

  setup: ->
    @original.data 'original-position',
      position: @original.css('position')
      left: @original.css('left')
      top: @original.css('top')
      visibility:  @original.css('visibility')

    @original.css
      position: 'absolute'
      left: '-100000px'
      top: '0px'
      visibility: 'hidden'

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

    @container = ($ '<div />',
      id: @_id
      class: "taggable_container"
    ).css
      'max-width':  "#{@original.width()}px"
      'min-height': "#{@original.height()}px"
      position: 'relative'

    @input = ($ '<input />',
      type: 'text'
      name: 'taggable'
      autocomplete: 'off'
    ).css(computed_styles).css(
      width: "#{@original.width()}px"
      background: 'transparent'
      position: 'absolute'
      top: @container.css('paddingTop')
      left: @container.css('paddingLeft')
      border: 'none'
      outline: 'none'
    ).appendTo @container

    @container.insertAfter @original

    existing_tags_string = $.trim @original.val()
    unless existing_tags_string == ''
      $.each existing_tags_string.split(@options.delimiter), (index, tag) =>
        this.add_tag tag


  setup_observers: ->
    @input.keydown (event) => this.keydown_checker(event)
    @input.keyup (event) => this.keyup_checker(event)
    @input.keypress (event) => this.keypress_checker(event)
    @input.blur (event) => this.add_tag @input.val()
    @container.delegate('a', 'click.taggable', (event) =>
      event.preventDefault()
      tag_id = $(event.currentTarget).parent('span').attr('id')
      matched_tags = @_tags.filter (tag) -> tag.id == tag_id
      if matched_tags.length > 0
        this.remove_tag(matched_tags[0])
    ).bind 'click.taggable', (event) =>
      event.preventDefault()
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
        this.add_tag @input.val()
        break
      when 38
        event.preventDefault()
        break
      when 40
        break
      else
        available_width = this.available_width()
        if @_tags.length != 0
          tmp_tag = $('<span />', {
            class: 'tag'
          }).css(
            visibility: 'hidden',
            position: 'absolute',
            left: '-100000px'
          ).text(@input.val()).append $('<a href="#">x</a>')
          tmp_tag.appendTo(@container)
          width = tmp_tag.outerWidth()
          if width >= available_width
            added_height = @input.position().top + tmp_tag.outerHeight()
            @container.css
              'height': @container.innerHeight() + added_height
            @input.css
              left: @container.css('paddingLeft'),
              top: "#{added_height}px"
          else
            @input.css
              width: "#{available_width}px"
          tmp_tag.remove()

  keyup_checker: (event) ->
    stroke = event.which ? event.keyCode
    this.clear_backstroke() if stroke != 8
    switch stroke
      when 8
        if @backstroke_length < 1 and @_tags.length > 0
          this.backstroke()
      else
        if @options.delimiter_inserted
          value = @input.val().replace(new RegExp(@options.delimiter, 'g'), '')
          @input.val(value)
          if value != ''
            this.add_tag @input.val()

  keypress_checker: (event) ->
    if String.fromCharCode(event.charCode) == @options.delimiter
      @options.delimiter_inserted = true
    else
      @options.delimiter_inserted = false
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

  add_tag: (value) ->
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
    @original.val (tag.value for tag in @_tags).join(@options.delimiter)

  destroy: ->
    this.write()
    @container.remove()
    @original.css @original.data('original-position')

  available_width: ->
    if @_tags.length > 0
      last_tag_element = this.last_tag().element()
      @container.innerWidth() - (@input.position().left + last_tag_element.outerWidth())
    else
      @container.innerWidth()

  generate_random_id: ->
    string = "sel" + this.generate_random_char() + this.generate_random_char() + this.generate_random_char()
    while $("#" + string).length > 0
      string += this.generate_random_char()
    string

  generate_random_char: ->
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZ";
    rand = Math.floor(Math.random() * chars.length)
    newchar = chars.substring rand, rand+1