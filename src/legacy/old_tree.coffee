
#Rudiments of a system for generic tree types.
arrayNode =
  create: (parent, val) ->
    leaf = [val]
    if parent
      parent[1] ||= []
      parent[1].push(leaf)
    leaf

  getValue: (node) ->
    node[0]

  setValue: (node, val) ->
    node[0] = val
    node[0]

  children: (node) ->
    node[1]


#Breadth first traversal.  The getChildren function takes a
#node as its argument and returns something that responds to
#forEach().
#Extremely General FTW.
traverse = (root, getChildren) ->
  current = []
  current.push(root)

  while current.length != 0
    next = []
    for node in current
      children = getChildren(node)
      for child in children
        next.push(child)
    current = next



#One application of the traverse() function. Returns a tree
#composed of arrays.  TODO:  generalize for any kind of tree
#structure by taking createNode and nodeValue functions.
#The return value of the getValue function will be used as the
#node value when constructing the new tree.
#The getChildren function is used by traverse().
copy = (root, getValue, getChildren) ->
  newRoot = arrayNode.create(null, null)
  traverse root, (item) ->
    a = []
    if item.node
      n = item
    else
      arrayNode.setValue(newRoot, getValue(item))
      n = {node: item, leaf: newRoot}
    children = getChildren(n.node)
    for child in children
      v = getValue(child)
      if v
        a.push
          node: child
          leaf: arrayNode.create(n.leaf, v)
    return a
  return newRoot


copyArrayTree = (root) ->
  copy root,
    (node) -> arrayNode.getValue(node),
    (node) -> arrayNode.children(node) || []



module.exports =
  arrayNode: arrayNode
  traverse: traverse
  copy: copy
  copyArrayTree: copyArrayTree



