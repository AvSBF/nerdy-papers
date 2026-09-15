class_name InteractionRaycast
extends RefCounted

static func ray_forward(camera: Camera3D, distance: float, mask: int = 0xFFFFFFFF) -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + camera.global_transform.basis * Vector3(0, 0, -1) * distance
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space.intersect_ray(query)

static func get_node_in_front(camera: Camera3D, distance: float, predicate: Callable, mask: int = 0xFFFFFFFF) -> Node:
	var hit := ray_forward(camera, distance, mask)
	if hit.is_empty():
		return null
	var collider := hit["collider"] as Node
	while collider != null:
		if predicate.call(collider):
			return collider
		collider = collider.get_parent()
	return null
