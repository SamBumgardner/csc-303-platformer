package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.addons.editors.ogmo.FlxOgmoLoader;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.math.FlxPoint;


class PlayState extends FlxState
{
	public var GRAVITY(default, never):Float = 600;

	private var map:FlxTilemap;
	private var _map:FlxOgmoLoader;
	private var _mGround:FlxTilemap;
	public var player:Player;
	private var flagpole:FlagPole;
	private var platform:Platforms;

	private var trap:Trap;
 	private var coins:FlxTypedGroup<Coin> = new FlxTypedGroup<Coin>();
	private var flag_x_loc:Int = 37;
	private var sword:Sword;
	private var flag_y_loc:Int = 11;

	public static var hud:HeadsUpDisplay;
	public var _pUp:FlxTypedGroup<PowerUp> = new FlxTypedGroup<PowerUp>();
	public var sprites:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();
	public var trapGroup:FlxTypedGroup<Trap> = new FlxTypedGroup<Trap>();
	public var fireBarGroup:FlxTypedGroup<FlxTypedGroup<Trap>> = new FlxTypedGroup<FlxTypedGroup<Trap>>();
	private var blockGroup:FlxTypedGroup<Block> = new FlxTypedGroup<Block>();
	private var platformGroup:FlxTypedGroup<Platforms> = new FlxTypedGroup<Platforms>();
	private var mushroom:PowerupMushroom;
	private var fireflower:FireFlower;
	
	//music
	private var music:ReactiveBGPlatforming;
	
	// Enemies
	private var dtmEnemy:DontTouchMe;
	private var dtmGroup:FlxTypedGroup<DontTouchMe> = new FlxTypedGroup<DontTouchMe>();
	private var turEnemy:Turtle;
	private var turGroup:FlxTypedGroup<Turtle> = new FlxTypedGroup<Turtle>();
	private var flyingEnemy:FlyingTurtle;
	private var flyingGroup:FlxTypedGroup<FlyingTurtle> = new FlxTypedGroup<FlyingTurtle>();
	private var sentry:Sentry;
	private var bullets:FlxTypedGroup<Bullet> = new FlxTypedGroup<Bullet>(20);
	
	override public function create():Void
	{

		hud = new HeadsUpDisplay(0, 0, "MARIO");
		music = setUpBackgroundMusic();
		//Loading the map created in Ogmo Editor
		_map = new FlxOgmoLoader(AssetPaths.CSC303_Level__oel);
		_mGround = _map.loadTilemap(AssetPaths.overworld__png, 16, 16, "Overworld");
		_mGround.follow();
		_mGround.setTileProperties(2, FlxObject.ANY);
		add(_mGround);
		_map.loadEntities(placeEntities, "Entities");

		//Camera will follow player as they get closer to edges of screen
		FlxG.camera.setScrollBoundsRect(0, 0, _mGround.width, _mGround.height);
		FlxG.worldBounds.set(0, 0, _mGround.width, _mGround.height);
		FlxG.camera.follow(player, LOCKON, 2);
		
		//Add Groups to map
		add(blockGroup);
		add(dtmGroup);
		add(turGroup);
		add(flyingGroup);
		add(platformGroup);
		add(trapGroup);
		add(fireBarGroup);
		add(bullets);
		add(_pUp);
		
		hud = new HeadsUpDisplay(0, 0, "MARIO");
		add(hud);
		music.play();
	}
	
