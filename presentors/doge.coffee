fs     = require 'fs'
Canvas = require 'canvas'
Font   = Canvas.Font
canvas = null
ctx    = null
caopt  =
  max: 50 * 1048576 # ~50M
  length: (n) -> n.length
  maxAge: 1000 * 60 * 60
cache  = require('lru-cache')(caopt)
config =
  fontSize: 100
  wordsPerLine: 2
  lineHeight: 0
  lineIndents: [0, .15, .40, .10, 0, .30]
  colors: ["#dd7c5c", "#000", "#cdd156", "#7a9fba", "#b996ae"]
  fontFamily: "comicSans"
  maxsize: [1280,1280]
images =
  base: # default
    name: 'reallybigdoge.jpeg'
    size: [680,510]
  dogecoin:
    name: 'dogecoin.png'
    size: [300,300]
  dogeface:
    name: 'doge.jpeg'
    size: [264,264]


module.exports = (req, res) ->

  res.setHeader "content-type", "image/png"

  imgdata = images[req.query.image] || images.base

  if req.query.size && req.query.size.match(/^\d+(?:x\d+)?$/i)
    [width,height] = req.query.size.split(/x/i)
    width = Math.min(parseInt(width), config.maxsize[0])
    height = if height then Math.min(parseInt(height), config.maxsize[1]) else width

  width = width || imgdata.size[0]
  height = height || imgdata.size[1]

  cachekey = [req.path,imgdata.name,width,height].join()

  if cache.has(cachekey)
    res.end(cache.get(cachekey))
  else
    fs.readFile __dirname+"/../images/"+imgdata.name, (err, d) ->
      message = formatMessage(req.path.split("/").slice(1))
      canvas  = new Canvas(width, height)
      ctx     = canvas.getContext('2d')
      img     = new Canvas.Image
      img.src = d

      ctx.addFont(new Font("comicSans", "#{__dirname}/../fonts/cs.ttf"))
      ctx.drawImage img, 0, 0, width, height
      drawMessage message

      cache.set(cachekey, canvas.toBuffer())
      canvas.pngStream().pipe(res)

removeExtension = (message) ->
  l = message.length - 1
  if ~message[l].indexOf('.')
    message[l] = message[l].slice(0, message[l].indexOf('.'))
  message

formatMessage = (message) ->
  hold      = []
  formatted = []
  removeExtension(message).forEach (w) ->
    hold.push decodeURI(w)
    if hold.length % config.wordsPerLine is 0
      formatted.push(hold.join(" "))
      hold = []

  formatted.push(hold.join(" ")) if hold.length
  formatted

drawMessage = (messages) ->
  heightStack = 0

  messages.forEach (m, i) ->
    ctx.font = "#{config.fontSize}px #{config.fontFamily}"
    size     = ctx.measureText(m)
    step     = 0

    while size.width > canvas.width - config.lineIndents[i]*canvas.width and ++step < config.fontSize
      ctx.font = "#{config.fontSize - step}px #{config.fontFamily}"
      size     = ctx.measureText(m)

    ctx.fillStyle = config.colors[~~(Math.random() * config.colors.length)]
    ctx.fillText m,
      config.lineIndents[i]*canvas.width,
      size.emHeightAscent + heightStack + config.lineHeight * ++i

    heightStack += config.fontSize - step
