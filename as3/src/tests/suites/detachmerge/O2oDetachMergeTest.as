package tests.suites.detachmerge {
	import flash.events.Event;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class O2oDetachMergeTest extends AbstractTest {
		private var photo1:Photo;
		private var photo2:Photo;
		private var student:Student;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		[Test(async, description = "Check that changing a o2o association keeps the change during a detachCopy/merge cycle.")]
		public function o2oDetachMergeTest():void {
			photo1 = new Photo();
			photo1.url = "photo1.jpg";
			
			photo2 = new Photo();
			photo2.url = "photo2.jpg";
			
			student = new Student();
			student.name = "Student 1";
			student.photo = photo1;
			
			em.persist(student);
			em.persist(photo1);
			em.persist(photo2);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 5000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			var studentCopy:Student = em.detachCopy(student) as Student;
			
			// Change the photo and merge
			studentCopy.photo = photo2;
			
			var mergedStudent:Student = em.merge(studentCopy) as Student;
			
			Assert.assertStrictlyEquals(student, mergedStudent);
			Assert.assertStrictlyEquals(photo2, student.photo);
		}
		
		[Test(async, description = "Check that setting a o2o association to null flushes the change during a detachCopy/merge cycle.")]
		public function o2oDetachMergeNullTest():void {
			photo1 = new Photo();
			photo1.url = "photo1.jpg";
			
			student = new Student();
			student.name = "Student 1";
			student.photo = photo1;
			
			em.persist(student);
			em.persist(photo1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 5000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			var studentCopy:Student = em.detachCopy(student) as Student;
			
			// Change the photo to null and merge
			studentCopy.photo = null;
			
			var mergedStudent:Student = em.merge(studentCopy) as Student;
			
			Assert.assertStrictlyEquals(student, mergedStudent);
			Assert.assertNull(student.photo);
		}
		
	}

}