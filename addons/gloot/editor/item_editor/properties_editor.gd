extends Window

const GridConstraint = preload("res://addons/gloot/core/constraints/grid_constraint.gd")
const DictEditor = preload("res://addons/gloot/editor/common/dict_editor.tscn")
const EditorIcons = preload("res://addons/gloot/editor/common/editor_icons.gd")
const COLOR_OVERRIDDEN = Color.GREEN
const COLOR_INVALID = Color.RED
const POPUP_SIZE = Vector2i(800, 300)
const POPUP_MIN_SIZE = Vector2i(400, 200)
const POPUP_MARGIN = 10
var IMMUTABLE_KEYS: Array[String] = [ItemProtoset.KEY_ID, GridConstraint.KEY_GRID_POSITION]

var _dict_editor: Control
var _margin_container: MarginContainer
var gloot_undo_redo = null
var editor_interface: EditorInterface
var item: InventoryItem = null :
    get:
        return item
    set(new_item):
        if new_item == null:
            return
        assert(item == null, "Item already set!")
        item = new_item
        if item.protoset:
            item.protoset.changed.connect(Callable(self, "_refresh"))
        _refresh()


func _init(gloot_undo_redo_, editor_interface_: EditorInterface) -> void:
    assert(gloot_undo_redo_, "gloot_undo_redo_ is null!")
    assert(editor_interface_, "editor_interface_ is null!")
    gloot_undo_redo = gloot_undo_redo_
    editor_interface = editor_interface_

    title = "Edit Item Properties"
    unresizable = false
    size = POPUP_SIZE
    min_size = POPUP_MIN_SIZE
    close_requested.connect(func(): hide())
    visible = false
    exclusive = true

    _dict_editor = DictEditor.instantiate()
    _dict_editor.value_changed.connect(Callable(self, "_on_value_changed"))
    _dict_editor.value_removed.connect(Callable(self, "_on_value_removed"))

    _margin_container = MarginContainer.new()
    _margin_container.offset_bottom = -POPUP_MARGIN
    _margin_container.offset_left = POPUP_MARGIN
    _margin_container.offset_right = -POPUP_MARGIN
    _margin_container.offset_top = POPUP_MARGIN
    _margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _margin_container.anchor_bottom = 1.0
    _margin_container.anchor_right = 1.0
    _margin_container.add_child(_dict_editor)

    add_child(_margin_container)


func _ready() -> void:
    about_to_popup.connect(func(): _refresh())


func _on_value_changed(key: String, new_value) -> void:
    var new_properties = item.properties.duplicate()
    new_properties[key] = new_value

    var item_prototype: Dictionary = item.protoset.get_prototype(item.prototype_id)
    if item_prototype.has(key) && (item_prototype[key] == new_value):
        new_properties.erase(key)

    if new_properties.hash() == item.properties.hash():
        return

    gloot_undo_redo.set_item_properties(item, new_properties)
    _refresh()


func _on_value_removed(key: String) -> void:
    var new_properties = item.properties.duplicate()
    new_properties.erase(key)

    if new_properties.hash() == item.properties.hash():
        return

    gloot_undo_redo.set_item_properties(item, new_properties)
    _refresh()


func _refresh() -> void:
    if _dict_editor.btn_add:
        _dict_editor.btn_add.icon = EditorIcons.get_icon(editor_interface, "Add")
    _dict_editor.dictionary = _get_dictionary()
    _dict_editor.color_map = _get_color_map()
    _dict_editor.remove_button_map = _get_remove_button_map()
    _dict_editor.immutable_keys = IMMUTABLE_KEYS
    _dict_editor.refresh()


func _get_dictionary() -> Dictionary:
    if item == null:
        return {}

    if !item.protoset:
        return {}

    if !item.protoset.has_prototype(item.prototype_id):
        return {}

    var result: Dictionary = item.protoset.get_prototype(item.prototype_id).duplicate()
    for key in item.properties.keys():
        result[key] = item.properties[key]
    return result


func _get_color_map() -> Dictionary:
    if item == null:
        return {}

    if !item.protoset:
        return {}

    var result: Dictionary = {}
    var dictionary: Dictionary = _get_dictionary()
    for key in dictionary.keys():
        if item.properties.has(key):
            result[key] = COLOR_OVERRIDDEN
        if key == ItemProtoset.KEY_ID && !item.protoset.has_prototype(dictionary[key]):
            result[key] = COLOR_INVALID

    return result
            

func _get_remove_button_map() -> Dictionary:
    if item == null:
        return {}

    if !item.protoset:
        return {}

    var result: Dictionary = {}
    var dictionary: Dictionary = _get_dictionary()
    for key in dictionary.keys():
        result[key] = {}
        if item.protoset.get_prototype(item.prototype_id).has(key):
            result[key]["text"] = ""
            result[key]["icon"] = EditorIcons.get_icon(editor_interface, "Reload")
        else:
            result[key]["text"] = ""
            result[key]["icon"] = EditorIcons.get_icon(editor_interface, "Remove")

        result[key]["disabled"] = (not key in item.properties) or (key in IMMUTABLE_KEYS)
    return result

    