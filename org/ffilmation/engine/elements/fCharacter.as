// Character class
package org.ffilmation.engine.elements {
	
		// Imports
	  import flash.display.*
		import flash.events.*
		import flash.geom.Point
		import org.ffilmation.engine.core.*
		import org.ffilmation.engine.helpers.*
		import org.ffilmation.engine.events.*
		import org.ffilmation.engine.datatypes.*
		import org.ffilmation.engine.logicSolvers.collisionSolver.*


		/** 
		* <p>A Character is a dynamic object in the scene. Characters can move and rotate, and can be added and
		* removed from the scene at any time. Live creatures and vehicles are the most common
		* uses for the fCharacter class.</p>
		*
		* <p>There are other uses for fCharacter: If you want a chair to be "moveable", for example, you
		* will have to make it a fCharacter.</p>
		*
		* <p>You can add the parameter dynamic="true" to the XML definition for any object you want to be able to move
		* later. This will force the engine to make that object a Character.</p>
		*
		* <p>The main reason of having different classes for static and dynamic objects is that static objects can be
		* added to the light rendering cache along with floors and walls, whereas dynamic objects (characters) can't.</p>
		*
		* <p>Don't use this class to implement bullets. Use the fBullet class.</p>
		*
		* <p>YOU CAN'T CREATE INSTANCES OF THIS ELEMENT DIRECTLY.<br>
		* Use scene.createCharacter() to add new characters to an scene.</p>
		*
		* @see org.ffilmation.engine.core.fScene#createCharacter()
		*
		*/
		public class fCharacter extends fObject {
			
			// Constants

			/**
 			* The fCharacter.COLLIDE constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactercollide</code> event.
 			* The event is dispatched when the character collides with another element in the scene
 			* 
 			* @eventType charactercollide
 			*/
 		  public static const COLLIDE:String = "charactercollide"

			/**
 			* The fCharacter.WALKOVER constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>characterwalkover</code> event.
 			* The event is dispatched when the character walks over a non-solid object of the scene
 			* 
 			* @eventType characterwalkover
 			*/
 		  public static const WALKOVER:String = "characterwalkover"

			/**
 			* The fCharacter.EVENT_IN constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactereventin</code> event.
 			* The event is dispatched when the character enters a cell where an event was defined
 			* 
 			* @eventType charactereventin
 			*/
 		  public static const EVENT_IN:String = "charactereventin"

			/**
 			* The fCharacter.EVENT_OUT constant defines the value of the 
 			* <code>type</code> property of the event object for a <code>charactereventout</code> event.
 			* The event is dispatched when the character leaves a cell where an event was defined
 			* 
 			* @eventType charactereventout
 			*/
 		  public static const EVENT_OUT:String = "charactereventout"

			
			// Public properties
			
			/** 
			* Numeric counter assigned by scene
			* @private
			*/
			public var counter:int
			
			/** 
			* Array of render cache. For each light in the scene, a list of elements that are shadowed by this character at its current position
			* @private
			*/
			public var vLights:Array
			
			/**
			* Array of cells the character occupies
			* @private
			*/
			public var occupiedCells:Array


			// Constructor
			/** @private */
			function fCharacter(defObj:XML,scene:fScene):void {
				
				 // Characters are animated always
				 this.animated = true
				 
				 // Previous
				 super(defObj,scene)
				 
				 // Lights
				 this.vLights = new Array
				 
				 // Occupied cells
				 this.occupiedCells = new Array
				 if(!this.scene.ready) this.scene.addEventListener(fScene.LOADCOMPLETE, onSceneLoaded)
				 else this.updateOccupiedCells()
				 
			}
			
			
			/*
			* Moves a character into a new position, ignoring collisions
			* 
			* @param x: New x coordinate
			*
			* @param y: New y coordinate
			*
			* @param z: New z coordinate
			*
			*/
			public function teleportTo(x:Number,y:Number,z:Number):void {
					var s:Boolean = this.solid
					this.solid = false
					this.moveTo(x,y,z)
					this.solid = s
			}


			/*
			* Characters can be moved
			* 
			* @param x: New x coordinate
			*
			* @param y: New y coordinate
			*
			* @param z: New z coordinate
			*
			*/
			/** @private */
			public override function moveTo(x:Number,y:Number,z:Number):void {
			   
				 // Last position
			   var lx:Number = this.x
			   var ly:Number = this.y
			   var lz:Number = this.z
			   
			   // Movement
			   var dx:Number = x-lx
			   var dy:Number = y-ly
			   var dz:Number = z-lz

			   if(dx==0 && dy==0 && dz==0) return
			   
			   try {
			   	
			   		// Set new coordinates			   
			   		this.x = x
			   		this.y = y
			   		this.z = z
			   		
 		 		 		var radius:Number = this.radius
 		 		 		var height:Number = this.height
         		
			   		this.top = this.z+height
         		
				 		// Check for collisions against other fRenderableElements.
				 		// collisionSolver.solveCharacterCollisions() tests a character's collisions at its current position, generates collision events (if any)
						// and moves the character into a valid position if necessary.
				 		if(this.solid) fCollisionSolver.solveCharacterCollisions(this,dx,dy,dz)
         		
			   		// Check if element moved into a different cell
			   		var cell:fCell = this.scene.translateToCell(this.x,this.y,this.z)
			   		
			   		if(cell!=this.cell || this.cell == null) {
				 		
				 				// Check for XML events in cell we leave
				 				if(this.cell!=null) {
				 					var k:Number = this.cell.events.length
				 					for(var i:Number=0;i<k;i++) {
				 						var evt:fCellEventInfo = this.cell.events[i]
				 						if(cell.events.indexOf(evt)<0) dispatchEvent(new fEventOut(fCharacter.EVENT_OUT,true,true,evt.name,evt.xml))
				 					}
				 				}
         		
				 				var lastCell:fCell = this.cell
				 				this.cell = cell
				 				this.updateOccupiedCells()
				 				dispatchEvent(new Event(fElement.NEWCELL))
				 				
				 				// Check for XML events in new cell
				 				if(this.cell!=null && lastCell!=null) {
				 					k = this.cell.events.length
				 					for(i=0;i<k;i++) {
				 						evt = this.cell.events[i]
				 						if(lastCell.events.indexOf(evt)<0) dispatchEvent(new fEventIn(fCharacter.EVENT_IN,true,true,evt.name,evt.xml))
				 					}
				 				}
         		
				 		}
				 		
				 		// Dispatch move event
				 		if(this.x!=lx || this.y!=ly || this.z!=lz) dispatchEvent(new fMoveEvent(fElement.MOVE,true,true,this.x-lx,this.y-ly,this.z-lz))
				 
			  } catch(e:Error) {
			  		
			  		trace(e)
			  		// This means we tried to move outside scene limits
			  		this.x = lx
			  		this.y = ly
			  		this.z = lz
			  		dispatchEvent(new fCollideEvent(fCharacter.COLLIDE,true,true,null))
			  		
			  }
				 
			}

			/** @private */
			public function disposeCharacter():void {

				for(var i in this.vLights) delete this.vLights[i]
				this.vLights = null
				this.disposeObject()
				
			}

			/** @private */
			public override function dispose():void {
				this.disposeCharacter()
			}		

			private function onSceneLoaded(evt:fProcessEvent):void {
				this.updateOccupiedCells()
			}

			// Assigns a new list of occupied cells to this character. Thnx to Alex Stone
			private function updateOccupiedCells():void {
				
				// Retrieve new list of occupied cells
				var theCell:fCell = this.scene.translateToCell(this.x,this.y,this.z)
				var cells:Array = new Array
				var cellRadius:Number = Math.ceil(this.radius / this.scene.gridSize)
				for(var i:Number = Math.max(theCell.i-cellRadius,0);i<theCell.i+cellRadius;i++) {
					for(var j:Number = Math.max(theCell.j-cellRadius, 0);j<theCell.j+cellRadius;j++) {
						for(var k:Number = Math.max(theCell.k-cellRadius, 0);k<theCell.k+cellRadius;k++) {
							var newCell:fCell = this.scene.getCellAt(i,j,k)
							if(newCell) {
								cells.push(newCell)
							}
						}
					}
				}
				
				// Clear out the old cells
				var filter:Function = function(item:*, index:int, array:Array) {
						if(item == this) {
							return false
						}
						return true
				}
				var forEach:Function  = function(item:*, index:int, array:Array) {
						item.charactersOccupying.filter(filter)
				}
				this.occupiedCells.forEach(forEach, this)
				
				// Update new cells
				this.occupiedCells = cells
				forEach = function(item:*, index:int, array:Array) {
						item.charactersOccupying.push(this)
				}
				this.occupiedCells.forEach(forEach, this)
			}
		
	}	
		
}