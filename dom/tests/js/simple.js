var node = document.documentElement

node.GetNodeType()

node.GetTagName()

var attrList = node.GetAttributes()

attrList.GetLength()

var attr = attrList.Item(0)

attr.GetName()

attr.value

attr.ToString()

node.HasChildNodes()

var children = node.GetChildNodes()

children.GetLength()

node = children.GetNextNode()
node.GetNodeType()

node.GetTagName()

children.ToFirst()

node = node.GetFirstChild()

node = node.GetNextSiblings()

node = node.GetParentNode()

 