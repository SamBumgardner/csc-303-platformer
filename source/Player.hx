package;

import flixel.util.FlxTimer;
import haxe.Timer;
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
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.effects.FlxFlicker;

/**
 * ...
 * @author Sam Bumgardner
 */
 class Player extends FlxSprite
 {
	public var brain:FSM;
	public var player:FlxSprite;

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
  private var controller:ReconfigurableController;
  public var canTakeDamage:Bool = true;
  

  // Variable used for overlap/collide logic with enemies. Checks if player is holding the star powerup.
	public var star:Bool = false;
	
	public var invincibleTimer:Float = 0;
	public var hurtInvincibility:Float = 2;
	public var hasFlower:Bool = false;
	public var tween:FlxTween;
	public var flicker:FlxFlicker;
  
  
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
		controller = new ReconfigurableController();
		// Initializes a basic graphic for the player
		player = makeGraphic(32, 32, FlxColor.ORANGE);

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

	FlxG.state.add(hitBoxComponents);
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
		// Implements an invincibilty timer to make the player temprarily invulnerable for a time after being hurt
		if (invincibleTimer > 0)
		{
			// If there is still time left on the timer, continue counting down
			invincibleTimer -= elapsed;
		}
		else if (invincibleTimer <= 0)
		{
			// When the timer runs out, the player is able to take damage again
			invincibleTimer = 0;
			canTakeDamage = true;
		}
		
		if (hasFlower)
		{
			if (FlxG.keys.anyJustPressed([FlxKey.SPACE, FlxKey.ENTER]))
			{
				new Fireball(x, y);
				trace("Fire");
			}
		}
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

    if (FlxG.keys.anyPressed([FlxKey.LEFT, FlxKey.A]) || controller.isLeft() )
    {
		facing = FlxObject.LEFT;
		step--;
    }
    if (FlxG.keys.anyPressed([FlxKey.RIGHT, FlxKey.D]) || controller.isRight() )
    {
		facing = FlxObject.RIGHT;
		step++;
    }
	//Attack key while weilding an item
	if (FlxG.keys.anyJustReleased([FlxKey.SPACE]))
	{
		if (weilding && !attacking){
			attacking = true;
			equipped_item.attack();
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
    return FlxG.keys.anyPressed([FlxKey.X, FlxKey.SLASH]) || controller.isJumping();
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
    return FlxG.keys.anyPressed([FlxKey.Z]) || controller.isRunning();

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
  
  /**
   * Overrides the parent "hurt" function to use the implement invincibilty timer
   * @param	damage - the amount of damage dealth by whatever enemy or object caused the damamge
   */
  override public function hurt(damage:Float)
  {
	  var options:TweenOptions = { type: FlxTween.PINGPONG};
	  if (canTakeDamage)
	  {
		  // Damages player
		 super.hurt(damage);
		 // Makes player invulnerable
		 canTakeDamage = false;
		 // Starts the invicibility timer
		 invincibleTimer = hurtInvincibility;
		FlxFlicker.flicker(player, 2, .1);
	  }  
  } 

  //Override player.kill to drop any weilded items
  override public function kill():Void 
  {
	  if (weilding){
		dropCurrentEquip();
	  }
	  super.kill();
	  new FlxTimer().start(2, (cast (FlxG.state, PlayState)).resetLevel, 1); //This helps speed things up for debugging
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
	private function dropCurrentEquip():Void{
		equipped_item.drop_item();
		weilding = false;
		equipped_item = null;
	}
	
	/**
	 * Functionality for keypress event to attack if an item is currently being 
	 * weilded. Disables user input to put them in the 'attacking state', but 
	 * still keeps their current velocity and acceleration
	 */
	public function attack_state():Bool{
		if(!attacking){
			return true;
		} else {
			return false;
		}
	}

  /**
   * Causes the player to bounce upwards
   */
  public function bounce():Void
  {
	  velocity.y = -270;
  }
 }

