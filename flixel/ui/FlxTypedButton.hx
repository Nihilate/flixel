package flixel.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.system.input.touch.FlxTouch;
import flixel.util.FlxPoint;

#if !FLX_NO_SOUND_SYSTEM
import flixel.system.FlxSound;
import flash.media.Sound;
#end

/**
 * A simple button class that calls a function when clicked by the mouse.
 */
class FlxTypedButton<T:FlxSprite> extends FlxSprite
{
	/**
	 * The label that appears on the button. Can be any FlxSprite.
	 */
	public var label:T;
	/**
	 * Controls the offset (from top left) of the text from the button.
	 */
	public var labelOffset(default, null):FlxPoint;
	/**
	 * Shows the current state of the button, either <code>FlxButton.NORMAL</code>, 
	 * <code>FlxButton.HIGHLIGHT</code> or <code>FlxButton.PRESSED</code>.
	 */
	public var status:Int = FlxButton.NORMAL;
	/**
	 * The properties of this button's onUp event (callback function, sound).
	 */
	public var onUp(default, null):FlxButtonEvent;
	/**
	 * The properties of this button's onDown event (callback function, sound).
	 */
	public var onDown(default, null):FlxButtonEvent;
	/**
	 * The properties of this button's onOver event (callback function, sound).
	 */
	public var onOver(default, null):FlxButtonEvent;
	/**
	 * The properties of this button's onOut event (callback function, sound).
	 */
	public var onOut(default, null):FlxButtonEvent;

	/**
	 * The touch currently pressing this button, if none, it's null. Needed to check for its release.
	 */
	private var _pressedTouch:FlxTouch = null;
	/**
	 * Whether this button is currently being pressed by the mouse. Needed to check for its release.
	 */
	private var _pressedMouse:Bool = false;
	
	/**
	 * Creates a new <code>FlxTypedButton</code> object with a gray background.
	 * 
	 * @param	X				The X position of the button.
	 * @param	Y				The Y position of the button.
	 * @param	Label			The text that you want to appear on the button.
	 * @param	OnClick			The function to call whenever the button is clicked.
	 * @param	OnClickParams	The params to call the onClick function with
	 */
	public function new(X:Float = 0, Y:Float = 0, ?Label:String, ?OnClick:Dynamic, ?OnClickParams:Array<Dynamic>)
	{
		super(X, Y);
		
		loadGraphic(FlxAssets.IMG_BUTTON, true, false, 80, 20);
		
		onUp = new FlxButtonEvent();
		onDown = new FlxButtonEvent(OnClick, OnClickParams);
		onOver = new FlxButtonEvent();
		onOut = new FlxButtonEvent();
		
		labelOffset = new FlxPoint();
		
		// Since this is a UI element, the default scrollFactor is (0, 0)
		scrollFactor.set();
	}
	
	/**
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void
	{
		FlxG.safeDestroy(label);
		FlxG.safeDestroy(labelOffset);
		
		FlxG.safeDestroy(onUp);
		FlxG.safeDestroy(onDown);
		FlxG.safeDestroy(onOver);
		FlxG.safeDestroy(onOut);
		
		_pressedTouch = null;
		
		super.destroy();
	}
	
	/**
	 * Called by the game loop automatically, handles mouseover and click detection.
	 */
	override public function update():Void
	{
		super.update();
		
		// Update the button, but only if at least either mouse or touches are enabled
		#if (!FLX_NO_MOUSE || !FLX_NO_TOUCH)
		updateButton();
		#end
		
		// Label positioning
		if (label != null)
		{
			label.x = x;
			label.y = y;
			
			label.x += labelOffset.x;
			label.y += labelOffset.y;
			
			label.scrollFactor = scrollFactor;
		}
		
		// Pick the appropriate animation frame
		
		var nextFrame:Int = status;
		
		// "Highlight" doesn't make much sense on mobile devices / touchscreens
		#if mobile
			if (nextFrame == FlxButton.HIGHLIGHT) {
				nextFrame = FlxButton.NORMAL;
			}
		#end
		
		frame = framesData.frames[nextFrame];
	}
	
	/**
	 * Basic button update logic - searches for overlaps with touches and
	 * the mouse cursor and calls <code>updateStatus()</code>
	 */
	private function updateButton():Void
	{
		if (cameras == null) {
			cameras = FlxG.cameras.list;
		}
		
		// We're looking for any touch / mouse overlaps with this button
		var overlapFound = false;
		
		// Have a look at all cameras
		for (camera in cameras)
		{
			#if !FLX_NO_MOUSE
				FlxG.mouse.getWorldPosition(camera, _point);
				
				if (overlapsPoint(_point, true, camera))
				{
					overlapFound = true;
					updateStatus(true, FlxG.mouse.justPressed, FlxG.mouse.pressed);
					break;
				}
			#end
			
			#if !FLX_NO_TOUCH
				for (touch in FlxG.touches.list)
				{
					touch.getWorldPosition(camera, _point);
					
					if (overlapsPoint(_point, true, camera))
					{
						overlapFound = true;
						updateStatus(true, touch.justPressed, touch.pressed, touch);
						break;
					}
				}
			#end
		}
		
		if (!overlapFound)
		{
			updateStatus(false, false, false);
		}
	}
	
