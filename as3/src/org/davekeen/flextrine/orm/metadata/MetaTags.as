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

package org.davekeen.flextrine.orm.metadata {
	import mx.utils.DescribeTypeCache;
	/**
	 * @private 
	 * @author Dave Keen
	 */
	[Entity]
	[Id]
	[Association]
	public class MetaTags {
		
		public static const ENTITY:String = "Entity";
		public static const ID:String = "Id";
		public static const ASSOCIATION:String = "Association";
		
		/**
		 * Ensure that the required metadata is compiled into the SWF (by adding the metadata to this MetaTags class and checking for it)
		 */
		public static function checkKeepMetaData():void {
			var metadata:XMLList = DescribeTypeCache.describeType(MetaTags).typeDescription.factory.metadata;
			checkKeepMetaDataTag(metadata, ENTITY);
			checkKeepMetaDataTag(metadata, ID);
			checkKeepMetaDataTag(metadata, ASSOCIATION);
		}
		
		private static function checkKeepMetaDataTag(metadata:XMLList, tag:String):void {
			if (metadata.(@name == tag).length() == 0)
				throw new Error("Metadata tag [" + tag + "] was not compiled into your application.  If you are using Flex 3 you need to add '-keep-as3-metadata += Id Association Entity' to the compiled arguments.  This should not be necessary for Flex 4 and above, although there are reports that it is still necessary when using 'Export Release Build' in Flash Builder 4.");
		}
		
	}

}