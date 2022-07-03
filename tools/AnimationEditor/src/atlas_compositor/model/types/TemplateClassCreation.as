package atlas_compositor.model.types
{
	public class TemplateClassCreation
	{
		public static const CLASS_BODY:String = 'package $package_name\n' +
			'{\n' +
			'\tpublic class $class_name\n' +
			'\t{\n' +
			'$class_content' +
			'\t}\n' +
			'}\n';
		
		public static const PUBLIC_VAR_STRING:String 	 = '\t\tpublic static var $var_name:String = \'$var_name\';\n';
		public static const AUTO_GENERATION_START:String = '\t\t/* ===== AUTO-GENERATED CONTENT BEGIN ===== */';
		public static const AUTO_GENERATION_END:String	 = '\t\t/* ===== AUTO-GENERATED CONTENT END ===== */';
	}
}