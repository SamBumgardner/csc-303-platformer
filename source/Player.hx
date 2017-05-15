package;

import flixel.util.FlxTimer;
import states.FSM;
import states.BaseState;
import states.PlayerGroundState;
import states.PlayerAirState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup;

/**
 * ...
 * @author Sam Bumgardner
 */
 class Player extends FlxSprite
 {
  public var brain:FSM;

	public var xAccel:Float = 400;
	public var xMaxSpeed(default, set):Float;

	public var walkSpeed:Float = 100;
	public var runSpeed:Float = 200;

	public var xSlowdown:Float = 600;
	
	public var coinCount:Int = 0;
	public var scoreTotal:Int = 0;
	
	public var weilding:Bool = false;
	public var equipped_item:Item;
	public var attacking:Bool = false;

  public var hitBoxComponents:FlxTypedGroup<FlxObject>;
  public var topBox:FlxObject;
  public var btmBox:FlxObject;

  private var hitBoxHeight:Int = 3;
  private var hitBoxWidthOffset:Int = 4;  //how much narrower the hitboxes are than the player

  
  // Variable used for overlap/collide logic with enemies. Checks if player is holding the star powerup.
  public var star:Bool = false;
  
  
	/**
	 * Intializer
	 *
	 * @param	X	Starting x coordinate
	 * @param	Y	Starting y coordinate
	 * @param	SimpleGraphic	Non-animating graphic. Nothing fancy (optional)
	 */
	public function new(?X:Float=0, ?Y:Float=0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);

		// Initializes a basic graphic for the player
		makeGraphic(32, 32, FlxColor.ORANGE);

		// Initialize gravity. Assumes the currentState has GRAVITY property.
		acceleration.y = (cast FlxG.state).GRAVITY;
		maxVelocity.y = acceleration.y;

		// Sets the starting x max velocity.
		xMaxSpeed = walkSpeed;

		// Initialize the finite-state machine with initial state
		brain = new FSM( new PlayerAirState() );

    // Multiple hitbox support
    hitBoxComponents = new FlxTypedGroup<FlxObject>(2);
    topBox = new FlxObject(X + hitBoxWidthOffset, Y, width - hitBoxWidthOffset*2, hitBoxHeight);
    btmBox = new FlxObject(X + hitBoxWidthOffset, Y + height - hitBoxHeight, width - hitBoxWidthOffset*2, hitBoxHeight);
    hitBoxComponents.add(topBox);
    hitBoxComponents.add(btmBox);
	}

	/**
	 * Setter for the xMaxSpeed variable.
	 * Updates maxVelocity's x component to match the new value.
	 *
	 * @param	newXSpeed	The new max speed in the x direction.
	 * @return	The new value contained in xMaxSpeed.
	 */
	public function set_xMaxSpeed(newXSpeed:Float):Float
	{
		maxVelocity.x = newXSpeed;
		return xMaxSpeed = newXSpeed;
	}

	/**
	 * Update function.
	 *
	 * Responsible for calling the update method of the current state and
   * switching states if a new one is returned.
	 *
	 * @param	elapsed	Time passed since last call to update in seconds.
	 */
	public override function update(elapsed:Float):Void
	{
		brain.update(this);
		super.update(elapsed);
		updateHitBoxes();
	}

  /**
   * Convenience method for polling for horizontal movement as
   * most of the player states need to take it into account
   *
   * @return scalar value of the players next horizontal move
   */
  public function pollForHorizontalMove():Int
  {
    var step:Int = 0;

    if (FlxG.keys.anyPressed([FlxKey.LEFT, FlxKey.A]))
    {
		facing = FlxObject.LEFT;
		step--;
    }
    if (FlxG.keys.anyPressed([FlxKey.RIGHT, FlxKey.D]))
    {
		facing = FlxObject.RIGHT;
		step++;
    }
	//Attack key while weilding an item
	if (FlxG.keys.anyPressed([FlxKey.SPACE]))
	{
		if (weilding && !attacking){ 
			attacking = true;
			equipped_item.attack_state();
		}
	}
	//'g' keypress to drop the currently equipped item
	if (FlxG.keys.anyPressed([FlxKey.G]))
	{
		if(weilding && !attacking){
			dropCurrentEquip();
		}
	}

    return step;
  }
  

  /**
   * Convenience method for checking if a jump is being requested.
   *
   * @return boolean value for if the jump key is being held
   */
  public function isJumping():Bool
  {
    return FlxG.keys.anyPressed([FlxKey.X, FlxKey.SLASH]);
  }

  /**
   * Convenience method for checking if the player is currently touching a
   * surface from above the surface.
   *
   * @return boolean value for if the player is touching a surface from above
   *         the surface
   */
  public function isOnGround():Bool
  {
    return isTouching(FlxObject.DOWN);
  }

  /**
   * Convenience method for checking if the player is running
   *
   * @ return boolean value for if the run key is eing held
   */
  public function isRunning():Bool
  {
    return FlxG.keys.anyPressed([FlxKey.Z]);
  }
   
  /**
   * When the coin gets collected, the update function in the playstate will call collectCoin.
   * collectCoin will then call this function based on the color of the coin collected.
   * Depending on the coin collected, then the respective total will be incremented.
   * @param	color The color of the coin being collected
   */
  public function scoreCoin(color:FlxColor):Void 
  {
	if (color == FlxColor.RED) {
		coinCount += 5;
		scoreTotal += 500;
	}
	if (color == FlxColor.YELLOW) {
		coinCount += 1;
		scoreTotal += 100;
	}
  }
    
  /**
   * This method is called during every Player update cycle
   * to keep the hitboxes in the same position relative to the player
   */
  private function updateHitBoxes():Void
  {
    topBox.x = btmBox.x = x + hitBoxWidthOffset;
    topBox.y = y;
    btmBox.y = y + height - hitBoxHeight;
  }
  
  //Override player.kill to drop any weilded items
  override public function kill():Void 
  {
	  if (weilding){
		dropCurrentEquip();
	  }
	  super.kill();
	  new FlxTimer().start(2, resetLevel, 1); //This helps speed things up for debugging
  }
  
  private function resetLevel(Timer:FlxTimer):Void
	{
		FlxG.resetState();
	}

	/**
	 * Method to pickup items. If the player is not holding anything
	 * and the item is weildable, equip the item. Otherwise add it to his bag.
	 * If player is not weilding anything and the item is weildable
	 *	set weilding to true and equip
	*/
	public function pickup_item(player:Player, item:Item):Void {
		if (!weilding && item.weildable){
			if(!item.justDropped){
				weilding = true;
				equipped_item = item;
				item.equip(this);
			}
		} 
	}

	/**
	 * Method to drop the currently equipped item
	 * 
	 */
	private function dropCurrentEquip(){
		equipped_item.drop_item();
		weilding = false;
		equipped_item = null;
	}
}
