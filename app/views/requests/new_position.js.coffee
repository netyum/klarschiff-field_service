KS.nav.bar.close()
KS.nav.switchTo 'map'
KS.map.actions().html('<%= j render("new_position_buttons") %>').removeClass 'hidden'
KS.createFeature '<%= @request.type %>'