	/**
	 * Updates the button status by calling the respective event handler function.
	 * 
	 * @param	Overlap			Whether there was any overlap with this button
	 * @param	JustPressed		Whether the input (touch or mouse) was just pressed
	 * @param	Pressed			Whether the input (touch or mouse) is pressed
	 * @param	Touch			A FlxTouch, if this was called from an overlap with one
	 */
	private function updateStatus(Overlap:Bool, JustPressed:Bool, Pressed:Bool, ?Touch:FlxTouch):Void
	{
		if (Overlap)
		{
			if (JustPressed)
			{
				_pressedTouch = Touch;
				if (Touch == null) {
					_pressedMouse = true;
				}
				onDownHandler();
			}
			else if (status == FlxButton.NORMAL)
			{
				// Allow "swiping" to press a button (dragging it over the button while pressed)
				if (Pressed) {
					onDownHandler();
				}
				else {
					onOverHandler();
				}
			}
		}
		else if (status != FlxButton.NORMAL)
		{
			onOutHandler();
		}
		
		// onUp
		if ((_pressedTouch != null) && (_pressedTouch.justReleased))
		{
			onUpHandler();
		}
		else if ((_pressedMouse) && (FlxG.mouse.justReleased))
		{
			onUpHandler();
		}
	}
	
	/**
	 * Just draws the button graphic and text label to the screen.
	 */
	override public function draw():Void
	{
		super.draw();
		
		if (label != null)
		{
			label.cameras = cameras;
			label.draw();
		}
	}
	
	#if !FLX_NO_DEBUG
	/**
	 * Helper function to draw the debug graphic for the label as well.
	 */
	override public function drawDebug():Void 
	{
		super.drawDebug();
		
		if (label != null) {
			label.drawDebug();
		}
	}
	#end
	
	/**
	 * Internal function that handles the onUp event.
	 */
	inline private function onUpHandler():Void
	{
		onUp.fire();
		_pressedTouch = null;
		_pressedMouse = false;
		status = FlxButton.NORMAL;
		if (label != null) {
			label.alpha = 0.8;
		}
	}
	
	/**
	 * Internal function that handles the onDown event.
	 */
	inline private function onDownHandler():Void
	{
		onDown.fire();
		status = FlxButton.PRESSED;
		if (label != null) {
			label.alpha = 0.5;
			label.y++;
		}
	}
	
	/**
	 * Internal function that handles the onOver event.
	 */
	inline private function onOverHandler():Void
	{
		onOver.fire();
		status = FlxButton.HIGHLIGHT;
		if (label != null) {
			label.alpha = 1.0;
		}
	}
	
	/**
	 * Internal function that handles the onOut event.
	 */
	inline private function onOutHandler():Void
	{
		onOut.fire();
		status = FlxButton.NORMAL;
		if (label != null) {
			label.alpha = 0.8;
		}	
	}
}

/** 
 * Helper function for <code>FlxButton</code> which handles its events.
 */ 
private class FlxButtonEvent implements IDestroyable
{
	/**
	 * The callback function to call when this even fires.
	 */
	public var callback:Dynamic;
	/**
	 * The callback function parameters.
	 */
	public var callbackParams:Array<Dynamic>;
	
	#if !FLX_NO_SOUND_SYSTEM
	/**
	 * The sound to play when this event fires.
	 */
	public var sound:FlxSound;
	#end
	
	/**
	 * Creates a new <code>FlxButtonEvent</code>
	 * 
	 * @param	Callback		The callback function to call when this even fires.
	 * @param	CallbackParams	The callback function parameters.
	 * @param	sound			The sound to play when this event fires.
	 */
	public function new(?Callback:Dynamic, ?CallbackParams:Dynamic, ?sound:FlxSound)
	{
		callback = Callback;
		callbackParams = CallbackParams;
		
		#if !FLX_NO_SOUND_SYSTEM
			this.sound = sound;
		#end
	}
	
	/**
	 * Cleans up memory.
	 */
	inline public function destroy():Void
	{
		callback = null;
		callbackParams = null;
		#if !FLX_NO_SOUND_SYSTEM
			FlxG.safeDestroy(sound);
		#end
	}
	
	/**
	 * Fires this event (calls the callback and plays the sound)
	 */
	inline public function fire():Void
	{
		if (callback != null) 
		{
			if (callbackParams == null) {
				callbackParams = [];
			}
			Reflect.callMethod(null, callback, callbackParams);
		}
		
		#if !FLX_NO_SOUND_SYSTEM
			if (sound != null) {
				sound.play(true);
			}
		#end
	}
	
	/**
	 * Sets the callback for this button event.
	 * 
	 * @param	Callback		The callback function to call when this even fires.
	 * @param	CallbackParams	The callback function parameters.
	 */
	inline public function setCallback(Callback:Dynamic, ?CallbackParams:Array<Dynamic>):Void
	{
		callback = Callback;
		callbackParams = CallbackParams;
	}
}