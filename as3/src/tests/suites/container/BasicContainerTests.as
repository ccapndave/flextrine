package tests.suites.container {
	import flexunit.framework.Assert;
	
	import tests.AbstractTest;
	import tests.vo.Artist;
	import tests.vo.Country;
	import tests.vo.Movie;
	import tests.vo.Student;
	import tests.vo.cookbook.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class BasicContainerTests extends AbstractTest {
		
		[Before]
		override public function setUp():void {
			super.setUp();
		}
		
		[Test(description = "Basic test of manyToOne adding and removing")]
		public function manyToOneAddRemove():void {
			var garden:Garden = new Garden();
			var tree:Tree = new Tree();
			
			garden.trees.addItem(tree);
			
			// Check the garden was automatically set on the tree
			Assert.assertStrictlyEquals(garden, tree.garden);
			
			// Now remove the tree
			garden.trees.removeItem(tree);
			
			// Check the garden was automatically set back to null
			Assert.assertNull(tree.garden);
		}
		
		[Test(description = "Basic test of oneToMany adding and removing")]
		public function oneToManyAddRemove():void {
			var garden:Garden = new Garden();
			var tree:Tree = new Tree();
			
			tree.garden = garden;
			
			// Check the tree was automatically added to trees on the garden
			Assert.assertEquals(1, garden.trees.length);
			Assert.assertStrictlyEquals(tree, garden.trees.getItemAt(0));
			
			tree.garden = null;
			
			// Check the tree was automatically removed from trees on the garden
			Assert.assertEquals(0, garden.trees.length);
		}
		
		[Test(description = "Basic test of oneToMany adding and removing")]
		public function manyToManyAddRemove():void {
			var artist:Artist = new Artist();
			var movie:Movie = new Movie();
			
			artist.movies.addItem(movie);
			
			// Check the artist was automatically added to the movie
			Assert.assertEquals(1, movie.artists.length);
			Assert.assertStrictlyEquals(artist, movie.artists.getItemAt(0));
			
			artist.movies.removeItem(movie);
			
			// Check the artist was automatically removed from the movie
			Assert.assertEquals(0, movie.artists.length);
		}
		
		[Test(description = "Basic test of uniDirectional adding and removing")]
		public function uniDirectionalAdd():void {
			var student:Student = new Student();
			var country:Country = new Country();
			
			// We don't need to do any assertions, we are just checking that student doesn't try (and fail) to set anything on country since the
			// association is uni-directional.
			student.country = country;
		}
		
	}

}