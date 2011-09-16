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
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.utils.DescribeTypeCache;
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.cache.DictionaryCache;
	import org.davekeen.flextrine.cache.ICache;
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.FlextrineError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.metadata.MetaTags;

	/**
	 * @private
	 * @author Dave Keen
	 */
	public class EntityUtil {
		
		private static var entityAttributeTagCache:ICache = new DictionaryCache();
		
		flextrine static var isCopying:Boolean = false; 
		
		/**
		 * Return true if the given object is an entity (i.e. The class has [Entity] metadata)
		 * 
		 * @param entity
		 * @return 
		 */
		public static function isEntity(entity:Object):Boolean {
			return (DescribeTypeCache.describeType(entity).typeDescription.metadata.(@name == MetaTags.ENTITY).length() == 1);
		}
		
		/**
		 * Return an xml list of the attributes in the entity that have the given metadata tag.  So, to return the attributes that have tag [Id] you would
		 * call getAttributesWithTag(myObject, "Id").
		 * 
		 * @param	entity
		 * @param	tag
		 * @return
		 */
		public static function getAttributesWithTag(entity:Object, tag:String):XMLList {
			// The e4x query is quite inefficient and this is called a lot, so cache the results
			var entityClass:String = ClassUtil.getClassAsString(entity);
			var cacheKey:String = entityClass + "_" + tag;
			
			if (!entityAttributeTagCache.contains(cacheKey))
				// Use length() to evaluation the sub-filter to 1 or more (== true) to make the nested e4x behave properly
				entityAttributeTagCache.save(cacheKey, DescribeTypeCache.describeType(entity).typeDescription.accessor.(@access == "readwrite" && metadata.(@name == tag).length()).@name);
			
			return entityAttributeTagCache.fetch(cacheKey);
		}
		
		/**
		 * Get the full metadata for a particular attribute and tag
		 * 
		 * @param entity
		 * @param attributeName
		 * @param tag
		 * @return 
		 */
		public static function getMetaDataForAttributeAndTag(entity:Object, attributeName:String, tag:String):XMLList {
			return DescribeTypeCache.describeType(entity).typeDescription.accessor.(@name == attributeName).metadata.(@name == tag);
		}
		
		/**
		 * Use the metadata to determine whether or not a particular attribute is an association
		 * 
		 * @param entity
		 * @param attributeName
		 * @return 
		 */
		public static function isAssociation(entity:Object, attributeName:String):Boolean {
			return (DescribeTypeCache.describeType(entity).typeDescription.accessor.(@name == attributeName).metadata.(@name == MetaTags.ASSOCIATION).length() > 0);
		}
		
		/**
		 * Return an object mapping id fields to their values.  This will work with composite keys as well as single keys.
		 * 
		 * @param	entity
		 * @return
		 */
		public static function getIdObject(entity:Object):Object {
			if (!entity)
				throw new Error("Attempted to call getIdObject with a null entity");
			
			var idObject:Object = {};
			
			for each (var idAttribute:String in getIdFields(entity))
				idObject[idAttribute] = entity[idAttribute];
			
			return idObject;
		}
		
		/**
		 * Gets an id hash of an entity based on a string concatentation of all its [Id] attributes.
		 * 
		 * @param	entity
		 * @return
		 */
		public static function getIdHash(entity:Object):String {
			if (!entity)
				throw new Error("Attempted to call getIdHash with a null entity");
			
			var idHashArray:Array = [];
			
			for each (var idAttribute:String in getIdFields(entity))
				idHashArray.push(entity[idAttribute]);
			
			return idHashArray.join("_");
		}
		
		/**
		 * Returns an array containing the names of the identity fields.
		 * 
		 * @param	entity
		 * @return
		 */
		public static function getIdFields(entity:Object):Array {
			var idXmlList:XMLList = getAttributesWithTag(entity, MetaTags.ID);
			
			var xmlListArray:Array = [];
			for each (var id:String in idXmlList)
				xmlListArray.push(id);
				
			return xmlListArray;
		}
		
		/**
		 * Does the entity have an id?
		 * 
		 * @param	entity
		 * @return
		 */
		public static function hasId(entity:Object):Boolean {
			return (getIdHash(entity) != "");
		}
		
		/**
		 * Is the entity initialized or is it a stub that needs to be loaded from the database
		 * 
		 * @param	entity
		 * @return
		 */
		public static function isInitialized(entity:Object):Boolean {
			if (entity is ArrayCollection)
				throw new FlextrineError("isInitialized can only be called on an entity, not a collection");
			
			return entity.isInitialized__;
		}
		
		/**
		 * Is the associated collection within the entity initialized or does it need to be loaded from the database
		 * 
		 * @param	entity
		 * @param	attributeName	The name of the 'many' attribute
		 * @return
		 */
		public static function isCollectionInitialized(collection:PersistentCollection):Boolean {
			if (!collection)
				throw new FlextrineError("A null value was passed to isCollectionInitialized.  Are you sure the owning entity is initialized?");
			
			return collection.isInitialized__;
		}
		
		/**
		 * Gets a unique hash based on the id and class.
		 * 
		 * @param	entity
		 * @param	An optional unique identifier that is appended to the hash.  This is useful for entities that have no id.
		 * @return
		 */
		public static function getUniqueHash(entity:Object, uniqueIdentifier:String = null):String {
			if (!EntityUtil.isEntity(entity))
				throw new ReferenceError(entity + " is not an entity");
			
			return ClassUtil.getClassAsString(entity) + "_" + getIdHash(entity) + ((uniqueIdentifier) ? uniqueIdentifier : "");
		}
		
		public static function mergeEntity(fromEntity:Object, toEntity:Object, forRemote:Boolean = false):Object {
            if (!(ClassUtil.getClass(fromEntity) === ClassUtil.getClass(toEntity)))
				throw new Error("You cannot merge entities unless they are of the same class (attempt to merge " + fromEntity + " into " + toEntity);
			
			// If the fromEntity is not initialized then we don't want to merge it as there will be nothing there apart from the id, so just return the
			// toEntity.
			if (!EntityUtil.isInitialized(fromEntity))
				return toEntity;
			
			// Make sure that __isInitialized__ is the first thing that is merged otherwise we won't be able to access the properties
			toEntity.isInitialized__ = true;
			
			var describeTypeXML:XML = DescribeTypeCache.describeType(fromEntity).typeDescription;
			
			// Copy over each readwrite attribute
			for each (var accessor:XML in describeTypeXML..accessor) {
				if (accessor.@access == "readwrite") {
					if (accessor..metadata.(@name == MetaTags.ASSOCIATION).length() == 0) {
						switch (accessor.@name.toString()) {
							case "isInitialized__":
							case "isUnserialized__":
								// Don't copy these
								break;
							default:
								// Normal properties are copied
								toEntity[accessor.@name] = fromEntity[accessor.@name];
						}
					} else {
						if (accessor.@type == getQualifiedClassName(PersistentCollection)) {
							// If this is a multivalued association set the initialized flag.  If no PersistentCollection exists on the
							// toEntity we might have to create a blank one.  Use a logical OR on the initialized status coming in and the
							// current initialized status so that we don't overwrite initialized collections with uninitialized ones.
							if (!toEntity[accessor.@name]) toEntity[accessor.@name] = new PersistentCollection();
							toEntity[accessor.@name].isInitialized__ = EntityUtil.isCollectionInitialized(fromEntity[accessor.@name]) || EntityUtil.isCollectionInitialized(toEntity[accessor.@name]);
						}
					}
				}
			}
			
            return toEntity;
		}
		
		public static function copyEntity(entity:Object):Object {
			EntityUtil.flextrine::isCopying = true;
			var entityCopy:Object = ObjectUtil.copy(entity);
			EntityUtil.flextrine::isCopying = false;
			
			return entityCopy;
		}
		
	}

}