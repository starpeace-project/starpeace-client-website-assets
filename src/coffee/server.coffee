
express = require('express')
path = require('path')

app = express()
app.set('port', 11015)
app.use((req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
  next()
)
app.use(express.static(path.join(__dirname, 'web')))
app.use('/assets', express.static(path.join(__dirname, 'web/assets')))
app.use('/assets/images', express.static(path.join(__dirname, '../src/images')))

app.get('/', (req, res) -> res.redirect('/land.html'))

app.use('/manifest/land.json', express.static(path.join(__dirname, '../src/images/land/manifest.json')))

server = app.listen(app.get('port'), ->
  console.log("starpeace-website-client-assets listening at port #{server.address().port}")
)
