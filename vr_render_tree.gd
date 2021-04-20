extends Spatial


func create_attachment_point(p_name: String) -> Spatial:
	var attachment: Spatial = Spatial.new()
	attachment.set_name(p_name)
	# Create attachment attach
	var attachment_attach = Spatial.new()
	attachment_attach.set_name("attach")
	attachment.add_child(attachment_attach)

	return attachment
