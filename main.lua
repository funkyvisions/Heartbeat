-- 
-- Project: heartbeat
--
-- Description: Use a beating heart as a life meter
-- Also shows how to change the pitch of a backing
-- track and keep the animation in synch with it
--
-- Version: 0.1
--
-- Copyright 2013 Doug Davies. All Rights Reserved.
-- MIT License. Feel free to use this however you want!
-- https://github.com/csddavies
-- http://www.funkyvisions.com
--

-- Constants

local _W = display.contentWidth
local _H = display.contentHeight
local ORIGINAL_SOUND_BPM = 116            -- original BPM for soundtrack
local BPM_INC = 0.4                       -- how fast to increment the BPM
local HEART_INC = 4.0                     -- how fast to increment/decrement the life meter
local HEART_HEIGHT = 100                  -- how heigh is the heart image
local HEART_WIDTH = 100                   -- how wide is the heart image

-- Hide the statusbar

display.setStatusBar( display.HiddenStatusBar )

-- Setup the background image

local background = display.newImageRect( "background.png", 600, 600 )
background.anchorX = 0.5; background.anchorY = 0.5;
background.x = _W/2 background.y = _H/2

-- Setup the spritesheet images

local heartSheetOptions = 
{
	frames = 
	{
		{
			x=0, y=0,
			width=HEART_WIDTH, height=HEART_HEIGHT
		},
		{
			x=125, y=0,
			width=HEART_WIDTH, height=HEART_HEIGHT
		}
	},
	sheetContentWidth = 225,
	sheetContentHeight = 100
}

-- Create the spritesheet

local heartSheet = graphics.newImageSheet( "hearts.png", heartSheetOptions )

-- Setup the heart background image ( white heart )

local heartBack = display.newImage( heartSheet, 2 )
heartBack.anchorX = 0.5; heartBack.anchorY = 0.5;
heartBack.x = _W/2 heartBack.y = _H/2

-- Setup the heart foreground image	( red heart )

local heartFront = display.newImage( heartSheet, 1 )
heartFront.anchorX = 0.5; heartFront.anchorY = 0.5;
heartFront.x = _W/2 heartFront.y = _H/2

-- Setup the mask for display the life meter

local heartPower = 100                    -- initial power on life meter

local mask = graphics.newMask( "mask.png" )
heartFront:setMask( mask )

-- Setup the heartbeat

local sound_bpm = ORIGINAL_SOUND_BPM      -- current BPM for soundtrack
local halfHeartRate                       -- how long it should take to animate half a heartbeat
local heartbeat2                          -- forward declaration for function (since function calls are cyclic)
local transitions = {}                    -- keep track of all the transitions in 1 object
local sounds = {}                         -- keep track of all the sounds in 1 object
local myChannel, mySource                 -- keep track of the OpenAL channel and source (for changing pitch)

-- Recalculate the life meter position/mask and increase the speed of the background track

local recalculate = function()
	
	heartPower = heartPower - HEART_INC
	if ( heartPower < 0 ) then
		heartPower = 0
		HEART_INC = HEART_INC * -1
	elseif ( heartPower > 100 ) then
		heartPower = 100
		HEART_INC = HEART_INC * -1
	end
	
	-- Increase the speed of the background track
	
	if ( sound_bpm < 180 ) then
		sound_bpm = sound_bpm + BPM_INC
	end
	
	-- Figure out where the mask for the top image (red heart) should go
	-- The mask will be centered over the object it is attached to
	-- So if maskY is 0 and our mask is half black and half white
	-- we would only see half of our red heart.  Since we want the heart
	-- to be completely visible when the power is 100, then we need to move
	-- the mid-way point up half the height of our heart
	
	heartFront.maskY = ( HEART_HEIGHT / 2 ) - heartPower

	-- Some more magic.  What is al???  Check out this blog entry
	-- http://www.coronalabs.com/blog/2011/07/27/the-secretundocumented-audio-apis-in-corona-sdk/
	-- This is changing the pitch of the background track (making it faster) each time the heart beats
	
	al.Source( mySource, al.PITCH, sound_bpm / ORIGINAL_SOUND_BPM )
	
	-- This calculation might be a bit confusing. It's just figuring out how long a heartbeat should take at
	-- the current BPM of the background track.  This should be in milliseconds.  We also divide it by 2 
	-- since we are scaling up and back down
	
	halfHeartRate = ( ( 60 / sound_bpm ) * 1000 ) / 2
	
end

-- Scale both images up to 100% and when done start scaling back down

local heartbeat1 = function()

	recalculate()	
	
	transitions.scaleUp1 = transition.to( heartBack, { time=halfHeartRate, xScale=1.0, yScale=1.0, onComplete=heartbeat2 } )
	transitions.scaleUp2 = transition.to( heartFront, { time=halfHeartRate, xScale=1.0, yScale=1.0 } )

end

-- Scale both images down to 50% and when done start scaling back up

heartbeat2 = function()

	transitions.scaleDown1 = transition.to( heartBack, { time=halfHeartRate, xScale=0.5, yScale=0.5, onComplete=heartbeat1 } )
	transitions.scaleDown2 = transition.to( heartFront, { time=halfHeartRate, xScale=0.5, yScale=0.5 } )
	
end
	
-- Rotate background

local rotateBackground = function()
		
	background:rotate(1)

end

-- Start the background rotating

timer.performWithDelay( 10, rotateBackground, 0 )

-- Start the background track
-- Thanks to Kevin MacLeod at incompetech.com for the background track "Pixel Peeker Polka"

sounds.bgSound = audio.loadStream( "background.mp3" )
audio.reserveChannels(1)
myChannel, mySource = audio.play( sounds.bgSound, { channel=1, loops=-1 } )	

-- Start the heartbeat

heartbeat1()
