bl_info = {
	"name" : "Fysiks Collsion Shape Exporter",
	"description" : "Exports a blender mesh as a fysiks-compatible lua script",
	"author" : "krokoschlange",
	"blender" : (2, 80, 0),
	"location" : "File > Export",
	"category" : "Import-Export"
}

import bpy
import os

def export(object, path):
	mesh = object.data
	vertices = mesh.vertices.items()
	edges = mesh.edges.items()
	faces = mesh.polygons.items()

	file = open(path, "w")

	file.write("local vertices = {\n")
	for vertex in vertices:
		x = vertex[1].co[0]
		y = vertex[1].co[1]
		z = vertex[1].co[2]
		file.write("\t{x = %s, y = %s, z = %s}, -- %s\n" % (x, z, y, vertex[0]))
	file.write("}\n")

	file.write("local edges = {\n")
	for edge in edges:
		a = edge[1].vertices[0] + 1
		b = edge[1].vertices[1] + 1

		file.write("\t{%s, %s}, -- %s\n" % (a, b, edge[0]))
	file.write("}\n")

	file.write("local faces = {\n")
	for face in faces:
		file.write("\t{")
		for vertex in face[1].vertices:
			file.write("%s, " % (vertex + 1))
		file.write("},\n")
	file.write("}\n")

	file.write("local %sDefinition = {type = fysiks.FullPolyhedron, args = {vertices, edges, faces}}" % (object.name))

	file.close()

class ConfirmOperator(bpy.types.Operator):
	bl_idname = ("screen.fysiks_confirm")
	bl_label = ("File Exists, Overwrite?")

	def invoke(self, context, event):
		wm = context.window_manager
		return wm.invoke_props_dialog(self)

	def execute(self, context):
		export(self.object, self.filepath)
		self.report({"INFO"}, "Export successful")
		return {"FINISHED"}

class ExportOperator(bpy.types.Operator):
	bl_idname = ("screen.fysiks_export")
	bl_label = ("Fysiks Export")
	filepath: bpy.props.StringProperty(subtype="FILE_PATH")
	overwrite: bpy.props.BoolProperty(name="Overwrite without asking", default=False)

	def invoke(self, context, event):
		obj = context.active_object
		if obj.type != "MESH":
			self.report({"ERROR"}, "Selected object is not a mesh")
			return {"FINISHED"}
		path = bpy.path.abspath("//")
		self.filepath = path + obj.name + ".lua"
		context.window_manager.fileselect_add(self)
		return {"RUNNING_MODAL"}

	def execute(self, context):
		if self.filepath == "":
			return {"FINISHED"}
		if not self.filepath.endswith(".lua"):
			self.filepath += ".lua"

		self.object = context.active_object

		if os.path.exists(self.filepath) and not self.overwrite:
			ConfirmOperator.object = self.object
			ConfirmOperator.filepath = self.filepath
			bpy.ops.screen.fysiks_confirm("INVOKE_DEFAULT")
		else:
			export(self.object, self.filepath)
			self.report({"INFO"}, "Export successful")

		return {"FINISHED"}

def menu_func_export(self, context):
	self.layout.operator(ExportOperator.bl_idname, text = "Fysiks (.lua)")

def register():
	bpy.utils.register_class(ExportOperator)
	bpy.utils.register_class(ConfirmOperator)
	bpy.types.TOPBAR_MT_file_export.append(menu_func_export)

def unregister():
	bpy.utils.unregister_class(ConfirmOperator)
	bpy.utils.unregister_class(ExportOperator)
	bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)
