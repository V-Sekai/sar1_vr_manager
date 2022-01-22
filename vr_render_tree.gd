extends Node3D


func create_attachment_point(p_name: String) -> Node3D:
	var attachment: Node3D = Node3D.new()
	attachment.set_name(p_name)
	# Create attachment attach
	var attachment_attach = Node3D.new()
	attachment_attach.set_name("attach")
	attachment.add_child(attachment_attach, true)

	return attachment
