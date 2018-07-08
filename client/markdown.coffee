###
 * Federated Wiki : Markdown Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-markdown/blob/master/LICENSE.txt
###

marked = require 'marked3'

dataLine = 0

renderer = new (marked.Renderer)()

# wiki headings are always h3
renderer.heading = (text, level) ->
  # all sub headings will be level 3
  '<h3>' + text + '</h3>'

# modify listitem renderer, so we can know which checkbox has been clicked
renderer.listitem = (text, checked) ->
  if checked == undefined
    return "<li>#{text}</li>\n"

  dataLine++
  return """<li class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" data-line=#{dataLine}#{if checked then ' checked' else ''}>#{text}</li>\n"""

# we are opinionated about images - they should make use of the image plugin
renderer.image = (href, title, text) ->
  return """
    ![#{text}](#{href} #{if text then text})
  """


markedOptions =
  gfm: true
  sanitize: true
  taskLists: true
  renderer: renderer
  linksInNewTab: true
  breaks: true

expand = (text) ->
  dataLine = 0
  marked(text, markedOptions)

emit = ($item, item) ->
  pluginOrigin = new URL(wiki.pluginRoutes["markdown"])
  cssURL = pluginOrigin + '/client/markdown.css'
  if (!$("link[href='#{cssURL}']").length)
    $("<link rel='stylesheet' href='#{cssURL}' type='text/css'>").appendTo("head")

  $item.append """
      #{wiki.resolveLinks item.text, expand}
  """

toggle = (item, taskNumber) ->
  n = 0
  item.text = item.text.replace /\[[ x]\]/g, (box, i, original) ->
    n++
    if box is '[x]' then newBox = '[ ]' else newBox = '[x]'
    if n is taskNumber then newBox else box

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('[type=checkbox]').change (e) ->
    toggle item, $(e.target).data('line')
    $item.empty()
    emit($item, item)
    bind($item, item)
    wiki.pageHandler.put $item.parents('.page:first'),
      type: 'edit',
      id: item.id,
      item: item

window.plugins.markdown = {emit, bind} if window?
module.exports = {expand} if module?
