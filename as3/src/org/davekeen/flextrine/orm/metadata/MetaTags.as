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