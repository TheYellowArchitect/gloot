@tool
extends InventoryGrid
class_name InventoryGridStacked

const ItemStackManager = preload("res://addons/gloot/item_stack_manager.gd")


func has_place_for(item: InventoryItem) -> bool:
    if _has_grid_space_for(item):
        return true

    if _has_stack_space_for(item):
        return true

    return false


func _has_grid_space_for(item: InventoryItem) -> bool:
    return Verify.vector_positive(find_free_place(item))


func _has_stack_space_for(item: InventoryItem) -> bool:
    return _get_stack_space_for(item) >= ItemStackManager.get_item_stack_size(item);


func _get_stack_space_for(item: InventoryItem) -> int:
    var mergable_items = ItemStackManager.get_mergable_items(self, item, [KEY_GRID_POSITION])
    var free_stack_space := 0
    for mergable_item in mergable_items:
        free_stack_space += ItemStackManager.get_free_stack_space(mergable_item)
    return free_stack_space
    

func add_item_automerge(item: InventoryItem) -> bool:
    if !has_place_for(item):
        return false

    ItemStackManager.add_item_automerge(self, item, [KEY_GRID_POSITION])
    return true
    
    
func split(item: InventoryItem, new_stack_size: int) -> InventoryItem:
    if !_has_grid_space_for(item):
        return null

    var new_item = ItemStackManager.split_stack(item, new_stack_size)
    assert(add_item(new_item))
    return new_item


func join(item_dst: InventoryItem, item_src: InventoryItem) -> bool:
    return ItemStackManager.join_stacks(self, item_dst, item_src, [KEY_GRID_POSITION])


static func get_item_stack_size(item: InventoryItem) -> int:
    return ItemStackManager.get_item_stack_size(item)


static func set_item_stack_size(item: InventoryItem, new_stack_size: int) -> void:
    return ItemStackManager.set_item_stack_size(item, new_stack_size)


static func get_item_max_stack_size(item: InventoryItem) -> int:
    return ItemStackManager.get_item_max_stack_size(item)


static func set_item_max_stack_size(item: InventoryItem, new_stack_size: int) -> void:
    return ItemStackManager.set_item_max_stack_size(item, new_stack_size)


func get_prototype_stack_size(prototype_id: String) -> int:
    return ItemStackManager.get_prototype_stack_size(item_protoset, prototype_id)


func get_prototype_max_stack_size(prototype_id: String) -> int:
    return ItemStackManager.get_prototype_max_stack_size(item_protoset, prototype_id)


func transfer_automerge(item: InventoryItem, destination: InventoryGridStacked) -> bool:
    # TODO: Get rid of code duplication (inventory_stacked.gd)
    if destination.has_place_for(item) && remove_item(item):
        return destination.add_item_automerge(item)

    return false


func transfer_autosplitmerge(item: InventoryItem, destination: InventoryGridStacked) -> bool:
    if destination.has_place_for(item):
        return transfer_automerge(item, destination)

    var count: int = destination._get_stack_space_for(item)
    if count > 0:
        var new_item: InventoryItem = ItemStackManager.split_stack(item, count)
        assert(new_item != null)
        return destination.add_item_automerge(new_item)

    return false


func transfer_to(item: InventoryItem, destination: InventoryGrid, position: Vector2i) -> bool:
    if super.transfer_to(item, destination, position):
        return true

    var destination_stacked = (destination as InventoryGridStacked)
    if destination_stacked == null:
        return false
        
    var item_dst := destination_stacked._get_mergable_item_at(item, position)
    if item_dst == null:
        return false

    return ItemStackManager.merge_stacks_autodelete(item_dst, item) == ItemStackManager.MergeResult.SUCCESS


func _get_mergable_item_at(item: InventoryItem, position: Vector2i) -> InventoryItem:
    var rect := Rect2i(position, get_item_size(item))
    var mergable_items := _get_mergable_items_under(item, rect)
    for mergable_item in mergable_items:
        if ItemStackManager.stacks_joinable(self, item, mergable_item, [KEY_GRID_POSITION]):
            return mergable_item
    return null


func _get_mergable_items_under(item: InventoryItem, rect: Rect2i) -> Array[InventoryItem]:
    var result: Array[InventoryItem]

    for item_dst in get_items_under(rect):
        if item_dst == item:
            continue
        if ItemStackManager.items_mergable(item_dst, item, [KEY_GRID_POSITION]):
            result.append(item_dst)

    return result

