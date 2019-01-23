PROGRAM_NAME='Panasonic_Cameras'

(***********************************************************)
(*  FILE CREATED ON: 08/02/2018  AT: 09:11:39              *)
(***********************************************************)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/02/2018  AT: 14:30:06        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

dvCamFront =			0:2:0
dvCamRearLeft =			0:3:0
dvCamRearRight =		0:4:0

dvTP_Main =			10001:1:0 
dvBlackMagic =			5001:1:0 //Black Magic (Smart VideoHub 20x20)

vdvCamFront =			41001:1:0 //Virtual Comm
vdvCamRearLeft =		41011:1:0 //Virtual Comm
vdvCamRearRight =		41021:1:0 //Virtual Comm

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//BlackMagic Video Routing...
CAMERA_ONE			= 1 //Rear Left
CAMERA_TWO			= 0
CAMERA_THREE			= 2

DES_EXTRON      = 6
DES_EPIPHAN     = 7

TILT_UP				= 132
TILT_DN				= 133
PAN_LEFT				= 134
PAN_RIGHT				= 135
ZOOM_IN				= 159
ZOOM_OUT				= 158

BTN_CAMERA_FRONT    = 51
BTN_CAMERA_RL     = 52 //Rear Left
BTN_CAMERA_RR     = 53 //Rear Right

BTN_PRESET_1				= 71
BTN_PRESET_2				= 72
BTN_PRESET_3				= 73
BTN_PRESET_4				= 74
BTN_PRESET_5				= 75

BTN_SAVE_1				= 81
BTN_SAVE_2				= 82
BTN_SAVE_3				= 83
BTN_SAVE_4				= 84
BTN_SAVE_5				= 85

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE INTEGER nSource_Camera
VOLATILE CHAR cMagicBuffer[500]
VOLATILE INTEGER nPanasonicPresets


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
DEFINE_FUNCTION fnRouteCamera(INTEGER cIn)
{
    SEND_STRING dvBlackMagic, "'@ X:0/',ITOA(DES_EXTRON),',',ITOA(cIn),'/',ITOA(DES_EPIPHAN),',',ITOA(cIn),CR"
}
DEFINE_FUNCTION fnParseBlackMagic()
{
    STACK_VAR CHAR cResponse[500] CHAR cTrash[500]
    
    WHILE(FIND_STRING(cMagicBuffer,"CR,LF",1))
    {
	cResponse = REMOVE_STRING(cMagicBuffer,"CR,LF",1)
	
	SELECT
	{
	    ACTIVE(FIND_STRING(cResponse,'S:06,0',1)):
	    {
		    nSource_Camera = CAMERA_TWO
	    }

	    ACTIVE(FIND_STRING(cResponse,'S:06,1',1)):
	    {
		    nSource_Camera = CAMERA_ONE
	    }
	    ACTIVE(FIND_STRING(cResponse,'S:06,2',1)):
	    {
		    nSource_Camera = CAMERA_THREE
	    }
	}
 }
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

CREATE_BUFFER dvBlackMagic,cMagicBuffer;

DEFINE_MODULE 'Panasonic_AWHE50_IP_Comm_dr1_0_0' CameraFront(vdvCamFront, dvCamFront)
DEFINE_MODULE 'Panasonic_AWHE50_IP_Comm_dr1_0_0' commRearLeft(vdvCamRearLeft, dvCamRearLeft);
DEFINE_MODULE 'Panasonic_AWHE50_IP_Comm_dr1_0_0' commRearRight(vdvCamRearRight, dvCamRearRight);

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
BUTTON_EVENT [vdvTP_Main, BTN_CAMERA_FRONT]
BUTTON_EVENT [vdvTP_Main, BTN_CAMERA_RL]
BUTTON_EVENT [vdvTP_Main, BTN_CAMERA_RR]
{
  PUSH :
  {
    SWITCH (BUTTON.INPUT.CHANNEL)
    {
      CASE BTN_CAMERA_FRONT :
      {
        //PULSE [vdvCamFront, POWER_ON]
        fnRouteCamera(CAMERA_ONE)
      }
      CASE BTN_CAMERA_RL :
      {
        fnRouteCamera(CAMERA_TWO)
      }
      CASE BTN_CAMERA_RR :
      {
        fnRouteCamera(CAMERA_THREE)
      }
    }
  }
 }
BUTTON_EVENT [vdvTP_Main, TILT_UP]
BUTTON_EVENT [vdvTP_Main, TILT_DOWN]
BUTTON_EVENT [vdvTP_Main, PAN_LEFT]
BUTTON_EVENT [vdvTP_Main, PAN_RIGHT]
BUTTON_EVENT [vdvTP_Main, ZOOM_IN]
BUTTON_EVENT [vdvTP_Main, ZOOM_OUT] //Control Camera...
{
  PUSH :
  {
    OFF [nPanasonicPresets]
    
    IF (nSource_Camera = BTN_CAMERA_FRONT)
    {
      ON [vdvCamFront, BUTTON.INPUT.CHANNEL]
     }
    ELSE IF (nSource_Camera = BTN_CAMERA_RL)
    {
      ON [vdvCamRearLeft, BUTTON.INPUT.CHANNEL]
    }
    ELSE
    {
      ON [vdvCamRearRight, BUTTON.INPUT.CHANNEL]
    }
  }
  RELEASE :
  {
		OFF [vdvCamFront, BUTTON.INPUT.CHANNEL]
		OFF [vdvCamRearLeft, BUTTON.INPUT.CHANNEL]
		OFF [vdvCamRearRight, BUTTON.INPUT.CHANNEL]
  }
}
BUTTON_EVENT [vdvTP_Main, BTN_PRESET_1]
BUTTON_EVENT [vdvTP_Main, BTN_PRESET_2]
BUTTON_EVENT [vdvTP_Main, BTN_PRESET_3]
BUTTON_EVENT [vdvTP_Main, BTN_PRESET_4]
BUTTON_EVENT [vdvTP_Main, BTN_PRESET_5]
{	
    PUSH :
    {
      nPanasonicPresets = BUTTON.INPUT.CHANNEL
      
      IF (nSource_Camera = BTN_CAMERA_FRONT)
      {
        SEND_COMMAND vdvCamFront, "'CAMERAPRESET-',ITOA(BUTTON.INPUT.CHANNEL - 70)"
      }
      ELSE IF (nSource_Camera = BTN_CAMERA_RL)
      {
        SEND_COMMAND vdvCamRearLeft, "'CAMERAPRESET-',ITOA(BUTTON.INPUT.CHANNEL - 70)"
      }
      ELSE
      {
        SEND_COMMAND vdvCamRight, "'CAMERAPRESET-',ITOA(BUTTON.INPUT.CHANNEL - 70)"
      }
    }
}   
