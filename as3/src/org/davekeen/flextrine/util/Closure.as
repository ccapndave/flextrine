/**
 * Copyright (C) 2012 Dave Keen http://www.actionscriptdeveloper.co.uk
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package org.davekeen.flextrine.util {
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class Closure extends Object {
		
		public static function create(context:Object, func:Function, ... pms):Function {
			var f:Function = function():* {
				var target:* = arguments.callee.target;
				var func:* = arguments.callee.func;
				var params:* = arguments.callee.params;
				var len:Number = arguments.length;
				var args:Array = new Array(len);
				for (var i:uint=0; i < len; i++)
					   args[i] = arguments[i];

				args["push"].apply(args, params);
				
				return func.apply(target, args);
			};
	   
			var _f:Object = f;
			
			_f.target = context;
			_f.func = func;
			_f.params = pms;
			
			return f;
		}
	}
	
}