	/**
	 * This function reads the Ogmo Level file and places the different entities based on position and
	 * type in Ogmo Editor
	 * @param	entityName Object name placed in Ogmo Editor
	 * @param	entityData Any data associated with object. Mostly just X and Y coords
	 */
	private function placeEntities(entityName:String, entityData:Xml):Void
	{
		var x:Int = Std.parseInt(entityData.get("x"));
		var y:Int = Std.parseInt(entityData.get("y"));
		
		//Logic for adding adding the player
		if (entityName == "Player")
		{
			player = new Player(x, y);
			add(player);
			sprites.add(player);
		}
		
		//Logic for adding the DontTouchMes
		else if (entityName == "DontTouchMe")
		{
			dtmEnemy = new DontTouchMe(x, y);
			dtmEnemy.turnAround();
			sprites.add(dtmGroup.add(dtmEnemy));
		}
		
		//Logic for adding the sentries
		else if (entityName == "Sentry")
		{
			sentry = new Sentry(x, y, bullets, player);
			add(sentry);
			sprites.add(sentry);
		}
		
		//Logic for adding the Blocks
		else if (entityName == "Block")
		{
			var type:Int = Std.parseInt(entityData.get("BlockType"));
			if (type == 2)
			{
				blockGroup.add(new ItemBlock(x, y, "Fake Item"));
			}
			else if (type == 3)
			{
				blockGroup.add(new FallingBlock(x, y, 200));
			}
			else
			{
				blockGroup.add(new Block(x, y, true));
			}
		}
		
		//Logic for adding the ending Flagpole
		else if (entityName == "Flagpole")
		{
			flagpole = new FlagPole(x, y);
			add(flagpole);
			add(flagpole.flag);
		}
		
		//Logic for adding Lava tiles
		else if (entityName == "Lava")
		{
			trap = new Trap(x, y);
			trapGroup.add(trap);
		}
		
		//Logic for adding Fire Bars
		else if (entityName == "FireBar")
		{
			trap = new Trap(x, y);
			trap.buildTrap(trap);
			trap.placeTrap(trap._grpBarTrap, x, y);
			fireBarGroup.add(trap._grpBarTrap);
		}
		
		//Logic for adding platforms
		else if (entityName == "Platform")
		{
			var type:String = entityData.get("Type");
			if (type == "Platform")
			{
				platform =  new Platforms(x, y, 4, 0, 0, 0, 0, player);
				platform.immovable = platform.solid = true;
				platform.allowCollisions = FlxObject.UP;
				platform.inContact = false;
				platformGroup.add(platform);
			}
			
			else if (type == "Elevator")
			{
				platform =  new Platforms(x, y, 4, 0, 0, 50, 50, player);
				platform.immovable = platform.solid = true;
				platform.allowCollisions = FlxObject.UP;
				platform.inContact = false;
				platformGroup.add(platform);
			}
			
			else if (type == "Walkway")
			{
				platform =  new Platforms(x, y, 4, 50, 50, 0, 0, player);
				platform.immovable = platform.solid = true;
				platform.allowCollisions = FlxObject.UP;
				platform.inContact = false;	
				platformGroup.add(platform);
			}
		}
		
		//Logic for adding Coins
		else if (entityName == "Coin")
		{
			var color:Int = Std.parseInt(entityData.get("Color"));
			if (color == 2)
			{
				coins.add(new Coin(x, y, "red"));
			}
			else
			{
				coins.add(new Coin(x, y, "yellow"));
			}
			add(coins);
		}
		
		//Logic for adding Turtle/FlyingTurtles
		else if (entityName == "Turtle")
		{
			var wings:String = entityData.get("Wings");
			if (wings == "True")
			{
				flyingEnemy = new FlyingTurtle(x, y);
				sprites.add(flyingGroup.add(flyingEnemy));
			}
			else
			{
				turEnemy = new Turtle(x, y);
				sprites.add(turGroup.add(turEnemy));
			}
			
		}
		
		//Logic for adding the powerups
		else if (entityName == "PowerUp")
		{
			var type:String = entityData.get("Type");
			if (type == "Mushroom") 
			{
				mushroom = new PowerupMushroom(x, y);
				sprites.add(_pUp.add(mushroom));	
			}
			
			else if (type == "FireFlower")
			{
				fireflower = new FireFlower(x, y);
				sprites.add(_pUp.add(fireflower));
			}
			
			else if (type == "Sword")
			{
				sword = new Sword(x, y, AssetPaths.sword__png);
				add(sword);
				add(sword.hitbox);
				add(sword.hitbox.hitboxFrames);
				add(sword.hitbox.Animation);
			}
		}
		
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		//platform.platformUpdate(elapsed, sprites, platform);

		hud.update(elapsed);

		// Add overlap logic
		FlxG.overlap(player, coins, collectCoin);
		FlxG.overlap(player, mushroom, mushroom.getPowerup);
		FlxG.overlap(player, fireflower, fireflower.getPowerup);  
		FlxG.overlap(blockGroup, player.hitBoxComponents, function(b:Block, obj:FlxObject) {b.onTouch(obj, player);} );
		FlxG.overlap(player, dtmGroup, DontTouchMe.playerHitResolve);
		FlxG.overlap(dtmGroup, turGroup, Turtle.enemyHitResolve);
		FlxG.overlap(player, turGroup, Turtle.playerHitResolve);
		FlxG.overlap(player, flyingGroup, Turtle.playerHitResolve);
		FlxG.overlap(player, bullets, bulletHitPlayer);
		FlxG.overlap(player, trapGroup, Trap.playerTrapResolve);
		FlxG.overlap(player, fireBarGroup, Trap.playerTrapResolve);
		FlxG.overlap(player, sword, player.pickup_item);
		FlxG.overlap(sword.hitbox.hitboxFrames, dtmGroup, sword.hit_enemy);
		
		// Add collision logic
		FlxG.collide(platformGroup, sprites);
		FlxG.collide(blockGroup, sprites);
		FlxG.collide(_mGround, bullets);
		FlxG.collide(_mGround, sprites);

		if(player.equipped_item != sword){
			FlxG.collide(_mGround, sword);
			FlxG.collide(blockGroup, sword);
		}
		decideMusicMix();
   		if (!flagpole.level_over()){
			FlxG.overlap(player, flagpole, flagpole.win_animation);
		} else {
			//kill all enemies and bullets on screen. Deactivate cannons
			bullets.forEachAlive(function(bullet:Bullet){bullet.kill(); });
			dtmGroup.forEachAlive(function(dtm:DontTouchMe){ dtm.kill(); });
			turGroup.forEachAlive(function(tur:Turtle){ tur.kill(); });
			flyingGroup.forEachAlive(function(fly:Turtle){ fly.kill(); });
			sentry.active = false;
			// time (seconds), callback, loops
			new FlxTimer().start(10, resetLevel, 1);
		}

	}
	
