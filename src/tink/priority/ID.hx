package tink.priority;

import haxe.PosInfos;

using StringTools;

abstract ID({ cls:String, ?method:String }) {
	
	public var cls(get, never):String;
	public var method(get, never):Null<String>;
	
	public function new(cls:String, ?method:String)
		this = { cls: cls, method: method };
		
	inline function get_cls() 
		return this.cls;
		
	inline function get_method()
		return this.method;
		
	@:to public function toString() 
		return 
			if (this.method == null) this.cls;
			else this.cls + '::' + this.method;
	
	@:from static function ofString(s:String) {
		var parts = s.split('::');
		return new ID(parts[0], parts[1]);
	}
	
	@:from static function ofPosInfos(pos:PosInfos)
		return new ID(pos.className, pos.methodName);
}