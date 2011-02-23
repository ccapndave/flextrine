package tests.suites.types {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.types.TypesObject;
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class TypesTest extends AbstractTest {
		
		private var typesObject:TypesObject;
		private var dateTime:Date;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		[Test(async, description = "This tests that different types are written and read correctly.")]
		public function typesTest():void {
			typesObject = new TypesObject();
			em.persist(typesObject);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(TypesObject).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			typesObject = e.result as TypesObject;
			
			// Check all the fields still have their unitialized values
			Assert.assertEquals(0, typesObject.bigIntField);
			Assert.assertEquals(false, typesObject.booleanField);
			Assert.assertEquals(null, typesObject.dateField);
			Assert.assertEquals(null, typesObject.dateTimeField);
			Assert.assertEquals(0, typesObject.decimalField);
			Assert.assertEquals(0, typesObject.integerField);
			Assert.assertEquals(0, typesObject.smallIntField);
			Assert.assertEquals(null, typesObject.stringField);
			Assert.assertEquals(null, typesObject.textField);
			
			dateTime = new Date();
			
			// Now set a value on each of the fields
			typesObject.bigIntField = 1000;
			typesObject.booleanField = true;
			typesObject.dateField = dateTime; // This should be truncated to just the date on the server
			typesObject.dateTimeField = dateTime;
			typesObject.decimalField = 2000;
			typesObject.integerField = 3000;
			typesObject.smallIntField = 4000;
			typesObject.stringField = "I am a string";
			typesObject.textField = "I am text";
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// This line isn't really necessary, but anyway
			typesObject = em.getRepository(TypesObject).find(1) as TypesObject;
			
			// Check all the fields still have their unitialized values
			Assert.assertEquals(1000, typesObject.bigIntField);
			Assert.assertEquals(true, typesObject.booleanField);
			
			// The date field should really have just the date but it seems that the whole thing gets stored in MySQL under the hood
			Assert.assertTrue(typesObject.dateTimeField is Date);
			Assert.assertEquals(dateTime.getTime(), typesObject.dateTimeField.getTime());
			
			Assert.assertTrue(typesObject.dateField is Date);
			var dateTimeOnlyDate:Date = new Date(dateTime.getTime());
			dateTimeOnlyDate.setMilliseconds(0);
			dateTimeOnlyDate.setSeconds(0);
			dateTimeOnlyDate.setHours(0);
			Assert.assertEquals(dateTimeOnlyDate.getTime(), typesObject.dateField.getTime());
			
			
			
			Assert.assertEquals(2000, typesObject.decimalField);
			Assert.assertEquals(3000, typesObject.integerField);
			Assert.assertEquals(4000, typesObject.smallIntField);
			Assert.assertEquals("I am a string", typesObject.stringField);
			Assert.assertEquals("I am text", typesObject.textField);
			
			// Now set everything back to their original unitialized values
			typesObject.bigIntField = 0;
			typesObject.booleanField = false;
			typesObject.dateField = null;
			typesObject.dateTimeField = null;
			typesObject.decimalField = 0;
			typesObject.integerField = 0;
			typesObject.smallIntField = 0;
			typesObject.stringField = null;
			typesObject.textField = null;
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 10000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			// This line isn't really necessary, but anyway
			typesObject = em.getRepository(TypesObject).find(1) as TypesObject;
			
			Assert.assertEquals(0, typesObject.bigIntField);
			Assert.assertEquals(false, typesObject.booleanField);
			Assert.assertEquals(null, typesObject.dateField);
			Assert.assertEquals(null, typesObject.dateTimeField);
			Assert.assertEquals(0, typesObject.decimalField);
			Assert.assertEquals(0, typesObject.integerField);
			Assert.assertEquals(0, typesObject.smallIntField);
			Assert.assertEquals(null, typesObject.stringField);
			Assert.assertEquals(null, typesObject.textField);
			
			em.clear();
			em.getRepository(TypesObject).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result5, remoteFault), 10000));
		}
		
		private function result5(e:ResultEvent, token:AsyncToken):void {
			typesObject = e.result as TypesObject;
			
			Assert.assertEquals(0, typesObject.bigIntField);
			Assert.assertEquals(false, typesObject.booleanField);
			Assert.assertEquals(null, typesObject.dateField);
			Assert.assertEquals(null, typesObject.dateTimeField);
			Assert.assertEquals(0, typesObject.decimalField);
			Assert.assertEquals(0, typesObject.integerField);
			Assert.assertEquals(0, typesObject.smallIntField);
			Assert.assertEquals(null, typesObject.stringField);
			Assert.assertEquals(null, typesObject.textField);
		}
		
	}
}