		/**
	 * bulletHitPlayer
	 * Logic for when a bullet overlaps with a player
	 * 
	 * @param	player	A player's character
	 * @param	bullet	A bullet sprite
	 */
	public function bulletHitPlayer(player:Player, bullet:FlxObject):Void
	{
		if (!player.star) {
			player.kill();
		}
		
		bullet.kill();
	}

  
  	/**
	 * Updates HUD when player collects a coin
	 * @param	p Player object collecting coin
	 * @param	c Coin object getting collected
	 */
	private function collectCoin(p:Player, c:Coin):Void
	{
		p.scoreCoin(c.coinColor);
		hud.handleScoreUpdate(p.scoreTotal);
		hud.handleCoinsUpdate(p.coinCount);
		c.kill();
	}

	public function resetLevel(?Timer:FlxTimer):Void
	{
		FlxG.resetState();
	}
	    private function setUpBackgroundMusic():ReactiveBGPlatforming
    {
        //Set up bass track and mixes
        #if debug
            trace("setting up bass track");
        #end
        var bassTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneBass"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.Bass);
        bassTrack.addMix("Normal", 0.9, 0.5);
        bassTrack.addMix("RunningFast", 0.97, 0.7);
        bassTrack.addMix("NearTurret", 0.2, 0.5);
        bassTrack.addMix("YouWin", 1, 1);
        
        //Set up effects track and mixes
        #if debug
            trace("setting up effects track");
        #end
        var effectsTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneEffects"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.Effects);
        effectsTrack.addMix("Normal", 0.9, 0.5);
        effectsTrack.addMix("RunningFast", .9, 0.5);
        effectsTrack.addMix("NearTurret", 0.2, 0.5);
        effectsTrack.addMix("YouWin", 0, 0.5);
        
        //Set up GenesisKit track and mixes
        #if debug
            trace("setting up genesis track");
        #end
        var genesisKitTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneGenesisKit"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.GeneralPercussion);
        genesisKitTrack.addMix("Normal", 0, 0.5);
        genesisKitTrack.addMix("RunningFast", 1, 0.5);
        genesisKitTrack.addMix("NearTurret", 0, 0.5);
        genesisKitTrack.addMix("YouWin", 1, 0.5);
        
        //Set up MetalKit track and mixes
        #if debug
            trace("setting up metalKit track");
        #end
        var metalKitTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneMetalKit"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.GeneralPercussion);
        metalKitTrack.addMix("Normal", .9, 0.5);
        metalKitTrack.addMix("RunningFast", 0.4, 0.5);
        metalKitTrack.addMix("NearTurret", 0.5, 0.5);
        metalKitTrack.addMix("YouWin", 0, 0.5);
        
        //Set up Lead track and mixes
        #if debug
            trace("setting up lead track");
        #end
        var leadTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneLead"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.Lead);
        leadTrack.addMix("Normal", .8, 0.5);
        leadTrack.addMix("RunningFast", 0.99, 0.5);
        leadTrack.addMix("NearTurret", 0.5, 0.5);
        leadTrack.addMix("YouWin", 0, 0.5);
        
        //Set up Rhythm track and mixes
        #if debug
            trace("setting up rhythm track");
        #end
        var rhythmTrack:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneRhythm"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.Rhythm);
        rhythmTrack.addMix("Normal", 1, 0.5);
        rhythmTrack.addMix("RunningFast", 0.99, 0.3);
        rhythmTrack.addMix("NearTurret", 0.7, 0.5);
        rhythmTrack.addMix("YouWin", 0.4, 0.0);
        
        //Set up Rhythm 2 track and mixes
        #if debug
            trace("setting up rhythm2 track");
        #end
        var rhythm2Track:ReactiveBGMusicTrack = new ReactiveBGMusicTrack(FlxAssets.getSound("assets/music/FlyingBatteryZoneRhythm2"), 0, 0, 1.595, 107.205, false, ReactiveBGMusicTrackType.Rhythm);
        rhythm2Track.addMix("Normal", 1, 0.5);
        rhythm2Track.addMix("RunningFast", 0.99, 0.3);
        rhythm2Track.addMix("NearTurret", 0.5, 0.5);
        rhythm2Track.addMix("YouWin", 0.5, 0.0);
        
        
        //set up track object
        var song:ReactiveBGPlatforming = new ReactiveBGPlatforming(false);
        song.addTrack(bassTrack);
        song.addTrack(effectsTrack);
        song.addTrack(genesisKitTrack);
        song.addTrack(metalKitTrack);
        song.addTrack(rhythmTrack);
        song.addTrack(rhythm2Track);
        song.setMix("Normal");
        return song;
    }
    
    public function decideMusicMix(){
            if (flagpole.level_over()){
                if( music.currentMix != "YouWin")
                music.youWin();
            }
            else{
                if (music.currentMix != "RunningFast"){
					if (player.maxVelocity.x== player.runSpeed && Math.abs(player.velocity.x) >= player.walkSpeed){
                        music.runningFast();
                    }
                }
                if (music.currentMix != "Normal"){
                    if (Math.abs(player.velocity.x) <= player.walkSpeed){
                        music.normal();

					}

				}
		}
	} 
    
    override public function destroy(){
        super.destroy();
        music.destroy();
    }
}