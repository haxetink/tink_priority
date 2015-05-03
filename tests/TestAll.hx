package ;

import tink.priority.*;
import haxe.ds.Option;
using tink.CoreApi;

typedef Event = Int;
typedef Result = Int;

class TestAll extends Base {
	var out:Array<Int>;
	var queue:Queue<Void->Void>;
	override function setup() {
		this.queue = new Queue();
		this.out = [];
	}
	
	function testOrdering() {				
		item(0);
		item(9).after(8);
		item(5);
		item(7);
		item(3);
		item(2).before(3);
		item(4).before(5).after(3);
		item(6).before(7).after(5);
		item(8).after(7);
		item(1).before(2);
		item(11).after(9);
		item(10).before(11);
		
		checkSorted();
	}
		
	function runQueue()
		for (f in queue) f();
		
	function checkSorted() {
		if (out.length == 0)
			runQueue();
			
		var s = out.toString();
		
		out.sort(Reflect.compare);
		
		assertEquals(out.toString(), s);		
	}
	
	function testLazyness() {
		
		item(9).after(8);
		item(5);
		item(7);
		item(3);
		item(2).before(3);
		item(4).before(5).after(3);
		item(6).before(7).after(5);
		item(8).after(7);
		item(1).before(2);
		item(11).after(9);
		item(10).before(11);
		item(0);
		
		runQueue();
		
		out.unshift(out.pop());//the 0 shouldn't propagate itself, so we do it by hand
		
		checkSorted();
	}
	
	function item(order:Int) {
		function id(id:Int)
			return 'TestAll::item($id)';
		var ret:Item<Void->Void> = {
			id: id(order),
			data: function () out.push(order)
		};
		queue.add(ret);
		var handle:Handle = null;
		return handle = {
			before: function (item:Int) {
				@:privateAccess ret.before = id(item);
				return handle;
			},
			after: function (item:Int) {
				@:privateAccess ret.after = id(item);
				return handle;
			},
		}
	}	
	
	function testFutures() {
		var q:Queue<Event->Future<Option<Result>>> = new Queue();
		
		function dispatch(e:Event):Future<Option<Result>> {
			var ret = Future.sync(None);
			for (handler in q)
				ret = ret.flatMap(function (result) return switch result {
					case Some(result): Future.sync(Some(result));
					case None: handler(e);
				});
			return ret;
		}
		
		q.after('overflow', function (x) return Future.sync(if (x % 2 == 0) Some(x >> 1) else None), 'div2');
		
		q.whenever(function (x) return switch x {
			case n if (n < 0): throw 'overflow';
			default: Future.sync(None);
		}, 'overflow');
			
		
		q.after('div2', function (x) return Future.sync(Some(x * 3 + 1)));
		
		var count = 0;
		
		var buf = [];
		function doDispatch(e:Event)
			dispatch(e).handle(function (x) {
				var x = x.toOutcome().sure();
				buf.push(x);
				if (count++ < 1000) 
					doDispatch(x);
			});
			
		doDispatch(100000);
		assertTrue(buf.slice(buf.length - 20).join(',').indexOf('4,2,1,4,2,1') != -1);
		count = 0;
		throws(
			function () doDispatch(1000000001),
			String,
			function (x) return x == 'overflow'
		);
	}
	static public var boot;
	
	static function __init__() 
		boot = new Queue();
	
	function testInit() 
		assertEquals('A,B,C', [for (setup in boot) setup()].join(','));
	
}

class C {
	static function __init__() 
		TestAll.boot.whenever(setup);
		
	static function setup() return 'C';
}

class A {
	static function __init__() 
		TestAll.boot.before('C', setup);
	
	static function setup() return 'A';
}

class B {
	static function __init__() 
		TestAll.boot.add({
			before: 'C',
			after: 'A',
			data: setup,
		});
	
	static function setup() return 'B';
}

typedef Handle = {
	function before(item:Int):Handle;
	function after(item:Int):Handle;
}