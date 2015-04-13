class KS.Flash
  constructor: ->
    @modal = $('div#flash.modal')

  show: (content, target) ->
    return unless content?
    @modal.data('target', target) if target?
    @modal.find('.modal-content').html(content)
    @modal.modal 'show'

$ ->
  KS.flash = new KS.Flash
  KS.flash.modal.on 'hidden.bs.modal', ->
    if target = $(@).data('target')
      $.ajax
        url: target,
        dataType: 'script'
    else
      KS.nav.switchTo 'map'
