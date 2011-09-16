/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 * 
 * This file is part of Flextrine.
 * 
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see http://www.gnu.org/licenses/.
 * 
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
