class VideoPlayer
  constructor: (@video) ->
    @currentTime = 0
    @element = $("#video_#{@video.id}")
    @render()
    @bind()

  $: (selector) ->
    $(selector, @element)

  bind: ->
    $(@).bind('seek', @onSeek)
      .bind('updatePlayTime', @onUpdatePlayTime)
      .bind('speedChange', @onSpeedChange)
      .bind('play', @onPlay)
      .bind('pause', @onPause)
      .bind('ended', @onPause)
    $(document).keyup @bindExitFullScreen

    @$('.add-fullscreen').click @toggleFullScreen
    @addToolTip unless onTouchBasedDevice()

  bindExitFullScreen: (event) =>
    if @element.hasClass('fullscreen') && event.keyCode == 27
      @toggleFullScreen(event)

  render: ->
    new VideoControl(this)
    new VideoCaption(this, @video.youtubeId('1.0'))
    new VideoSpeedControl(this, @video.speeds)
    new VideoProgressSlider(this)
    @player = new YT.Player @video.id,
      playerVars:
        controls: 0
        wmode: 'transparent'
        rel: 0
        showinfo: 0
        enablejsapi: 1
      videoId: @video.youtubeId()
      events:
        onReady: @onReady
        onStateChange: @onStateChange

  addToolTip: ->
    @$('.add-fullscreen, .hide-subtitles').qtip
      position:
        my: 'top right'
        at: 'top center'

  onReady: =>
    @setProgress(0, @duration())
    $(@).trigger('ready')
    unless true || onTouchBasedDevice()
      $('.course-content .video:first').data('video').player.play()

  onStateChange: (event) =>
    switch event.data
      when YT.PlayerState.PLAYING
        $(@).trigger('play')
      when YT.PlayerState.PAUSED
        $(@).trigger('pause')
      when YT.PlayerState.ENDED
        $(@).trigger('ended')

  onPlay: =>
    window.player.pauseVideo() if window.player && window.player != @player
    window.player = @player
    unless @player.interval
      @player.interval = setInterval(@update, 200)

  onPause: =>
    window.player = null if window.player == @player
    clearInterval(@player.interval)
    @player.interval = null

  onSeek: (event, time) ->
    @player.seekTo(time, true)
    if @isPlaying()
      clearInterval(@player.interval)
      @player.interval = setInterval(@update, 200)
    else
      @currentTime = time
      $(@).trigger('updatePlayTime', time)

  onSpeedChange: (event, newSpeed) =>
    @currentTime = Time.convert(@currentTime, parseFloat(@currentSpeed()), newSpeed)
    @video.setSpeed(parseFloat(newSpeed).toFixed(2).replace /\.00$/, '.0')

    if @isPlaying()
      @player.loadVideoById(@video.youtubeId(), @currentTime)
    else
      @player.cueVideoById(@video.youtubeId(), @currentTime)
      @setProgress(@currentTime, @duration())
    $(@).trigger('updatePlayTime', @currentTime)

  update: =>
    if @currentTime = @player.getCurrentTime()
      $(@).trigger('updatePlayTime', @currentTime)

  onUpdatePlayTime: (event, time) =>
    @setProgress(@currentTime) if time

  setProgress: (time) =>
    progress = Time.format(time) + ' / ' + Time.format(@duration())
    if @progress != progress
      @$(".vidtime").html(progress)
      @progress = progress

  toggleFullScreen: (event) =>
    event.preventDefault()
    if @element.hasClass('fullscreen')
      @$('.exit').remove()
      @$('.add-fullscreen').attr('title', 'Fill browser')
      @element.removeClass('fullscreen')
    else
      @element.append('<a href="#" class="exit">Exit</a>').addClass('fullscreen')
      @$('.add-fullscreen').attr('title', 'Exit fill browser')
      @$('.exit').click @toggleFullScreen
    $(@).trigger('resize')

  # Delegates
  play: ->
    @player.playVideo() if @player.playVideo

  isPlaying: ->
    @player.getPlayerState() == YT.PlayerState.PLAYING

  pause: ->
    @player.pauseVideo()

  duration: ->
    @video.getDuration()

  currentSpeed: ->
    @video.speed
