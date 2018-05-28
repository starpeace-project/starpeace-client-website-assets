###
* main logic
###



$ ->


  $.get('/manifest/land.json', (land_manifest) ->

    $table = $("table.land-table[data-id='earth']")
    $tbody = $table.find('tbody')

    html = []
    for tile in land_manifest
      html[html.length] = "<tr><td>#{tile.id}</td><td>##{new Number(tile.map_color).toString(16).toUpperCase()}</td><td>#{tile.zone}</td><td>#{tile.type}</td><td>#{tile.variant}</td>"

      for season in ['winter', 'spring', 'summer', 'fall']
        for orientation in ['0deg', '90deg', '180deg', '270deg']
          html[html.length] = "<td><img src='/assets/images/land/earth/#{season}/#{tile.image_keys[orientation]}'></td>"

      console.log tile

      html[html.length] = "</tr>"

    $tbody.append($(html.join('')))
    $tbody.find('img').on('error', -> $(this).hide())
  )

#       0deg: "land.240.water.nwi.0.bmp", 90deg: "land.240.water.swi.0.bmp", 180deg: "land.240.water.sei.0.bmp", 270deg: "land.240.water.nei.0.bmp"