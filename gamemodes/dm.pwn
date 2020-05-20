////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
	Credits:
	Joe Staff: Screen fader! (Used for the blood screen on getting hit, you can disable it by toggling USE_BLOODSCREEN)
	Elorreli: For his map packs.
	Y_Less: fixes.inc && YSI.
	Slice: md-sort && fixes.inc.
    Infernus: progress.inc.
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <a_samp>

#undef MAX_PLAYERS
#define MAX_PLAYERS 50 // CHANGE THIS

#include <fixes>
#include <sscanf2>
#include <streamer>
#include "..\include\DM\colors.inc"
#include <md-sort>
#include <progress>
#include <YSI\y_commands>
#include <YSI\y_iterate>
#include <YSI\y_ini>

#define SERVER_NAME 					"Cops vs Terrorists"
#define SCRIPT_VERSION					"1.00"
#define SERVER_VERSION					"1.00"
#define SERVER_GMODE					"Cops vs Terrorists (1.00)"

// #define USE_IRC						1
#define USE_HEADSHOTS					1
#define USE_NUTSHOTS					1
#define USE_BLOODSCREEN					1 // Use 1 to turn on
#define TOTAL_MAPS						21 // TOGGLE THIS ONLY IF YOU ADD A NEW MAP WITH NEW SPAWN POINTS!


#define GLOBAL_STRING_LENGTH			(144)
#define ATTACH_ARMOUR_INDEX				(1)
#define ATTACH_HELMET_INDEX				(2)
#define ATTACHMENT_INDEX_LASER1			(3)
#define ATTACHMENT_INDEX_LASER2			(4)

#if USE_BLOODSCREEN==1
	#include <j_fader_v2>
#endif

#define formatex(%1,%2)					format(%1, (sizeof(%1)), %2)
#define randomex(%0,%1)					(random(%1-%0)+%0)
#define PRESSED(%0) 					(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define HOLDING(%0) 					((newkeys & (%0)) == (%0))
#define RELEASED(%0)					(((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define IncreasePlayerScore(%0,%1)		SetPlayerScore((%0), (GetPlayerScore((%0)) + %1))

#define COLOR_COP_INV					0x4646FF00
#define COLOR_TER_INV					0xFF4F4F00
#define COLOR_COP_VIS					0x4646FF55
#define COLOR_TER_VIS					0xFF4F4F55

#define DIALOG_NO_RESPONSE				(9999)
#define DIALOG_WEAPONS_BUY				(101)
#define DIALOG_MAP_VOTE					(102)
#define DIALOG_REGISTER					(103)
#define DIALOG_LOGIN					(104)

#define ERROR_CMD_PLAYER_NOT_CONNECTED	"The playerid you entered is not connected to the server."
#define ERROR_CMD_PLAYER_SAME_PLAYER	"You cannot use this command on yourself."

#define UpperToLower(%1) 		for(new ToLowerChar; ToLowerChar < strlen( %1 ); ToLowerChar ++ ) if ( %1[ ToLowerChar ]> 64 && %1[ ToLowerChar ] < 91 ) %1[ ToLowerChar ] += 32

enum pData
{
	ORM:pORMID,
	pID,
	pSpawned,
	pKills,
	pTotalKills,
	pDeaths,
	pTotalDeaths,
	pHeadShots,
	pTotalHeadShots,
	pNutShots,
	pTotalNutShots,
	pMarks,
	pTotalMarks,
	pKillStreak,
	pTotalKicks,
	pTotalWarns,
	pTotalBans,
	pTotalaBans,
	pTotalaKicks,
	pTotalaWarns,
	pTotal,
	pInFight,
	pDamageObject,
	pDamageObjectTimer,
	pSpawnProtected,
	pCounted,
	pLastClass,
	pVisible,
	pLastMark,
	pAFK,
	pLastUpdate,
	pWins,
	pLosses,
	pFirstSpawn,
	pBuySystem,
	pBuyAllowed,
	pHasItem[13],
	pMuted,
	pMuteTime,
	pCallDeath,
	pKillMessage,
	pKillCam,
	pLastPM,
	pPassword[129],
	pAutoLog,
	pJoinMessages,
	pTeamJoinMessages,
	pCookies,
	pAdminLevel,
	pVIPLevel,
	pVIPCredits,
	pScore,
	Float:pTotalAccuracy,
	pLoggedIn,
	pWrongLoginAttempts,
	pRegistered,
	pHits,
	pTotalHits,
	pShots,
	pTotalShots,
	pDead,
	pLastDamage,
	pLastDamageReason,
	pHasHelmet,
	Float:pHelmetHealth,
	pLaserColor,
	pLaserPref,
	pSpamTime,
	pSpamCount,
	pBeingKicked,
	pFetchedIP[16],
	pSecondsPlayed,
	pMinutesPlayed,
	pHoursPlayed,
	pLastSession[24],
	pTotalSecondsPlayed,
	pTotalMinutesPlayed,
	pTotalHoursPlayed,
	pFrozen,
	pWarns,
	pTimeSinceSpawn,
	pNoAKA,
	pAKAString[128],
	pLowerText
}

enum sData
{
	sCountDown,
	sCountDownF
}

enum banData
{
	pBanID,
	pBanTime,
	pBanName[24],
	pBanIP[16],
	pBannerName[24],
	pBanReason[40]
}

new bInfo[MAX_PLAYERS][banData]; // Ban info

#define TEAM_COP	0
#define TEAM_TER	1

new
	p_Name[MAX_PLAYERS][MAX_PLAYER_NAME],
	p_IP[MAX_PLAYERS][16],
	g_string[GLOBAL_STRING_LENGTH],
	g_bString[256],
	maps_string[2048],
	pInfo[MAX_PLAYERS][pData],
	gTeam[MAX_PLAYERS],
	gTeamPlayers[2],
	gTeamKills[2],
	gPlayerCount,
	gCurrentMap,
	gMapSpecified,
	roundInProgress,
	lastCopSpawn,
	lastTerSpawn,
	roundTimer[2],
	gMapPaused,
	gLastCount,
	mapVotes[TOTAL_MAPS],
	sInfo[sData]
;

new
	Text:mapChangeTD[3],
	//Text:fullScreen,
	Text:versionTD,
	Text:infoTD[4],
	Text:mapInfoTD[4],
	Text:roundEndTD[21],
	Text:g_killCamTD[3],
	Text:p_killCamTD[MAX_PLAYERS][2],
	Bar:helmetHealthBar[MAX_PLAYERS]
;

#define playerName(%1)			p_Name[(%1)]
#define playerIP(%1)			p_IP[(%1)]
#define banID(%0)				bInfo[(%0)][pBanID]
#define pBanTime(%0)			bInfo[(%0)][pBanTime]
#define pBanName(%0)			bInfo[(%0)][pBanName]
#define pBanIP(%0)				bInfo[(%0)][pBanIP]
#define pBannerName(%0)			bInfo[(%0)][pBannerName]
#define pBanReason(%0)			bInfo[(%0)][pBanReason]

forward mapChange();
forward mapChanged(playerid);
forward serverEverySecond();
forward playersEverySecond();

enum mapData
{
	mapID,
	mapTime,
	mapName[32],
	mapperName[24]
}

new mapInfo[TOTAL_MAPS][mapData] =
{
	// {Map id (incremental), map time in minutes, map name, mapper name}
	{0, 10, "The Market", "Elorreli"}, // 7
	{1, 10, "Narrow Passage", "Elorreli"}, // 7
	{2, 10, "K.O.H (King of Hill)", "Elorreli"},
	{3, 10, "Sindacco Abatoir", "Rockstar Games"}, // 8
	{4, 10, "The Olympia", "Elorreli"}, // 7
	{5, 10, "de_westwood", "Not known"}, // 6
	{6, 10, "Paintball Arena", "Famous."}, // 7
	{7, 10, "Small TDM Arena", "LeGGGeNNdA"}, // 7
	{8, 10, "cs_compound", "TheYoungCapone"}, // 8
	{9, 10, "aim_heashot", "Tobias100500"}, // 6
	{10, 10, "Cidade Abandonada", "Kudy"}, // 9
	{11, 10, "Block War", "saawan"}, // 8
	{12, 10, "cs_italy", "Not known"},
	{13, 10, "Jefferson Motel", "Rockstar Games"}, // 8
	{14, 10, "cs_rockwar", "Amirab"},
	{15, 10, "LVPD", "Rockstar Games"},
	{16, 10, "Sherman Dam", "Rockstar Games"},
	{17, 10, "RC Battlefield", "Rockstar Games"},
	{18, 10, "Terminal Island", "Leo"},
	{19, 10, "Carribean War", "Leo"},
	{20, 10, "Isla de Tierra", "Leo"}
};


enum achievementsEnum
{
	aKill[23],
	aHeadshot[23],
	aMark[23],
	aTime[14],
	aLowHealth,
	aFirstSpawn
}

new sAchievements[achievementsEnum];

enum spawnPointData
{
	Float:s_posX,
	Float:s_posY,
	Float:s_posZ,
	Float:s_Angle,
	s_Interior
}

new cop_spawnPoints[][][spawnPointData] =
{
	{
		{896.5433, -3696.5537, 12.3350, 99.0636, 0},
		{887.4947,-3705.7903,16.6878,90.9169, 0},
		{876.7745,-3715.2551,12.3350,184.6044, 0}
	},

	{
		{-358.5990,-4158.4209,22.9744,93.9239,0},
		{-365.4854,-4164.8428,22.9744,93.9239,0},
		{-363.8830,-4143.9888,18.7890,88.2839,0}
	},

	{
		{-1557.4220,-4428.0068,20.0764,93.1288,0},
		{-1583.3959,-4418.3955,17.7816,266.8621,0},
		{-1577.8881,-4436.7407,17.7816,271.2489,0}
	},

	{
		{958.6984,2099.9578,1011.0253,358.0201,1},
		{962.7363,2108.5017,1011.0303,88.2610,1},
		{948.3508,2105.2729,1011.0234,0.8402,1}
	},

	{
		{-3263.0156,-7010.6309,13.0854,182.9119,0},
		{-3286.6301,-6987.2271,11.2044,179.1518,0},
		{-3262.0142,-6983.7646,8.8807,177.5850,0}
	},

	{
		{-43.1586,1542.1619,12.7500,357.4894,0},
		{-47.6250,1504.5416,12.7500,268.1161,0},
		{-27.7189,1491.5773,12.7500,286.2897,0}
	},

	{
		{3166.7537,-1591.4999,11.2016,174.4052},
		{3179.3491,-1606.8268,11.1078,86.6711},
		{3172.5798,-1614.4172,12.5980,358.3102}
	},

	{
		{2422.7693,-644.6253,126.2972,93.8542},
		{2423.7085,-656.6492,125.7402,98.0960},
		{2419.9824,-634.7958,125.0672,97.0110}
	},

	{
		{2024.6276,274.7263,248.8178,89.3572},
		{2026.1354,318.9085,248.8178,88.1039},
		{2015.2892,305.6288,248.8178,90.6106}
	},

	{
		{3100.1716,-1956.0469,29.7699,177.7180},
		{3115.3892,-1955.0125,29.7510,187.7448},
		{3123.9116,-1955.3287,29.7255,184.6114}
	},

	{
		{694.7194,-2323.9150,297.4899,355.1132},
		{733.4135,-2342.2671,294.3263,3.8866},
		{732.0282,-2321.6890,294.3070,346.3632}
	},

	{
		{1934.2156,-2546.7212,13.5469,267.1126},
		{1933.1089,-2520.7188,13.5469,273.0661},
		{1934.0145,-2569.3564,13.5469,261.4726}
	},

	{
		{-4014.1365,-1133.0048,107.1588,267.1416,0},
		{-3998.8376,-1142.2354,112.0338,352.3692,0},
		{-4006.9429,-1115.8575,107.1746,2.0826,0}
	},

	{
		{2221.2952,-1150.5564,1025.7969,358.2650,15},
		{2216.7246,-1150.6565,1025.7969,270.8441,15},
		{2226.9937,-1150.4554,1025.7969,87.5424,15}
	},

	{
		{1162.2820,2058.3284,143.4960,1.6611,0},
		{1151.3967,2055.8027,143.4960,5.1078,0},
		{1182.0071,2057.6079,143.4960,1.3478,0}
	},

	{
		{301.2722,183.9653,1007.1719,86.7233,3},
		{298.5580,191.3069,1007.1794,90.4834,3},
		{272.8279,173.5297,1007.6719,357.4225,3}
	},

	{
		{-951.5983,1848.2931,5.0000,6.5770,17},
		{-961.2835,1854.8136,9.0000,267.8761,17},
		{-952.5535,1852.9352,9.5720,359.0570,17}
	},

	{
		{-1136.5131,1070.7905,1345.7982,269.7791,10},
		{-1135.0847,1057.5872,1345.7776,271.9725,10},
		{-1136.1528,1029.9691,1345.7571,261.6327,10}
	},

	{
		{11964.8037,-1114.7217,12.6098,184.2677,0},
		{11949.3799,-1108.6525,12.7582,198.0546,0},
		{11985.8086,-1116.0627,12.6098,174.5778,0}
	},

	{
		{-265.3761,9424.6729,2.7184,276.1455,0},
		{-274.9333,9391.0352,3.3811,284.2923,0},
		{-236.3871,9413.4961,2.9805,87.3721,0}
	},

	{
		{3596.1289,1238.4197,30.8687,92.7953,0},
		{3587.8020,1260.6654,30.8687,173.7811,0},
		{3588.6567,1216.7354,30.8687,359.2527,0}
	}
};

new ter_spawnPoints[][][spawnPointData] =
{
	{
		{726.4619,-3733.7625,12.3350,178.9410, 0},
		{736.3986,-3744.5762,12.3350,100.9203, 0},
		{739.3179,-3765.6245,14.8124,263.8553, 0}
	},

	{
		{-500.6485,-4150.1436,18.7890,270.0192,0},
		{-506.4293,-4158.1318,18.7890,271.8992,0},
		{-499.8796,-4166.4297,18.7890,268.7657,0}
	},

	{
		{-1456.2759,-4427.7344,20.1194,268.2839,0},
		{-1434.4473,-4436.1250,17.7894,91.1039,0},
		{-1434.1340,-4417.0059,17.7816,89.2239,0}
	},

	{
		{963.4450,2166.0413,1011.0234,180.3585,1},
		{963.3043,2149.7087,1011.0234,87.2976,1},
		{953.3961,2150.3059,1011.0234,357.3701,1}
	},

	{
		{-3405.9919,-6989.9775,8.9636,90.7673,0},
		{-3414.6521,-6999.8442,8.8108,230.8286,0},
		{-3409.6089,-6975.6768,9.6444,264.9822,0}
	},

	{
		{41.9839,1498.4042,12.7500,114.2681,0},
		{54.3035,1532.7496,13.0238,110.1712,0},
		{40.8719,1541.7579,12.7500,40.3207,0}
	},

	{
		{3179.1438,-1391.7727,11.1078,92.6009},
		{3169.2983,-1406.2297,11.1078,85.3942},
		{3113.0210,-1384.8817,11.1078,176.8884}
	},

	{
		{2355.5056,-648.4540,128.0547,269.2254},
		{2350.7830,-655.5956,128.0547,264.6458},
		{2347.2124,-655.0242,128.0547,260.5491}
	},

	{
		{1877.4546,339.1113,248.8178,272.0089},
		{1876.6367,304.3142,249.8959,278.1072},
		{1867.9807,269.1738,248.8178,264.8021}
	},

	{
		{3106.5898,-2062.3345,29.9525,359.1398},
		{3113.4155,-2062.0769,29.9462,4.4665},
		{3120.9646,-2062.0046,29.9450,359.1398}
	},

	{
		{697.9631,-2206.3735,294.3730,2.1984},
		{697.9713,-2195.6487,295.3295,179.8600},
		{715.4349,-2198.2903,294.3730,269.9326}
	},

	{
		{2030.9854,-2569.4873,13.5469,89.4510},
		{2030.0714,-2543.9165,13.5469,91.3310},
		{2031.2596,-2517.8005,13.5469,86.6310}
	},

	{
		{-3958.5024,-1037.8525,107.8830,176.2743,0},
		{-3958.9170,-1059.8408,112.1638,3.0227,0},
		{-3969.4438,-1039.6144,107.8533,263.3760,0}
	},

	{
		{2193.4375,-1140.5291,1029.7969,177.4232,15},
		{2193.6208,-1146.0369,1033.7969,356.9415,15},
		{2204.6638,-1139.9786,1031.7969,85.6157,15}
	},

	{
		{1183.2919,2109.4265,143.4960,181.6808,0},
		{1196.3229,2109.0142,143.4960,176.6674,0},
		{1164.4779,2108.6213,143.4960,176.9807,0}
	},

	{
		{191.8848,157.9818,1003.0234,267.8083,3},
		{197.5485,168.4308,1003.0234,266.8684,3},
		{192.6232,179.1646,1003.0234,269.0618,3}
	},

	{
		{-961.2173,1945.5920,9.0000,265.3929,17},
		{-952.8084,1948.4690,9.0000,183.6120,17},
		{-943.1032,1935.7091,5.0000,177.6586,17}
	},

	{
		{-969.5856,1037.9895,1345.0625,94.3345,10},
		{-970.6086,1061.0787,1345.0336,91.8278,10},
		{-970.6419,1089.6484,1345.0044,91.2011,10}
	},

	{
		{12030.1543,-1257.3842,12.6098,90.00,0},
		{12042.6191,-1256.5604,12.6098,3.2296,0},
		{12027.4189,-1244.2084,12.6098,1.6629,0}
	},

	{
		{-123.3712,9367.9697,3.1182,6.9897,0},
		{-123.6309,9358.9463,8.7756,6.3396,0},
		{-137.9431,9398.1563,3.0671,196.1980,0}
	},

	{
		{3495.0378,1266.8181,30.8687,174.8426,0},
		{3490.5754,1210.1649,30.8687,275.2786,0},
		{3482.4983,1238.8931,30.8687,267.9269,0}
	}
};

new deathReason[256][] = {
	{"Fists"},
	{"Brass Knuckles"},
	{"Golf Club"},
	{"Nite Stick"},
	{"Knife"},
	{"Baseball Bat"},
	{"Shovel"},
	{"Pool Cue"},
	{"Katana"},
	{"Chainsaw"},
	{"Purple Dildo"},
	{"Small White Vibrator"},
	{"Large White Vibrator"},
	{"Silver Vibrator"},
	{"Flowers"},
	{"Cane"},
	{"Grenade"},
	{"Tear Gas"},
	{"Molotov Cocktail"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"9mm"},
	{"Silenced 9mm"},
	{"Desert Eagle"},
	{"Shotgun"},
	{"Sawn-off Shotgun"},
	{"Combat Shotgun"},
	{"Micro SMG"},
	{"MP5"},
	{"AK-47"},
	{"M4"},
	{"Tec9"},
	{"Country Rifle"},
	{"Sniper Rifle"},
	{"Rocket Launcher"},
	{"Heat Seeking Rocket Launcher"},
	{"Flamethrower"},
	{"Minigun"},
	{"Satchel Charge"},
	{"Detonator"},
	{"Spraycan"},
	{"Fire Extinguisher"},
	{"Camera"},
	{"Nightvision Goggles"},
	{"Thermal Goggles"},
	{"Parachute"},
	{"Fake Pistol"},
	{"Invalid"},
	{"Vehicle"},
	{"Helicopter Blades"},
	{"Explosion"},
	{"Invalid"},
	{"Drowned"},
	{"Fall"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Connect"},
	{"Disconnect"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Invalid"},
	{"Vehicle Explosion"}
};

enum rankingEnum
{
	r_playerRank,
	r_playerID
}

enum rankingEnumEx
{
	Float:r_playerRankEx,
	r_playerIDEx
}

new
	r_playerKills[MAX_PLAYERS][rankingEnum],
	r_playerDeaths[MAX_PLAYERS][rankingEnum],
	r_playerKDRatio[MAX_PLAYERS][rankingEnumEx],
	r_playerHeadShots[MAX_PLAYERS][rankingEnum],
	r_playerAccuracy[MAX_PLAYERS][rankingEnumEx],
	r_playerMarks[MAX_PLAYERS][rankingEnum]
;

enum wtbb_enum
{
	weaponID,
	weaponName[16],
	weaponAmmo,
	weaponPrice
}

new weaponsToBeBought[][wtbb_enum] =
{
	{23, "Silenced 9mm", 75, 350},
	{24, "Desert Eagle", 75, 500},
	{25, "Shotgun", 125, 1000},
	{27, "Combat Shotgun", 125, 1250},
	{26, "Sawn off", 75, 1750},
	{29, "MP5", 125, 1750},
	{31, "M4", 125, 3000},
	{33, "County Rifle", 75, 3000},
	{34, "Sniper Rifle", 50, 4000},
	{38, "Minigun", 500, 15000},
	{16, "Grenade", 1, 2000},
	{-1, "Armour", 100, 2500},
	{-2, "Helmet", 100, 1000}
};

enum weaponDamageDataEnum
{
	wDD_weaponName[32],
	Float:wDD_amount
}

new weaponDamageData[][weaponDamageDataEnum] =
{
	{"Fists",1.00},
	{"Brass Knuckles",2.00},
	{"Golf Club",3.00},
	{"Nite Stick",3.00},
	{"Knife",3.00},
	{"Baseball Bat",3.00},
	{"Shovel",3.00},
	{"Pool Cue",3.00},
	{"Katana",4.00},
	{"Chainsaw",4.00},
	{"Purple Dildo",2.00},
	{"Small Whit Vibrator",2.00},
	{"Large White Vibrator",2.00},
	{"Silver Vibrator",2.00},
	{"Flowers",2.00},
	{"Cane",2.00},
	{"Grenade",45.00},
	{"Tear Gas",0.00},
	{"Molotov Cocktail",30.00},
	{"Invalid",0.00},
	{"Invalid",0.00},
	{"Invalid",0.00},
	{"9mm",6.5},
	{"Silenced 9mm",7.2},
	{"Desert Eagle",45.00},
	{"Shotgun",9.5},
	{"Sawn-off Shotgun",14.00},
	{"Combat Shotgun",12.00},
	{"Micro SMG",10.00},
	{"MP5",8.9},
	{"AK-47",12.00},
	{"M4",13.00},
	{"Tec9",12.00},
	{"Country Rifle",13.50},
	{"Sniper Rifle",22.00},
	{"Rocket Launcher",50.00},
	{"Heat Seeking Rocket Launcher",50.00},
	{"Flamethrower",20.00},
	{"Minigun",8.5}
};

enum enum_attachmentCoordinates
{
	Float:fOffX,
	Float:fOffY,
	Float:fOffZ,
	Float:fRotX,
	Float:fRotY,
	Float:fRotZ,
	Float:fScaX,
	Float:fScaY,
	Float:fScaZ
}

new armourCoordinates[][enum_attachmentCoordinates] = {
	// counter terrorists
	{0.106999, 0.064999, 0.002000, 2.700001, -1.899998, -2.300000, 0.957000, 1.366000, 0.984999}, // Skin 121
	{0.036999, 0.039999, 0.003000, 2.700001, -1.899998, -2.300000, 0.957000, 1.044000, 0.984999}, // Skin 165
	{0.049999, 0.048999, 0.000000, 2.700001, -1.899998, -2.300000, 0.957000, 1.126000, 0.984999}, // Skin 266
	{0.099999, 0.044999, 0.007000, 2.700001, -1.899998, -2.300000, 0.957000, 1.238000, 0.984999}, // Skin 282
	{0.108999, 0.044999, 0.007000, 2.700001, -1.899998, -2.300000, 0.957000, 1.238000, 0.984999}, // Skin 286
	{0.146999, 0.059999, 0.003000, 2.700001, -1.899998, -2.300000, 0.957000, 1.126000, 0.984999}, // Skin 192

	// terrorists
	{0.106999, 0.081000, 0.001000, 2.700001, -1.899998, -2.300000, 0.957000, 1.314999, 0.892999}, // Skin 90
	{0.071999, 0.046000, 0.000000, 0.000000, 0.000000, 0.000000, 1.001000, 1.215999, 1.078000}, // Skin 28
	{0.096000, 0.050000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000}, // Skin 108
	{0.057999, 0.055000, -0.000999, 2.700001, -1.899998, -2.300000, 1.000000, 1.177000, 0.930999}, // Skin 97
	{0.051999, 0.046000, 0.008000, 2.700001, -1.899998, -2.300000, 1.000000, 1.220999, 1.068999}, // Skin 98
	{0.103999, 0.033000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000} // Skin 293
};

new helmetCoordinates[][enum_attachmentCoordinates] = {
	// counter terrorists
	{0.122000, 0.009000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.109000, 1.000000}, // Skin 121
	{0.114000, 0.013000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.034999, 1.000000}, // Skin 165
	{0.114000, 0.003000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.062999, 1.000000}, // Skin 266
	{0.114000, 0.003000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.062999, 1.000000}, // Skin 282
	{0.114000, 0.003000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.062999, 1.000000}, // Skin 286
	{0.114000, 0.003000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.062999, 1.000000}, // Skin 192

	// terrorists
	{0.106000, -0.006999, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.109000, 1.000000}, // Skin 90
	{0.106999, 0.064998, 0.002000, 2.700001, -1.899997, -2.299999, 0.957000, 1.366000, 0.984999}, // Skin 28
	{0.109999, 0.004999, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000}, // Skin 108
	{0.098000, 0.006000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.109000, 1.000000}, // Skin 97
	{0.119000, 0.024000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.109000, 1.000000}, // Skin 98
	{0.109999, 0.016999, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000} // Skin 293
};

#if defined USE_IRC
	#include "..\include\DM\irc.inc"
#endif

#include "..\include\DM\mysql.inc"
#include "..\include\DM\ach.inc"
#include "..\include\DM\commands.inc"

main() { AntiDeAMX(); }

public OnGameModeInit()
{
	AntiDeAMX();
	Init_AchSystem();

	roundInProgress = 1;

	// mysql_log(LOG_ALL, LOG_TYPE_TEXT);

	print(" ");
	print("_______________________________________________________");
	print(" ");
	print("Initiating....");
	print(" ");
	print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
	print(""SERVER_NAME"");
	print("Version "SERVER_VERSION"");
	print("Developed by Cell_  (164585)");
	print("Start date 8/26/2014");
	print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
	print(" ");
	print("Initiation successful!");
	print(" ");
	print("_______________________________________________________");

	SetGameModeText(SERVER_GMODE);
	UsePlayerPedAnims();

	/* Counter terrorists
	AddPlayerClass(285, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(286, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(288, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(179, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(192, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(191, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);

	// Terrorists
	AddPlayerClass(193, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(56, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(113, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(126, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(127, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(101, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);*/

	// Counter terrorists
	AddPlayerClass(121, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(165, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(266, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(282, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(286, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(192, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);

	// Terrorists
	AddPlayerClass(90, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(28, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(108, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(97, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(98, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(293, 1127.2300,-2037.0039,69.8836,266.1534, 0, 0, 0, 0, 0, 0);

	loadMaps();
	loadTextdraws();
	loadProgressBars();
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(false);

	SendRconCommand("hostname "SERVER_NAME"");
	SendRconCommand("language English");
	TextDrawSetString(versionTD, "~r~~h~Version: ~w~"SERVER_VERSION"");

	SetTimer("mapChange", 10000, false);
	SetTimer("playersEverySecond", 1000, true);
	SetTimer("serverEverySecond", 1000, true);

	#if defined USE_IRC
		irc_init();
		SetTimerEx("connectBots", 60000, false, "i", 0);
		SetTimerEx("connectBots", 90000, false, "i", 1);
		SetTimerEx("connectBots", 120000, false, "i", 2);
		SetTimerEx("connectBots", 150000, false, "i", 3);
	#endif

	// Achievements
	// Kills
	sAchievements[aKill][0] = CreateAchievement("First kill", "Congratulations! You have made your ~r~first ~w~kill on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~10 kills.", 1);
	sAchievements[aKill][1] = CreateAchievement("10th kill", "Congratulations! You have made your ~r~10th ~w~kill on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~25 kills.", 10);
	sAchievements[aKill][2] = CreateAchievement("25th kill", "Congratulations! You have made your ~r~25th~w~ kill on the server.~n~You recieve +2 score and $1500 cash.~n~~y~Next achievement: ~w~50 kills.", 25);
	sAchievements[aKill][3] = CreateAchievement("50th kill", "Congratulations! You have made your ~r~50th ~w~kill on the server.~n~You recieve +3 score and $2000 cash.~n~~y~Next achievement: ~w~100 kills.", 50);
	sAchievements[aKill][4] = CreateAchievement("100th kill", "Congratulations! You have made your ~r~100th ~w~kill on the server.~n~You recieve +4 score and $2500 cash.~n~~y~Next achievement: ~w~250 kills.", 100);
	sAchievements[aKill][5] = CreateAchievement("250th kill", "Congratulations! You have made your ~r~250th ~w~kill on the server.~n~You recieve +5 score and $2750 cash.~n~~y~Next achievement: ~w~500 kills.", 250);
	sAchievements[aKill][6] = CreateAchievement("500th kill", "Congratulations! You have made your ~r~500th ~w~kill on the server.~n~You recieve +5 score and $3000 cash.~n~~y~Next achievement: ~w~1000 kills.", 500);
	sAchievements[aKill][7] = CreateAchievement("1000th kill", "Congratulations! You have made your ~r~1000th ~w~kill on the server.~n~You recieve +6 score and $3500 cash.~n~~y~Next achievement: ~w~2500 kills.", 1000);
	sAchievements[aKill][8] = CreateAchievement("2500th kill", "Congratulations! You have made your ~r~2500th ~w~kill on the server.~n~You recieve +6 score and $3750 cash.~n~~y~Next achievement: ~w~5000 kills.", 2500);
	sAchievements[aKill][9] = CreateAchievement("5000th kill", "Congratulations! You have made your ~r~5000th ~w~kill on the server.~n~You recieve +7 score and $4000 cash.~n~~y~Next achievement: ~w~10000 kills.", 5000);
	sAchievements[aKill][10] = CreateAchievement("10000th kill", "Congratulations! You have made your ~r~10000th ~w~kill on the server.~n~You recieve +7 score and $4500 cash.~n~~y~Next achievement: ~w~25000 kills.", 10000);
	sAchievements[aKill][11] = CreateAchievement("25k kills", "Congratulations! You have made ~r~25k ~w~kills on the server.~n~You recieve +8 score and $5000 cash.~n~~y~Next achievement: ~w~50000 kills.", 25000);
	sAchievements[aKill][12] = CreateAchievement("50k kills", "Congratulations! You have made ~r~50k ~w~kills on the server.~n~You recieve +8 score and $6000 cash.~n~~y~Next achievement: ~w~100k kills.", 50000);
	sAchievements[aKill][13] = CreateAchievement("100k kills", "Congratulations! You have made ~r~100k ~w~kills on the server.~n~You recieve +10 score and $10000 cash.~n~~y~Next achievement: ~w~250k kills.", 100000);
	sAchievements[aKill][14] = CreateAchievement("250k kills", "Congratulations! You have made ~r~250k ~w~kills on the server.~n~You recieve +15 score and $15000 cash.~n~~y~Next achievement: ~w~500k kills.", 250000);
	sAchievements[aKill][15] = CreateAchievement("500k kills", "Congratulations! You have made ~r~500k ~w~kills on the server.~n~You recieve +20 score and $20000 cash.~n~~y~Next achievement: ~w~1m kills.", 500000);
	sAchievements[aKill][16] = CreateAchievement("1m kills", "Congratulations! You have made ~r~1m ~w~kills on the server.~n~You recieve +25 score and $30000 cash.~n~~y~Next achievement: ~w~2.5m kills.", 1000000);
	sAchievements[aKill][17] = CreateAchievement("2.5m kills", "Congratulations! You have made ~r~2.5m ~w~kills on the server.~n~You recieve +30 score and $40000 cash.~n~~y~Next achievement: ~w~5m kills.", 2500000);
	sAchievements[aKill][18] = CreateAchievement("5m kills", "Congratulations! You have made ~r~5m ~w~kills on the server.~n~You recieve +40 score and $50000 cash.~n~~y~Next achievement: ~w~10m kills.", 5000000);
	sAchievements[aKill][19] = CreateAchievement("10m kills", "Congratulations! You have made ~r~10m ~w~kills on the server.~n~You recieve +50 score and $50000 cash.~n~~y~Next achievement: ~w~25m kills.", 10000000);
	sAchievements[aKill][20] = CreateAchievement("25m kills", "Congratulations! You have made ~r~10m ~w~kills on the server.~n~You recieve +100 score and $50000 cash.~n~~y~Next achievement: ~w~50m kills.", 25000000);
	sAchievements[aKill][21] = CreateAchievement("50m kills", "Congratulations! You have made ~r~10m ~w~kills on the server.~n~You recieve +500 score and $50000 cash.~n~~y~Next achievement: ~w~100m kills.", 50000000);
	sAchievements[aKill][22] = CreateAchievement("100m kills", "Congratulations! You have made ~r~100m ~w~kills on the server.~n~You recieve +1000 score and $50000 cash.~n~~y~Next achievement: ~w~Immortality!", 100000000);

	// Headshots
	sAchievements[aHeadshot][0] = CreateAchievement("First Headshot", "Congratulations! You have made your ~r~first ~w~Headshot on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~10 Headshots.", 1);
	sAchievements[aHeadshot][1] = CreateAchievement("10th Headshot", "Congratulations! You have made your ~r~10th ~w~Headshot on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~25 Headshots.", 10);
	sAchievements[aHeadshot][2] = CreateAchievement("25th Headshot", "Congratulations! You have made your ~r~25th~w~ Headshot on the server.~n~You recieve +2 score and $1500 cash.~n~~y~Next achievement: ~w~50 Headshots.", 25);
	sAchievements[aHeadshot][3] = CreateAchievement("50th Headshot", "Congratulations! You have made your ~r~50th ~w~Headshot on the server.~n~You recieve +3 score and $2000 cash.~n~~y~Next achievement: ~w~100 Headshots.", 50);
	sAchievements[aHeadshot][4] = CreateAchievement("100th Headshot", "Congratulations! You have made your ~r~100th ~w~Headshot on the server.~n~You recieve +4 score and $2500 cash.~n~~y~Next achievement: ~w~250 Headshots.", 100);
	sAchievements[aHeadshot][5] = CreateAchievement("250th Headshot", "Congratulations! You have made your ~r~250th ~w~Headshot on the server.~n~You recieve +5 score and $2750 cash.~n~~y~Next achievement: ~w~500 Headshots.", 250);
	sAchievements[aHeadshot][6] = CreateAchievement("500th Headshot", "Congratulations! You have made your ~r~500th ~w~Headshot on the server.~n~You recieve +5 score and $3000 cash.~n~~y~Next achievement: ~w~1000 Headshots.", 500);
	sAchievements[aHeadshot][7] = CreateAchievement("1000th Headshot", "Congratulations! You have made your ~r~1000th ~w~Headshot on the server.~n~You recieve +6 score and $3500 cash.~n~~y~Next achievement: ~w~2500 Headshots.", 1000);
	sAchievements[aHeadshot][8] = CreateAchievement("2500th Headshot", "Congratulations! You have made your ~r~2500th ~w~Headshot on the server.~n~You recieve +6 score and $3750 cash.~n~~y~Next achievement: ~w~5000 Headshots.", 2500);
	sAchievements[aHeadshot][9] = CreateAchievement("5000th Headshot", "Congratulations! You have made your ~r~5000th ~w~Headshot on the server.~n~You recieve +7 score and $4000 cash.~n~~y~Next achievement: ~w~10000 Headshots.", 5000);
	sAchievements[aHeadshot][10] = CreateAchievement("10000th Headshot", "Congratulations! You have made your ~r~10000th ~w~Headshot on the server.~n~You recieve +7 score and $4500 cash.~n~~y~Next achievement: ~w~25000 Headshots.", 10000);
	sAchievements[aHeadshot][11] = CreateAchievement("25k Headshots", "Congratulations! You have made ~r~25k ~w~Headshots on the server.~n~You recieve +8 score and $5000 cash.~n~~y~Next achievement: ~w~50000 Headshots.", 25000);
	sAchievements[aHeadshot][12] = CreateAchievement("50k Headshots", "Congratulations! You have made ~r~50k ~w~Headshots on the server.~n~You recieve +8 score and $6000 cash.~n~~y~Next achievement: ~w~100k Headshots.", 50000);
	sAchievements[aHeadshot][13] = CreateAchievement("100k Headshots", "Congratulations! You have made ~r~100k ~w~Headshots on the server.~n~You recieve +10 score and $10000 cash.~n~~y~Next achievement: ~w~250k Headshots.", 100000);
	sAchievements[aHeadshot][14] = CreateAchievement("250k Headshots", "Congratulations! You have made ~r~250k ~w~Headshots on the server.~n~You recieve +15 score and $15000 cash.~n~~y~Next achievement: ~w~500k Headshots.", 250000);
	sAchievements[aHeadshot][15] = CreateAchievement("500k Headshots", "Congratulations! You have made ~r~500k ~w~Headshots on the server.~n~You recieve +20 score and $20000 cash.~n~~y~Next achievement: ~w~1m Headshots.", 500000);
	sAchievements[aHeadshot][16] = CreateAchievement("1m Headshots", "Congratulations! You have made ~r~1m ~w~Headshots on the server.~n~You recieve +25 score and $30000 cash.~n~~y~Next achievement: ~w~2.5m Headshots.", 1000000);
	sAchievements[aHeadshot][17] = CreateAchievement("2.5m Headshots", "Congratulations! You have made ~r~2.5m ~w~Headshots on the server.~n~You recieve +30 score and $40000 cash.~n~~y~Next achievement: ~w~5m Headshots.", 2500000);
	sAchievements[aHeadshot][18] = CreateAchievement("5m Headshots", "Congratulations! You have made ~r~5m ~w~Headshots on the server.~n~You recieve +40 score and $50000 cash.~n~~y~Next achievement: ~w~10m Headshots.", 5000000);
	sAchievements[aHeadshot][19] = CreateAchievement("10m Headshots", "Congratulations! You have made ~r~10m ~w~Headshots on the server.~n~You recieve +50 score and $50000 cash.~n~~y~Next achievement: ~w~25m Headshots.", 10000000);
	sAchievements[aHeadshot][20] = CreateAchievement("25m Headshots", "Congratulations! You have made ~r~10m ~w~Headshots on the server.~n~You recieve +100 score and $50000 cash.~n~~y~Next achievement: ~w~50m Headshots.", 25000000);
	sAchievements[aHeadshot][21] = CreateAchievement("50m Headshots", "Congratulations! You have made ~r~10m ~w~Headshots on the server.~n~You recieve +500 score and $50000 cash.~n~~y~Next achievement: ~w~100m Headshots.", 50000000);
	sAchievements[aHeadshot][22] = CreateAchievement("100m Headshots", "Congratulations! You have made ~r~100m ~w~Headshots on the server.~n~You recieve +1000 score and $50000 cash.~n~~y~Next achievement: ~w~Immortality!", 100000000);
	// Marks
	sAchievements[aMark][0] = CreateAchievement("First Mark", "Congratulations! You have made your ~r~first ~w~Mark on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~10 Marks.", 1);
	sAchievements[aMark][1] = CreateAchievement("10th Mark", "Congratulations! You have made your ~r~10th ~w~Mark on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~25 Marks.", 10);
	sAchievements[aMark][2] = CreateAchievement("25th Mark", "Congratulations! You have made your ~r~25th~w~ Mark on the server.~n~You recieve +2 score and $1500 cash.~n~~y~Next achievement: ~w~50 Marks.", 25);
	sAchievements[aMark][3] = CreateAchievement("50th Mark", "Congratulations! You have made your ~r~50th ~w~Mark on the server.~n~You recieve +3 score and $2000 cash.~n~~y~Next achievement: ~w~100 Marks.", 50);
	sAchievements[aMark][4] = CreateAchievement("100th Mark", "Congratulations! You have made your ~r~100th ~w~Mark on the server.~n~You recieve +4 score and $2500 cash.~n~~y~Next achievement: ~w~250 Marks.", 100);
	sAchievements[aMark][5] = CreateAchievement("250th Mark", "Congratulations! You have made your ~r~250th ~w~Mark on the server.~n~You recieve +5 score and $2750 cash.~n~~y~Next achievement: ~w~500 Marks.", 250);
	sAchievements[aMark][6] = CreateAchievement("500th Mark", "Congratulations! You have made your ~r~500th ~w~Mark on the server.~n~You recieve +5 score and $3000 cash.~n~~y~Next achievement: ~w~1000 Marks.", 500);
	sAchievements[aMark][7] = CreateAchievement("1000th Mark", "Congratulations! You have made your ~r~1000th ~w~Mark on the server.~n~You recieve +6 score and $3500 cash.~n~~y~Next achievement: ~w~2500 Marks.", 1000);
	sAchievements[aMark][8] = CreateAchievement("2500th Mark", "Congratulations! You have made your ~r~2500th ~w~Mark on the server.~n~You recieve +6 score and $3750 cash.~n~~y~Next achievement: ~w~5000 Marks.", 2500);
	sAchievements[aMark][9] = CreateAchievement("5000th Mark", "Congratulations! You have made your ~r~5000th ~w~Mark on the server.~n~You recieve +7 score and $4000 cash.~n~~y~Next achievement: ~w~10000 Marks.", 5000);
	sAchievements[aMark][10] = CreateAchievement("10000th Mark", "Congratulations! You have made your ~r~10000th ~w~Mark on the server.~n~You recieve +7 score and $4500 cash.~n~~y~Next achievement: ~w~25000 Marks.", 10000);
	sAchievements[aMark][11] = CreateAchievement("25k Marks", "Congratulations! You have made ~r~25k ~w~Marks on the server.~n~You recieve +8 score and $5000 cash.~n~~y~Next achievement: ~w~50000 Marks.", 25000);
	sAchievements[aMark][12] = CreateAchievement("50k Marks", "Congratulations! You have made ~r~50k ~w~Marks on the server.~n~You recieve +8 score and $6000 cash.~n~~y~Next achievement: ~w~100k Marks.", 50000);
	sAchievements[aMark][13] = CreateAchievement("100k Marks", "Congratulations! You have made ~r~100k ~w~Marks on the server.~n~You recieve +10 score and $10000 cash.~n~~y~Next achievement: ~w~250k Marks.", 100000);
	sAchievements[aMark][14] = CreateAchievement("250k Marks", "Congratulations! You have made ~r~250k ~w~Marks on the server.~n~You recieve +15 score and $15000 cash.~n~~y~Next achievement: ~w~500k Marks.", 250000);
	sAchievements[aMark][15] = CreateAchievement("500k Marks", "Congratulations! You have made ~r~500k ~w~Marks on the server.~n~You recieve +20 score and $20000 cash.~n~~y~Next achievement: ~w~1m Marks.", 500000);
	sAchievements[aMark][16] = CreateAchievement("1m Marks", "Congratulations! You have made ~r~1m ~w~Marks on the server.~n~You recieve +25 score and $30000 cash.~n~~y~Next achievement: ~w~2.5m Marks.", 1000000);
	sAchievements[aMark][17] = CreateAchievement("2.5m Marks", "Congratulations! You have made ~r~2.5m ~w~Marks on the server.~n~You recieve +30 score and $40000 cash.~n~~y~Next achievement: ~w~5m Marks.", 2500000);
	sAchievements[aMark][18] = CreateAchievement("5m Marks", "Congratulations! You have made ~r~5m ~w~Marks on the server.~n~You recieve +40 score and $50000 cash.~n~~y~Next achievement: ~w~10m Marks.", 5000000);
	sAchievements[aMark][19] = CreateAchievement("10m Marks", "Congratulations! You have made ~r~10m ~w~Marks on the server.~n~You recieve +50 score and $50000 cash.~n~~y~Next achievement: ~w~25m Marks.", 10000000);
	sAchievements[aMark][20] = CreateAchievement("25m Marks", "Congratulations! You have made ~r~10m ~w~Marks on the server.~n~You recieve +100 score and $50000 cash.~n~~y~Next achievement: ~w~50m Marks.", 25000000);
	sAchievements[aMark][21] = CreateAchievement("50m Marks", "Congratulations! You have made ~r~10m ~w~Marks on the server.~n~You recieve +500 score and $50000 cash.~n~~y~Next achievement: ~w~100m Marks.", 50000000);
	sAchievements[aMark][22] = CreateAchievement("100m Marks", "Congratulations! You have made ~r~100m ~w~Marks on the server.~n~You recieve +1000 score and $50000 cash.~n~~y~Next achievement: ~w~Immortality!", 100000000);
	// Time
	sAchievements[aTime][0] = CreateAchievement("First 10 minutes", "Congratulations! You have spent ~r~10 minutes~w~ on the server.~n~You recieve +1 score and $1000 cash.~n~~y~Next achievement: ~w~30 Minutes.", 10);
	sAchievements[aTime][1] = CreateAchievement("30 minutes", "Congratulations! You have spent ~r~30 minutes~w~ on the server.~n~You recieve +2 score and $1500 cash.~n~~y~Next achievement: ~w~1 hour.", 30);
	sAchievements[aTime][2] = CreateAchievement("1 hour", "Congratulations! You have spent ~r~1 hour~w~ on the server.~n~You recieve +3 score and $2000 cash.~n~~y~Next achievement: ~w~2 hours.", 60);
	sAchievements[aTime][3] = CreateAchievement("2 hours", "Congratulations! You have spent ~r~2 hours~w~ on the server.~n~You recieve +4 score and $2500 cash.~n~~y~Next achievement: ~w~5 hours.", 120);
	sAchievements[aTime][4] = CreateAchievement("5 hours", "Congratulations! You have spent ~r~5 hours~w~ on the server.~n~You recieve +5 score and $3000 cash.~n~~y~Next achievement: ~w~10 hours.", 300);
	sAchievements[aTime][5] = CreateAchievement("10 hours", "Congratulations! You have spent ~r~10 hours~w~ on the server.~n~You recieve +6 score and $3500 cash.~n~~y~Next achievement: ~w~24 hours.", 600);
	sAchievements[aTime][6] = CreateAchievement("24 hours", "Congratulations! You have spent ~r~24 hours~w~ on the server.~n~You recieve +10 score and $5000 cash.~n~~y~Next achievement: ~w~48 hours.", 1440);
	sAchievements[aTime][7] = CreateAchievement("48 hours", "Congratulations! You have spent ~r~48 hours~w~ on the server.~n~You recieve +20 score and $10000 cash.~n~~y~Next achievement: ~w~7 days.", 2880);
	sAchievements[aTime][8] = CreateAchievement("7 days", "Congratulations! You have spent ~r~7 days~w~ on the server.~n~You recieve +45 score and $20000 cash.~n~~y~Next achievement: ~w~14 days.", 10080);
	sAchievements[aTime][9] = CreateAchievement("14 days", "Congratulations! You have spent ~r~14 days~w~ on the server.~n~You recieve +75 score and $30000 cash.~n~~y~Next achievement: ~w~30 days.", 20160);
	sAchievements[aTime][10] = CreateAchievement("30 days", "Congratulations! You have spent ~r~30 days~w~ on the server.~n~You recieve +100 score and $50000 cash.~n~~y~Next achievement: ~w~2 months.", 43200);
	sAchievements[aTime][11] = CreateAchievement("2 months", "Congratulations! You have spent ~r~2 months~w~ on the server.~n~You recieve +250 score and $750000 cash.~n~~y~Next achievement: ~w~6 months.", 86400);
	sAchievements[aTime][12] = CreateAchievement("6 months", "Congratulations! You have spent ~r~6 months~w~ on the server.~n~You recieve +500 score and $100000 cash.~n~~y~Next achievement: ~w~1 year.", 259200);
	sAchievements[aTime][13] = CreateAchievement("1 year", "Congratulations! You have spent ~r~1 year~w~ on the server.~n~You recieve +2000 score and $500000 cash.~n~~y~Next achievement: ~w~Immortality!", 518400);
	// Rare ones
	sAchievements[aLowHealth] = CreateAchievement("Death kill", "Congratulations! You managed to kill a player with 1.00 health.~n~You recieve +5 score and $5000 cash.", 1);
	// Spawn
	sAchievements[aFirstSpawn] = CreateAchievement("First spawn", "You have spawned for the first time in the server.~n~You recieve +1 score and $5000 cash.", 1);

	// MySQL
	mysql_init();

	// Commands
	Command_AddAltNamed("reply", "r");
	Command_AddAltNamed("commands", "cmds");


	gCurrentMap = -1;
	gLastCount = gettime();

	#if USE_BLOODSCREEN==1
	FadeInit();
	#endif

	print("Everything went ahead properly. Gamemode started.");
	return 1;
}

public OnGameModeExit()
{
	Exit_AchSystem();
	print(" ");
	print("_______________________________________________________");
	print(" ");
	print("Closing server....");
	print(" ");
	print("Imma print the same shit as in initiation.");
	print(" ");
	print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
	print(""SERVER_NAME"");
	print("Version "SERVER_VERSION"");
	print("Developed by Cell_  (164585)");
	print("Start date 8/26/2014");
	print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
	print(" ");
	print("Close succsessful!");
	print(" ");
	print("_______________________________________________________");
	print(" ");

	destroyTextdraws();
	DestroyAllDynamicObjects();
	
	#if defined USE_IRC
		disconnectBots();
	#endif	

	mysql_exit();

	#if USE_BLOODSCREEN==1
	FadeExit();
	#endif

	return 1;
}

public OnPlayerConnect(playerid)
{
    mysql_banCheck(playerid);
    mysql_getAKA(playerid);

	gPlayerCount++;
	ach_OnPlayerConnect(playerid);

	SendServerMessage(playerid, "Hello and welcome to the server!");
	SendServerMessage(playerid, "Enjoy your stay!");
	SendServerMessage(playerid, "This server needs some staff. Contact any of the admins to know more.");
	SendServerMessage(playerid, "We are also looking at setting up a Discord server soon.");
	
	#if defined USE_IRC
		SendServerMessage(playerid, "This server is connected to \'"COL_RED""IRC_SERVER"{FFFFFF}\', Channel: \'"COL_RED""IRC_CHANNEL"{FFFFFF}\'.");
	#endif

	GetPlayerName(playerid, playerName(playerid), MAX_PLAYER_NAME);
	GetPlayerIp(playerid, playerIP(playerid), 16);
	GetPlayerIp(playerid, playerIP(playerid), 16);

	ResetVariables(playerid);

	TextDrawHideForPlayer(playerid, mapChangeTD[0]);
	TextDrawHideForPlayer(playerid, mapChangeTD[1]);
	TextDrawHideForPlayer(playerid, mapChangeTD[2]);
	TextDrawShowForPlayer(playerid, versionTD);
	for(new x = 0; x < sizeof(infoTD); x++) TextDrawHideForPlayer(playerid, infoTD[x]);
	for(new i = 0; i < MAX_PLAYERS; i++) HideProgressBarForPlayer(playerid, helmetHealthBar[i]);
	hideMapInfoTDs(playerid);
	hideRoundEndTDs(playerid);
	hideKillCam(playerid);

	SetPlayerColor(playerid, COLOR_GRAY);

	#if USE_BLOODSCREEN==1
	FadePlayerConnect(playerid);
	#endif

	mysql_onPlayerConnect(playerid);
	RemoveBuildings(playerid);

	formatex(g_string, "[JOIN]: "COL_GRAY"%s <%d> {FFFFFF}connected to the server.", playerName(playerid), playerid);
	formatex(g_bString, "[JOIN]: "COL_GRAY"%s <%d> {FFFFFF}connected to the server. [IP: %s].", playerName(playerid), playerid, playerIP(playerid));

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] > 0)
		{
			SendClientMessage(x, COLOR_PINK, g_bString);
		}
		else
		{
			SendClientMessage(x, COLOR_PINK, g_string);
		}
	}

	#if defined USE_IRC
		formatex(g_string, "3,15[JOIN]: %s <%d> joined the server!", playerName(playerid), playerid);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);

		formatex(g_string, "3,15[JOIN]: 1,15%s <%d> joined the server! [IP: 1,15%s]", playerName(playerid), playerid, playerIP(playerid));
		IRC_CSay(g_string, 1337);
	#endif
	
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	gPlayerCount--;

	pInfo[playerid][pTotalSecondsPlayed] += pInfo[playerid][pSecondsPlayed];
	pInfo[playerid][pTotalMinutesPlayed] += pInfo[playerid][pMinutesPlayed];
	pInfo[playerid][pTotalHoursPlayed] += pInfo[playerid][pHoursPlayed];

	format(pInfo[playerid][pLastSession], 24, "%d %d %d", pInfo[playerid][pHoursPlayed], pInfo[playerid][pMinutesPlayed], pInfo[playerid][pSecondsPlayed]);

	mysql_onPlayerDisconnect(playerid, reason);
	ach_OnPlayerDisconnect(playerid);

	new tempString[256];

	switch(reason)
	{
		case 0:
		{
			formatex(g_bString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Desync{FFFFFF})", playerName(playerid), playerid);
			formatex(tempString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Desync{FFFFFF}) [IP: %s]", playerName(playerid), playerid, playerIP(playerid));
		}

		case 1:
		{
			formatex(g_bString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Leave{FFFFFF})", playerName(playerid), playerid);
			formatex(tempString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Leave{FFFFFF}) [IP: %s]", playerName(playerid), playerid, playerIP(playerid));
		}

		case 2:
		{
			formatex(g_bString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Kick{FFFFFF})", playerName(playerid), playerid);
			formatex(tempString, "[PART]: "COL_GRAY"%s <%d> {FFFFFF}disconnected from the server. ("COL_YELLOW"Kick{FFFFFF}) [IP: %s]", playerName(playerid), playerid, playerIP(playerid));
		}
	}

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] > 0)
		{
			SendClientMessage(x, COLOR_PINK, tempString);
		}
		else
		{
			SendClientMessage(x, COLOR_PINK, g_bString);
		}
	}

	#if defined USE_IRC
		switch(reason)
		{
			case 0:
			{
				formatex(g_bString, "13,15[PART]: %s <%d> left the the server! (Reason: 1,15Connection Problem)", playerName(playerid), playerid);
				formatex(g_string, "3,15[PART]: 1,15%s <%d> left the server! (Reason: 1,15Desynced)  [IP: 1,15%s]", playerName(playerid), playerid, playerIP(playerid));
			}

			case 1:
			{
				formatex(g_bString, "13,15[PART]: %s <%d> left the the server! (Reason: 1,15Leaving)", playerName(playerid), playerid);
				formatex(g_string, "3,15[PART]: 1,15%s <%d> left the server! (Reason: 1,15Leaving)  [IP: 1,15%s]", playerName(playerid), playerid, playerIP(playerid));
			}

			case 2:
			{
				formatex(g_bString, "13,15[PART]: %s <%d> left the the server! (Reason: 1,15Kicked)", playerName(playerid), playerid);
				formatex(g_string, "3,15[PART]: 1,15%s <%d> left the server! (Reason: 1,15Kicked)  [IP: 1,15%s]", playerName(playerid), playerid, playerIP(playerid));
			}
		}

		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
		IRC_CSay(g_string, 1337);
	#endif
	
	if(IsValidObject(pInfo[playerid][pDamageObject])) DestroyObject(pInfo[playerid][pDamageObject]);


	#if USE_BLOODSCREEN==1
	FadePlayerDisconnect(playerid);
	#endif

	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerInterior(playerid,0);
	SetPlayerPos(playerid, -2667.6221, 1594.9678, 217.2739);
	SetPlayerCameraPos(playerid, -2676.2485, 1594.9004, 219.2739);
	SetPlayerCameraLookAt(playerid, -2667.6221, 1594.9678, 217.2739);
	SetPlayerFacingAngle(playerid, 84.1685);

	switch(classid)
	{
		case 0..5:
		{
			GameTextForPlayer(playerid, "~n~~n~~n~~b~Cops", 1000, 5);
			gTeam[playerid] = TEAM_COP;
		}

		default:
		{
			GameTextForPlayer(playerid, "~n~~n~~n~~r~Terrorists", 1000, 5);
			gTeam[playerid] = TEAM_TER;
		}
	}

	SetPlayerTeam(playerid, 1);
	pInfo[playerid][pLastClass] = classid;
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{

	new
		temp[2]
	;

	foreach(new x : Player)
	{
		if(pInfo[x][pSpawned])
		{
			if(gTeam[x] != -1)
			{
				temp[gTeam[x]]++;
			}
		}
	}

	switch(pInfo[playerid][pLastClass])
	{
		case 0..5:
		{
			if(temp[TEAM_COP] > temp[TEAM_TER])
			{
				GameTextForPlayer(playerid, "~n~~n~~w~This team has enough players. ~n~Please join ~r~Team Terrorists~w~.", 2000, 5);

				return 0;
			}

			return 1;
		}

		default:
		{
			if(temp[TEAM_TER] > temp[TEAM_COP])
			{
				GameTextForPlayer(playerid, "~n~~n~~w~This team has enough players. ~n~Please join ~b~Team Cops~w~.", 2000, 5);

				return 0;
			}
		}
	}

	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetCameraBehindPlayer(playerid);

	if(pInfo[playerid][pRegistered])
	{
		if(!pInfo[playerid][pLoggedIn])
		{
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Login", ""COL_WHITE"Please input your password to log in.", "Login", "");
		}
	}

	// SetPlayerPosEx(playerid, -2620.8210, 1401.2201, 7.1016, 269.7980);

	pInfo[playerid][pSpawned] = 1;
	pInfo[playerid][pDead] = 0;
	pInfo[playerid][pLaserColor] = 18643;
	hideKillCam(playerid);

	takeCareOfSpawn(playerid);

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	new
		killeridex = pInfo[playerid][pLastDamage],
		reasonex = pInfo[playerid][pLastDamageReason]
	;

	GameTextForPlayer(playerid, "~n~~r~Wasted!", 2000, 4);
	HideProgressBarForPlayer(playerid, helmetHealthBar[playerid]);

	if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_ARMOUR_INDEX)) RemovePlayerAttachedObject(playerid, ATTACH_ARMOUR_INDEX);
	if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_HELMET_INDEX)) RemovePlayerAttachedObject(playerid, ATTACH_HELMET_INDEX);
	if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACHMENT_INDEX_LASER1)) RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1);
	if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACHMENT_INDEX_LASER2)) RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);

	if(!pInfo[playerid][pCallDeath])
	{
		SendDeathMessage(killeridex, playerid, reasonex);

		if(killeridex != INVALID_PLAYER_ID)
		{

			pInfo[playerid][pDeaths]++;
			pInfo[killeridex][pKills]++;
			pInfo[playerid][pTotalDeaths]++;
			pInfo[killeridex][pTotalKills]++;
			pInfo[killeridex][pKillStreak]++;

			IncreasePlayerScore(killeridex, 1);

			for(new i = 0; i < sizeof(sAchievements[aKill]); i++)
			{
				if(!DidPlayerAchieve(killeridex, sAchievements[aKill][i]))
				{
					GivePlayerAchievement(killeridex, sAchievements[aKill][i], 1);
				}
			}

			new Float:pHealth;
			GetPlayerHealth(killeridex, pHealth);
			if(floatround(pHealth) == 1)
			{
				if(!DidPlayerAchieve(killeridex, sAchievements[aLowHealth]))
				{
					GivePlayerAchievement(killeridex, sAchievements[aLowHealth], 1);
				}
			}

			if(pInfo[playerid][pKillStreak] > 1)
			{
				if(pInfo[playerid][pKillStreak] > 5)
				{
					formatex(g_string, "[KILLSTREAK]: "COL_GRAY"%s <%d> {FFFFFF}just ended "COL_GRAY"%s <%d>{FFFFFF}'s killstreak of "COL_RED"%d{FFFFFF}.", playerName(killeridex), killeridex, playerName(playerid), playerid, pInfo[playerid][pKillStreak]);
					SendClientMessageToAll(COLOR_DRED, g_string);

					#if defined USE_IRC
						formatex(g_bString, "4,15[KILL]: %d,15%s <%d> ended %d,15%s's <%d> killstreak of 1,15%d. (1,15%s)", ((gTeam[killeridex] == TEAM_TER) ? (4) : (12)), playerName(killeridex), killeridex, ((gTeam[playerid] == TEAM_TER) ? (4) : (12)), playerName(playerid), playerid, pInfo[playerid][pKillStreak], deathReason[reasonex]);
						IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
					#endif
					formatex(g_string, "[KILL]: "COL_WHITE"You get 1 score and $200 for ending %s <%d>'s killstreak.", playerName(playerid), playerid);
					SendClientMessage(killeridex, COLOR_DRED, g_string);

					pInfo[playerid][pKillMessage] = 1;

					GivePlayerMoney(killeridex, 200);
					IncreasePlayerScore(killeridex, 1);
				}
			}

			pInfo[playerid][pKillStreak] = 0;

			if(!pInfo[playerid][pKillMessage])
			{
				GivePlayerMoney(killeridex, 150);

				/*formatex(g_bString, "[KILL]: "COL_GRAY"%s <%d> {FFFFFF}killed "COL_GRAY"%s <%d>{FFFFFF}. ("COL_YELLOW"%s{FFFFFF})", playerName(killeridex), killeridex, playerName(playerid), playerid, deathReason[reasonex]);
				SendClientMessageToAll(COLOR_DRED, g_bString);*/
				#if defined USE_IRC
					formatex(g_bString, "4,15[KILL]: %d,15%s <%d> killed %d,15%s <%d>. (1,15%s)", ((gTeam[killeridex]) ? (4) : (12)), playerName(killeridex), killeridex, ((gTeam[playerid]) ? (4) : (12)), playerName(playerid), playerid, deathReason[reasonex]);
					IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
				#endif				
				formatex(g_string, "[KILL]: "COL_WHITE"You get +1 score and $150 for killing %s <%d>.", playerName(playerid), playerid);
				SendClientMessage(killeridex, COLOR_DRED, g_string);
			}

			else
			{
				pInfo[playerid][pKillMessage] = 1;
			}

			if(gTeam[killeridex] != gTeam[playerid])
			{
				if(gTeam[killeridex] == TEAM_COP)
					gTeamKills[TEAM_COP]++;

				if(gTeam[killeridex] == TEAM_TER)
					gTeamKills[TEAM_TER]++;

				kills_updateInfoTD();
			}
		}
	}

	else
	{
		pInfo[playerid][pCallDeath] = 0;
	}

	TextDrawHideForPlayer(playerid, mapChangeTD[0]);
	TextDrawHideForPlayer(playerid, mapChangeTD[1]);
	TextDrawHideForPlayer(playerid, mapChangeTD[2]);
	for(new i = 0; i < sizeof(infoTD); i++) TextDrawHideForPlayer(playerid, infoTD[i]);
	hideMapInfoTDs(playerid);

	if(IsValidObject(pInfo[playerid][pDamageObject])) DestroyObject(pInfo[playerid][pDamageObject]);

	pInfo[playerid][pSpawned] = 0;
	pInfo[playerid][pTimeSinceSpawn] = 0;
	pInfo[playerid][pVisible] = 0;
	pInfo[playerid][pLastMark] = 0;
	pInfo[playerid][pLastDamage] = INVALID_PLAYER_ID;
	pInfo[playerid][pLastDamageReason] = 255;
	pInfo[playerid][pDead] = 1;

	if(killeridex != INVALID_PLAYER_ID)
	{
		TogglePlayerSpectating(playerid, 1);
		PlayerSpectatePlayer(playerid, killeridex);

		pInfo[playerid][pKillCam] = 5;
		showKillCam(playerid, killeridex, reasonex);
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(pInfo[playerid][pBeingKicked])
	{
		SendErrorMessage(playerid, "You are being kicked, bro. Don't talk.");
		return 0;
	}

	if(pInfo[playerid][pMuted])
	{
		SendFErrorMessage(playerid, "You have been muted by an administrator. You cannot talk for another %d seconds.", pInfo[playerid][pMuteTime]);
		return 0;
	}

	if(!pInfo[playerid][pSpamCount]) pInfo[playerid][pSpamTime] = gettime();
    pInfo[playerid][pSpamCount]++;
	if(gettime() - pInfo[playerid][pSpamTime] > 2)
	{
		pInfo[playerid][pSpamCount] = 0;
		pInfo[playerid][pSpamTime] = gettime();
	}
	else if(pInfo[playerid][pSpamCount] == 3)
	{
		formatex(g_string,"[ANTI-CHEAT]: "COL_WHITE"Player %s(%d) has been automatically kicked. (Reason: "COL_RED"Flooding{FFFFFF})", playerName(playerid), playerid);
		SendClientMessageToAll(COLOR_ORANGE, g_string);
		#if defined USE_IRC
			format(g_string,sizeof(g_string),"7,15[ANTI-SPAM]: 1,15%s <%d> has been automatically kicked. Reason: 7,15Flooding.",playerName(playerid),playerid);
			IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
		#endif
		pInfo[playerid][pBeingKicked] = 1;
		return 0;
	}
	else if(pInfo[playerid][pSpamCount] == (4-1))
	{
		SendErrorMessage(playerid, "Anti spam warning. Do not spam or else you'll be kicked.");
		return 0;
	}

    if(pInfo[playerid][pLowerText])
		UpperToLower(text);

	if(text[0] == '@')
	{
		if(IPCheck(text, 2, playerid, 1)) return 0;

		text[1] = toupper(text[1]);

		if(pInfo[playerid][pSpawned])
		{
			formatex(g_string, "[RADIO]: {FFFFFF}<%d> %s: %s", playerid, playerName(playerid), text[1]);
			mysql_log_radioChat(playerid, text);

			foreach(new x : Player)
			{
				if(pInfo[x][pSpawned])
				{
					if(gTeam[x] == gTeam[playerid]) SendClientMessage(x, 0xFFBF0033, g_string);
					#if defined USE_IRC
						formatex(g_bString, "9,15[RADIO CHAT]: <%d> %d%s: %s", playerid, ((gTeam[playerid] == TEAM_COP) ? (12) : (4)), playerName(playerid), text);
						IRC_GroupSay(irc_botGroups[1], IRC_CHANNEL, g_bString);
					#endif
				}
			}

			return 0;
		}
	}

	if(IPCheck(text, 0, playerid, 1)) return 0;

	if(text[0] == '#')
	{
		if(IPCheck(text, 2, playerid, 1)) return 0;

		if(pInfo[playerid][pVIPLevel] >= 1)
		{
			text[1] = toupper(text[1]);

			formatex(g_string, "[VIP]: {FFFFFF}<%d> %s: %s", playerid, playerName(playerid), text[1]);
			mysql_log_adminChat(playerid, g_string);

			foreach(new x : Player)
			{
				if(pInfo[x][pAdminLevel] >= 3 || pInfo[x][pVIPLevel] >= 1)
				{
					SendClientMessage(x, COLOR_VIP, g_string);
					#if defined USE_IRC							
						formatex(g_bString, "9,15[VIP CHAT]: <%d> 5%s: %s", playerid, playerName(playerid), text[1]);
						IRC_GroupSay(irc_botGroups[1], IRC_CHANNEL, g_bString);
					#endif	
				}
			}
			return 0;
		}
	}
	if(text[0] == '!')
	{
		if(IPCheck(text, 2, playerid, 1)) return 0;

		if(pInfo[playerid][pAdminLevel] >= 1)
		{
			text[1] = toupper(text[1]);

			formatex(g_string, "[ADMIN]: {FFFFFF}<%d> %s: %s", playerid, playerName(playerid), text[1]);
			mysql_log_adminChat(playerid, text);

			foreach(new x : Player)
			{
				if(pInfo[x][pAdminLevel] >= 1)
				{
					SendClientMessage(x, COLOR_ADMIN, g_string);
					#if defined USE_IRC							
						formatex(g_bString, "9,15[ADMIN CHAT]: <%d> 5%s: %s", playerid, playerName(playerid), text[1]);
						IRC_GroupSay(irc_botGroups[1], IRC_CHANNEL, g_bString);
					#endif	
				}
			}
			return 0;
		}
	}


	new
		pos
	;

	mysql_log_chat(playerid, text);

	#if defined USE_IRC
		formatex(g_bString, "9,15[CHAT]: <%d> %d%s: %s", playerid, ((gTeam[playerid] == TEAM_COP) ? (12) : (4)), playerName(playerid), text);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
	#endif

	foreach(new x : Player)
	{
		if(x != playerid)
		{
			pos = strfind(text, playerName(x));
			if(pos != -1)
			{
			    strins(text, "{FFFFFF}", pos + strlen(playerName(x)), 129);
				strins(text, "{AFAFAF}", pos, 128);
			}
		}
	}

	text[0] = toupper(text[0]);

	formatex(g_bString, "<%02d> %s%s: {FFFFFF}%s", playerid, ((gTeam[playerid] == TEAM_COP) ? (COL_BLUE) : (COL_RED)), playerName(playerid), text);
	SendClientMessageToAll(COLOR_GRAY, g_bString);

	return 0;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	#if USE_BLOODSCREEN==1
	FadeColorForPlayer(playerid, 128, 0, 0, 125, 255, 0, 0, 0, 3, 50);
	#endif

	pInfo[playerid][pLastDamage] = issuerid;
	pInfo[playerid][pLastDamageReason] = weaponid;

	if(issuerid != INVALID_PLAYER_ID) if(weaponid == 51) damagePlayer(issuerid, playerid, weaponid, amount, bodypart);
	if(issuerid != INVALID_PLAYER_ID) if(weaponid == 00) damagePlayer(issuerid, playerid, weaponid, amount, bodypart);

	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(pInfo[playerid][pAFK])
	{
		OnPlayerReturn(playerid, gettime() - pInfo[playerid][pLastUpdate]);
		pInfo[playerid][pAFK] = 0;
	}

	pInfo[playerid][pLastUpdate] = gettime();

	switch(GetPlayerCameraMode(playerid))
	{
		case 7:
		{
			if(pInfo[playerid][pHasHelmet])
			{
				if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_HELMET_INDEX))
					RemovePlayerAttachedObject(playerid, ATTACH_HELMET_INDEX);
			}
		}

		default:
		{
			if(pInfo[playerid][pHasHelmet])
			{
				if(!IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_HELMET_INDEX))
				{
					new tempVar = pInfo[playerid][pLastClass];
					SetPlayerAttachedObject(playerid, ATTACH_HELMET_INDEX, 19141, 2, helmetCoordinates[tempVar][fOffX], helmetCoordinates[tempVar][fOffY], helmetCoordinates[tempVar][fOffZ], helmetCoordinates[tempVar][fRotX], helmetCoordinates[tempVar][fRotY], helmetCoordinates[tempVar][fRotZ], helmetCoordinates[tempVar][fScaX], helmetCoordinates[tempVar][fScaY], helmetCoordinates[tempVar][fScaZ]);
				}
			}
		}
	}

    if(pInfo[playerid][pSpawned])
    {
        switch(GetPlayerWeapon(playerid))
        {
            case 0..21:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1);
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
            }

            case 22:
            {
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 5, 0.140000, 0.019999, -0.090000, 0.000000, 7.000000, -3.000000, 1.000000, 1.000000, 1.000000);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2, pInfo[playerid][pLaserColor], 6, 0.100000, 0.029999, 0.090000, 0.000000, -9.000000, 3.000000, 1.000000, 1.000000, 1.000000);
            }

            case 23:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.100000, 0.029999, 0.079999, 0.000000, -10.000000, 4.000000, 1.000000, 1.000000, 1.000000);
            }

            case 24:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.139999, 0.019999, 0.079999, 0.000000, 3.000000, 0.000000, 1.000000, 1.000000, 1.000000);
            }
            case 25:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.400000, -0.000000, 0.110000, 0.000000, -9.000000, -6.000000, 1.000000, 1.000000, 1.000000);
            }
            case 26:
            {
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 5, 0.389999, 0.019999, -0.119999, 0.000000, 5.000000, 2.000000, 1.000000, 1.000000, 1.000000);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2, pInfo[playerid][pLaserColor], 6, 0.299999, 0.019999, 0.119999, 0.000000, -6.000000, -1.000000, 1.000000, 1.000000, 1.000000);
            }
            case 27:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.200000, 0.019999, 0.139999, 0.000000, -8.000000, -6.000000, 1.000000, 1.000000, 1.000000);
            }
            case 28:
            {
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2, pInfo[playerid][pLaserColor], 6, -0.000000, 0.019999, 0.080000, 0.000000, -4.000000, -5.000000, 1.000000, 1.000000, 1.000000);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2, pInfo[playerid][pLaserColor], 5, 0.089999, 0.029999, -0.080000, 0.000000, 3.000000, 6.000000, 1.000000, 1.000000, 1.000000);
            }

            case 29:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.200000, 0.000000, 0.159999, 0.000000, -6.000000, -6.000000, 1.000000, 1.000000, 1.000000);
            }

            case 30:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.200000, 0.010000, 0.089999, 0.000000, -3.000000, -5.000000, 1.000000, 1.000000, 1.000000);
            }

            case 31:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.200000, 0.010000, 0.089999, 0.000000, -3.000000, -5.000000, 1.000000, 1.000000, 1.000000);
            }

            case 32:
            {
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.100000, 0.039999, 0.099999, 0.000000, -3.000000, -3.000000, 1.000000, 1.000000, 1.000000);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2, pInfo[playerid][pLaserColor], 5, 0.200000, 0.009999, -0.099999, 0.000000, 4.000000, 3.000000, 1.000000, 1.000000, 1.000000);
            }

            case 33:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.300000, 0.010000, 0.109999, 0.000000, -9.000000, -6.800000, 1.000000, 1.000000, 1.000000);
            }

            case 34:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, -0.199999, 0.050000, 0.040000, 0.000000, -7.000000, -5.000000, 1.000000, 1.000000, 1.000000);
            }

            case 35:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, -0.289999, 0.039999, 0.109999, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000);
            }

            case 36:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, -0.400000, 0.039999, 0.139999, 0.000000, 0.000000, 0.000000, 1.000000, 1.000000, 1.000000);
            }

            case 37:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.600000, 0.009999, 0.190000, 0.000000, -29.000000, -4.000000, 1.000000, 1.000000, 1.000000);
            }

            case 38:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
                SetPlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1, pInfo[playerid][pLaserColor], 6, 0.400000, 0.029999, -0.009999, 0.000000, -29.000000, -4.000000, 1.000000, 1.000000, 1.000000);
            }

            case 39..46:
            {
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER1);
                RemovePlayerAttachedObject(playerid, ATTACHMENT_INDEX_LASER2);
            }
        }
    }

	return 1;
}

OnPlayerAFK(playerid)
{
	formatex(g_string, "[AFK]: "COL_GRAY"%s <%d> {FFFFFF}has gone AFK.", playerName(playerid), playerid);
	SendClientMessageToAll(COLOR_PINK, g_string);

	#if defined USE_IRC
		formatex(g_string, "14,15[AFK]: %d,15%s <%d> has gone AFK.", ((gTeam[playerid] == TEAM_COP) ? (12) : (4)), playerName(playerid), playerid);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
	#endif
	return 1;
}

OnPlayerReturn(playerid, difference)
{
	formatex(g_string, "[AFK]: "COL_GRAY"%s <%d> {FFFFFF}has returned from being AFK. ("COL_YELLOW"%d seconds{FFFFFF})", playerName(playerid), playerid, difference);
	SendClientMessageToAll(COLOR_PINK, g_string);
	#if defined USE_IRC
		formatex(g_string, "14,15[AFK]: %d,15%s <%d> has returned from being AFK. (1,15%d seconds)", ((gTeam[playerid] == TEAM_COP) ? (12) : (4)), playerName(playerid), playerid, difference);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
	#endif
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_WEAPONS_BUY)
	{
		if(!response)
		{
			pInfo[playerid][pSpawnProtected] = 0;
			return 1;
		}

		if(GetPlayerMoney(playerid) < weaponsToBeBought[listitem][weaponPrice])
		{
			g_bString = "{FFFFFF}";
			for(new i = 0; i < sizeof(weaponsToBeBought); i++)
			{
				formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
			}
			pInfo[playerid][pSpawnProtected] = 99;
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");
			return SendErrorMessage(playerid, "You don't have enough cash to buy that item.");
		}

		if(pInfo[playerid][pHasItem][listitem])
		{
			g_bString = "{FFFFFF}";
			for(new i = 0; i < sizeof(weaponsToBeBought); i++)
			{
				formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
			}
			pInfo[playerid][pSpawnProtected] = 99;
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");
			return SendErrorMessage(playerid, "You already have that weapon!");
		}

		if(weaponsToBeBought[listitem][weaponID] == -1)
		{
			SetPlayerArmour(playerid, 100.0);
			pInfo[playerid][pHasItem][listitem] = 1;

			g_bString = "{FFFFFF}";
			for(new i = 0; i < sizeof(weaponsToBeBought); i++)
			{
				formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
			}
			pInfo[playerid][pSpawnProtected] = 99;
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");
		}

		else if(weaponsToBeBought[listitem][weaponID] == -2)
		{
			pInfo[playerid][pHasItem][listitem] = 1;
			pInfo[playerid][pHasHelmet] = 1;
			pInfo[playerid][pHelmetHealth] = 100.00;
			SetProgressBarValue(helmetHealthBar[playerid], 100);
			ShowProgressBarForPlayer(playerid, helmetHealthBar[playerid]);

			new tempVar = pInfo[playerid][pLastClass];

			if(!IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_HELMET_INDEX))
				SetPlayerAttachedObject(playerid, ATTACH_HELMET_INDEX, 19141, 2, helmetCoordinates[tempVar][fOffX], helmetCoordinates[tempVar][fOffY], helmetCoordinates[tempVar][fOffZ], helmetCoordinates[tempVar][fRotX], helmetCoordinates[tempVar][fRotY], helmetCoordinates[tempVar][fRotZ], helmetCoordinates[tempVar][fScaX], helmetCoordinates[tempVar][fScaY], helmetCoordinates[tempVar][fScaZ]);

			g_bString = "{FFFFFF}";
			for(new i = 0; i < sizeof(weaponsToBeBought); i++)
			{
				formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
			}
			pInfo[playerid][pSpawnProtected] = 99;
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");
		}

		else
		{
			GivePlayerWeapon(playerid, weaponsToBeBought[listitem][weaponID], weaponsToBeBought[listitem][weaponAmmo]);
			pInfo[playerid][pHasItem][listitem] = 1;

			g_bString = "{FFFFFF}";
			for(new i = 0; i < sizeof(weaponsToBeBought); i++)
			{
				formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
			}
			pInfo[playerid][pSpawnProtected] = 99;
			ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");
		}

		GivePlayerMoney(playerid, -weaponsToBeBought[listitem][weaponPrice]);
		pInfo[playerid][pHasItem][listitem] = 1;
	}

	if(dialogid == DIALOG_MAP_VOTE)
	{
		if(roundInProgress)
		{
			SendErrorMessage(playerid, "The round has already begun. You missed the vote!");
			return 1;
		}

		if(listitem == gCurrentMap)
		{
			ShowPlayerDialog(playerid, DIALOG_MAP_VOTE, DIALOG_STYLE_LIST, ""COL_YELLOW"Vote for next map", maps_string, "Select", "");
			SendErrorMessage(playerid, "You just played this map!");

			return 1;
		}

		mapVotes[listitem]++;
		formatex(g_string, "[SERVER]: {FFFFFF}You have voted for \'"COL_YELLOW"%s{FFFFFF}\' by \'"COL_YELLOW"%s{FFFFFF}\'.", mapInfo[listitem][mapName], mapInfo[listitem][mapperName]);
		SendClientMessage(playerid, COLOR_SERVER, g_string);

		return 1;
	}

	if(dialogid == DIALOG_REGISTER)
	{
		if(isnull(inputtext))
		{
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Register", ""COL_WHITE"Please input your desired password to register your account.\nYou cannot put an empty password.", "Register", "");
			return 1;
		}

		if(strlen(inputtext) < 3)
		{
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Register", ""COL_WHITE"Please input your desired password to register your account.\nFor security reasons, your password must be at least 3 words.", "Register", "");
			return 1;
		}

		if(strlen(inputtext) > 32)
		{
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Register", ""COL_WHITE"Please input your desired password to register your account.\nWe recommend a shorter password in case you forget it.", "Register", "");
			return 1;
		}

		WP_Hash(pInfo[playerid][pPassword], 129, inputtext);
		orm_insert(pInfo[playerid][pORMID], "onPlayerRegister", "is", playerid, inputtext);

		return 1;
	}

	if(dialogid == DIALOG_LOGIN)
	{
		if(isnull(inputtext))
		{
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Login", ""COL_WHITE"Please input your password to log in.\nThe input can't be left empty.", "Login", "");
			return 1;
		}

		if(strlen(inputtext) < 3)
		{
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Login", ""COL_WHITE"Please input your password to log in.\nOur password lengths are more than 3 words.", "Login", "");
			return 1;
		}

		new
			string[129]
		;

		WP_Hash(string, sizeof(string), inputtext);

		if(!strcmp(string, pInfo[playerid][pPassword]))
		{
			pInfo[playerid][pLoggedIn] = 1;

			onPlayerLogin(playerid);

			return 1;
		}

		else
		{
			pInfo[playerid][pWrongLoginAttempts]++;

			if(pInfo[playerid][pWrongLoginAttempts] >= 3)
			{
				formatex(g_string, "[SERVER]: "COL_GRAY"%s <%d> {FFFFFF}has been kicked from the server. Reason: "COL_YELLOW"Failing to log in{FFFFFF}.", playerName(playerid), playerid);
				SendClientMessageToAll(COLOR_SERVER, g_string);
				Kick(playerid);
				return 1;
			}

			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_YELLOW"Login", ""COL_WHITE"Please input your password to log in.\n"COL_RED"Wrong password, please try again!", "Login", "");

			return 1;
		}
	}

	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	pInfo[playerid][pShots]++;
	pInfo[playerid][pTotalShots]++;

	if(hittype == BULLET_HIT_TYPE_PLAYER)
	{
		if(pInfo[hitid][pSpawnProtected] >= 1)
		{
			SetPlayerChatBubble(hitid, "** SPAWNKILL PROTECTION **", COLOR_BLUE, GetPlayerDistanceFromPoint(playerid, fX, fY, fZ), 1000);
			return 0;
		}

		if(gTeam[playerid] == gTeam[hitid])
		{
			return 0;
		}
	}

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_NO) && (newkeys & KEY_AIM))
	{
		new
			player = GetPlayerTargetPlayer(playerid)
		;

		if(player != INVALID_PLAYER_ID)
		{
			if(!IsPlayerAimingAtPlayer(playerid, playerid)) return 0;
			if(IsPlayerStreamedIn(player, playerid))
			{
				if(pInfo[player][pVisible] != 1)
				{
					if(gTeam[player] != gTeam[playerid])
					{
						if(!pInfo[playerid][pLastMark])
						{
							if(gTeam[player] == TEAM_COP) SetPlayerColor(player, COLOR_COP_VIS);
							else SetPlayerColor(player, COLOR_TER_VIS);

							formatex(g_string, "[MARK]: "COL_GRAY"%s <%d> {FFFFFF}has marked "COL_GRAY"%s <%d> {FFFFFF}on the map!", playerName(playerid), playerid, playerName(player), player);
							foreach(new x : Player)
							{
								if(x != playerid && x != player)
								{
									if(pInfo[x][pSpawned])
									{
										SendClientMessage(x, COLOR_SERVER, g_string);
									}
								}
							}

							formatex(g_string, "[MARK]: {FFFFFF}You have been marked on the map by "COL_GRAY"%s <%d>{FFFFFF}. Be careful!", playerName(playerid), playerid);
							SendClientMessage(player, COLOR_SERVER, g_string);

							formatex(g_string, "[MARK]: {FFFFFF}You have marked "COL_GRAY"%s <%d> {FFFFFF}on the map. You get +1 score and $150!", playerName(player), player);
							SendClientMessage(playerid, COLOR_SERVER, g_string);

							formatex(g_string, "13,15[MARK]: %d,15%s <%d> has marked %d,15%s <%d> on the map.", ((gTeam[playerid] == TEAM_COP) ? (4) : (12)), playerName(playerid), playerid, ((gTeam[player] == TEAM_COP) ? (4) : (12)), playerName(player), player);

							IncreasePlayerScore(playerid, 1);
							GivePlayerMoney(playerid, 150);

							pInfo[player][pVisible] = 1;
							pInfo[playerid][pLastMark] = 20;
							pInfo[playerid][pMarks]++;
							pInfo[playerid][pTotalMarks]++;

							for(new i = 0; i < sizeof(sAchievements[aMark]); i++)
							{
								if(!DidPlayerAchieve(playerid, sAchievements[aMark][i]))
								{
									GivePlayerAchievement(playerid, sAchievements[aMark][i], 1);
								}
							}

							return 1;
						}
					}
				}
			}
		}
	}

	return 1;
}

stock num_hash(buf[])
{
	new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++) {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

SetPlayerPosEx(playerid, Float:XX, Float:YY, Float:ZZ, Float:Angle, Interior = 0, VW = 0)
{
	Streamer_UpdateEx(playerid, XX, YY, ZZ + 2.00);
	SetPlayerPos(playerid, XX, YY, ZZ);
	SetPlayerFacingAngle(playerid, Angle);
	SetPlayerInterior(playerid, Interior);
	SetPlayerVirtualWorld(playerid, VW);
	SetCameraBehindPlayer(playerid);

	return 1;
}

public mapChange()
{
	if(gMapSpecified == -1) gCurrentMap = getNextMap();

	else
	{
		gCurrentMap = gMapSpecified;
		gMapSpecified = -1;
	}

	roundInProgress = 1;

	foreach(new x : Player)
		takeCareOfSpawn(x);

	formatex(g_string, "mapname %s", mapInfo[gCurrentMap][mapName]);
	SendRconCommand(g_string);

	roundTimer[0] = mapInfo[gCurrentMap][mapTime];
	roundTimer[1] = 0;

	updateMapInfoTDs();

	formatex(g_string, "[SERVER]: {FFFFFF}The map has been changed! New map: "COL_GREEN"%s{FFFFFF}.", mapInfo[gCurrentMap][mapName]);
	SendClientMessageToAll(COLOR_SERVER, g_string);

	#if defined USE_IRC
		formatex(g_string, "10,15[MAP]: Server map has been changed to 1,15%s.", mapInfo[gCurrentMap][mapName]);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
	#endif
	
	return 1;
}

public mapChanged(playerid)
{
	if(!pInfo[playerid][pInFight]) return 0;

	TogglePlayerControllable(playerid, true);
	GameTextForPlayer(playerid, "~r~FIGHT!", 1000, 4);
	TextDrawHideForPlayer(playerid, mapChangeTD[0]);
	TextDrawHideForPlayer(playerid, mapChangeTD[1]);
	TextDrawHideForPlayer(playerid, mapChangeTD[2]);

	if(!DidPlayerAchieve(playerid, sAchievements[aFirstSpawn]))
	{
		GivePlayerAchievement(playerid, sAchievements[aFirstSpawn], 1);
	}

	kills_updateInfoTD();

	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

getNextMap()
{
	new nextmap = 0,
		highestVotes = -1
	;

	for(new i = 0; i < TOTAL_MAPS; i++)
	{
		if(mapVotes[i] > highestVotes)
		{
			highestVotes = mapVotes[i];
			nextmap = i;
		}

		mapVotes[i] = 0;
	}
	return nextmap;
}

mapEnd()
{
	roundInProgress = 0;

	for(new i = 0; i < sizeof(infoTD); i++) { TextDrawHideForAll(infoTD[i]); }
	for(new i = 0; i < sizeof(mapInfoTD); i++) { TextDrawHideForAll(mapInfoTD[i]); }

	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(IsPlayerConnected(i))
		{
			r_playerKills[i][r_playerRank] = pInfo[i][pKills];
			r_playerKills[i][r_playerID] = i;

			r_playerDeaths[i][r_playerRank] = pInfo[i][pDeaths];
			r_playerDeaths[i][r_playerID] = i;

			if(pInfo[i][pDeaths] != 0) r_playerKDRatio[i][r_playerRankEx] = floatdiv((pInfo[i][pKills]), pInfo[i][pDeaths]); else r_playerKDRatio[i][r_playerRankEx] = 0.00;
			r_playerKDRatio[i][r_playerIDEx] = i;

			r_playerHeadShots[i][r_playerRank] = pInfo[i][pHeadShots];
			r_playerHeadShots[i][r_playerID] = i;

			if(pInfo[i][pShots] != 0) r_playerAccuracy[i][r_playerRankEx] = floatdiv((pInfo[i][pHits] * 100), pInfo[i][pShots]);
			else r_playerAccuracy[i][r_playerRankEx] = 0.00;
			r_playerAccuracy[i][r_playerIDEx] = i;

			r_playerMarks[i][r_playerRank] = pInfo[i][pMarks];
			r_playerMarks[i][r_playerID] = i;
		}

		else
		{
			r_playerKills[i][r_playerRank] = -1;
			r_playerKills[i][r_playerID] = -1;

			r_playerDeaths[i][r_playerRank] = -1;
			r_playerDeaths[i][r_playerID] = -1;

			r_playerKDRatio[i][r_playerRankEx] = -1.00;
			r_playerKDRatio[i][r_playerIDEx] = -1;

			r_playerHeadShots[i][r_playerRank] = -1;
			r_playerHeadShots[i][r_playerID] = -1;

			r_playerAccuracy[i][r_playerRankEx] = -1;
			r_playerAccuracy[i][r_playerIDEx] = -1;

			r_playerMarks[i][r_playerRank] = -1;
			r_playerMarks[i][r_playerID] = -1;
		}
	}

	#if defined USE_IRC
		formatex(g_bString, "10,15[MAP]: Round ended! Winners: %d,15Team %s (12,15%d : 4,15%d).", ((gTeamKills[TEAM_COP] > gTeamKills[TEAM_TER]) ? (12) : (gTeamKills[TEAM_COP] == gTeamKills[TEAM_TER]) ? (7) : (4)), ((gTeamKills[TEAM_COP] > gTeamKills[TEAM_TER]) ? ("Cops") : (gTeamKills[TEAM_COP] == gTeamKills[TEAM_TER]) ? ("None") : ("Terrorists")), gTeamKills[TEAM_COP], gTeamKills[TEAM_TER]);
		IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
	#endif

	SortDeepArray(r_playerKills, r_playerRank, .order = SORT_DESC);
	SortDeepArray(r_playerDeaths, r_playerRank, .order = SORT_DESC);
	SortDeepArray(r_playerKDRatio, r_playerRankEx, .order = SORT_DESC);
	SortDeepArray(r_playerHeadShots, r_playerRank, .order = SORT_DESC);
	SortDeepArray(r_playerAccuracy, r_playerRankEx, .order = SORT_DESC);
	SortDeepArray(r_playerMarks, r_playerRank, .order = SORT_DESC);

	updateRoundEndTDs();

	foreach(new x: Player)
	{
		if((pInfo[x][pSpawned]) && (pInfo[x][pFirstSpawn]))
		{
			TogglePlayerSpectating(x, true);
			PlayerSpectatePlayer(x, x);
			showRoundEndTDs(x);
			hideKillCam(x);
			pInfo[x][pKillCam] = 0;
		}

		ResetPlayerWeapons(x);
		SetPlayerArmour(x, 0.00);
		pInfo[x][pCounted] = 0;

		pInfo[x][pMarks] = 0;
		pInfo[x][pKills] = 0;
		pInfo[x][pDeaths] = 0;
		pInfo[x][pHeadShots] = 0;
		pInfo[x][pNutShots] = 0;
		pInfo[x][pHits] = 0;
		pInfo[x][pShots] = 0;
		pInfo[x][pHasHelmet] = 0;
		pInfo[x][pHelmetHealth] = 0.0;

		pInfo[x][pBuySystem] = 0;

		for(new i = 0; i < 13; i++)
		{
			pInfo[x][pHasItem][i] = 0;
		}

		if(gTeamKills[TEAM_COP] != gTeamKills[TEAM_TER])
		{
			if(gTeamKills[TEAM_COP] > gTeamKills[TEAM_TER])
			{
				if(gTeam[x] == TEAM_COP)
				{
					pInfo[x][pWins]++;
					GivePlayerMoney(x, 7500);
				}

				else if(gTeam[x] == TEAM_TER)
				{
					pInfo[x][pLosses]++;
					GivePlayerMoney(x, 5000);
				}
			}

			else
			{
				if(gTeam[x] == TEAM_TER)
				{
					pInfo[x][pWins]++;
					GivePlayerMoney(x, 7500);
				}

				else if(gTeam[x] == TEAM_COP)
				{
					pInfo[x][pLosses]++;
					GivePlayerMoney(x, 5000);
				}
			}
		}
	}

	gTeamKills[TEAM_COP] = 0;
	gTeamKills[TEAM_TER] = 0;

	gTeamPlayers[TEAM_COP] = 0;
	gTeamPlayers[TEAM_TER] = 0;
	SetTimer("askToVote", 15000, false);
	SetTimer("mapChange", 30000, false);
	return 1;
}

forward askToVote();
public askToVote()
{
	maps_string = "{FFFFFF}";
	for(new i = 0; i < TOTAL_MAPS; i++)
	{
		if(i != gCurrentMap) formatex(maps_string, "%s%02d - %s by %s.\n", maps_string, i, mapInfo[i][mapName], mapInfo[i][mapperName]);
		else formatex(maps_string, "%s"COL_RED"%02d - %s by %s. (Can't vote)"COL_WHITE"\n", maps_string, i, mapInfo[i][mapName], mapInfo[i][mapperName]);
	}

	foreach(new x : Player)
	{
		hideRoundEndTDs(x);
		ShowPlayerDialog(x, DIALOG_MAP_VOTE, DIALOG_STYLE_LIST, ""COL_YELLOW"Vote for next map", maps_string, "Select", "");
	}

	return 1;
}

takeCareOfSpawn(playerid)
{
	if(!pInfo[playerid][pSpawned]) return 1;

	TogglePlayerSpectating(playerid, false);

	if(!roundInProgress)
	{
		SetPlayerPosEx(playerid, 480.6109,-1499.5015,20.4830,264.7466);

		return 1;
	}

	if(gTeam[playerid] == TEAM_COP)
	{
		SetPlayerPosEx(playerid, cop_spawnPoints[gCurrentMap][lastCopSpawn][s_posX], cop_spawnPoints[gCurrentMap][lastCopSpawn][s_posY], cop_spawnPoints[gCurrentMap][lastCopSpawn][s_posZ], cop_spawnPoints[gCurrentMap][lastCopSpawn][s_Angle], cop_spawnPoints[gCurrentMap][lastCopSpawn][s_Interior]);

		lastCopSpawn++;
		if(lastCopSpawn >= 3) lastCopSpawn = 0;

		if(!pInfo[playerid][pCounted] && pInfo[playerid][pFirstSpawn] == 0)
		{
			formatex(g_string, "[SPAWN]: "COL_GRAY"%s <%d>{FFFFFF} joined "COL_BLUE"Team Cops{FFFFFF}.", playerName(playerid), playerid);
			SendClientMessageToAll(COLOR_YELLOW, g_string);

			#if defined USE_IRC				
				formatex(g_string, "11,15[SPAWN]: 12,15%s <%d> joined 12,15Team Cops.", playerName(playerid), playerid);
				IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
			#endif
			
			GivePlayerMoney(playerid, -(GetPlayerMoney(playerid)));
			GivePlayerMoney(playerid, 5000);
			pInfo[playerid][pFirstSpawn] = 1;
		}

		SetPlayerColor(playerid, COLOR_COP_INV);
		SetPlayerFightingStyle(playerid, FIGHT_STYLE_GRABKICK);
	}

	if(gTeam[playerid] == TEAM_TER)
	{
		SetPlayerPosEx(playerid, ter_spawnPoints[gCurrentMap][lastTerSpawn][s_posX], ter_spawnPoints[gCurrentMap][lastTerSpawn][s_posY], ter_spawnPoints[gCurrentMap][lastTerSpawn][s_posZ], ter_spawnPoints[gCurrentMap][lastTerSpawn][s_Angle], ter_spawnPoints[gCurrentMap][lastTerSpawn][s_Interior]);

		lastTerSpawn++;
		if(lastTerSpawn >= 3) lastTerSpawn = 0;

		if(!pInfo[playerid][pCounted] && pInfo[playerid][pFirstSpawn] == 0)
		{
			formatex(g_string, "[SPAWN]: "COL_GRAY"%s <%d>{FFFFFF} joined "COL_RED"Team Terrorists{FFFFFF}.", playerName(playerid), playerid);
			SendClientMessageToAll(COLOR_YELLOW, g_string);

			#if defined USE_IRC
				formatex(g_string, "11,15[SPAWN]: 4,15%s <%d> joined 4,15Team Terrorists.", playerName(playerid), playerid);
				IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_string);
			#endif			

			GivePlayerMoney(playerid, -(GetPlayerMoney(playerid)));
			GivePlayerMoney(playerid, 5000);
			pInfo[playerid][pFirstSpawn] = 1;
		}

		SetPlayerColor(playerid, COLOR_TER_INV);
		SetPlayerFightingStyle(playerid, FIGHT_STYLE_KUNGFU);
	}

	pInfo[playerid][pInFight] = 1;
	pInfo[playerid][pCounted] = 1;
	pInfo[playerid][pSpawnProtected] = 8;

	TextDrawShowForPlayer(playerid, mapChangeTD[0]);
	TextDrawShowForPlayer(playerid, mapChangeTD[1]);
	TextDrawShowForPlayer(playerid, mapChangeTD[2]);
	for(new i = 0; i < sizeof(infoTD); i++) TextDrawShowForPlayer(playerid, infoTD[i]);
	showMapInfoTDs(playerid);

	TogglePlayerControllable(playerid, false);
	SetPlayerVirtualWorld(playerid, playerid);

	GivePlayerWeapon(playerid, 22, 500);
	GivePlayerWeapon(playerid, 30, 500);
	SetPlayerHealth(playerid, 100.0);

	if(!pInfo[playerid][pBuySystem])
	{
		g_bString = "{FFFFFF}";
		for(new i = 0; i < sizeof(weaponsToBeBought); i++)
		{
			formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
		}
		ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");

		pInfo[playerid][pBuySystem] = 1;
		pInfo[playerid][pSpawnProtected] = 99;
	}

	else if(pInfo[playerid][pBuyAllowed])
	{
		g_bString = "{FFFFFF}";
		for(new i = 0; i < sizeof(weaponsToBeBought); i++)
		{
			formatex(g_bString, "%s%s ($%d)\n", g_bString, weaponsToBeBought[i][weaponName], weaponsToBeBought[i][weaponPrice]);
		}
		ShowPlayerDialog(playerid, DIALOG_WEAPONS_BUY, DIALOG_STYLE_LIST, ""COL_YELLOW"Buy weapon", g_bString, "Ok", "Cancel");

		pInfo[playerid][pBuyAllowed] = 0;
		pInfo[playerid][pSpawnProtected] = 99;
	}

	for(new i = 0; i < sizeof(weaponsToBeBought); i++)
	{
		if(pInfo[playerid][pHasItem][i])
		{
			if(weaponsToBeBought[i][weaponID] == -1)
				SetPlayerArmour(playerid, 100.0);

			if(weaponsToBeBought[i][weaponID] == -2)
			{
				pInfo[playerid][pHasHelmet] = 1;
				SetProgressBarValue(helmetHealthBar[playerid], 100);
				ShowProgressBarForPlayer(playerid, helmetHealthBar[playerid]);
				pInfo[playerid][pHelmetHealth] = 100.00;

				new tempVar = pInfo[playerid][pLastClass];
				if(!IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_HELMET_INDEX))
				SetPlayerAttachedObject(playerid, ATTACH_HELMET_INDEX, 19141, 2, helmetCoordinates[tempVar][fOffX], helmetCoordinates[tempVar][fOffY], helmetCoordinates[tempVar][fOffZ], helmetCoordinates[tempVar][fRotX], helmetCoordinates[tempVar][fRotY], helmetCoordinates[tempVar][fRotZ], helmetCoordinates[tempVar][fScaX], helmetCoordinates[tempVar][fScaY], helmetCoordinates[tempVar][fScaZ]);
			}

			else
				GivePlayerWeapon(playerid, weaponsToBeBought[i][weaponID], weaponsToBeBought[i][weaponAmmo]);
		}
	}

	players_updateInfoTD();
	SetTimerEx("mapChanged", 3000, false, "i", playerid);

	return 1;
}

Float:GetPlayerDistanceFromPlayer(playerid, fromplayerid)
{
	new
		Float:pos[3]
	;

	GetPlayerPos(fromplayerid, pos[0], pos[1], pos[2]);
	return GetPlayerDistanceFromPoint(playerid, pos[0], pos[1], pos[2]);
}

damagePlayer(playerid, damagedid, weaponid, Float:amount, bodypart)
{
	new
		Float:distance = GetPlayerDistanceFromPlayer(playerid, damagedid),
		Float:pHealth,
		Float:formula = bodypart,
		smallString[8]
	;

	switch(weaponid)
	{
		case 16, 35, 36:
		{
			GetPlayerArmour(damagedid, pHealth);

			formatex(smallString, "Damage: {FFFFFF}%d", floatround(amount));
			SetPlayerChatBubble(damagedid, smallString, COLOR_RED, GetPlayerDistanceFromPlayer(playerid, damagedid), 1000);

			if(pHealth == 0.00 || bodypart != 3)
			{
				GetPlayerHealth(damagedid, pHealth);
				SetPlayerHealth(damagedid, pHealth - amount);
			}

			else
			{
				if(pHealth >= amount)
				{
					SetPlayerArmour(damagedid, pHealth - amount);
				}

				else
				{
					new Float:difference = amount - pHealth;
					SetPlayerArmour(damagedid, 0.00);
					GetPlayerHealth(damagedid, pHealth);
					SetPlayerHealth(damagedid, pHealth - difference);
				}
			}
		}

		case 24:
		{
			if(distance > 10.00) formula = (weaponDamageData[weaponid][wDD_amount] - ((weaponDamageData[weaponid][wDD_amount] * distance) / 100));
			else formula = weaponDamageData[weaponid][wDD_amount];

			if(formula < 2.5) formula = 2.5;

			formatex(smallString, "-%d", floatround(formula));
			SetPlayerChatBubble(damagedid, smallString, COLOR_RED, 10.00, 1000);

			GetPlayerArmour(damagedid, pHealth);

			if(pHealth == 0.00 || bodypart != 3)
			{
				GetPlayerHealth(damagedid, pHealth);
				SetPlayerHealth(damagedid, pHealth - formula);
			}

			else
			{
				if(pHealth >= formula)
				{
					SetPlayerArmour(damagedid, pHealth - formula);
				}

				else
				{
					new Float:difference = formula + pHealth;
					SetPlayerArmour(damagedid, 0.00);
					GetPlayerHealth(damagedid, pHealth);
					SetPlayerHealth(damagedid, pHealth - difference);
				}
			}
		}

		case 0..15, 17..23, 25..34, 37..40:
		{
			if(distance > 10.00) formula = ((weaponDamageData[weaponid][wDD_amount] - (weaponDamageData[weaponid][wDD_amount] * distance) / 100));
			else formula = weaponDamageData[weaponid][wDD_amount];
			if(formula < 2.5) formula = 2.5;

			formatex(smallString, "-%d", floatround(formula));
			SetPlayerChatBubble(damagedid, smallString, COLOR_RED, 10.00, 1000);

			GetPlayerArmour(damagedid, pHealth);

			if(pHealth == 0.00 || bodypart != 3)
			{
				GetPlayerHealth(damagedid, pHealth);
				SetPlayerHealth(damagedid, pHealth - formula);
			}

			else
			{
				if(pHealth >= formula)
				{
					SetPlayerArmour(damagedid, pHealth - formula);
				}

				else
				{
					new Float:difference = formula - pHealth;
					SetPlayerArmour(damagedid, 0.00);
					GetPlayerHealth(damagedid, pHealth);
					SetPlayerHealth(damagedid, pHealth - difference);
				}
			}
		}

		default:
		{
			formula = amount;

			formatex(smallString, "-%d", floatround(formula));
			SetPlayerChatBubble(damagedid, smallString, COLOR_RED, 10.00, 1000);

			GetPlayerArmour(damagedid, pHealth);

			if(pHealth == 0.00 || bodypart != 3)
			{
				GetPlayerHealth(damagedid, pHealth);
				SetPlayerHealth(damagedid, pHealth - formula);
			}

			else
			{
				if(pHealth >= formula)
				{
					SetPlayerArmour(damagedid, pHealth - formula);
				}

				else
				{
					new Float:difference = formula - pHealth;
					SetPlayerArmour(damagedid, 0.00);
					GetPlayerHealth(damagedid, pHealth);
					SetPlayerHealth(damagedid, pHealth - difference);
				}
			}
		}
	}

	return 1;
}

public serverEverySecond()
{
	if(roundInProgress)
	{
		if(!gMapPaused)
		{
			if(gPlayerCount >= 2)
			{
				if(roundTimer[1] == 0)
				{
					roundTimer[0]--;

					if(roundTimer[0] == 0)
					{
						GameTextForAll("~n~~n~~n~~y~60 seconds remaining!", 2000, 5);
					}

					if(roundTimer[0] == -1)
					{
						mapEnd();

						return 1;
					}

					roundTimer[1] = 59;
				}

				else
					roundTimer[1]--;

				formatex(g_string, "~y~Round Timer: ~w~%02d:%02d", roundTimer[0], roundTimer[1]);
				TextDrawSetString(mapInfoTD[3], g_string);
			}
		}
	}

	if(sInfo[sCountDown] >= 1)
	{
		sInfo[sCountDown] --;
		formatex(g_string, "~g~%d", sInfo[sCountDown]);
		GameTextForAll(g_string, 800, 4);
	}

	if(!sInfo[sCountDown])
	{
		sInfo[sCountDown] --;
		GameTextForAll("~r~GO!!!~w~!", 800, 4);
		if(sInfo[sCountDownF])
		{
			sInfo[sCountDownF] = -1;
			for(new i = 0; i < MAX_PLAYERS; i++)
			{
				TogglePlayerControllable(i, 1);
			}
		}
	}

	if(gettime() - gLastCount >= 3)
	{
		gTeamPlayers[TEAM_COP] = 0;
		gTeamPlayers[TEAM_TER] = 0;

		foreach(new x : Player)
		{
			if(gTeam[x] != -1)
			{
				gTeamPlayers[gTeam[x]]++;
			}
		}

		players_updateInfoTD();
		gLastCount = gettime();
	}

	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if(gTeam[playerid] == gTeam[damagedid]) return 0;

	if(pInfo[damagedid][pSpawnProtected] >= 1)
	{
		SetPlayerChatBubble(damagedid, "** SPAWNKILL PROTECTION **", COLOR_BLUE, 30.00, 1000);
		return 0;
	}

	pInfo[playerid][pHits]++;
	pInfo[playerid][pTotalHits]++;
	pInfo[damagedid][pLastDamage] = playerid;
	pInfo[damagedid][pLastDamageReason] = weaponid;

	#if USE_HEADSHOTS == 1
		if(weaponid == 33 || weaponid == 34) // rifles
		{
			if(bodypart == 9) // Headshot!
			{
				if(gTeam[playerid] != gTeam[damagedid])
				{
					if(!pInfo[damagedid][pSpawnProtected])
					{
						if(!pInfo[damagedid][pAFK])
						{
							if(pInfo[damagedid][pDead]) return 1;

							if(pInfo[damagedid][pHasHelmet])
							{
								pInfo[damagedid][pHelmetHealth] = floatsub(pInfo[damagedid][pHelmetHealth], 35.00);

								if(pInfo[damagedid][pHelmetHealth] <= 0.00)
								{
									pInfo[damagedid][pHasHelmet] = 0;
									pInfo[damagedid][pHelmetHealth] = 0.00;

									HideProgressBarForPlayer(damagedid, helmetHealthBar[damagedid]);
									return 1;
								}

								SetProgressBarValue(helmetHealthBar[damagedid], pInfo[damagedid][pHelmetHealth]);
								HideProgressBarForPlayer(damagedid, helmetHealthBar[damagedid]);
								ShowProgressBarForPlayer(damagedid, helmetHealthBar[damagedid]);

								return 1;
							}

							SendDeathMessage(playerid, damagedid, weaponid);

							pInfo[playerid][pKillStreak]++;
							if(pInfo[damagedid][pKillStreak] > 1)
							{
								if(pInfo[damagedid][pKillStreak] > 5)
								{
									formatex(g_string, "[KILLSTREAK]: "COL_GRAY"%s <%d> {FFFFFF}just ended "COL_GRAY"%s <%d>{FFFFFF}'s killstreak of "COL_RED"%d{FFFFFF}.", playerName(playerid), playerid, playerName(damagedid), damagedid, pInfo[damagedid][pKillStreak]);
									SendClientMessageToAll(COLOR_RED, g_string);

									#if defined USE_IRC
										formatex(g_bString, "4,15[KILL]: %d,15%s <%d> ended %d,15%s's <%d> killstreak of 1,15%d. (1,15%s)", ((gTeam[playerid] == TEAM_COP) ? (4) : (12)), playerName(playerid), playerid, ((gTeam[damagedid] == TEAM_COP) ? (4) : (12)), playerName(damagedid), damagedid, pInfo[damagedid][pKillStreak], deathReason[weaponid]);
										IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
									#endif

									formatex(g_string, "[KILL]: "COL_WHITE"You get +1 score and $200 for ending %s <%d>'s killstreak.", playerName(damagedid), damagedid);
									SendClientMessage(playerid, COLOR_DRED, g_string);

									GivePlayerMoney(playerid, 200);
									IncreasePlayerScore(playerid, 1);
								}

								pInfo[damagedid][pKillStreak] = 0;
							}

							pInfo[damagedid][pCallDeath] = 1;
							SetTimerEx("OnPlayerDeath", 200, false, "iii", damagedid, playerid, 34);
							GameTextForPlayer(playerid, "Headshot!", 1000, 5);
							GameTextForPlayer(damagedid, "~r~Headshot!", 1000, 5);

							if(!pInfo[damagedid][pKillMessage])
							{
								formatex(g_string, "[KILL]: "COL_GRAY"%s <%d> {FFFFFF}headshot "COL_GRAY"%s <%d>{FFFFFF}. (Distance: "COL_YELLOW"%.2f!{FFFFFF} meters)", playerName(playerid), playerid, playerName(damagedid), damagedid, GetPlayerDistanceFromPlayer(playerid, damagedid));
								SendClientMessageToAll(COLOR_DRED, g_string);

								#if defined USE_IRC
									formatex(g_bString, "4,15[KILL]: %d,15%s <%d> killed %d,15%s <%d>. (1,15Headshot!)", ((gTeam[playerid]) ? (4) : (12)), playerName(playerid), playerid, ((gTeam[damagedid]) ? (4) : (12)), playerName(damagedid), damagedid);
									IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
								#endif
								
								GivePlayerMoney(playerid, 200);
							}

							else
							{
								pInfo[damagedid][pKillMessage] = 0;
							}

							pInfo[playerid][pHeadShots]++;
							pInfo[playerid][pTotalHeadShots]++;
							pInfo[damagedid][pDeaths]++;
							pInfo[damagedid][pTotalDeaths]++;
							pInfo[playerid][pKills]++;
							pInfo[playerid][pTotalKills]++;
							pInfo[damagedid][pDead] = 1;

							for(new i = 0; i < sizeof(sAchievements[aHeadshot]); i++)
							{
								if(!DidPlayerAchieve(playerid, sAchievements[aHeadshot][i]))
								{
									GivePlayerAchievement(playerid, sAchievements[aHeadshot][i], 1);
								}
							}

							IncreasePlayerScore(playerid, 1);

							if(gTeam[damagedid] != gTeam[playerid])
							{
								if(gTeam[playerid] == TEAM_COP)
									gTeamKills[TEAM_COP]++;

								if(gTeam[playerid] == TEAM_TER)
									gTeamKills[TEAM_TER]++;

								kills_updateInfoTD();
							}
						}
					}
				}
			}
		}
	#endif

	#if USE_NUTSHOTS == 1
		if(weaponid == 24) // rifles
		{
			if(bodypart == 4) // Nut shot!
			{
				if(gTeam[playerid] != gTeam[damagedid])
				{
					if(!pInfo[damagedid][pSpawnProtected])
					{
						if(!pInfo[damagedid][pAFK])
						{
							SendDeathMessage(playerid, damagedid, weaponid);

							pInfo[playerid][pKillStreak]++;
							if(pInfo[damagedid][pKillStreak] > 1)
							{
								if(pInfo[damagedid][pKillStreak] > 5)
								{
									formatex(g_string, "[KILLSTREAK]: "COL_GRAY"%s <%d> {FFFFFF}just ended "COL_GRAY"%s <%d>{FFFFFF}'s killstreak of "COL_RED"%d{FFFFFF}.", playerName(playerid), playerid, playerName(damagedid), damagedid, pInfo[damagedid][pKillStreak]);
									SendClientMessageToAll(COLOR_RED, g_string);
									#if defined USE_IRC
										formatex(g_bString, "4,15[KILL]: %d,15%s <%d> ended %d,15%s's <%d> killstreak of 1,15%d. (1,15%s)", ((gTeam[playerid] == TEAM_COP) ? (4) : (12)), playerName(playerid), playerid, ((gTeam[damagedid] == TEAM_COP) ? (4) : (12)), playerName(damagedid), damagedid, pInfo[damagedid][pKillStreak], deathReason[weaponid]);
										IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
									#endif
									GivePlayerMoney(playerid, 200);
									IncreasePlayerScore(playerid, 1);
								}

								pInfo[damagedid][pKillStreak] = 0;
							}

							SetPlayerHealth(damagedid, 0.00);
							GameTextForPlayer(playerid, "Headshot!", 1000, 5);
							GameTextForPlayer(damagedid, "~r~Headshot!", 1000, 5);


							if(!pInfo[damagedid][pKillMessage])
							{
								formatex(g_string, "[KILL]: "COL_GRAY"%s <%d> {FFFFFF}killed  "COL_GRAY"%s <%d>{FFFFFF}. ("COL_YELLOW"Nutshot!{FFFFFF})", playerName(playerid), playerid, playerName(damagedid), damagedid);
								SendClientMessageToAll(COLOR_DRED, g_string);
								#if defined USE_IRC
									formatex(g_bString, "4,15[KILL]: %d,15%s <%d> killed %d,15%s <%d>. (1,15Nutshot!)", ((gTeam[playerid]) ? (4) : (12)), playerName(playerid), playerid, ((gTeam[damagedid]) ? (4) : (12)), playerName(damagedid), damagedid);
									IRC_GroupSay(irc_botGroups[0], IRC_CHANNEL, g_bString);
								#endif
								GivePlayerMoney(playerid, 200);
							}

							pInfo[damagedid][pCallDeath] = 1;
							pInfo[playerid][pNutShots]++;
							pInfo[playerid][pTotalNutShots]++;
							pInfo[damagedid][pDeaths]++;
							pInfo[damagedid][pTotalDeaths]++;
							pInfo[playerid][pKills]++;
							pInfo[playerid][pTotalKills]++;

							IncreasePlayerScore(playerid, 1);

							if(gTeam[playerid] != gTeam[damagedid])
							{
								if(gTeam[playerid] == TEAM_COP)
									gTeamKills[TEAM_COP]++;

								if(gTeam[playerid] == TEAM_TER)
									gTeamKills[TEAM_TER]++;

								kills_updateInfoTD();
							}
						}
					}
				}
			}
		}
	#endif 
		
	if(damagedid != INVALID_PLAYER_ID)
	{
		if(floatround(amount) != 0)
		{
			if(gTeam[playerid] != gTeam[damagedid])
			{
				new
					Float:playerArmour
				;

				GetPlayerArmour(damagedid, playerArmour);

				if(IsValidObject(pInfo[damagedid][pDamageObject])) DestroyObject(pInfo[damagedid][pDamageObject]);

				if(floatround(playerArmour) <= 1) pInfo[damagedid][pDamageObject] = CreateObject(1240, 0.0, 0.0, -100.0, 0.0, 0.0, 0.0, 0.0);
				else pInfo[damagedid][pDamageObject] = CreateObject(1242, 0.0, 0.0, -100.0, 0.0, 0.0, 0.0, 0.0);

				pInfo[damagedid][pDamageObjectTimer] = 2;

				AttachObjectToPlayer(pInfo[damagedid][pDamageObject], damagedid, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0);
			}
		}
	}

	damagePlayer(playerid, damagedid, weaponid, amount, bodypart);

	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	new tstr[56], tempstr[256], tpid = clickedplayerid;
	format(tempstr, sizeof(tempstr), ""COL_WHITE"User ID: %d.\nKills: %d.\nDeaths: %d.\nK/D Ratio: %.2f.\n", pInfo[tpid][pID], pInfo[tpid][pTotalKills], pInfo[tpid][pTotalDeaths], ((!pInfo[tpid][pTotalDeaths]) ? (0) : (pInfo[tpid][pTotalKills]/pInfo[tpid][pTotalDeaths])));
	format(tempstr, sizeof(tempstr), "%sHead Shots: %d.\nAccuracy: %.2f.\nCurrent Killstreak: %d.\nCookies: %d.\n", tempstr, pInfo[tpid][pTotalHeadShots], pInfo[tpid][pTotalAccuracy], pInfo[tpid][pKillStreak], pInfo[tpid][pCookies]);
	format(tempstr, sizeof(tempstr), "%sTime Played [HH:MM:SS]: %d:%d:%d.\nTotal Time Played [HH:MM:SS]: %d:%d:%d.", tempstr, pInfo[tpid][pHoursPlayed], pInfo[tpid][pMinutesPlayed], pInfo[tpid][pSecondsPlayed], pInfo[tpid][pTotalHoursPlayed], pInfo[tpid][pTotalMinutesPlayed], pInfo[tpid][pTotalSecondsPlayed]);
	format(tstr, sizeof(tstr), ""COL_WHITE"%s <%d>'s Stats", playerName(tpid), tpid);
	ShowPlayerDialog(playerid, DIALOG_NO_RESPONSE, DIALOG_STYLE_MSGBOX, tstr, tempstr, "Okay", "");
	return 1;
}

public playersEverySecond()
{
	new
		Float:tempFloat,
		tempVar
	;

	foreach(new x : Player)
	{
		if(pInfo[x][pBeingKicked])
		{
			Kick(x);
			continue;
		}

		if(pInfo[x][pMuteTime] == 1)
		{
			pInfo[x][pMuted] = 0;
			SendFAdminMessage(x, "You have been automatically unmuted");
		}

		if(pInfo[x][pMuteTime] > 0)
			pInfo[x][pMuteTime]--;

		if(pInfo[x][pSpawned])
		{
			pInfo[x][pTimeSinceSpawn]++;
			if(!pInfo[x][pAFK])
			{
				if(gettime() - pInfo[x][pLastUpdate] >= 5)
				{
					OnPlayerAFK(x);
					pInfo[x][pAFK] = 1;
				}
			}

			if(pInfo[x][pDamageObjectTimer] != 0)
			{
				if(pInfo[x][pDamageObjectTimer] == 1)
				{
					if(IsValidObject(pInfo[x][pDamageObject])) DestroyObject(pInfo[x][pDamageObject]);
					pInfo[x][pDamageObjectTimer] = 0;
				}

				if(pInfo[x][pDamageObjectTimer] > 1)
					pInfo[x][pDamageObjectTimer]--;
			}

			if(pInfo[x][pSpawnProtected] != 0) // Spawnkill protection
				pInfo[x][pSpawnProtected]--;

			if(pInfo[x][pLastMark] != 0) // Marking limiter
				pInfo[x][pLastMark]--;

			// Attachments ____
			// Armour attach
			tempVar = pInfo[x][pLastClass];
			GetPlayerArmour(x, tempFloat);
			if(tempFloat > 0)
			{
				if(!IsPlayerAttachedObjectSlotUsed(x, ATTACH_ARMOUR_INDEX))
					SetPlayerAttachedObject(x, ATTACH_ARMOUR_INDEX, 19142, 1, armourCoordinates[tempVar][fOffX], armourCoordinates[tempVar][fOffY], armourCoordinates[tempVar][fOffZ], armourCoordinates[tempVar][fRotX], armourCoordinates[tempVar][fRotY], armourCoordinates[tempVar][fRotZ], armourCoordinates[tempVar][fScaX], armourCoordinates[tempVar][fScaY], armourCoordinates[tempVar][fScaZ]);
			}
			else if(IsPlayerAttachedObjectSlotUsed(x, ATTACH_ARMOUR_INDEX))
				RemovePlayerAttachedObject(x, ATTACH_ARMOUR_INDEX);

			// Time...
			pInfo[x][pSecondsPlayed]++;

			if(pInfo[x][pSecondsPlayed] >= 60)
			{
				pInfo[x][pSecondsPlayed] = 0;
				pInfo[x][pMinutesPlayed]++;

				for(new i = 0; i < sizeof(sAchievements[aTime]); i++)
				{
					if(!DidPlayerAchieve(x, sAchievements[aTime][i]))
					{
						GivePlayerAchievement(x, sAchievements[aTime][i], 1);
					}
				}

				if(pInfo[x][pMinutesPlayed] >= 60)
				{
					pInfo[x][pHoursPlayed]++;
				}
			}

			/* Helmet attach
			if(pInfo[x][pHasHelmet])
			{
				if(!IsPlayerAttachedObjectSlotUsed(x, ATTACH_HELMET_INDEX))
					SetPlayerAttachedObject(x, ATTACH_HELMET_INDEX, 19141, 2, helmetCoordinates[tempVar][fOffX], helmetCoordinates[tempVar][fOffY], helmetCoordinates[tempVar][fOffZ], helmetCoordinates[tempVar][fRotX], helmetCoordinates[tempVar][fRotY], helmetCoordinates[tempVar][fRotZ], helmetCoordinates[tempVar][fScaX], helmetCoordinates[tempVar][fScaY], helmetCoordinates[tempVar][fScaZ]);
			}
			else if(IsPlayerAttachedObjectSlotUsed(x, ATTACH_HELMET_INDEX))
				RemovePlayerAttachedObject(x, ATTACH_HELMET_INDEX);*/
		}

		if(pInfo[x][pKillCam] != 0)
		{
			if(pInfo[x][pKillCam] == 1)
			{
				TogglePlayerSpectating(x, false);
				pInfo[x][pKillCam] = 0;
				hideKillCam(x);
			}

			else
			{
				pInfo[x][pKillCam]--;
			}
		}
	}
	return 1;
}

/*ResetVariables(playerid)
{
	pInfo[playerid][pSpawned] = 0;
	pInfo[playerid][pKillStreak] = 0;
	pInfo[playerid][pKills] = 0;
	pInfo[playerid][pDeaths] = 0;
	pInfo[playerid][pInFight] = 0;
	pInfo[playerid][pCounted] = 0;
	pInfo[playerid][pSpawnProtected] = 0;
	pInfo[playerid][pLastClass] = 0;
	pInfo[playerid][pLastMark] = 0;
	pInfo[playerid][pVisible] = 0;
	gTeam[playerid] = -1;
	pInfo[playerid][pLastUpdate] = 0;
	pInfo[playerid][pAFK] = 0;

	return 1;
}*/

ResetVariables(playerid)
{
    static sBlank[pData];
    pInfo[playerid] = sBlank;
}

stock SendServerMessage(playerid, message[])
{
	formatex(g_string, "[SERVER]: {FFFFFF}%s", message);
	SendClientMessage(playerid, COLOR_SERVER, g_string);

	return 1;
}

stock SendFServerMessage(playerid, const message[], va_args<>)
{
	va_format(g_string, sizeof (g_string), message, va_start<2>);
	strins(g_string, "[SERVER]: {FFFFFF}", 0);
    return SendClientMessage(playerid, COLOR_SERVER, g_string);
}

stock SendErrorMessage(playerid, message[])
{
	formatex(g_string, "[ERROR]: {FFFFFF}%s", message);
	SendClientMessage(playerid, COLOR_DRED, g_string);

	return 1;
}

stock SendFErrorMessage(playerid, const message[], va_args<>)
{
	va_format(g_string, sizeof (g_string), message, va_start<2>);
	strins(g_string, "[ERROR]: {FFFFFF}", 0);
    return SendClientMessage(playerid, COLOR_DRED, g_string);
}

stock SendAdminMessage(playerid, message[])
{
	formatex(g_string, "[ADMIN]: {FFFFFF}%s", message);
	SendClientMessage(playerid, COLOR_ADMIN, g_string);

	return 1;
}

stock SendFAdminMessage(playerid, const message[], va_args<>)
{
	va_format(g_string, sizeof (g_string), message, va_start<2>);
	strins(g_string, "[ADMIN]: {FFFFFF}", 0);
    return SendClientMessage(playerid, COLOR_ADMIN, g_string);
}

stock SendFAdminMessageToAll(const message[], va_args<>)
{
	va_format(g_string, sizeof (g_string), message, va_start<1>);
	strins(g_string, "[ADMIN]: {FFFFFF}", 0);

	foreach(new x : Player)
	{
		SendClientMessage(x, COLOR_ADMIN, g_string);
	}
    return 1;
}

stock SendFAdminMessageToAdmins(const message[], va_args<>)
{
	va_format(g_string, sizeof (g_string), message, va_start<1>);
	strins(g_string, "[ADMIN]: {FFFFFF}", 0);

	foreach(new x : Player)
	{
		if(pInfo[x][pAdminLevel] < 1) continue;
		SendClientMessage(x, COLOR_ADMIN, g_string);
	}
    return 1;
}

stock SendUsageMessage(playerid, message[])
{
	formatex(g_string, "[USAGE]: {FFFFFF}/%s", message);
	SendClientMessage(playerid, COLOR_YELLOW, g_string);

	return 1;
}

stock SendHelpMessage(playerid, message[])
{
	formatex(g_string, "[HELP]: {FFFFFF}%s", message);
	SendClientMessage(playerid, COLOR_ORANGE, g_string);

	return 1;
}

loadProgressBars()
{
	for(new i = 0, slots = GetMaxPlayers(); i < slots; i++)
	{
		helmetHealthBar[i] = CreateProgressBar(548.00, 58.00, 57.50, 3.19, 1375687167, 100.0);
		SetProgressBarMaxValue(helmetHealthBar[i], 100);
		SetProgressBarColor(helmetHealthBar[i], COLOR_YELLOW);
	}
}

loadTextdraws()
{
	mapChangeTD[0] = TextDrawCreate(320.000000, 335.000000, "~y~Paused");
	TextDrawAlignment(mapChangeTD[0], 2);
	TextDrawBackgroundColor(mapChangeTD[0], 255);
	TextDrawFont(mapChangeTD[0], 2);
	TextDrawLetterSize(mapChangeTD[0], 0.240000, 1.000000);
	TextDrawColor(mapChangeTD[0], -1);
	TextDrawSetOutline(mapChangeTD[0], 1);
	TextDrawSetProportional(mapChangeTD[0], 1);
	TextDrawUseBox(mapChangeTD[0], 1);
	TextDrawBoxColor(mapChangeTD[0], 255);
	TextDrawTextSize(mapChangeTD[0], 0.000000, 120.000000);
	TextDrawSetSelectable(mapChangeTD[0], 0);

	mapChangeTD[1] = TextDrawCreate(384.000000, 348.000000, "~n~");
	TextDrawBackgroundColor(mapChangeTD[1], 255);
	TextDrawFont(mapChangeTD[1], 1);
	TextDrawLetterSize(mapChangeTD[1], 0.700000, 4.000000);
	TextDrawColor(mapChangeTD[1], -1);
	TextDrawSetOutline(mapChangeTD[1], 0);
	TextDrawSetProportional(mapChangeTD[1], 1);
	TextDrawSetShadow(mapChangeTD[1], 1);
	TextDrawUseBox(mapChangeTD[1], 1);
	TextDrawBoxColor(mapChangeTD[1], 75);
	TextDrawTextSize(mapChangeTD[1], 256.000000, 0.000000);
	TextDrawSetSelectable(mapChangeTD[1], 0);

	mapChangeTD[2] = TextDrawCreate(320.000000, 351.000000, "Loading Objects...~n~Please wait.");
	TextDrawAlignment(mapChangeTD[2], 2);
	TextDrawBackgroundColor(mapChangeTD[2], 255);
	TextDrawFont(mapChangeTD[2], 1);
	TextDrawLetterSize(mapChangeTD[2], 0.349999, 1.300000);
	TextDrawColor(mapChangeTD[2], -1);
	TextDrawSetOutline(mapChangeTD[2], 1);
	TextDrawSetProportional(mapChangeTD[2], 1);
	TextDrawSetSelectable(mapChangeTD[2], 0);

	versionTD = TextDrawCreate(41.000000, 428.000000, "Version");
	TextDrawBackgroundColor(versionTD, 255);
	TextDrawFont(versionTD, 1);
	TextDrawLetterSize(versionTD, 0.300000, 1.000000);
	TextDrawColor(versionTD, -1);
	TextDrawSetOutline(versionTD, 1);
	TextDrawSetProportional(versionTD, 1);
	TextDrawSetSelectable(versionTD, 0);

	infoTD[0] = TextDrawCreate(631.000000, 409.000000, "~n~");
	TextDrawBackgroundColor(infoTD[0], 255);
	TextDrawFont(infoTD[0], 1);
	TextDrawLetterSize(infoTD[0], 0.500000, 3.199997);
	TextDrawColor(infoTD[0], -1);
	TextDrawSetOutline(infoTD[0], 0);
	TextDrawSetProportional(infoTD[0], 1);
	TextDrawSetShadow(infoTD[0], 1);
	TextDrawUseBox(infoTD[0], 1);
	TextDrawBoxColor(infoTD[0], 75);
	TextDrawTextSize(infoTD[0], 519.000000, 0.000000);
	TextDrawSetSelectable(infoTD[0], 0);

	infoTD[1] = TextDrawCreate(575.000000, 397.000000, "~b~Cops ~w~vs ~r~Terrorists");
	TextDrawAlignment(infoTD[1], 2);
	TextDrawBackgroundColor(infoTD[1], 255);
	TextDrawFont(infoTD[1], 2);
	TextDrawLetterSize(infoTD[1], 0.160000, 1.000000);
	TextDrawColor(infoTD[1], -1);
	TextDrawSetOutline(infoTD[1], 1);
	TextDrawSetProportional(infoTD[1], 1);
	TextDrawUseBox(infoTD[1], 1);
	TextDrawBoxColor(infoTD[1], 255);
	TextDrawTextSize(infoTD[1], 636.000000, 104.000000);
	TextDrawSetSelectable(infoTD[1], 0);

	infoTD[2] = TextDrawCreate(575.000000, 412.000000, "~b~00 ~w~PLAYERS ~r~00");
	TextDrawAlignment(infoTD[2], 2);
	TextDrawBackgroundColor(infoTD[2], 255);
	TextDrawFont(infoTD[2], 2);
	TextDrawLetterSize(infoTD[2], 0.240000, 1.000000);
	TextDrawColor(infoTD[2], -1);
	TextDrawSetOutline(infoTD[2], 1);
	TextDrawSetProportional(infoTD[2], 1);
	TextDrawSetSelectable(infoTD[2], 0);

	infoTD[3] = TextDrawCreate(575.000000, 425.000000, "~b~00 ~w~KILLS~r~ 00");
	TextDrawAlignment(infoTD[3], 2);
	TextDrawBackgroundColor(infoTD[3], 255);
	TextDrawFont(infoTD[3], 2);
	TextDrawLetterSize(infoTD[3], 0.240000, 1.000000);
	TextDrawColor(infoTD[3], -1);
	TextDrawSetOutline(infoTD[3], 1);
	TextDrawSetProportional(infoTD[3], 1);
	TextDrawSetSelectable(infoTD[3], 0);

	mapInfoTD[0] = TextDrawCreate(631.000000, 349.000000, "~n~");
	TextDrawBackgroundColor(mapInfoTD[0], 255);
	TextDrawFont(mapInfoTD[0], 1);
	TextDrawLetterSize(mapInfoTD[0], 0.500000, 4.199996);
	TextDrawColor(mapInfoTD[0], -1);
	TextDrawSetOutline(mapInfoTD[0], 0);
	TextDrawSetProportional(mapInfoTD[0], 1);
	TextDrawSetShadow(mapInfoTD[0], 1);
	TextDrawUseBox(mapInfoTD[0], 1);
	TextDrawBoxColor(mapInfoTD[0], 75);
	TextDrawTextSize(mapInfoTD[0], 519.000000, 0.000000);
	TextDrawSetSelectable(mapInfoTD[0], 0);

	mapInfoTD[1] = TextDrawCreate(575.000000, 336.000000, "~y~Map Info");
	TextDrawAlignment(mapInfoTD[1], 2);
	TextDrawBackgroundColor(mapInfoTD[1], 255);
	TextDrawFont(mapInfoTD[1], 2);
	TextDrawLetterSize(mapInfoTD[1], 0.159999, 1.000000);
	TextDrawColor(mapInfoTD[1], -1);
	TextDrawSetOutline(mapInfoTD[1], 1);
	TextDrawSetProportional(mapInfoTD[1], 1);
	TextDrawUseBox(mapInfoTD[1], 1);
	TextDrawBoxColor(mapInfoTD[1], 255);
	TextDrawTextSize(mapInfoTD[1], 636.000000, 104.000000);
	TextDrawSetSelectable(mapInfoTD[1], 0);

	mapInfoTD[2] = TextDrawCreate(575.000000, 351.000000, "~b~Paintball Arena~n~~w~By: ~b~THEYOUNGCAPONE");
	TextDrawAlignment(mapInfoTD[2], 2);
	TextDrawBackgroundColor(mapInfoTD[2], 255);
	TextDrawFont(mapInfoTD[2], 2);
	TextDrawLetterSize(mapInfoTD[2], 0.159999, 1.000000);
	TextDrawColor(mapInfoTD[2], -1);
	TextDrawSetOutline(mapInfoTD[2], 1);
	TextDrawSetProportional(mapInfoTD[2], 1);
	TextDrawSetSelectable(mapInfoTD[2], 0);

	mapInfoTD[3] = TextDrawCreate(575.000000, 373.000000, "Round Timer: 00:00");
	TextDrawAlignment(mapInfoTD[3], 2);
	TextDrawBackgroundColor(mapInfoTD[3], 255);
	TextDrawFont(mapInfoTD[3], 2);
	TextDrawLetterSize(mapInfoTD[3], 0.159999, 1.000000);
	TextDrawColor(mapInfoTD[3], -1);
	TextDrawSetOutline(mapInfoTD[3], 1);
	TextDrawSetProportional(mapInfoTD[3], 1);
	TextDrawSetSelectable(mapInfoTD[3], 0);

	roundEndTD[0] = TextDrawCreate(320.000000, 130.000000, "~n~");
	TextDrawAlignment(roundEndTD[0], 2);
	TextDrawBackgroundColor(roundEndTD[0], 255);
	TextDrawFont(roundEndTD[0], 1);
	TextDrawLetterSize(roundEndTD[0], 0.500000, 31.000000);
	TextDrawColor(roundEndTD[0], -1);
	TextDrawSetOutline(roundEndTD[0], 0);
	TextDrawSetProportional(roundEndTD[0], 1);
	TextDrawSetShadow(roundEndTD[0], 1);
	TextDrawUseBox(roundEndTD[0], 1);
	TextDrawBoxColor(roundEndTD[0], 75);
	TextDrawTextSize(roundEndTD[0], 0.000000, 500.000000);
	TextDrawSetSelectable(roundEndTD[0], 0);

	roundEndTD[1] = TextDrawCreate(320.000000, 107.000000, "Round finished!");
	TextDrawAlignment(roundEndTD[1], 2);
	TextDrawBackgroundColor(roundEndTD[1], 255);
	TextDrawFont(roundEndTD[1], 2);
	TextDrawLetterSize(roundEndTD[1], 0.500000, 2.000000);
	TextDrawColor(roundEndTD[1], -1);
	TextDrawSetOutline(roundEndTD[1], 1);
	TextDrawSetProportional(roundEndTD[1], 1);
	TextDrawUseBox(roundEndTD[1], 1);
	TextDrawBoxColor(roundEndTD[1], 255);
	TextDrawTextSize(roundEndTD[1], 0.000000, 500.000000);
	TextDrawSetSelectable(roundEndTD[1], 0);

	roundEndTD[2] = TextDrawCreate(320.000000, 136.000000, "~w~(~b~10~w~) ~b~Team Cops ~w~(~g~W~w~) 10 : 20 (~p~L~w~) ~r~Team Terrorist ~w~(~r~12~w~)");
	TextDrawAlignment(roundEndTD[2], 2);
	TextDrawBackgroundColor(roundEndTD[2], 255);
	TextDrawFont(roundEndTD[2], 2);
	TextDrawLetterSize(roundEndTD[2], 0.400000, 2.000000);
	TextDrawColor(roundEndTD[2], -1);
	TextDrawSetOutline(roundEndTD[2], 1);
	TextDrawSetProportional(roundEndTD[2], 1);
	TextDrawSetSelectable(roundEndTD[2], 0);

	roundEndTD[3] = TextDrawCreate(150.000000, 169.000000, "~y~Top kills:");
	TextDrawAlignment(roundEndTD[3], 2);
	TextDrawBackgroundColor(roundEndTD[3], 255);
	TextDrawFont(roundEndTD[3], 2);
	TextDrawLetterSize(roundEndTD[3], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[3], -1);
	TextDrawSetOutline(roundEndTD[3], 1);
	TextDrawSetProportional(roundEndTD[3], 1);
	TextDrawUseBox(roundEndTD[3], 1);
	TextDrawBoxColor(roundEndTD[3], 255);
	TextDrawTextSize(roundEndTD[3], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[3], 0);

	roundEndTD[4] = TextDrawCreate(150.000000, 187.000000, "~n~");
	TextDrawAlignment(roundEndTD[4], 2);
	TextDrawBackgroundColor(roundEndTD[4], 255);
	TextDrawFont(roundEndTD[4], 1);
	TextDrawLetterSize(roundEndTD[4], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[4], -1);
	TextDrawSetOutline(roundEndTD[4], 0);
	TextDrawSetProportional(roundEndTD[4], 1);
	TextDrawSetShadow(roundEndTD[4], 1);
	TextDrawUseBox(roundEndTD[4], 1);
	TextDrawBoxColor(roundEndTD[4], 50);
	TextDrawTextSize(roundEndTD[4], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[4], 0);

	roundEndTD[5] = TextDrawCreate(150.000000, 188.000000, "Loading...");
	TextDrawAlignment(roundEndTD[5], 2);
	TextDrawBackgroundColor(roundEndTD[5], 255);
	TextDrawFont(roundEndTD[5], 1);
	TextDrawLetterSize(roundEndTD[5], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[5], -1);
	TextDrawSetOutline(roundEndTD[5], 1);
	TextDrawSetProportional(roundEndTD[5], 1);
	TextDrawSetSelectable(roundEndTD[5], 0);

	roundEndTD[6] = TextDrawCreate(322.000000, 169.000000, "~y~Top Deaths:");
	TextDrawAlignment(roundEndTD[6], 2);
	TextDrawBackgroundColor(roundEndTD[6], 255);
	TextDrawFont(roundEndTD[6], 2);
	TextDrawLetterSize(roundEndTD[6], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[6], -1);
	TextDrawSetOutline(roundEndTD[6], 1);
	TextDrawSetProportional(roundEndTD[6], 1);
	TextDrawUseBox(roundEndTD[6], 1);
	TextDrawBoxColor(roundEndTD[6], 255);
	TextDrawTextSize(roundEndTD[6], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[6], 0);

	roundEndTD[7] = TextDrawCreate(322.000000, 187.000000, "~n~");
	TextDrawAlignment(roundEndTD[7], 2);
	TextDrawBackgroundColor(roundEndTD[7], 255);
	TextDrawFont(roundEndTD[7], 1);
	TextDrawLetterSize(roundEndTD[7], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[7], -1);
	TextDrawSetOutline(roundEndTD[7], 0);
	TextDrawSetProportional(roundEndTD[7], 1);
	TextDrawSetShadow(roundEndTD[7], 1);
	TextDrawUseBox(roundEndTD[7], 1);
	TextDrawBoxColor(roundEndTD[7], 50);
	TextDrawTextSize(roundEndTD[7], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[7], 0);

	roundEndTD[8] = TextDrawCreate(321.000000, 188.000000, "Loading...");
	TextDrawAlignment(roundEndTD[8], 2);
	TextDrawBackgroundColor(roundEndTD[8], 255);
	TextDrawFont(roundEndTD[8], 1);
	TextDrawLetterSize(roundEndTD[8], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[8], -1);
	TextDrawSetOutline(roundEndTD[8], 1);
	TextDrawSetProportional(roundEndTD[8], 1);
	TextDrawSetSelectable(roundEndTD[8], 0);

	roundEndTD[9] = TextDrawCreate(491.000000, 169.000000, "~y~Top K/D Ratios:");
	TextDrawAlignment(roundEndTD[9], 2);
	TextDrawBackgroundColor(roundEndTD[9], 255);
	TextDrawFont(roundEndTD[9], 2);
	TextDrawLetterSize(roundEndTD[9], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[9], -1);
	TextDrawSetOutline(roundEndTD[9], 1);
	TextDrawSetProportional(roundEndTD[9], 1);
	TextDrawUseBox(roundEndTD[9], 1);
	TextDrawBoxColor(roundEndTD[9], 255);
	TextDrawTextSize(roundEndTD[9], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[9], 0);

	roundEndTD[10] = TextDrawCreate(491.000000, 187.000000, "~n~");
	TextDrawAlignment(roundEndTD[10], 2);
	TextDrawBackgroundColor(roundEndTD[10], 255);
	TextDrawFont(roundEndTD[10], 1);
	TextDrawLetterSize(roundEndTD[10], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[10], -1);
	TextDrawSetOutline(roundEndTD[10], 0);
	TextDrawSetProportional(roundEndTD[10], 1);
	TextDrawSetShadow(roundEndTD[10], 1);
	TextDrawUseBox(roundEndTD[10], 1);
	TextDrawBoxColor(roundEndTD[10], 50);
	TextDrawTextSize(roundEndTD[10], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[10], 0);

	roundEndTD[11] = TextDrawCreate(490.000000, 188.000000, "Loading...");
	TextDrawAlignment(roundEndTD[11], 2);
	TextDrawBackgroundColor(roundEndTD[11], 255);
	TextDrawFont(roundEndTD[11], 1);
	TextDrawLetterSize(roundEndTD[11], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[11], -1);
	TextDrawSetOutline(roundEndTD[11], 1);
	TextDrawSetProportional(roundEndTD[11], 1);
	TextDrawSetSelectable(roundEndTD[11], 0);

	roundEndTD[12] = TextDrawCreate(150.000000, 289.000000, "~y~Top Headshots:");
	TextDrawAlignment(roundEndTD[12], 2);
	TextDrawBackgroundColor(roundEndTD[12], 255);
	TextDrawFont(roundEndTD[12], 2);
	TextDrawLetterSize(roundEndTD[12], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[12], -1);
	TextDrawSetOutline(roundEndTD[12], 1);
	TextDrawSetProportional(roundEndTD[12], 1);
	TextDrawUseBox(roundEndTD[12], 1);
	TextDrawBoxColor(roundEndTD[12], 255);
	TextDrawTextSize(roundEndTD[12], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[12], 0);

	roundEndTD[13] = TextDrawCreate(150.000000, 307.000000, "~n~");
	TextDrawAlignment(roundEndTD[13], 2);
	TextDrawBackgroundColor(roundEndTD[13], 255);
	TextDrawFont(roundEndTD[13], 1);
	TextDrawLetterSize(roundEndTD[13], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[13], -1);
	TextDrawSetOutline(roundEndTD[13], 0);
	TextDrawSetProportional(roundEndTD[13], 1);
	TextDrawSetShadow(roundEndTD[13], 1);
	TextDrawUseBox(roundEndTD[13], 1);
	TextDrawBoxColor(roundEndTD[13], 50);
	TextDrawTextSize(roundEndTD[13], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[13], 0);

	roundEndTD[14] = TextDrawCreate(150.000000, 309.000000, "Loading...");
	TextDrawAlignment(roundEndTD[14], 2);
	TextDrawBackgroundColor(roundEndTD[14], 255);
	TextDrawFont(roundEndTD[14], 1);
	TextDrawLetterSize(roundEndTD[14], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[14], -1);
	TextDrawSetOutline(roundEndTD[14], 1);
	TextDrawSetProportional(roundEndTD[14], 1);
	TextDrawSetSelectable(roundEndTD[14], 0);

	roundEndTD[15] = TextDrawCreate(322.000000, 289.000000, "~y~Top Accuracy:");
	TextDrawAlignment(roundEndTD[15], 2);
	TextDrawBackgroundColor(roundEndTD[15], 255);
	TextDrawFont(roundEndTD[15], 2);
	TextDrawLetterSize(roundEndTD[15], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[15], -1);
	TextDrawSetOutline(roundEndTD[15], 1);
	TextDrawSetProportional(roundEndTD[15], 1);
	TextDrawUseBox(roundEndTD[15], 1);
	TextDrawBoxColor(roundEndTD[15], 255);
	TextDrawTextSize(roundEndTD[15], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[15], 0);

	roundEndTD[16] = TextDrawCreate(322.000000, 307.000000, "~n~");
	TextDrawAlignment(roundEndTD[16], 2);
	TextDrawBackgroundColor(roundEndTD[16], 255);
	TextDrawFont(roundEndTD[16], 1);
	TextDrawLetterSize(roundEndTD[16], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[16], -1);
	TextDrawSetOutline(roundEndTD[16], 0);
	TextDrawSetProportional(roundEndTD[16], 1);
	TextDrawSetShadow(roundEndTD[16], 1);
	TextDrawUseBox(roundEndTD[16], 1);
	TextDrawBoxColor(roundEndTD[16], 50);
	TextDrawTextSize(roundEndTD[16], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[16], 0);

	roundEndTD[17] = TextDrawCreate(321.000000, 308.000000, "Loading...");
	TextDrawAlignment(roundEndTD[17], 2);
	TextDrawBackgroundColor(roundEndTD[17], 255);
	TextDrawFont(roundEndTD[17], 1);
	TextDrawLetterSize(roundEndTD[17], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[17], -1);
	TextDrawSetOutline(roundEndTD[17], 1);
	TextDrawSetProportional(roundEndTD[17], 1);
	TextDrawSetSelectable(roundEndTD[17], 0);

	roundEndTD[18] = TextDrawCreate(491.000000, 289.000000, "~y~Top Marks:");
	TextDrawAlignment(roundEndTD[18], 2);
	TextDrawBackgroundColor(roundEndTD[18], 255);
	TextDrawFont(roundEndTD[18], 2);
	TextDrawLetterSize(roundEndTD[18], 0.310000, 1.500000);
	TextDrawColor(roundEndTD[18], -1);
	TextDrawSetOutline(roundEndTD[18], 1);
	TextDrawSetProportional(roundEndTD[18], 1);
	TextDrawUseBox(roundEndTD[18], 1);
	TextDrawBoxColor(roundEndTD[18], 255);
	TextDrawTextSize(roundEndTD[18], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[18], 0);

	roundEndTD[19] = TextDrawCreate(491.000000, 307.000000, "~n~");
	TextDrawAlignment(roundEndTD[19], 2);
	TextDrawBackgroundColor(roundEndTD[19], 255);
	TextDrawFont(roundEndTD[19], 1);
	TextDrawLetterSize(roundEndTD[19], 0.500000, 9.799999);
	TextDrawColor(roundEndTD[19], -1);
	TextDrawSetOutline(roundEndTD[19], 0);
	TextDrawSetProportional(roundEndTD[19], 1);
	TextDrawSetShadow(roundEndTD[19], 1);
	TextDrawUseBox(roundEndTD[19], 1);
	TextDrawBoxColor(roundEndTD[19], 50);
	TextDrawTextSize(roundEndTD[19], 0.000000, 144.000000);
	TextDrawSetSelectable(roundEndTD[19], 0);

	roundEndTD[20] = TextDrawCreate(490.000000, 308.000000, "Loading...");
	TextDrawAlignment(roundEndTD[20], 2);
	TextDrawBackgroundColor(roundEndTD[20], 255);
	TextDrawFont(roundEndTD[20], 1);
	TextDrawLetterSize(roundEndTD[20], 0.250000, 0.899999);
	TextDrawColor(roundEndTD[20], -1);
	TextDrawSetOutline(roundEndTD[20], 1);
	TextDrawSetProportional(roundEndTD[20], 1);
	TextDrawSetSelectable(roundEndTD[20], 0);

	g_killCamTD[0] = TextDrawCreate(320.000000, 377.000000, "~y~Kill info");
	TextDrawAlignment(g_killCamTD[0], 2);
	TextDrawBackgroundColor(g_killCamTD[0], 255);
	TextDrawFont(g_killCamTD[0], 2);
	TextDrawLetterSize(g_killCamTD[0], 0.200000, 1.000000);
	TextDrawColor(g_killCamTD[0], -1);
	TextDrawSetOutline(g_killCamTD[0], 1);
	TextDrawSetProportional(g_killCamTD[0], 1);
	TextDrawUseBox(g_killCamTD[0], 1);
	TextDrawBoxColor(g_killCamTD[0], 255);
	TextDrawTextSize(g_killCamTD[0], 0.000000, 131.000000);
	TextDrawSetSelectable(g_killCamTD[0], 0);

	g_killCamTD[1] = TextDrawCreate(320.000000, 390.000000, "~n~");
	TextDrawAlignment(g_killCamTD[1], 2);
	TextDrawBackgroundColor(g_killCamTD[1], 255);
	TextDrawFont(g_killCamTD[1], 1);
	TextDrawLetterSize(g_killCamTD[1], 0.500000, 5.000000);
	TextDrawColor(g_killCamTD[1], -1);
	TextDrawSetOutline(g_killCamTD[1], 0);
	TextDrawSetProportional(g_killCamTD[1], 1);
	TextDrawSetShadow(g_killCamTD[1], 1);
	TextDrawUseBox(g_killCamTD[1], 1);
	TextDrawBoxColor(g_killCamTD[1], 75);
	TextDrawTextSize(g_killCamTD[1], 0.000000, 131.000000);
	TextDrawSetSelectable(g_killCamTD[1], 0);

	g_killCamTD[2] = TextDrawCreate(320.000000, 416.000000, "~r~Note: ~w~Use /spawnnow to skip~n~killcam.");
	TextDrawAlignment(g_killCamTD[2], 2);
	TextDrawBackgroundColor(g_killCamTD[2], 255);
	TextDrawFont(g_killCamTD[2], 1);
	TextDrawLetterSize(g_killCamTD[2], 0.200000, 1.000000);
	TextDrawColor(g_killCamTD[2], -1);
	TextDrawSetOutline(g_killCamTD[2], 1);
	TextDrawSetProportional(g_killCamTD[2], 1);
	TextDrawSetSelectable(g_killCamTD[2], 0);

	for(new x = 0; x < MAX_PLAYERS; x++)
	{
		p_killCamTD[x][0] = TextDrawCreate(320.000000, 391.000000, "Name: PlayerNameHere <44>");
		TextDrawAlignment(p_killCamTD[x][0], 2);
		TextDrawBackgroundColor(p_killCamTD[x][0], 255);
		TextDrawFont(p_killCamTD[x][0], 1);
		TextDrawLetterSize(p_killCamTD[x][0], 0.200000, 1.200000);
		TextDrawColor(p_killCamTD[x][0], -1);
		TextDrawSetOutline(p_killCamTD[x][0], 1);
		TextDrawSetProportional(p_killCamTD[x][0], 1);
		TextDrawSetSelectable(p_killCamTD[x][0], 0);

		p_killCamTD[x][1] = TextDrawCreate(320.000000, 403.000000, "Death reason: Explosion");
		TextDrawAlignment(p_killCamTD[x][1], 2);
		TextDrawBackgroundColor(p_killCamTD[x][1], 255);
		TextDrawFont(p_killCamTD[x][1], 1);
		TextDrawLetterSize(p_killCamTD[x][1], 0.200000, 1.200000);
		TextDrawColor(p_killCamTD[x][1], -1);
		TextDrawSetOutline(p_killCamTD[x][1], 1);
		TextDrawSetProportional(p_killCamTD[x][1], 1);
		TextDrawSetSelectable(p_killCamTD[x][1], 0);
	}

	return 1;
}

updateRoundEndTDs()
{
	new
		string[2056],
		temp
	;

	formatex(string, "~w~<~b~%02d~w~> ~b~Team Cops ~w~(%s~w~) %02d : %02d (%s~w~) ~r~Team Terrorist ~w~<~r~%02d~w~>", gTeamPlayers[TEAM_COP], ((gTeamKills [TEAM_COP] > gTeamKills[TEAM_TER]) ? ("~g~W") : (gTeamKills [TEAM_COP] < gTeamKills[TEAM_TER]) ? ("~p~L") : ("~y~D")), gTeamKills[TEAM_COP], gTeamKills[TEAM_TER], ((gTeamKills [TEAM_COP] < gTeamKills[TEAM_TER]) ? ("~g~W") : (gTeamKills [TEAM_COP] > gTeamKills[TEAM_TER]) ? ("~p~L") : ("~y~D")), gTeamPlayers[TEAM_TER]);
	TextDrawSetString(roundEndTD[2], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerKills[i][r_playerID];
		if(r_playerKills[i][r_playerRank] != -1) formatex(string, "%s%02d - %s <%d> (%02d)~n~", string, i + 1, playerName(temp), temp, r_playerKills[i][r_playerRank]);
		else formatex(string, "%s%02d - N/A <0> (00)~n~", string, i+1);
	}
	TextDrawSetString(roundEndTD[5], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerDeaths[i][r_playerID];
		if(r_playerDeaths[i][r_playerRank] != -1) formatex(string, "%s%02d - %s <%d> (%02d)~n~", string, i + 1, playerName(temp), temp, r_playerDeaths[i][r_playerRank]);
		else formatex(string, "%s%02d - N/A <0> (00)~n~", string, i+1);
	}
	TextDrawSetString(roundEndTD[8], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerKDRatio[i][r_playerIDEx];
		if(floatround(r_playerKDRatio[i][r_playerRankEx]) != -1) formatex(string, "%s%d - %s <%d> (%.2f)~n~", string, i + 1, playerName(temp), temp, r_playerKDRatio[i][r_playerRankEx]);
		else formatex(string, "%s%02d - N/A <0> (0.00)~n~", string, i+1);
	}
	TextDrawSetString(roundEndTD[11], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerHeadShots[i][r_playerID];
		if(r_playerHeadShots[i][r_playerRank] != -1) formatex(string, "%s%d - %s <%d> (%02d)~n~", string, i + 1, playerName(temp), temp, r_playerHeadShots[i][r_playerRank]);
		else formatex(string, "%s%02d - N/A <0> (00)~n~", string, i+1);
	}
	TextDrawSetString(roundEndTD[14], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerAccuracy[i][r_playerIDEx];
		if(floatround(r_playerAccuracy[i][r_playerRankEx]) != -1) formatex(string, "%s%d - %s <%d> (%.2f)~n~", string, i + 1, playerName(temp), temp, r_playerAccuracy[i][r_playerRankEx]);
		else formatex(string, "%s%02d - N/A <0> (0.00)~n~", string, i+1);
	}
	TextDrawSetString(roundEndTD[17], string);
	string[0] = EOS;

	for(new i = 0; i < 10; i++)
	{
		temp = r_playerMarks[i][r_playerID];
		if(r_playerMarks[i][r_playerRank] != -1) formatex(string, "%s%02d - %s <%d> (%02d)~n~", string, i + 1, playerName(temp), temp, r_playerMarks[i][r_playerRank]);
		else formatex(string, "%s%02d - N/A <0> (00)~n~", string, i + 1);
	}
	TextDrawSetString(roundEndTD[20], string);
	string[0] = EOS;

	return 1;
}

showRoundEndTDs(playerid)
{
	for(new i = 0; i < sizeof(roundEndTD); i++)
		TextDrawShowForPlayer(playerid, roundEndTD[i]);

	return 1;
}

hideRoundEndTDs(playerid)
{
	for(new i = 0; i < sizeof(roundEndTD); i++)
		TextDrawHideForPlayer(playerid, roundEndTD[i]);

	return 1;
}

players_updateInfoTD()
{
	formatex(g_string, "~b~%02d ~w~PLAYERS ~r~%02d", gTeamPlayers[TEAM_COP], gTeamPlayers[TEAM_TER]);
	TextDrawSetString(infoTD[2], g_string);

	TextDrawHideForAll(infoTD[2]);
	foreach(new x : Player)
	{
		if(pInfo[x][pSpawned] && roundInProgress)	TextDrawShowForPlayer(x, infoTD[2]);
		else TextDrawHideForPlayer(x, infoTD[2]);
	}


	return 1;
}

kills_updateInfoTD()
{
	formatex(g_string, "~b~%02d ~w~KILLS ~r~%02d", gTeamKills[TEAM_COP], gTeamKills[TEAM_TER]);
	TextDrawSetString(infoTD[3], g_string);

	TextDrawHideForAll(infoTD[3]);
	foreach(new x : Player)
	{
		if(pInfo[x][pSpawned])	TextDrawShowForPlayer(x, infoTD[3]);
	}

	return 1;
}

updateMapInfoTDs()
{
	formatex(g_string, "~b~%s~n~~w~By: ~r~%s", mapInfo[gCurrentMap][mapName], mapInfo[gCurrentMap][mapperName]);
	TextDrawSetString(mapInfoTD[2], g_string);

	formatex(g_string, "~y~Round Timer: ~w~%02d:%02d", roundTimer[0], roundTimer[1]);
	TextDrawSetString(mapInfoTD[3], g_string);

	foreach(new x : Player) if(pInfo[x][pSpawned]) for(new i = 0; i < sizeof(mapInfoTD); i++) TextDrawShowForPlayer(x, mapInfoTD[i]);
	return 1;
}

showMapInfoTDs(playerid)
{
	for(new i = 0; i < sizeof(mapInfoTD); i++) TextDrawShowForPlayer(playerid, mapInfoTD[i]);

	return 1;
}

hideMapInfoTDs(playerid)
{
	for(new i = 0; i < sizeof(mapInfoTD); i++) TextDrawHideForPlayer(playerid, mapInfoTD[i]);
	return 1;
}

showKillCam(playerid, killerid, reason)
{
	formatex(g_string, "Name: %s%s ~w~<%d>", ((gTeam[killerid] == TEAM_COP) ? ("~b~") : ("~r~")), playerName(killerid), killerid);
	TextDrawSetString(p_killCamTD[playerid][0], g_string);

	formatex(g_string, "Death reason: ~y~%s", deathReason[reason]);
	TextDrawSetString(p_killCamTD[playerid][1], g_string);

	for(new i = 0; i < sizeof(g_killCamTD); i++)
	{
		if(i < 2)
			TextDrawShowForPlayer(playerid, p_killCamTD[playerid][i]);

		TextDrawShowForPlayer(playerid, g_killCamTD[i]);
	}
	return 1;
}


hideKillCam(playerid)
{

	for(new i = 0; i < sizeof(g_killCamTD); i++)
	{
		if(i < 2)
			TextDrawHideForPlayer(playerid, p_killCamTD[playerid][i]);

		TextDrawHideForPlayer(playerid, g_killCamTD[i]);
	}

	return 1;
}

destroyTextdraws()
{
	TextDrawDestroy(mapChangeTD[0]);
	TextDrawDestroy(mapChangeTD[1]);
	TextDrawDestroy(mapChangeTD[2]);
	//TextDrawDestroy(fullScreen);
	TextDrawDestroy(versionTD);

	for(new x = 0; x < MAX_PLAYERS; x++)
	{
		if(x < sizeof(infoTD))
		{
			TextDrawDestroy(infoTD[x]);
		}

		if(x < sizeof(g_killCamTD))
		{
			TextDrawDestroy(g_killCamTD[x]);
		}

		if(x < sizeof (mapInfoTD))
		{
			TextDrawDestroy(mapInfoTD[x]);
		}

		if(x < sizeof (roundEndTD))
		{
			TextDrawDestroy(roundEndTD[x]);
		}

		TextDrawDestroy(p_killCamTD[x][0]);
		TextDrawDestroy(p_killCamTD[x][1]);
	}

	return 1;
}

loadMaps()
{
	// Elorreli - The Market
	CreateDynamicObject(4867, 803, -3687, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 893.1749878, -3689.1140137, 13.4099998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 903.0969849, -3709.9899903, 13.4099998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 903.1010132, -3741.5219727, 13.4099998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 876.6829834, -3689.6081543, 13.4099998, 0.0000000, 0.0000000, 140.0000000);
	CreateDynamicObject(4199, 865.8900147, -3711.6831055, 13.4099998, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 874.2260132, -3733.236084, 8.1499996, 340.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 865.8889771, -3711.6831055, 17.6040001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 876.6820068, -3689.6081543, 17.6009998, 0.0000000, 0.0000000, 139.9987793);
	CreateDynamicObject(4199, 893.1740112, -3689.1140137, 17.5709991, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 903.0960083, -3709.9899903, 17.5669994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 903.0999756, -3741.5219727, 17.5480003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 854.3040161, -3723.2290039, 13.4350004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 865.8510132, -3711.6850586, 17.6040001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 855.1400147, -3701.7331543, 17.6040001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 843.1399841, -3731.894043, 17.6040001, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 855.8460083, -3744.7851563, 13.4099998, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 875.7940064, -3744.8161621, 17.5869999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 887.2700195, -3744.7900391, 13.4099998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 887.2700195, -3744.7890625, 17.5919991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 832.7269898, -3711.8449707, 13.4350004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 827.2129822, -3701.7121582, 17.6040001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, 832.2009888, -3717.2131348, 15.3000002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 827.2120056, -3701.7121582, 13.4469995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 806.2539978, -3711.7111817, 17.6040001, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 806.2529907, -3711.7111817, 13.4490004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 802.1340027, -3705.6601563, 13.4350004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, 814.9880066, -3713.7351075, 12.2580004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14416, 813.5400086, -3713.7321778, 12.257, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 843.1019898, -3731.894043, 17.6040001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 843.1009827, -3731.894043, 13.434, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 806.2080078, -3742.6611328, 13.4490004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 844.3529968, -3752.8671875, 13.4089994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 822.1139832, -3752.6601563, 13.4099998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 875.8059692, -3754.2780762, 17.5869999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 844.2649841, -3763.7680664, 17.6040001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(8650, 827.2129822, -3747.2919922, 15.3459997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, 811.5859985, -3731.6411133, 15.3459997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, 811.7179871, -3747.1381836, 16.7029991, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 806.2269898, -3742.946045, 21.7189999, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(4199, 806.2529907, -3711.7111817, 21.7469997, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 827.4199829, -3752.3500977, 21.7189999, 0.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(4199, 843.1390076, -3731.894043, 21.7859993, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 844.2640076, -3763.7680664, 21.7450008, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 843.1009827, -3731.8950196, 21.7859993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3862, 833.3959961, -3720.7509766, 12.507, 0.0000000, 0.0000000, 306.0000000);
	CreateDynamicObject(3862, 834.4089966, -3726.9870606, 12.507, 0.0000000, 0.0000000, 268.7467041);
	CreateDynamicObject(3863, 834.6699829, -3736.657959, 12.507, 0.0000000, 0.0000000, 268.0000000);
	CreateDynamicObject(3861, 822.8850098, -3719.953125, 12.507, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 813.6959839, -3745.3010254, 11.2110004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 799.071991, -3763.9321289, 17.6040001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 795.8039856, -3750.2131348, 17.6040001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 785.8309937, -3731.7641602, 9.1610003, 344.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 795.803009, -3750.2131348, 13.4560003, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 795.8039856, -3711.7050782, 17.6040001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 795.8039856, -3711.7050782, 13.434, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 786.7739868, -3721.7321778, 13.4350004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 786.7739868, -3721.7321778, 17.5849991, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 786.0929871, -3740.2021485, 17.5599995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 790.0329895, -3740.3139649, 13.3959999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 821.9049988, -3764.2050782, 13.4219999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 812.7099915, -3774.4331055, 13.4219999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 844.2779846, -3771.5871582, 17.6040001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 813.3119812, -3780.4541016, 17.6040001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 827.3859863, -3752.413086, 21.7189999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 799.071991, -3763.9321289, 21.8129997, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 844.2779846, -3771.5871582, 21.7579994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 813.3110046, -3780.453125, 21.7399998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 799.0660095, -3763.9689942, 17.6040001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 799.0660095, -3763.9689942, 21.7469997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 782.5700073, -3773.9780274, 13.4219999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 781.8059998, -3780.4580078, 17.6040001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 781.8049927, -3780.4570313, 21.7329998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 799.0660095, -3763.9689942, 13.4449997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 799.0679932, -3763.9321289, 13.4449997, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 795.7649841, -3750.2111817, 13.4560003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 795.7640076, -3750.2111817, 17.6490002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 795.7630005, -3750.2111817, 21.8010006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 786.0619812, -3740.2231446, 17.5599995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 790.0069885, -3740.2980957, 13.3959999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 782.5490112, -3773.2680664, 13.0629997, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 782.527832, -3772.5578614, 12.7039995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 782.5063477, -3771.8479004, 12.3449993, 0.0000000, 0.0000000, 270.0109863);
	CreateDynamicObject(4199, 782.4858399, -3771.1379395, 11.9859991, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 782.4650269, -3770.4282227, 11.6269989, 0.0000000, 0.0000000, 270.0219727);
	CreateDynamicObject(4199, 782.4440308, -3769.7182618, 11.2679987, 0.0000000, 0.0000000, 270.0274658);
	CreateDynamicObject(4199, 782.4230347, -3769.0083008, 10.9089985, 0.0000000, 0.0000000, 270.0329590);
	CreateDynamicObject(4199, 782.4018555, -3768.2980957, 10.5499983, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 782.3803711, -3767.5881348, 10.1909981, 0.0000000, 0.0000000, 270.0439453);
	CreateDynamicObject(4199, 782.3598633, -3766.8781739, 9.8319979, 0.0000000, 0.0000000, 270.0439453);
	CreateDynamicObject(4199, 782.3393555, -3766.1682129, 9.4729977, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 760.8729858, -3765.019043, 13.4560003, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 760.8729858, -3765.019043, 17.6110001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 760.8729858, -3765.019043, 21.7189999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 786.0870056, -3740.1979981, 17.5349998, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(3498, 770.6279907, -3734.7631836, 14.5200005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, 770.6159973, -3745.6269532, 14.5200005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 760.0849915, -3727.625, 13.3979998, 0.0000000, 0.0000000, 118.9999390);
	CreateDynamicObject(4199, 743.8039856, -3748.3090821, 13.3979998, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 806.177002, -3742.946045, 21.7189999, 0.0000000, 179.9945068, 180.0000000);
	CreateDynamicObject(4199, 806.2030029, -3711.7111817, 21.7469997, 0.0000000, 180.0000000, 180.0000000);
	CreateDynamicObject(4199, 760.0839844, -3727.6240235, 17.5680008, 0.0000000, 0.0000000, 118.9984131);
	CreateDynamicObject(4199, 743.803009, -3748.3090821, 17.5550003, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 760.8229981, -3765.0200196, 13.4560003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 760.8229981, -3765.0200196, 17.6130009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 760.8229981, -3765.0200196, 21.7970009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 740.5100098, -3783.8671875, 13.4350004, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, 740.5090027, -3783.8671875, 17.6329994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 740.5079956, -3783.8671875, 21.7900009, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 719.3529968, -3763.1430664, 13.4350004, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 719.3519898, -3763.1430664, 17.5919991, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 719.3509827, -3763.1430664, 21.7740002, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 743.7779846, -3748.2980957, 13.3979998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 743.7779846, -3748.2980957, 17.5429993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 719.348999, -3731.5500489, 13.4350004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 719.3479919, -3731.5500489, 17.6009998, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 728.6959839, -3726.8110352, 13.4350004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 728.6959839, -3726.8110352, 17.566, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3863, 772.2619934, -3737.1049805, 12.4700003, 359.7500000, 0.2500000, 270.4960938);
	CreateDynamicObject(1570, 824.6430054, -3744.5590821, 12.6660004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 803.1430054, -3756.3071289, 15.4289999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18257, 859.2799683, -3743.4511719, 15.5229998, 0.0000000, 0.0000000, 88.5000000);
	CreateDynamicObject(2973, 858.8049927, -3709.1469727, 15.4980001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2973, 855.9920044, -3713.0270996, 15.5109997, 0.0000000, 0.0000000, 346.0000000);
	CreateDynamicObject(3799, 829.8450012, -3714.8891602, 15.5480003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 838.6860046, -3714.3811035, 14.3719997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 891.9699707, -3724.3461914, 13.4099998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 891.9689941, -3724.3461914, 17.5389996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 826.8280029, -3759.0441895, 15.3739996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 816.4549866, -3767.0429688, 15.3859997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 809.3309937, -3773.2280274, 14.2840004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 784.5749817, -3771.2309571, 14.5979996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 803.2869873, -3754.0539551, 15.5620003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 827.3569946, -3759.1831055, 17.7240009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 800.1350098, -3774.0590821, 15.5349998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 800.144989, -3772.8881836, 15.5349998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 800.4869995, -3771.5871582, 15.4980001, 0.0000000, 0.0000000, 328.0000000);
	CreateDynamicObject(3800, 800.1279907, -3773.2460938, 16.5939999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3796, 787.6629944, -3748.3581543, 11.3100004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3633, 788.973999, -3757.4741211, 11.8100004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3633, 788.9519959, -3756.0871582, 11.8100004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3633, 787.3599854, -3757.4560547, 11.8100004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3633, 788.9960022, -3757.4941407, 12.7580004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 788.7720032, -3748.5451661, 11.8170004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 787.6279907, -3747.3271485, 11.8170004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 786.6170044, -3747.222168, 11.8170004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 787.3829956, -3749.1450196, 11.8170004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 836.5700073, -3746.1281739, 11.7410002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1225, 859.2020264, -3757.163086, 15.9280005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18260, 759.9100037, -3747.3310547, 12.908, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2991, 767.7160034, -3756.3549805, 11.9259996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(2991, 767.7149963, -3756.3549805, 13.1379995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(2974, 774.519989, -3747.4250489, 11.323, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 757.0409851, -3737.1530762, 11.2980003, 0.0000000, 0.0000000, 30.0000000);
	CreateDynamicObject(3798, 758.8420105, -3736.125, 11.2980003, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 760.6289978, -3735.0961914, 11.2980003, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 762.4309998, -3734.02417, 11.2980003, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 761.6869812, -3736.9240723, 11.2980003, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 758.7890015, -3736.1010743, 13.257, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 757.0029907, -3737.1120606, 13.257, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 757.0019836, -3737.1120606, 15.2510004, 0.0000000, 0.0000000, 29.9981689);
	CreateDynamicObject(3798, 756.9729919, -3740.3430176, 11.3240004, 0.0000000, 0.0000000, 46.9981995);
	CreateDynamicObject(3798, 750.6260071, -3754.3850098, 10.4759998, 0.0000000, 0.0000000, 356.9940186);
	CreateDynamicObject(3798, 752.6260071, -3754.4890137, 11.3000002, 0.0000000, 0.0000000, 356.9897461);
	CreateDynamicObject(3799, 840.1000061, -3749.1730957, 15.3739996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(874, 884.6149902, -3733.2680664, 11.9169998, 0.0000000, 0.0000000, 308.0000000);
	CreateDynamicObject(874, 876.1229858, -3702.3249512, 11.9169998, 0.0000000, 0.0000000, 307.9962158);
	CreateDynamicObject(874, 815.7269898, -3731.1240235, 10.415, 0.0000000, 0.0000000, 319.9962158);
	CreateDynamicObject(874, 835.0059815, -3742.1811524, 10.7910004, 0.0000000, 0.0000000, 279.9933167);
	CreateDynamicObject(874, 830.4349976, -3719.5300293, 10.7910004, 0.0000000, 0.0000000, 279.9920654);
	CreateDynamicObject(874, 769.2160034, -3729.486084, 10.7910004, 0.0000000, 0.0000000, 279.9920654);
	CreateDynamicObject(874, 790.2630005, -3751.6369629, 12.7290001, 0.0000000, 0.0000000, 279.9920654);
	CreateDynamicObject(874, 753.7890015, -3775.0109864, 11.79, 0.0000000, 0.0000000, 303.9920654);
	CreateDynamicObject(874, 729.2649841, -3778.2619629, 11.79, 0.0000000, 0.0000000, 239.9916992);
	CreateDynamicObject(874, 739.348999, -3746.9091797, 11.79, 0.0000000, 0.0000000, 165.9908447);
	CreateDynamicObject(4199, 827.2120056, -3701.7121582, 21.7469997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 855.1389771, -3701.7331543, 21.7859993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 865.8499756, -3711.6850586, 21.8110008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 865.8859863, -3711.6821289, 21.8110008, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, 876.6809692, -3689.6081543, 21.7350006, 0.0000000, 0.0000000, 139.9987793);
	CreateDynamicObject(4199, 893.1729736, -3689.1140137, 21.7670002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 875.7929688, -3744.8161621, 21.7390003, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, 875.8049927, -3754.2780762, 21.7639999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3799, 809.6829834, -3728.9301758, 15.4289999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 784.4700012, -3733.4821778, 11.3100004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 782.3909912, -3731.7199707, 11.2980003, 0.0000000, 0.0000000, 38.0000000);
	CreateDynamicObject(3798, 783.2799988, -3732.5739746, 13.2659998, 0.0000000, 0.0000000, 37.9962158);
	CreateDynamicObject(3799, 826.927002, -3772.7021485, 15.3859997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 792.3599854, -3772.7441407, 15.6269999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 812.9379883, -3773.3559571, 15.6269999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 818.7669983, -3762.9990235, 15.6269999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 824.4389954, -3753.5251465, 15.6149998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 823.6979981, -3738.6081543, 11.427, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 829.1820068, -3729.3491211, 11.427, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2670, 817.6149902, -3724.4780274, 11.427, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 814.9599915, -3753.0690918, 15.5450001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 805.9089966, -3745.6530762, 15.5839996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 807.0270081, -3735.9890137, 15.5839996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 777.5979919, -3730.5571289, 11.3570004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 762.6529846, -3741.3090821, 11.3570004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 771.5490112, -3750.4011231, 11.3570004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 777.4549866, -3769.8491211, 15.5570002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2674, 819.5639954, -3770.7751465, 15.5570002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 775.1600037, -3758.9670411, 11.4379997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 805.1149902, -3771.4020996, 15.6389999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 808.8240051, -3755.1091309, 15.6660004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 823.7619934, -3732.3110352, 11.4379997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 820.6210022, -3712.4431153, 15.6520004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 856.2719727, -3718.3559571, 15.6520004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 851.2249756, -3734.8439942, 15.6520004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 880.5720215, -3733.9980469, 11.4379997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 875.0609741, -3724.4941407, 11.4379997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2676, 892.9769898, -3699.1359864, 11.4379997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18260, 736.0809937, -3747.7370606, 12.908, 0.0000000, 0.0000000, 90.7500000);
	CreateDynamicObject(2912, 734.9140015, -3749.1701661, 13.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2912, 736.946991, -3751.1540528, 15.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2912, 737.1040039, -3749.1359864, 15.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 726.7519836, -3752.5639649, 11.1739998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 729.7309876, -3752.5671387, 11.1739998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 728.178009, -3752.5690918, 13.3380003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 743.8150024, -3753.9899903, 11.6990004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 743.803009, -3754.0429688, 11.6479998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 742.9329834, -3765.9101563, 13.6379995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 885.5739746, -3717.6159668, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 885.5629883, -3715.9401856, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 809.4849854, -3728.3920899, 17.7789993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 834.8930054, -3715.9069825, 15.5480003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 836.1940003, -3731.5810547, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 785.4660034, -3773.4790039, 15.5349998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 773.5100098, -3742.6420899, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 773.5570068, -3744.3671875, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 764.8359985, -3746.5671387, 13.3299999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, 750.1690064, -3768.1511231, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 885.1370239, -3712.3549805, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 883.0999756, -3712.3630371, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 881.0949707, -3712.3710938, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 883.0720215, -3712.4211426, 13.3380003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 849.9509888, -3720.157959, 15.5480003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 846.2149963, -3756.9589844, 15.5220003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 846.2210083, -3754.9050293, 15.5220003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 835.7730103, -3756.8840332, 15.5229998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 803.0220032, -3744.1210938, 15.5620003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 813.1329956, -3726.5400391, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 726.8760071, -3755.5310059, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 729.4629822, -3756.8769532, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 741.7940064, -3770.9650879, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, 780.3049927, -3747.2431641, 11.335, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 873.164978, -3720.9179688, 11.1990004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 876.1519775, -3720.9279785, 10.4239998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 879.1519775, -3720.9401856, 11.1859999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 887.6989746, -3706.9880371, 11.1610003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 887.7050171, -3703.894043, 11.1739998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, 887.6879883, -3705.6230469, 13.3380003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, 852.28302, -3759.1281739, 23.8369999, 0.0000000, 0.0000000, 89.7500000);
	CreateDynamicObject(4199, 786.7739868, -3721.7321778, 21.7439995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, 760.0839844, -3727.6230469, 21.6860008, 0.0000000, 0.0000000, 118.9984131);
	CreateDynamicObject(4199, 743.802002, -3748.3090821, 21.7369995, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, 743.7779846, -3748.2980957, 21.7199993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 795.7619934, -3750.2111817, 25.9790001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, 795.7980042, -3750.2050782, 25.9790001, 0.0000000, 0.0000000, 180.0000000);

	// Elorreli - Narrow Passage
	CreateDynamicObject(4867, -395, -4107, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -351.5751953, -4146.7675781, 19.8610001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -376.5718994, -4156.6796875, 19.8610001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -371.1948852, -4126.0256348, 19.8610001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -358.9089355, -4155.1247558, 18.7450008, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -373.1513671, -4162.7490234, 19.8610001, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -376.5718994, -4156.6796875, 24.0020008, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -351.5751953, -4146.7675781, 24.0249996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -376.5732421, -4156.7167969, 24.0020008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -351.5089111, -4165.1657715, 19.8610001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -351.5703124, -4159.6611328, 24.0249996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -373.1279296, -4174.2138672, 24.0139999, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -371.1953124, -4126.0253906, 24.0149994, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -381.2619018, -4144.7026367, 19.8239994, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14410, -372.8378906, -4148.996582, 18.7450008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -373.1289062, -4174.1877441, 19.7999992, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14410, -372.8378906, -4145.0266113, 18.7450008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -404.6728515, -4174.2373047, 24, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(14410, -372.8378906, -4141.0566406, 18.7450008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -372.8378906, -4137.0866699, 18.7450008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -372.8378906, -4133.1166992, 18.7450008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -404.6738891, -4162.7487793, 19.8610001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -392.2468872, -4145.1196289, 18.1529999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -404.6738891, -4174.2871094, 19.8999996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -403.4758911, -4141.2966308, 24.4290009, 0.0000000, 179.9945068, 179.9945068);
	CreateDynamicObject(4199, -402.7548828, -4126.0019531, 24.0149994, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -434.1796874, -4162.7548828, 13.8499994, 22.9998779, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -414.6469116, -4151.3286133, 24.0020008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -415.9808959, -4151.3566894, 19.8110008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -415.9808959, -4174.2297363, 19.8999996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(18260, -359.1289062, -4142.3876953, 19.2999992, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -415.9833984, -4174.2666015, 23.9920006, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -424.8085937, -4174.2685547, 19.8999996, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -424.8037109, -4174.2919922, 24.0550003, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -446.1019287, -4148.923584, 19.8500004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -446.0996093, -4153.8300781, 24.052, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(2359, -358.2294921, -4133.7871094, 18, 0.0000000, 0.0000000, 245.9948730);
	CreateDynamicObject(4199, -415.9853515, -4151.28125, 19.8110008, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(2359, -358.1289062, -4132.3876953, 18, 0.0000000, 0.0000000, 315.9948730);
	CreateDynamicObject(4199, -414.619934, -4151.3056641, 24.0020008, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(2359, -359.2288818, -4133.1877441, 18, 0.0000000, 0.0000000, 265.9942627);
	CreateDynamicObject(4199, -403.4929199, -4141.3395996, 24.4790001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -403.4918823, -4141.3518066, 15.8590002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -402.7548828, -4126.0009765, 19.8290005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -403.4238891, -4141.3037109, 24.4540005, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -392.296936, -4145.1186523, 18.1159992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -381.3115234, -4144.703125, 19.8610001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -413.4249267, -4151.2976074, 20.2450008, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(3499, -398.0529174, -4156.7807617, 25.2399998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -398.0878906, -4145.8977051, 16.8619995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -397.8129272, -4132.0266113, 16.875, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14410, -400.0299072, -4132.6867676, 17.0599995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14410, -400.0299072, -4136.6777344, 17.0599995, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14410, -400.0302734, -4140.6679687, 17.0599995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14410, -400.0299072, -4144.659668, 17.0599995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14410, -389.3508911, -4133.6018066, 18.7549992, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14410, -389.3508911, -4137.5708008, 18.7549992, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14410, -389.3515624, -4141.5390625, 18.7549992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14410, -389.3508911, -4145.5087891, 18.7549992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14410, -389.3515624, -4149.4775391, 18.7549992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3499, -408.619934, -4132.3276367, 17.0349998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -408.5089111, -4144.8056641, 17.0230007, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14410, -394.1757812, -4154.8183594, 18.7549992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14410, -398.0988769, -4154.8186035, 18.7549992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -432.3679199, -4118.1118164, 19.8290005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -446.1929321, -4153.8537598, 24.052, 0.0000000, 179.9945068, 179.9945068);
	CreateDynamicObject(4199, -456.185913, -4174.2707519, 19.8630009, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -464.7169189, -4149.0656738, 19.9249992, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -446.1589355, -4148.9487305, 19.8999996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -463.9078979, -4118.1166992, 19.8290005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -446.0969238, -4117.3647461, 19.8999996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -432.3679199, -4118.1118164, 24.0270004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -463.9078979, -4118.1166992, 24.0480003, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -438.3829345, -4136.1005859, 18.8029995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -438.3829345, -4132.1186523, 18.8029995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -438.3829345, -4128.1367187, 18.8029995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14410, -438.3829345, -4124.1547851, 18.8029995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -449.9042968, -4132.4111328, 19.8729992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4867, -395, -4107, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -449.9049072, -4132.4606933, 19.8980007, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -456.2819213, -4153.2246094, 16.5559998, 347.7500000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -464.7238769, -4130.8867187, 19.8999996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -463.5399169, -4121.5256348, 19.8980007, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -459.3479003, -4153.2687988, 21.4920006, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(8650, -444.4799194, -4168.9348144, 21.4920006, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -464.7619018, -4130.8867187, 19.8630009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -411.7519531, -4116.4023437, 19.8290005, 0.0000000, 0.0000000, 315.9997559);
	CreateDynamicObject(2991, -381.9296874, -4133.8876953, 22.6000004, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -455.3209228, -4185.2036133, 24.0550003, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -475.4039306, -4168.1877441, 24.0550003, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -475.4039306, -4132.6047363, 24.0550003, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -475.4039306, -4132.6047363, 19.875, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14410, -472.7279052, -4150.3427734, 18.7730007, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(2991, -381.928894, -4148.7875976, 22.6000004, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(8661, -469.5269165, -4183.8505859, 20.9710007, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(8650, -459.3486328, -4153.2685547, 21.4920006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, -469.5189208, -4184.4597168, 21.9260006, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3798, -381.928894, -4149.7875976, 23.2000008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -486.1759033, -4158.1726074, 19.9239998, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -493.251892, -4174.2707519, 19.8630009, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(3798, -381.9296874, -4132.8876953, 23.2000008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -485.2438964, -4185.2277832, 19.8869991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3798, -358.428894, -4167.3876953, 21.9899998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -513.744934, -4163.8046875, 19.875, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4867, -607.7879028, -4105.5808105, 17.7889996, 0.0000000, 0.0000000, 359.2500000);
	CreateDynamicObject(4199, -486.178894, -4158.2216797, 19.9239998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -494.8198852, -4165.0646973, 24.0709991, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -495.9238891, -4142.640625, 19.9239998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -494.7609252, -4153.6867676, 24.0709991, 0.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(3798, -393.428894, -4151.8876953, 20.2999992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, -479.4960937, -4180.5166015, 30.9489994, 90.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(8650, -479.1088867, -4169.1066894, 22.1000004, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(3798, -391.428894, -4149.8876953, 20.2999992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(856, -420.7288818, -4125.0905762, 20.8330002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3796, -421.1289062, -4126.8876953, 21.8999996, 0.0000000, 0.0000000, 46.2500000);
	CreateDynamicObject(3498, -434.4468994, -4137.8986816, 18.7049999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4468994, -4137.2226562, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4136.5458984, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4135.8701172, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4135.1943359, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4134.5185547, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4133.8417969, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4133.1660156, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4132.4902344, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4131.8144531, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4131.1376953, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4130.4619141, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4129.7861328, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4129.1103515, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4128.4335937, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4127.7578125, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -434.4472656, -4127.0820312, 18.7049999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -435.1259155, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -435.8129272, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -436.4999389, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -437.1869506, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -437.8739624, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -438.5609741, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -439.2479858, -4137.9316406, 18.2089996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3498, -439.9355468, -4137.9316406, 18.7049999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8130, -482.0679321, -4152.5097656, 10.1300001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8130, -482.0579223, -4149.2766113, 10.1300001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -419.6959228, -4144.4416504, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -421.7648925, -4144.4506836, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -424.1029052, -4143.2727051, 17.7889996, 0.0000000, 0.0000000, 70.0000000);
	CreateDynamicObject(2991, -455.2979125, -4170.5117187, 22.6000004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3798, -458.7628784, -4170.3706055, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -404.6729125, -4174.237793, 28.1450005, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -415.9829101, -4174.2666015, 28.1469994, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -424.803894, -4174.291748, 28.1310005, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -455.3209228, -4185.2036133, 28.1450005, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -446.1489257, -4153.8308105, 28.0970001, 0.0000000, 179.9945068, 179.9945068);
	CreateDynamicObject(4199, -446.0999145, -4153.8327637, 28.0970001, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(18257, -468.7288818, -4129.3876953, 22, 0.0000000, 0.0000000, 215.2500000);
	CreateDynamicObject(4199, -432.3679199, -4118.1118164, 28.2110004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -402.7548828, -4126.001709, 28.1739998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -371.1948852, -4126.0256348, 28.1790009, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -351.5748901, -4146.7675781, 28.177, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -351.5698852, -4159.6616211, 28.1790009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -373.1279296, -4174.213623, 28.1620007, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3798, -452.7288818, -4124.987793, 22, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -403.4249267, -4141.3037109, 28.6110001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -415.9808959, -4151.3566894, 27.6919994, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3798, -449.3289184, -4125.1877441, 22, 0.0000000, 0.0000000, 321.9999695);
	CreateDynamicObject(4199, -376.5728759, -4156.7167969, 28.1630001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -376.5709228, -4156.6425781, 28.1630001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -463.9078979, -4118.1166992, 28.1879997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -475.4039306, -4132.6047363, 28.177, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -475.4039306, -4168.1877441, 28.2189999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -403.4509277, -4141.3037109, 28.6110001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -415.9819335, -4151.2817383, 27.6919994, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3498, -431.3729248, -4145.9387207, 21.6630001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -415.9808959, -4151.3317871, 27.6550007, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(3498, -431.4669189, -4156.7775879, 21.6630001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -399.0659179, -4156.7807617, 24.7830009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -494.7619018, -4153.6867676, 28.2339993, 0.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(3798, -425.5438842, -4126.6516113, 17.7889996, 0.0000000, 0.0000000, 46.0000000);
	CreateDynamicObject(3798, -421.1759033, -4130.6616211, 17.7889996, 0.0000000, 0.0000000, 47.9997559);
	CreateDynamicObject(3798, -430.0128784, -4124.9116211, 17.7889996, 0.0000000, 0.0000000, 359.4992676);
	CreateDynamicObject(3798, -468.5189208, -4157.9257812, 22.0380001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -468.5659179, -4145.9296875, 22.0380001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -384.7689208, -4163.5266113, 21.9740009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -384.7568969, -4165.5556641, 20.927, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -468.6289062, -4169.3876953, 22, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -387.8519287, -4121.8666992, 18.0590019, 0.0000000, 0.0000000, 180.0109863);
	CreateDynamicObject(4199, -382.244934, -4104.409668, 14.6970024, 0.0000000, 0.0000000, 270.0164795);
	CreateDynamicObject(3499, -376.6379394, -4086.9526367, 11.3350029, 0.0000000, 0.0000000, 0.0219727);
	CreateDynamicObject(4199, -371.0309448, -4069.4956055, 7.9730034, 0.0000000, 0.0000000, 90.0274963);
	CreateDynamicObject(3499, -365.4239501, -4052.0385742, 4.6110039, 0.0000000, 0.0000000, 180.0329590);
	CreateDynamicObject(4199, -359.8169555, -4034.581543, 1.2490044, 0.0000000, 0.0000000, 270.0384521);
	CreateDynamicObject(3499, -354.2099609, -4017.1245117, -2.1129951, 0.0000000, 0.0000000, 0.0439148);
	CreateDynamicObject(4199, -348.6029663, -3999.6674805, -5.4749947, 0.0000000, 0.0000000, 90.0492554);
	CreateDynamicObject(3499, -342.9959716, -3982.2104492, -8.8369942, 0.0000000, 0.0000000, 180.0548706);
	CreateDynamicObject(3499, -400.0789184, -4156.7807617, 24.3260021, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -401.0919189, -4156.7807617, 23.8690033, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -402.1049194, -4156.7807617, 23.4120045, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -403.1179199, -4156.7807617, 22.9550056, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -404.1309204, -4156.7807617, 22.4980068, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -405.1439208, -4156.7807617, 22.041008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -406.1569213, -4156.7807617, 21.5840092, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -407.1699218, -4156.7807617, 21.1270103, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -408.1829223, -4156.7807617, 20.6700115, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -409.1959228, -4156.7807617, 20.2130127, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -423.6428833, -4128.7885742, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -420.6629028, -4144.4177246, 19.7919998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -439.6079101, -4145.1328125, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -463.2899169, -4128.166748, 24, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -468.5388793, -4171.6276855, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -449.5388793, -4170.2226562, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -449.5549316, -4171.3947754, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -449.2288818, -4172.7255859, 21.9759998, 0.0000000, 0.0000000, 32.0000000);
	CreateDynamicObject(3800, -449.5559082, -4171.3947754, 22.9769993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -362.6298828, -4149.7966308, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -371.5618896, -4167.3605957, 21.9740009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -393.4689331, -4163.0795898, 21.9740009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -393.4478759, -4161.060791, 21.9740009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -393.3189086, -4161.3327637, 23.8029995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -408.9429321, -4167.409668, 21.9740009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -408.9368896, -4165.3486328, 21.2350006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -438.9299316, -4163.8505859, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -458.0289306, -4160.6877441, 17.3999996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(874, -466.8358764, -4167.1157226, 17.4130001, 0.0000000, 0.0000000, 64.0000000);
	CreateDynamicObject(874, -501.9268798, -4166.9025879, 17.4130001, 0.0000000, 0.0000000, 63.9953613);
	CreateDynamicObject(874, -474.9498901, -4178.1018066, 17.4130001, 0.0000000, 0.0000000, 63.9953613);
	CreateDynamicObject(3798, -450.6578979, -4136.982666, 22, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -450.6809082, -4134.9526367, 21.0400009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -450.6838989, -4132.8886719, 21.9699993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -458.3289184, -4158.8876953, 17.7999992, 0.0000000, 0.0000000, 0.7500000);
	CreateDynamicObject(3800, -450.053894, -4131.1037598, 21.9880009, 0.0000000, 0.0000000, 342.0000000);
	CreateDynamicObject(3798, -432.8189086, -4151.0856933, 17.7520008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -449.126892, -4130.7277832, 17.3400002, 0.0000000, 0.0000000, 43.5000000);
	CreateDynamicObject(3800, -439.7139282, -4139.0065918, 19.441, 0.0000000, 0.0000000, 356.7500000);
	CreateDynamicObject(862, -362.2288818, -4133.0876465, 17.7999992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -366.8289184, -4149.987793, 17.7999992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -428.251892, -4131.7756348, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -416.5728759, -4139.8996582, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -435.270935, -4144.9086914, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -457.3759155, -4163.4587402, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -476.1968994, -4175.2565918, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -506.5718994, -4151.9196777, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -484.5098876, -4151.6616211, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -431.0858764, -4167.4125976, 17.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -465.4179077, -4130.9936523, 22.2849998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -447.3159179, -4135.4257812, 22.2849998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -423.6619262, -4130.1606445, 18.0610008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -433.3319091, -4155.6376953, 18.0610008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -387.4779052, -4163.8076172, 22.2460003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2677, -358.9838867, -4139.6748047, 18.0610008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -507.1289062, -4167.487793, 17.7999992, 0.0000000, 0.0000000, 320.0000000);
	CreateDynamicObject(2673, -364.9899291, -4149.7006836, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -384.0089111, -4149.3027344, 22.0620003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -393.5999145, -4149.4697265, 20.3540001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -434.4799194, -4141.8925781, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -467.6019287, -4155.1047363, 22.1259995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -467.2078857, -4177.2387695, 22.0639992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -491.9478759, -4150.4506836, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -507.1289062, -4167.487793, 19.7999992, 0.0000000, 0.0000000, 319.9987793);
	CreateDynamicObject(2673, -498.001892, -4166.3806152, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -468.7418823, -4166.1926269, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2673, -473.2999267, -4177.7246094, 17.8770008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2671, -443.6599121, -4171.5598144, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2671, -450.4589233, -4177.4047851, 21.9759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -493.7509155, -4163.9707031, 17.5109997, 0.0000000, 0.0000000, 319.9987793);
	CreateDynamicObject(3798, -489.211914, -4168.3347168, 17.5109997, 0.0000000, 0.0000000, 319.9987793);
	CreateDynamicObject(3798, -488.8159179, -4148.3596191, 17.5109997, 0.0000000, 0.0000000, 319.9987793);
	CreateDynamicObject(3798, -497.2669067, -4152.4348144, 17.5109997, 0.0000000, 0.0000000, 319.9987793);
	CreateDynamicObject(3798, -506.7479248, -4148.5895996, 17.5109997, 0.0000000, 0.0000000, 319.9987793);

	// Elorreli - King of hill
	CreateDynamicObject(16685, -1542, -4428, 16.8050003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1424.1790162, -4427.4440918, 18.8689995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1442.4810181, -4409.6481933, 18.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1442.4810181, -4444.8161621, 18.8689995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -1464.0549927, -4426.9921875, 16.9909992, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -1474.0729981, -4427.6691894, 21.1539993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1456.1419678, -4437.0371093, 15.8699999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1456.1259766, -4435.3859863, 15.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1470.5490113, -4427.6491699, 17.0060005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1456.1099854, -4419.8461914, 15.8690004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1456.110962, -4417.0510254, 15.868, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1465.7249756, -4456.3850097, 18.8810005, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1475.6369629, -4426.9799804, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1465.7249756, -4398.1159668, 18.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1497.2379761, -4427.6691894, 17.0060005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1474.1099854, -4427.6311035, 21.1539993, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -1475.6378174, -4426.9799804, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1487.1870118, -4426.9941406, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1498.7390137, -4426.9960937, 16.980999, 0.0000000, 0.0000000, 179.9835205);
	CreateDynamicObject(4199, -1507.2669678, -4427.0021972, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1515.795044, -4427.0083008, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1524.322876, -4427.0144043, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1532.8508301, -4427.0205078, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1541.3787842, -4427.0266113, 16.9909992, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1549.9069825, -4427.0332031, 16.9790001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1539.8920289, -4427.6691894, 21.1539993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1543.4619751, -4427.6889648, 16.9629993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1557.907959, -4419.9179687, 15.8640003, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -1571.4710083, -4409.6481933, 18.8939991, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(14416, -1557.9099732, -4416.415039, 15.8629999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1571.4710083, -4444.8161621, 18.8939991, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14416, -1557.8999634, -4435.5051269, 15.8629999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14416, -1557.8869629, -4438.2541504, 15.8619995, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1589.5419922, -4427.2800293, 18.8689995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -1547.2069703, -4398.1381836, 18.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1547.2069703, -4456.3591308, 18.8939991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1539.8980103, -4427.6440429, 21.1539993, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -1515.526001, -4458.6049804, 18.8939991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1490.3800049, -4458.5881347, 18.8939991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1516.0679932, -4395.1271972, 18.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1489.1209717, -4395.1340332, 18.8689995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1571.4719849, -4409.6481933, 23.0580006, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1589.5419922, -4427.2800293, 23.0370007, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1571.4719849, -4444.8161621, 23.0510006, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1547.2069703, -4398.1381836, 23.0400009, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1516.0679932, -4395.1271972, 23.0550003, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1489.1209717, -4395.1330566, 23.0489998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1465.7260132, -4398.1159668, 23.0389996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1442.4819947, -4409.6481933, 23.0529995, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1424.1799927, -4427.4440918, 23.0599995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1442.4819947, -4444.8161621, 23.0529995, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1465.7260132, -4456.3840332, 23.0489998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1490.3800049, -4458.5871582, 23.0389996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1515.526001, -4458.6049804, 23.0389996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1547.2069703, -4456.3591308, 23.0620003, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1506.8219605, -4426.9899902, 21.1490002, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14416, -1499.018982, -4444.8771972, 15.8809996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1491.2780152, -4430.4841308, 16.9659996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1506.8469849, -4430.4191894, 16.9909992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1490.7379761, -4423.5681152, 16.980999, 0.0000000, 0.0000000, 179.9844971);
	CreateDynamicObject(14416, -1498.5459595, -4409.1281738, 15.8809996, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -1506.2349854, -4423.5690918, 16.9909992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -1470.2600098, -4442.3720703, 18.8899994, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(8650, -1469.7109986, -4411.6081543, 18.8899994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1474.0729981, -4427.6679687, 25.309, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1539.8930054, -4427.6679687, 25.3379993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1474.078003, -4427.6430664, 25.309, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -1539.8950196, -4427.6301269, 25.3379993, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -1506.8469849, -4426.9921875, 21.1490002, 0.0000000, 180.0000000, 179.9945068);
	CreateDynamicObject(4199, -1539.893982, -4427.6679687, 29.4810009, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1539.8969727, -4427.6430664, 29.4810009, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -1474.0729981, -4427.6679687, 29.5020008, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1474.0750122, -4427.6430664, 29.5020008, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(3499, -1458.6530152, -4433.0629882, 24.6119995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -1458.6530152, -4422.3630371, 24.6119995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -1458.6630249, -4433.0620117, 26.1599998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -1458.6630249, -4422.3630371, 26.1529999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -1543.4240113, -4442.4060058, 18.8899994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1522.3829956, -4430.4191894, 16.980999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14416, -1514.6029664, -4444.8549804, 15.8809996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14416, -1514.0429688, -4409.1301269, 15.8809996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -1521.7799683, -4423.5751953, 16.9810009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -1542.8189698, -4411.6340332, 18.8899994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3499, -1555.3209839, -4422.3300781, 24.5690002, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(3499, -1555.3309937, -4422.3291015, 26.1439991, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3499, -1555.3209839, -4433.0361328, 24.5690002, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3499, -1555.3309937, -4433.0361328, 26.1079998, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(2988, -1458.3950196, -4423.5720215, 19.1189995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -1458.3820191, -4431.9221191, 19.1189995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(2988, -1555.610962, -4423.4812011, 19.0760002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -1555.6069947, -4431.8701172, 19.0760002, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -1443.5869751, -4427.6259765, 7.723, 38.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1570.419983, -4427.6691894, 7.6729999, 322.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(18260, -1543.1400147, -4435.2670898, 20.6779995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(18257, -1540.532959, -4420.993164, 19.1040001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1526.1679688, -4420.3220215, 18.9799995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1526.1220093, -4435.0270996, 18.9799995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1522.742981, -4429.9291992, 18.9799995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1514.2260132, -4420.3869629, 18.9799995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1516.7189942, -4423.8339843, 18.0709991, 0.0000000, 0.0000000, 18.0000000);
	CreateDynamicObject(3799, -1532.8809815, -4449.0520019, 16.6289997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18257, -1499.8510132, -4427.8330078, 19.0540009, 0.0000000, 0.0000000, 272.0000000);
	CreateDynamicObject(18257, -1478.9790039, -4434.2561035, 19.0540009, 0.0000000, 0.0000000, 178.4995117);
	CreateDynamicObject(18257, -1470.1090088, -4420.625, 19.0419998, 0.0000000, 0.0000000, 1.2500000);
	CreateDynamicObject(3800, -1506.6119996, -4446.7780761, 16.757, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1506.6049805, -4447.8781738, 16.7450008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1506.6099854, -4448.9799804, 16.757, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1506.5979615, -4447.3950195, 17.8040009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1492.1740113, -4446.8251953, 16.7450008, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(3800, -1492.1599732, -4447.9260254, 16.7450008, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3800, -1492.1820069, -4449.0290527, 16.7450008, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3800, -1492.1920166, -4450.1311035, 16.7450008, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3800, -1492.1879883, -4449.5820312, 17.8220005, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3800, -1518.203003, -4407.2250976, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1518.1950074, -4406.072998, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1518.1859742, -4404.9711914, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1518.6369629, -4403.6491699, 16.7819996, 0.0000000, 0.0000000, 38.0000000);
	CreateDynamicObject(3800, -1518.6380005, -4403.6491699, 17.8320007, 0.0000000, 0.0000000, 37.9962158);
	CreateDynamicObject(3800, -1518.18396, -4406.5991211, 17.8439999, 0.0000000, 0.0000000, 358.9962158);
	CreateDynamicObject(3800, -1495.4899903, -4407.2451172, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1495.4710083, -4406.1440429, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1495.4660035, -4405.0180664, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1495.4500122, -4403.8901367, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1495.4719849, -4405.6149902, 17.8570004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1473.4829712, -4449.25708, 16.6149998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1468.4479981, -4405.3540039, 16.2779999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1511.1629639, -4441.328125, 23.1130009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1502.5079956, -4441.3271484, 23.0760002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1511.1740113, -4412.6740722, 23.0879993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1502.5150147, -4412.6750488, 23.1000004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -1512.2069703, -4426.4870605, 23.3500004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -1501.4569703, -4427.0341797, 23.3500004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1503.3460083, -4427.6311035, 23.0750008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1510.3239747, -4421.5849609, 23.0750008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -1502.4879761, -4423.809082, 23.2000008, 0.0000000, 0.0000000, 358.9947510);
	CreateDynamicObject(3800, -1511.2210083, -4433.3200683, 23.2250004, 0.0000000, 0.0000000, 358.9947510);
	CreateDynamicObject(3800, -1502.4160157, -4435.5961914, 23.2250004, 0.0000000, 0.0000000, 358.9947510);
	CreateDynamicObject(3800, -1504.584961, -4412.3930664, 23.2369995, 0.0000000, 0.0000000, 358.9947510);
	CreateDynamicObject(18257, -1430.9689942, -4423.2050781, 16.7679996, 0.0000000, 0.0000000, 90.7469482);
	CreateDynamicObject(18257, -1582.8029786, -4431.5300293, 16.7679996, 0.0000000, 0.0000000, 270.2415771);
	CreateDynamicObject(3799, -1572.9489747, -4417.0581054, 16.6459999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1572.9609986, -4420.0500488, 16.6459999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1571.6029664, -4437.4831543, 16.6459999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1443.8889771, -4417.1369629, 16.6459999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1441.7269898, -4437.4680175, 16.6399994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1441.7149659, -4434.4941406, 16.6399994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1488.2199707, -4420.3520508, 18.9549999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1491.4799805, -4426.3869629, 18.9549999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1487.4219971, -4434.9301758, 18.9549999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1489.709961, -4438.540039, 18.2320004, 0.0000000, 0.0000000, 24.0000000);
	CreateDynamicObject(4199, -1515.526001, -4458.6049804, 27.191, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1490.3800049, -4458.5861816, 27.1609993, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1489.1209717, -4395.13208, 27.2269993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1516.0679932, -4395.1271972, 27.2140007, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1465.7269898, -4398.1159668, 27.2089996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1424.1809693, -4427.4440918, 27.2169991, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -1547.2069703, -4398.1381836, 27.1970005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -1547.2069703, -4456.3591308, 27.2639999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1465.7269898, -4456.3830566, 27.1410007, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -1589.5419922, -4427.2800293, 27.2189999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3799, -1486.4240113, -4409.2709961, 18.9549999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1489.0769654, -4412.6621093, 18.0779991, 0.0000000, 0.0000000, 287.9999695);
	CreateDynamicObject(3799, -1518.0700074, -4444.7211914, 18.9050007, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1520.2739869, -4441.3410644, 18.0970001, 0.0000000, 0.0000000, 328.0000000);
	CreateDynamicObject(856, -1533.2990113, -4412.2929687, 15.0430002, 0.0000000, 0.0000000, 84.0000000);
	CreateDynamicObject(856, -1544.4479981, -4442.4941406, 15.0430002, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1501.4519654, -4454.5800781, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1477.3869629, -4441.9711914, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1436.2780152, -4419.0861816, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1433.5219727, -4435.795166, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1465.2559815, -4406.6259765, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1484.2420044, -4400.2741699, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1508.7650147, -4409.5571289, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1580.4030152, -4438.7121582, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(856, -1569.1469727, -4417.6630859, 14.4940004, 0.0000000, 0.0000000, 83.9959717);
	CreateDynamicObject(862, -1525.8059693, -4402.790039, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1488.1929932, -4406.6420898, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1437.1599732, -4419.3171386, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1445.3690186, -4437.0051269, 16.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1467.4389649, -4446.5231933, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1501.7299805, -4448.9179687, 16.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1519.2529908, -4451.2521972, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -1543.6159668, -4448.9650879, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(861, -1501.1419678, -4407.1811523, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(861, -1439.0989991, -4434.9270019, 16.7889996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(861, -1582.5289917, -4421.3869629, 16.7819996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1463.0249634, -4444.2080078, 16.6130009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1463.0150147, -4447.1210937, 15.7659998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1550.5299683, -4449.1340332, 16.5550003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1550.5269776, -4446.2180175, 15.7810001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1550.2019654, -4409.7561035, 15.9049997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1550.1989747, -4406.8520508, 16.4540005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -1468.4420166, -4408.2819824, 15.3920002, 0.0000000, 0.0000000, 0.0000000);

	// Elorreli - de_dust2 (Long part)
	CreateDynamicObject(16685, -3751, -3000, 20.4479999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(16685, -3656.1290283, -3087.0900879, 20.4379997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(16685, -3479.8900147, -2997.8220215, -17.9430008, 0.7269287, 14.2511597, 359.8153686);
	CreateDynamicObject(4199, -3657.8760071, -3040.1369629, 22.4869995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3657.8770142, -3040.1369629, 26.6049995, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3679.4519959, -3030.1401368, 22.4869995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3679.4530029, -3030.1391602, 26.6599998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3636.3099976, -3061.722168, 22.5090008, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3636.3099976, -3061.7209473, 26.5809994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3615.6439819, -3040.0390625, 22.4880009, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3615.6439819, -3040.0390625, 26.6329994, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3799, -3650.4979858, -3049.6640625, 20.2910004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3647.5029907, -3049.6560059, 20.2539997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3650.4979858, -3049.6640625, 22.5170002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(1271, -3651.6409912, -3047.6420899, 20.7649994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3615.6470337, -3039.979004, 22.4869995, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3600.6279907, -3050.5490723, 22.4880009, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3600.6290283, -3050.5490723, 26.6700001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3605.7990112, -3061.7250977, 22.5090008, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3606.7059937, -3061.7309571, 26.5809994, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3499, -3652.5809937, -3024.64917, 23.2259998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(16685, -3606.473999, -3179.2070313, 20.1159992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3615.6470337, -3028.6591797, 18.3390007, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3615.6470337, -3039.9780274, 26.5499992, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3615.6470337, -3028.6591797, 14.1540003, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(8650, -3616.1990357, -3023.3149415, 20.5499992, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3603.9609986, -3007.9389649, 22.4869995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3603.9490357, -3007.932129, 26.6049995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3603.9329834, -3007.913086, 22.4869995, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(4199, -3615.2449951, -3003.7641602, 19.5349998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3615.7900391, -3009.1169434, 21.0639992, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3615.2460327, -3003.7629395, 15.3990002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(16685, -3481.7380371, -3006.4890137, 15.085, 0.7269287, 0.0000000, 359.8153686);
	CreateDynamicObject(4199, -3615.3240357, -2996.9760743, 22.408001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3595.059021, -3018.1479493, 18.3320007, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3595.059021, -3018.1469727, 14.1260004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3631.4689941, -3003.7609864, 19.5100002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3663.0429993, -3003.7641602, 22.5319996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3663.0440064, -3003.7629395, 26.7119999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3646.9110107, -2996.9770508, 22.408001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3646.9119873, -2996.9760743, 26.5900002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3615.3250122, -2996.9750977, 26.5620003, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3589.5889893, -3028.9421387, 22.4869995, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3589.5889893, -3028.9421387, 26.6509991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3799, -3607.8670044, -3025.3649903, 20.3029995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3607.8209839, -3028.334961, 20.3029995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3607.8010254, -3031.2971192, 20.3029995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3607.8469849, -3025.3781739, 22.5380001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3607.9960327, -3028.3171387, 22.5380001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3612.2460327, -3031.4279786, 20.3029995, 0.0000000, 0.0000000, 38.0000000);
	CreateDynamicObject(3799, -3611.3170166, -3004.3659668, 21.5119991, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3593.9420166, -3004.979004, 18.375, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3593.9420166, -3004.9780274, 14.2110004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3594.4539795, -3027.6311036, 14.0340004, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3594.4550171, -3027.6311036, 18.2469997, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(2988, -3600.7590332, -3012.0800782, 14.9940004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -3600.7681885, -3020.4753418, 14.9940004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(16685, -3745.2220154, -3010.3081055, 20.4479999, 7.2500000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3693.0950012, -2998.5461426, 22.5319996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3693.0950012, -2998.5461426, 26.7129993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3799, -3645.7789917, -3004.2961426, 21.4869995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(11472, -3638.4990235, -3008.7971192, 18.5849991, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3649.4719849, -3009.1459962, 21.0419998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3799, -3680.381012, -3005.8339844, 20.6690006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(16685, -3792.3070069, -3019.972168, 20.4470005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3689.4510193, -3051.7180176, 22.4869995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -3694.8220215, -3024.7341309, 23.3330002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3711.7630005, -3040.2370606, 22.4869995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3723.3000183, -3040.2299805, 22.4869995, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(16685, -3575.7009888, -2999.0920411, -4.0939999, 0.0000000, 10.5009460, 0.1088867);
	CreateDynamicObject(4199, -3724.5599976, -2998.5500489, 22.5319996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3724.6040039, -2998.5100098, 26.7129993, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(16685, -3789.756012, -3071.7719727, 15.5129995, 10.5000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3689.4519959, -3051.7180176, 18.3279991, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3711.7630005, -3040.2370606, 18.3810005, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(8650, -3690.7409973, -3055.6340333, 24.1359997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3690.723999, -3055.6469727, 24.1289997, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(8661, -3709.1289978, -3065.6311036, 24.5879993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3690.6329956, -3070.9960938, 20.9419994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3690.6329956, -3070.9960938, 16.7740002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3704.7839966, -3053.8310547, 18.2520008, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -3705.4040222, -3054.2641602, 20.6019993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -3718.3500061, -3055.64917, 23.1350002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3718.3540039, -3055.6621094, 22.1410007, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3718.3529968, -3055.6760254, 21.1380005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3718.3580017, -3055.6740723, 20.1359997, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8650, -3718.3780212, -3055.7021485, 19.1599998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3712.7539978, -3071.0839844, 22.4990006, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3712.7539978, -3071.0839844, 18.3649998, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(16685, -3789.7279968, -3082.3271485, 18.5909996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, -3709.1295166, -3065.6306153, 24.5879993, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(8661, -3709.1289978, -3065.6311036, 23.0219994, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(4199, -3701.2620239, -3085.552002, 22.4780006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3701.2620239, -3085.552002, 18.3069992, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3709.0100098, -3022.8901368, 20.0869999, 0.0000000, 10.5009460, 0.0000000);
	CreateDynamicObject(4199, -3679.4439697, -3041.6403809, 26.6599998, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3679.4110107, -3050.1940918, 26.6599998, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3679.375, -3050.2050782, 26.6350002, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3699.5110169, -3066.755127, 26.5939999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3731.0760193, -3066.7490235, 26.5939999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3740.4640198, -3017.5061036, 26.5939999, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3734.6560059, -3015.9111329, 22.4869995, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3734.809021, -3047.5129395, 22.4869995, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3731.4880066, -3048.4780274, 26.5939999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14409, -3681.7059937, -3059.02417, 21.4039993, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14409, -3681.7430115, -3056.7209473, 21.4039993, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3799, -3693.7130127, -3056.2519532, 24.4230003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -3734.8059998, -3013.5251465, 24.5629997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -3734.7749939, -3021.9050294, 24.5629997, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3723.1060181, -3004.2470704, 22.5240002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3723.1060181, -3004.2470704, 26.6809998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3740.4230042, -3045.3261719, 26.5569992, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3799, -3708.2900086, -3033.6320801, 24.4759998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3711.8770142, -3033.0661622, 24.4510002, 0.0000000, 0.0000000, 340.5000000);
	CreateDynamicObject(3799, -3710.1180115, -3033.597168, 26.6560001, 0.0000000, 0.0000000, 351.9992676);
	CreateDynamicObject(3799, -3712.1860047, -3026.7150879, 24.4699993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3679.3710022, -3050.2800294, 22.7010002, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3676.0390015, -3057.8491212, 19.0170002, 0.0000000, 0.0000000, 357.9890137);
	CreateDynamicObject(4199, -3687.8330078, -3066.7680665, 26.5709991, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3666.4330139, -3059.625, 23.1550007, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3666.3959961, -3059.6230469, 26.5809994, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3733.1040039, -3031.1240235, 24.4330006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8650, -3631.0270386, -3058.236084, 27.5960007, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(8650, -3631.0280152, -3058.236084, 25.5450001, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(4199, -3615.0170288, -3050.4440918, 26.6329994, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(3799, -3705.3980103, -3068.0981446, 18.4130001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3673.6940003, -3066.7590333, 23.1749992, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(8171, -3622.5150147, -3002.7260743, 28.7639999, 0.0000000, 90.0000000, 90.0000000);
	CreateDynamicObject(8171, -3748.0820007, -3004.302002, 28.7639999, 0.0000000, 90.0000000, 90.0000000);
	CreateDynamicObject(8661, -3589.7260132, -3027.9340821, 28.691, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(8661, -3633.9790039, -3048.8371583, 28.691, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, -3681.5670166, -3057.4389649, 28.7070007, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2988, -3637.1450195, -3002.7451172, 21.6229992, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(2988, -3628.7800293, -3002.7341309, 21.6229992, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3799, -3611.3170166, -3004.3659668, 23.7189999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3799, -3606.5289917, -3012.4621583, 14.8710003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -3604.4589844, -3011.6540528, 14.6059999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3715.2550049, -3075.6269532, 26.5569992, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(3799, -3628.776001, -3047.2580567, 20.2420006, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3719.9960022, -3030.1401368, 22.4619999, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(8650, -3706.3829956, -3054.907959, 9.9870005, 90.0000000, 180.0000000, 180.0000000);
	CreateDynamicObject(8650, -3706.3820191, -3052.6921387, 9.9870005, 90.0000000, 179.9945068, 179.9945068);
	CreateDynamicObject(8650, -3706.4060059, -3050.4770508, 9.9870005, 90.0000000, 179.9835205, 179.9835205);
	CreateDynamicObject(8650, -3706.3930054, -3048.2609864, 9.9870005, 90.0000000, 179.9835205, 179.9835205);
	CreateDynamicObject(8650, -3706.3919983, -3046.0451661, 9.9870005, 90.0000000, 179.9725342, 179.9725342);
	CreateDynamicObject(8650, -3706.4030152, -3043.8291016, 9.9870005, 90.0000000, 179.9725342, 179.9725342);
	CreateDynamicObject(8650, -3706.4020081, -3041.6140137, 9.9870005, 90.0000000, 179.9615478, 179.9615478);
	CreateDynamicObject(8650, -3706.401001, -3039.3979493, 9.9870005, 90.0000000, 179.9615478, 179.9615478);
	CreateDynamicObject(8650, -3706.3880005, -3037.182129, 9.9870005, 90.0000000, 180.0494385, 179.8516846);
	CreateDynamicObject(8650, -3705.6470032, -3036.2990723, 9.9870005, 90.0000000, 179.9560547, 270.0778809);
	CreateDynamicObject(8650, -3705.3200073, -3036.2961426, 9.9870005, 90.0000000, 180.0494385, 269.9880066);
	CreateDynamicObject(8650, -3704.611023, -3034.7800294, 9.9870005, 90.0000000, 180.0439453, 179.8516846);
	CreateDynamicObject(8650, -3704.6020203, -3032.5620118, 9.9870005, 90.0000000, 180.0439453, 179.8516846);
	CreateDynamicObject(8650, -3704.6040039, -3030.3330079, 9.9870005, 90.0000000, 180.0439453, 179.8516846);
	CreateDynamicObject(8650, -3704.6080017, -3028.1159668, 9.9870005, 90.0000000, 179.9560547, 179.9395752);
	CreateDynamicObject(8650, -3704.6119995, -3025.9030762, 9.9870005, 90.0000000, 179.9505615, 179.9340820);
	CreateDynamicObject(8650, -3704.6090088, -3025.4799805, 9.9870005, 90.0000000, 179.9505615, 179.9440918);
	CreateDynamicObject(8650, -3705.303009, -3024.7661133, 9.9870005, 90.0000000, 180.0439453, 269.9835510);
	CreateDynamicObject(8650, -3707.5120239, -3024.7761231, 9.9870005, 90.0000000, 179.9560547, 270.0714111);
	CreateDynamicObject(8650, -3709.7180176, -3024.7819825, 9.9870005, 90.0000000, 179.9505615, 270.0714111);
	CreateDynamicObject(8650, -3711.9240112, -3024.8000489, 9.9870005, 90.0000000, 180.0494385, 269.9725647);
	CreateDynamicObject(8650, -3714.151001, -3024.782959, 9.9870005, 90.0000000, 179.9560547, 270.0604553);
	CreateDynamicObject(8650, -3716.3670044, -3024.7770997, 9.9870005, 90.0000000, 179.9505615, 270.0604248);
	CreateDynamicObject(8650, -3718.5880127, -3024.769043, 9.9870005, 90.0000000, 180.0494385, 269.9615478);
	CreateDynamicObject(8650, -3720.8120117, -3024.7670899, 9.9870005, 90.0000000, 179.9560547, 270.0494385);
	CreateDynamicObject(8650, -3723.0230103, -3024.7761231, 9.9870005, 90.0000000, 180.0494385, 269.9450684);
	CreateDynamicObject(8650, -3725.2369995, -3024.7700196, 9.9870005, 90.0000000, 180.0439453, 269.9395752);
	CreateDynamicObject(8650, -3727.480011, -3024.7890625, 9.9870005, 90.0000000, 179.9560547, 270.0274658);
	CreateDynamicObject(8650, -3727.9420166, -3024.7841797, 9.9870005, 90.0000000, 179.9505615, 270.0219727);
	CreateDynamicObject(8661, -3694.9000244, -3035.5114747, 14.625, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(8661, -3629.0369873, -2999.7021485, 28.691, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(8661, -3738.5710144, -3016.9831544, 29.5750008, 0.0000000, 0.0000000, 89.5000000);
	CreateDynamicObject(8661, -3694.8529968, -3045.7351075, 14.625, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(8661, -3709.9620056, -3051.3481446, 38.7140007, 270.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(8661, -3728.6520081, -3017.1760254, 39.4189987, 90.0000000, 0.0000000, 270.0000000);

	// Elorreli - The Olympia
	CreateDynamicObject(16684, -3300.7610321, -7004.6230469, 7.8530002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3255.3260345, -6997.9301758, 9.9720001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3255.3270111, -6997.9301758, 14.1400003, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3276.8420257, -6976.4560547, 9.8979998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3276.8420257, -6976.4560547, 14.0690002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3276.8140106, -7006.3552246, 9.9720001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3281.2839813, -7006.3630371, 14.165, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3298.4160003, -6981.8540039, 9.8979998, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3298.405014, -6981.8540039, 14.0839996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3308.3899994, -7006.4072266, 9.9720001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3324.3400116, -7006.4082031, 14, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14409, -3295.2820282, -6999.1611328, 7.8930001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3302.9391937, -6986.6201172, 9.0059996, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3298.5170135, -6981.8461914, 14.0839996, 0.0000000, 180.0000000, 179.9945068);
	CreateDynamicObject(4199, -3314.4429779, -6981.9641113, 9.0229998, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14409, -3310.5569916, -6999.7910156, 7.8969998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3314.5070038, -6981.9611817, 9.0129995, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18260, -3309.5970306, -6980.170166, 12.6999998, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3305.3710174, -6972.5532227, 13.283, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3305.371994, -6972.5532227, 9.9870005, 180.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3322.9750213, -6981.9570313, 13.2480001, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3322.9750213, -6981.9692383, 9.0749998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3322.9869842, -6981.9602051, 13.2480001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3305.371994, -6972.5532227, 17.3409996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3322.9869842, -6981.9602051, 17.2900009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3308.3899994, -7006.4082031, 18.1779995, 0.0000000, 180.0000000, 89.9945068);
	CreateDynamicObject(4199, -3322.9750213, -6981.9570313, 17.2779999, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14409, -3299.0740204, -7014.045166, 8.8870001, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(14409, -3303.147995, -7014.045166, 8.8870001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14409, -3307.2280121, -7014.045166, 8.8870001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3324.371994, -7017.9492188, 9.8629999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3324.3699798, -7017.9370117, 14.0340004, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3281.2570038, -7017.7512207, 9.868, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3281.2579803, -7017.7512207, 14.0500002, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(2991, -3264.0970306, -6998.4702149, 8.3999996, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3308.3815765, -7006.4296875, 18.2900009, 0.0000000, 0.0000000, 89.9945068);
	CreateDynamicObject(4199, -3281.246994, -7029.0830078, 9.8929996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(2991, -3264.0970306, -6998.4702149, 9.6999998, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3441, -3297.905014, -7001.3371582, 14.0609999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3441, -3307.7649994, -7001.3710938, 14.0609999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3305.2659759, -6990.5800781, 11.0690002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(16684, -3358.4420013, -7035.8791504, 7.927, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3302.2839813, -7045.9592285, 9.8929996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3281.248764, -7029.2070313, 9.8929996, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3324.3740082, -7017.9990234, 9.8629999, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3324.371994, -7017.9741211, 14.0340004, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3283.3500213, -7026.7060547, 9.8929996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3283.3500213, -7026.7060547, 14.0539999, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3281.2490082, -7029.2070313, 14.04, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3270.7109833, -7045.9602051, 9.8929996, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3255.3179779, -7029.4741211, 9.9720001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3255.3179779, -7029.4741211, 14.0600004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3276.8141937, -7006.4042969, 9.9720001, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(14409, -3265.2120208, -7014.0170899, 8.875, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14409, -3261.1650238, -7014.0170899, 8.875, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3270.7120208, -7045.9602051, 14.0270004, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3275.3249969, -7053.8920899, 9.8859997, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3275.3260345, -7053.8920899, 14.0430002, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3333.8290252, -7034.4301758, 9.8629999, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3333.8240204, -7022.8901367, 9.8380003, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(14414, -3316.0649872, -7038.1572266, 8.7550001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14414, -3316.0649872, -7034.1640625, 8.7550001, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(14414, -3316.0649872, -7030.1708984, 8.7550001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14414, -3316.0649872, -7026.1777344, 8.7550001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(14414, -3316.0649872, -7022.1845703, 8.7550001, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3333.8300018, -7034.4301758, 17.9710007, 0.0000000, 180.0000000, 269.9890137);
	CreateDynamicObject(3441, -3318.8749847, -7039.4521484, 13.927, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3333.8300018, -7027.0961914, 17.9570007, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3324.3710174, -7017.9370117, 17.8980007, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(3441, -3318.8220062, -7024.4602051, 13.927, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2991, -3264.0970306, -6994.4702149, 8.3999996, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3333.8400116, -7045.9191895, 9.8629999, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(2991, -3264.0970306, -6984.2700195, 8.3999996, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3333.8409881, -7045.9191895, 14.0380001, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3333.8420257, -7045.9191895, 17.9580002, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3302.280014, -7045.9697266, 13.9969997, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3365.345993, -7022.8430176, 14.0340004, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3339.9269867, -7006.4101563, 9.823, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3365.3569793, -7011.3530274, 14.0340004, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(2991, -3264.0970306, -6984.2700195, 9.5999994, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3334.4360199, -7016.1811524, 9.8380003, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3339.1390228, -6981.9680176, 9.823, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(4199, -3339.1999969, -6981.953125, 9.823, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3365.3610077, -7006.3920899, 14.0340004, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3334.1882171, -7006.4082031, 17.9430008, 0.0000000, 179.9945068, 89.9945068);
	CreateDynamicObject(3525, -3323.8749847, -6997.9260254, 9.4790001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3318.7690277, -6997.9331055, 9.4790001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3334.688034, -7015.9382324, 17.9330006, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(3525, -3340.3099823, -7017.0742188, 13.9560003, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3525, -3340.3119964, -7004.8830567, 13.9560003, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(18260, -3347.7830047, -7006.4450684, 13.4729996, 0.0000000, 0.0000000, 270.2445068);
	CreateDynamicObject(3441, -3340.970993, -7001.3132324, 13.9119997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3268.3970184, -7039.170166, 7.8000002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3298.1970062, -7019.5700684, 7.8000002, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3339.1890106, -6965.6311035, 13.96, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3327.8710174, -6981.9411621, 13.9919996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3327.8220062, -6981.939209, 13.9919996, 0.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(8650, -3344.5770111, -6982.491211, 11.6879997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18260, -3335.4869842, -6989.9821777, 13.4729996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3322.9869842, -6981.9602051, 21.4290009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3334.2750091, -6950.9960938, 17.2900009, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3334.2750091, -6950.9960938, 21.4449997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3350.6459808, -6965.6540527, 13.96, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3350.6459808, -6965.6530762, 18.0799999, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3350.6589813, -6965.6520996, 21.5160007, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(14414, -3330.7599945, -6978.3300781, 4.7309999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14414, -3332.6470184, -6978.3210449, 4.7309999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3322.9750213, -6981.9692383, 4.8769999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3339.1500091, -6981.9960938, 5.723, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3339.1500091, -6981.9960938, 1.522, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3322.9750213, -6981.9692383, 0.645, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3332.1500091, -6974.3210449, 0.645, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14414, -3341.9039764, -6947.866211, 12.8459997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14414, -3343.7460174, -6947.8730469, 12.8449993, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3334.2750091, -6950.9960938, 13.1079998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3339.9665374, -6946.9394531, 8.9259996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14414, -3347.7789764, -6940.6520996, 7.816, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3350.6520233, -6958.3762207, 13.974, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3350.6520233, -6958.3762207, 9.8219995, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3798, -3282.0970306, -7039.0700684, 7.8000002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3343.6840057, -6974.3110352, 0.645, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3354.5944671, -6953.7753906, 0.719, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14414, -3354.8240204, -6940.644043, 3.0480001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3351.8439789, -6958.4082031, 9.7939997, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(3796, -3342.1970062, -6983.4702149, 11.8999996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3341.8730316, -6948.3781738, 4.5359998, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3341.8340301, -6948.4440918, 6.8390002, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3341.4499359, -6932.8994141, 13.1169996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3341.4509124, -6932.8984375, 17.2779999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3341.4499969, -6932.8991699, 8.9350004, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3341.4510345, -6932.8981934, 4.7350001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3350.6520233, -6958.3762207, 18.1630001, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3360.6760101, -6938.717041, 17.2779999, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(864, -3290.996994, -6983.7700195, 7.9000001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3372.9509124, -6932.8828125, 4.7350001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3372.951889, -6932.8828125, 8.8950005, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3372.9528656, -6932.8828125, 13.0830002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(864, -3266.3970184, -6999.670166, 7.8000002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3373.0049896, -6932.8530274, 9.6169996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3362.2106781, -6958.4619141, 9.7919998, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(864, -3265.5970306, -6982.4702149, 7.9000001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3341.8749847, -6948.4401856, 4.5359998, 0.0000000, 180.0000000, 269.9945068);
	CreateDynamicObject(4199, -3341.8347015, -6948.4052734, 6.8390002, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3362.2109833, -6958.4621582, 13.9399996, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(3525, -3333.7969818, -6986.3701172, 14, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3362.4460296, -6955.0231934, 17.2779999, 270.0000000, 179.9998779, 90.0108643);
	CreateDynamicObject(4199, -3362.4280243, -6966.4011231, 17.2779999, 270.0000000, 180.0000000, 90.0055237);
	CreateDynamicObject(4199, -3339.9670257, -6946.939209, 4.803, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3339.9670257, -6946.9382324, 0.887, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3345.6669769, -6962.5991211, 0.732, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3323.5179901, -6951.012207, 4.803, 0.0000000, 0.0000000, 328.0000000);
	CreateDynamicObject(4199, -3323.4889984, -6951.0141602, 8.9209995, 0.0000000, 0.0000000, 327.9968262);
	CreateDynamicObject(4199, -3329.582016, -6951.0461426, 12.927, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(4199, -3350.9280243, -6958.4592285, 9.7919998, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(4199, -3349.240036, -6958.4020996, 9.7919998, 0.0000000, 179.9945068, 0.0000000);
	CreateDynamicObject(3525, -3332.1970062, -7039.8706055, 14, 0.0000000, 0.0000000, 178.0000000);
	CreateDynamicObject(3525, -3331.7969818, -7023.8691406, 14, 0.0000000, 0.0000000, 357.9949951);
	CreateDynamicObject(4199, -3351.2259979, -6972.0070801, 5.7199998, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(4199, -3351.2259979, -6972.0070801, 1.529, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3341.5019989, -6943.9750977, 21.4549999, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(1303, -3343.5590057, -6943.2070313, 11.4259996, 0.0000000, 18.5000000, 60.0000000);
	CreateDynamicObject(1303, -3359.9349823, -6940.2990723, 2.6110001, 0.0000000, 18.4954834, 59.9908447);
	CreateDynamicObject(3525, -3353.496994, -6938.8500977, 9.3999996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3350.115036, -6964.9479981, 9.8290005, 0.0000000, 179.9945068, 105.7500000);
	CreateDynamicObject(3525, -3358.5970306, -6943.2700195, 9.3999996, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(2975, -3346.6730194, -6955.1459961, 2.7950001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2975, -3346.6620331, -6956.4750977, 2.7709999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2973, -3358.9169769, -6964.8681641, 2.7950001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(2973, -3358.9235687, -6962.171875, 2.7820001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(942, -3351.4239959, -6964.9870606, 5.289, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3295.4219818, -6985.2832031, 8.0909996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3798, -3291.615036, -6996.6911621, 7.717, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3295.4235687, -6985.2832031, 18.1380005, 0.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(4199, -3276.8420257, -6976.4560547, 18.1639996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3298.405014, -6981.8540039, 18.2770004, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3295.457016, -6985.3491211, 18.1630001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3525, -3353.3970184, -6954.4401856, 5.3000002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -3280.4730072, -6990.3251953, 10.7370005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -3280.4919891, -6983.0180664, 10.7370005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -3291.772995, -6990.3972168, 10.7370005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3342.6970062, -6962.8691406, 5.4000001, 0.0000000, 0.0000000, 2.0000000);
	CreateDynamicObject(3798, -3291.4169769, -6983.5322266, 10.2040005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3289.2059784, -6983.5532227, 10.2040005, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3287.6790008, -6990.0461426, 9.3009996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3290.6299896, -6988.0490723, 9.3009996, 0.0000000, 0.0000000, 300.0000000);
	CreateDynamicObject(3798, -3284.2490082, -6987.8911133, 9.3009996, 0.0000000, 0.0000000, 347.9981689);
	CreateDynamicObject(4199, -3350.6459808, -6965.6530762, 9.8170004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3360.207016, -6940.3701172, 6.1999998, 0.0000000, 0.0000000, 86.0000000);
	CreateDynamicObject(4199, -3365.3660125, -7006.3671875, 14.0340004, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3361.3480072, -7016.8442383, 9.823, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(4199, -3361.8080291, -6981.9250488, 9.7729998, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(3524, -3340.5070038, -6949.9702149, 18.8999996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3361.7989959, -6981.9050293, 13.9280005, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3361.8000335, -6981.9040527, 18.0480003, 0.0000000, 0.0000000, 179.9945068);
	CreateDynamicObject(4199, -3392.8379974, -7016.9050293, 9.823, 0.0000000, 0.0000000, 269.9945068);
	CreateDynamicObject(3524, -3344.3970184, -6949.9702149, 18.8999996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3365.3840179, -7006.3850098, 17.9060001, 0.0000000, 0.0000000, 269.9890137);
	CreateDynamicObject(4199, -3419.4230194, -7009.5571289, 9.823, 0.0000000, 0.0000000, 231.9945068);
	CreateDynamicObject(4199, -3428.0709991, -6990.9790039, 9.823, 0.0000000, 0.0000000, 179.9927979);
	CreateDynamicObject(4199, -3398.8769989, -6990.6970215, 9.823, 0.0000000, 0.0000000, 1.2390137);
	CreateDynamicObject(4199, -3407.3552093, -6965.0947266, 9.823, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3388.629013, -6965.0681152, 9.823, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3424.8639984, -6971.3081055, 9.823, 0.0000000, 0.0000000, 153.9890137);
	CreateDynamicObject(4199, -3396.9199981, -7006.380127, 14.0340004, 0.0000000, 180.0000000, 269.9890137);
	CreateDynamicObject(4199, -3411.7429962, -6992.4760742, 14.0340004, 0.0000000, 179.9945068, 181.9890137);
	CreateDynamicObject(4199, -3417.5139923, -6993.8581543, 14.059, 0.0000000, 179.9945068, 197.9885254);
	CreateDynamicObject(4199, -3411.1330108, -6975.3229981, 14.0340004, 0.0000000, 179.9945068, 277.9846191);
	CreateDynamicObject(4199, -3381.3161468, -6974.2539063, 14.0340004, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3380.897995, -6983.4501953, 14.0340004, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3378.7740326, -7002.116211, 14.059, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3362.3309784, -6981.9050293, 9.7729998, 0.0000000, 180.0000000, 179.9945068);
	CreateDynamicObject(4199, -3398.7169952, -6990.6931152, 9.823, 0.0000000, 0.0000000, 180.7500000);
	CreateDynamicObject(4199, -3378.7950287, -6995.0810547, 17.8400002, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3378.7330169, -6994.6220703, 14.059, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(864, -3356.2969818, -7010.2700195, 7.8000002, 0.0000000, 0.0000000, 16.0000000);
	CreateDynamicObject(4199, -3373.0250091, -6987.644043, 9.7729998, 0.0000000, 179.9945068, 270.4945068);
	CreateDynamicObject(3525, -3291.1970062, -6990.8701172, 13, 0.0000000, 0.0000000, 44.0000000);
	CreateDynamicObject(4199, -3410.0250091, -6965.1831055, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3421.5180206, -6965.4182129, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(3525, -3280.8470306, -6990.9602051, 13, 0.0000000, 0.0000000, 323.9947510);
	CreateDynamicObject(4199, -3398.5659942, -6964.434082, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3390.431015, -6966.2731934, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(3525, -3280.496994, -6983.7702637, 13, 0.0000000, 0.0000000, 1.9892578);
	CreateDynamicObject(4199, -3378.5530243, -6966.1459961, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3372.0670013, -6966.1740723, 2.9230001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3373.0120086, -6987.6081543, 9.7729998, 0.0000000, 0.0000000, 270.4943848);
	CreateDynamicObject(4199, -3427.6460113, -6996.7260742, 14.059, 0.0000000, 179.9945068, 197.9846191);
	CreateDynamicObject(4199, -3365.365036, -7034.2851563, 14.0340004, 0.0000000, 179.9945068, 269.9890137);
	CreateDynamicObject(4199, -3361.1210174, -7048.394043, 14.0340004, 0.0000000, 179.9945068, 134.4889526);
	CreateDynamicObject(4199, -3322.9869842, -6981.9602051, 21.4290009, 0.0000000, 0.0000000, 180.0000000);
	CreateDynamicObject(4199, -3298.4520111, -6981.8681641, 18.2770004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3499, -3310.621994, -6990.3930664, 16.6289997, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(18260, -3406.4620208, -6992.4470215, 9.3920002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3403.2250213, -6987.7670899, 14.0340004, 0.0000000, 179.9945068, 181.9885254);
	CreateDynamicObject(3798, -3335.6050262, -7039.0480957, 11.9390001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3338.0179901, -7037.4621582, 11.9639997, 0.0000000, 0.0000000, 100.7500000);
	CreateDynamicObject(3798, -3337.5790252, -7025.8491211, 11.927, 0.0000000, 0.0000000, 34.7446594);
	CreateDynamicObject(3798, -3338.5690155, -7028.3762207, 11.165, 0.0000000, 0.0000000, 130.7442627);
	CreateDynamicObject(18260, -3333.2880096, -6969.6091309, 17.6480007, 0.0000000, 0.0000000, 182.0000000);
	CreateDynamicObject(2934, -3354.1719818, -6985.7631836, 9.4829998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(864, -3368.6970062, -6994.0700684, 7.9000001, 0.0000000, 0.0000000, 355.9960938);
	CreateDynamicObject(2934, -3346.6940155, -6985.6020508, 9.4919996, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3798, -3351.5530243, -6988.302002, 7.9889998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3358.6310272, -6970.1940918, 17.2779999, 270.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(14437, -3344.2969818, -6999.0700684, 9.8999977, 0.0000000, 0.0000000, 269.2500000);
	CreateDynamicObject(3798, -3390.9189911, -7004.7451172, 7.7550001, 0.0000000, 0.0000000, 356.7442932);
	CreateDynamicObject(3798, -3390.9689789, -7002.2651367, 7.7550001, 0.0000000, 0.0000000, 7.4925537);
	CreateDynamicObject(3798, -3373.2330169, -7009.9921875, 7.7550001, 0.0000000, 0.0000000, 359.2371826);
	CreateDynamicObject(3798, -3374.8860321, -7008.1801758, 7.0479999, 0.0000000, 0.0000000, 33.2364502);
	CreateDynamicObject(3796, -3365.9470062, -7000.097168, 7.763, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3800, -3382.8560028, -6994.5390625, 7.881, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -3381.7150116, -6994.3720703, 7.8829999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3800, -3382.438034, -6994.3361817, 8.9549999, 0.0000000, 0.0000000, 21.5000000);
	CreateDynamicObject(3800, -3365.3959808, -7010.3552246, 7.7470002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(822, -3338.1260223, -7001.8320313, 6.7470002, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(822, -3372.7040252, -7009.203125, 6.7470002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(822, -3390.9250335, -6998.9970703, 6.7470002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(856, -3356.8140106, -6991.8261719, 5.414, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(856, -3263.8780365, -7022.0310059, 5.5339999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(856, -3263.9349823, -7030.6672363, 5.5339999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(856, -3266.9860077, -7037.7822266, 5.5339999, 0.0000000, 4.0000000, 56.0000000);
	CreateDynamicObject(862, -3307.9910125, -7023.7150879, 7.8839998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -3297.1539764, -7039.3291016, 7.8410001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -3324.7319793, -6998.3051758, 7.8299999, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -3363.3229828, -7000.4980469, 7.7950001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -3390.0060272, -6999.8901367, 7.8049998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(862, -3372.2989959, -6994.6120606, 7.8800001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(866, -3380.2649994, -7009.5200195, 7.7670002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(866, -3348.9100189, -6982.7990723, 8.0780001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(866, -3310.5419769, -7039.1171875, 7.8410001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(818, -3420.6840057, -6999.861084, 5.961, 0.0000000, 0.0000000, 2.0000000);
	CreateDynamicObject(866, -3297.4620208, -7032.9560547, 7.8410001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3261.3530121, -7026.5371094, 10.1029997, 0.0000000, 0.0000000, 269.4885254);
	CreateDynamicObject(818, -3403.8670196, -7001.1030274, 5.9629998, 0.0000000, 0.0000000, 1.9995117);
	CreateDynamicObject(818, -3422.9480133, -6982.3681641, 6.0749998, 0.0000000, 0.0000000, 280.0000000);
	CreateDynamicObject(856, -3330.5749969, -6987.1311035, 5.823, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3295.458725, -6985.3486328, 22.2329998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3276.8420257, -6976.4560547, 22.2889996, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(3798, -3304.7950287, -7039.1672363, 7.8000002, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(3798, -3303.2549896, -7039.170166, 6.4180002, 0.0000000, 0.0000000, 270.0000000);
	CreateDynamicObject(810, -3404.496994, -7006.9702149, 7.8000002, 0.0000000, 0.0000000, 266.0000000);
	CreateDynamicObject(3798, -3346.2969818, -6990.3652344, 7.5320001, 0.0000000, 0.0000000, 359.2364502);
	CreateDynamicObject(3798, -3346.0900116, -6996.4350586, 7.4819999, 0.0000000, 0.0000000, 0.9864502);
	CreateDynamicObject(810, -3392.3970184, -7005.7700195, 7.8000002, 0.0000000, 0.0000000, 265.9954834);
	CreateDynamicObject(3798, -3346.2350311, -6993.7922363, 7.4819999, 0.0000000, 0.0000000, 0.9832764);
	CreateDynamicObject(702, -3405.496994, -6981.2700195, 8.6000004, 0.0000000, 0.0000000, 32.0000000);
	CreateDynamicObject(702, -3392.7969818, -6982.3701172, 8, 0.0000000, 0.0000000, 31.9976807);
	CreateDynamicObject(2669, -3371.5446624, -6979.7675781, 9.9849997, 0.0000000, 0.0000000, 271.9995117);
	CreateDynamicObject(702, -3389.0970306, -6982.2700195, 8, 0.0000000, 0.0000000, 31.9976807);
	CreateDynamicObject(18260, -3383.8929901, -6972.8850098, 8.1700001, 0.0000000, 0.0000000, 179.0000000);
	CreateDynamicObject(639, -3373.496994, -6980.9602051, 10, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3399.5910187, -6971.0541992, 10.0570002, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(3525, -3422.0990143, -6990.5310059, 9.5979996, 0.0000000, 0.0000000, 87.2500610);
	CreateDynamicObject(3525, -3396.905014, -7010.972168, 9.5979996, 0.0000000, 0.0000000, 179.4979248);
	CreateDynamicObject(3525, -3368.3329925, -6993.6320801, 10.0369997, 0.0000000, 0.0000000, 311.4946289);
	CreateDynamicObject(3525, -3355.9029999, -7004.5852051, 10.0369997, 0.0000000, 0.0000000, 269.7398682);
	CreateDynamicObject(639, -3345.0970306, -6994.5700684, 10.1999998, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3372.3760223, -6977.1511231, 6.5310001, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3362.3509979, -6960.6740723, 9.7919998, 0.0000000, 180.0000000, 180.0000000);
	CreateDynamicObject(14407, -3370.0389862, -6959.2141113, 5.4390001, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(14407, -3371.082016, -6959.2050781, 5.402, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3378.5289764, -6966.1010742, 6.5310001, 0.0000000, 0.0000000, 181.0000000);
	CreateDynamicObject(4199, -3388.7180023, -6956.2890625, 9.823, 0.0000000, 0.0000000, 91.0000000);
	CreateDynamicObject(4199, -3364.6069793, -6953.9790039, 0.681, 0.0000000, 0.0000000, 1.2359619);
	CreateDynamicObject(4199, -3386.069992, -6944.9541016, 4.835, 0.0000000, 0.0000000, 90.9997559);
	CreateDynamicObject(4199, -3386.069992, -6944.9541016, 8.9940004, 0.0000000, 0.0000000, 0.0000000);
	CreateDynamicObject(4199, -3381.3249969, -6962.7150879, 14.0340004, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3381.3260345, -6951.9870606, 14.0340004, 0.0000000, 179.9945068, 270.2307129);
	CreateDynamicObject(4199, -3381.3270111, -6944.8540039, 12.8789997, 0.0000000, 179.9945068, 270.9807129);
	CreateDynamicObject(3095, -3368.1320038, -6956.7160645, 4.7789998, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(3095, -3368.1190033, -6949.6730957, 4.7789998, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(3095, -3368.030014, -6947.1540527, 4.7789998, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(4199, -3362.4750213, -6936.1831055, 17.2779999, 270.0000000, 180.0000000, 270.0109558);
	CreateDynamicObject(4199, -3362.4440155, -6951.2790527, 17.2779999, 270.0000000, 180.0000000, 90.0109863);
	CreateDynamicObject(4199, -3362.4730072, -6936.1381836, 17.2779999, 270.0000000, 180.0000000, 90.0109863);
	CreateDynamicObject(4199, -3377.819992, -6933.2451172, 4.7350001, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(4199, -3365.3780365, -6951.2351074, 17.2779999, 270.0000000, 180.0000000, 90.0109863);
	CreateDynamicObject(3095, -3368.030014, -6947.1530762, 13.7419996, 0.0000000, 90.0000000, 0.0000000);
	CreateDynamicObject(4199, -3386.069992, -6944.9541016, 9.0150003, 0.0000000, 0.0000000, 90.9997559);
	CreateDynamicObject(4199, -3341.504013, -6943.8500977, 21.4169998, 0.0000000, 180.0000000, 90.0000000);
	CreateDynamicObject(4199, -3295.4280243, -6980.486084, 18.1380005, 0.0000000, 179.9945068, 90.0000000);
	CreateDynamicObject(4199, -3295.4369964, -6980.5041504, 22.2329998, 0.0000000, 0.0000000, 90.0000000);
	CreateDynamicObject(8661, -3307.5569916, -7040.1911621, 16.1100006, 270.0000000, 180.0000000, 0.0000000);
	CreateDynamicObject(4199, -3334.188034, -7006.4082031, 21.9890003, 0.0000000, 179.9945068, 89.9945068);
	CreateDynamicObject(8661, -3329.9800262, -6964.0461426, 23.5240002, 0.0000000, 0.0000000, 90.0000000);

	// Unknown - de_westwood
	CreateDynamicObject(650, -55.35900, 1520.01794, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(650, -13.33400, 1566.73499, 11.75000,   0.00000, 0.00000, 40.00000);
	CreateDynamicObject(650, -12.09180, 1505.49219, 11.75000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(650, -1.48828, 1534.78809, 11.75000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(650, 17.95117, 1554.56641, 11.75000,   0.00000, 0.00000, 259.99146);
	CreateDynamicObject(650, 53.47400, 1543.06006, 11.75000,   0.00000, 0.00000, 209.99146);
	CreateDynamicObject(650, 30.67700, 1509.70996, 11.75000,   0.00000, 0.00000, 129.98718);
	CreateDynamicObject(650, 6.21500, 1492.42200, 11.75000,   0.00000, 0.00000, 69.98474);
	CreateDynamicObject(701, -46.17400, 1516.15295, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, -38.05600, 1529.05896, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, -20.25100, 1512.58606, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, -0.05800, 1530.48999, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, 21.69600, 1516.73401, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, 39.17900, 1534.10205, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, 31.43600, 1556.54504, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(701, -16.87000, 1551.47900, 12.33100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, 25.15200, 1564.48206, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, 34.83000, 1480.81201, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, 27.17700, 1482.93201, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, -22.14600, 1482.58105, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, 32.09668, 1488.39551, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, -35.80500, 1548.32495, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(727, -9.98400, 1541.98999, 11.75600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(732, 56.75300, 1525.16797, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(732, 45.04688, 1542.87891, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(732, 59.41600, 1512.50305, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(732, -48.79300, 1501.49304, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(753, 8.87500, 1542.90906, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(753, 11.05300, 1544.13501, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(753, 15.15300, 1510.75195, 11.79900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(753, -62.29700, 1524.62402, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(754, -43.88700, 1541.89600, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(754, 4.51700, 1499.31799, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -6.78600, 1499.88098, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 17.42700, 1496.62305, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 41.77600, 1504.36401, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 36.24000, 1543.03894, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 17.17500, 1545.71997, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -13.64500, 1532.54004, 11.75600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -54.77100, 1528.54895, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -21.93000, 1560.00696, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 8.72900, 1568.49402, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 45.25900, 1557.49805, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 49.20300, 1518.88306, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -38.93600, 1510.76196, 11.75600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 8.92188, 1483.68457, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -26.86816, 1494.73926, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(866, 4.34000, 1553.55298, 11.75600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(866, -20.17773, 1538.16895, 11.75600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(866, 17.31600, 1529.04395, 11.75000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 0.00000, 0.00000, 0.00000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1451, 36.18500, 1565.15295, 12.58400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1451, 34.33500, 1565.02295, 12.58400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1452, -16.32800, 1564.53503, 12.80900,   0.00000, 0.00000, 30.00000);
	CreateDynamicObject(1454, -10.86900, 1550.92395, 12.55400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -9.20700, 1550.97302, 12.55400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -7.69600, 1551.01001, 12.55400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -6.04600, 1551.10706, 12.55400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -6.83600, 1551.01404, 13.90400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -8.66000, 1550.94495, 13.90400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, -10.10800, 1550.89001, 13.90400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1458, 3.96700, 1509.58301, 11.98100,   0.00000, 0.00000, 210.00000);
	CreateDynamicObject(1458, -22.19300, 1509.60095, 11.97500,   0.00000, 0.00000, 209.99817);
	CreateDynamicObject(1458, -42.20300, 1538.08704, 11.95000,   0.00000, 0.00000, 159.99817);
	CreateDynamicObject(1458, 49.31700, 1552.13403, 11.75000,   0.00000, 0.00000, 209.99817);
	CreateDynamicObject(1463, 36.37400, 1530.96802, 11.82200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1463, -12.70900, 1557.87500, 11.82200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1463, -13.41600, 1494.21497, 11.87200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1486, -4.77200, 1509.90100, 15.28100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1486, -4.49800, 1509.87000, 15.28100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1486, -4.29600, 1509.64600, 15.28100,   0.00000, 0.00000, 50.00000);
	CreateDynamicObject(1486, -5.06600, 1509.73303, 15.28100,   0.00000, 0.00000, 260.00000);
	CreateDynamicObject(1486, -5.27500, 1509.88196, 15.28100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1486, -4.70200, 1509.48096, 15.18100,   90.00000, 0.00000, 90.00000);
	CreateDynamicObject(1492, -5.16000, 1499.26001, 11.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1735, -3.23900, 1508.54004, 14.33400,   0.00000, 0.00000, 310.00000);
	CreateDynamicObject(1735, -3.13000, 1506.47400, 14.33400,   0.00000, 0.00000, 239.99573);
	CreateDynamicObject(2096, -18.81700, 1509.42395, 11.75000,   0.00000, 0.00000, 110.00000);
	CreateDynamicObject(2096, -26.38800, 1533.19702, 12.25600,   0.00000, 0.00000, 319.99512);
	CreateDynamicObject(2096, 24.68100, 1544.08203, 12.25000,   0.00000, 0.00000, 319.99329);
	CreateDynamicObject(2096, 34.39400, 1526.51099, 11.75600,   0.00000, 0.00000, 229.99329);
	CreateDynamicObject(2096, 43.70800, 1560.02295, 12.15600,   0.00000, 0.00000, 309.99329);
	CreateDynamicObject(2115, -5.29300, 1509.55701, 14.33400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2939, 2808.39502, 464.98489, 100.40000,   156.00000, 0.00000, 0.00000);
	CreateDynamicObject(3053, 2810.27710, 462.29999, 100.21999,   180.00000, 0.00000, 240.00000);
	CreateDynamicObject(3246, -6.27734, 1532.03320, 11.75000,   0.00000, 0.00000, 3.99353);
	CreateDynamicObject(3249, 21.07900, 1504.51501, 11.75000,   0.00000, 0.00000, 191.99451);
	CreateDynamicObject(3250, 33.85000, 1514.65906, 11.75000,   0.00000, 0.00000, 223.99451);
	CreateDynamicObject(3250, -27.35840, 1538.19043, 11.75600,   0.00000, 0.00000, 341.99097);
	CreateDynamicObject(3250, 23.41200, 1549.16003, 11.75000,   0.00000, 0.00000, 341.98926);
	CreateDynamicObject(3250, -6.52600, 1568.34802, 11.75000,   0.00000, 0.00000, 351.99097);
	CreateDynamicObject(3250, 47.96100, 1562.80298, 11.65600,   0.00000, 0.00000, 271.99097);
	CreateDynamicObject(3252, -62.44700, 1526.09802, 11.75000,   0.00000, 0.00000, 355.98999);
	CreateDynamicObject(3252, -19.24400, 1543.30798, 11.75600,   0.00000, 0.00000, 355.98999);
	CreateDynamicObject(3252, 4.81600, 1499.60400, 11.75000,   0.00000, 0.00000, 125.98999);
	CreateDynamicObject(3363, -27.96700, 1489.84595, 11.60000,   0.00000, 0.00000, 32.52502);
	CreateDynamicObject(3363, 55.75100, 1535.41296, 11.70600,   0.00000, 0.00000, 102.52438);
	CreateDynamicObject(3363, 11.69100, 1487.47998, 11.55000,   0.00000, 0.00000, 32.52502);
	CreateDynamicObject(3363, 40.87600, 1498.18994, 11.70000,   0.00000, 0.00000, 312.52258);
	CreateDynamicObject(3363, 13.69500, 1565.85596, 11.50000,   1.00000, 0.00000, 102.51892);
	CreateDynamicObject(3363, -27.97900, 1556.16699, 11.45000,   355.98450, 0.00000, 222.52258);
	CreateDynamicObject(3425, -17.94000, 1486.22205, 23.19300,   0.00000, 0.00000, 354.99390);
	CreateDynamicObject(3515, 17.88900, 1528.98596, 12.54500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3524, 15.66800, 1512.36694, 14.64100,   0.00000, 0.00000, 210.00000);
	CreateDynamicObject(3524, 22.90800, 1513.90698, 14.64100,   0.00000, 0.00000, 159.99817);
	CreateDynamicObject(6865, 9.48200, 1544.56494, 23.00700,   0.00000, 0.00000, 72.00000);
	CreateDynamicObject(9833, 17.32700, 1528.86902, 16.65200,   0.00000, 0.00000, 0.25000);
	CreateDynamicObject(11503, 8.25195, 1506.73047, 11.75000,   0.00000, 0.00000, 177.98950);
	CreateDynamicObject(11503, -18.08100, 1505.63306, 11.75000,   0.00000, 0.00000, 175.99451);
	CreateDynamicObject(11503, -16.60547, 1534.77832, 11.75600,   0.00000, 0.00000, 357.98950);
	CreateDynamicObject(11503, 35.25781, 1538.60645, 11.75000,   0.00000, 0.00000, 297.98218);
	CreateDynamicObject(11503, -20.89000, 1563.50000, 11.75000,   0.00000, 0.00000, 45.98328);
	CreateDynamicObject(11503, 38.27300, 1526.40295, 11.75600,   0.00000, 0.00000, 257.98694);
	CreateDynamicObject(11503, 0.19141, 1539.78125, 11.75600,   0.00000, 0.00000, 45.98328);
	CreateDynamicObject(11513, -11.57500, 1471.26001, 18.25000,   0.00000, 0.00000, 60.00000);
	CreateDynamicObject(11513, -65.40900, 1549.09802, 16.00000,   0.00000, 0.00000, 305.99707);
	CreateDynamicObject(11513, -29.92300, 1568.71301, 16.00000,   0.00000, 0.00000, 283.99670);
	CreateDynamicObject(11513, 45.24512, 1574.08984, 16.00000,   0.00000, 0.00000, 227.98828);
	CreateDynamicObject(11513, 69.67090, 1528.13281, 16.00000,   0.00000, 0.00000, 157.98340);
	CreateDynamicObject(11513, 52.71800, 1485.40405, 16.00000,   0.00000, 0.00000, 109.98340);
	CreateDynamicObject(11513, -55.94300, 1496.07703, 18.25000,   0.00000, 0.00000, 11.99634);
	CreateDynamicObject(13367, 50.40100, 1515.14404, 17.31900,   0.00000, 0.00000, 350.00000);
	CreateDynamicObject(16108, -41.28500, 1522.10803, 16.16500,   0.00000, 0.00000, 176.00000);
	CreateDynamicObject(16135, 8.30371, 1527.16504, 12.15100,   0.00000, 0.00000, 353.99597);
	CreateDynamicObject(16326, -2.37695, 1502.76172, 11.72500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16404, 50.24600, 1552.28406, 13.65000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16404, -2.74900, 1486.64795, 13.65000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16404, -8.46094, 1551.63672, 13.65600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16406, 8.01700, 1547.27002, 16.97000,   0.00000, 0.00000, 118.00000);
	CreateDynamicObject(18691, 2032.28796, 1352.27295, 17.09500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18691, 2032.39294, 1334.46497, 17.09500,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18692, -12.65000, 1557.80603, 9.48100,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18692, -13.41400, 1494.04199, 9.40600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18692, 36.37000, 1530.79004, 10.40600,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18694, 0.00000, 0.00000, 0.00000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18761, 2032.38794, 1343.34399, 14.57000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(18857, 77.71900, -903.32098, 451.21399,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19055, 2033.56494, 1334.69800, 10.47700,   0.00000, 0.00000, 60.00000);
	CreateDynamicObject(19055, 2031.39648, 1351.89844, 10.47700,   0.00000, 0.00000, 59.99634);
	CreateDynamicObject(19056, 2032.41101, 1333.29504, 10.47700,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19057, 2033.36804, 1351.51904, 10.47700,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19057, 2031.57898, 1334.93201, 10.47700,   0.00000, 0.00000, 40.00000);
	CreateDynamicObject(19058, 2032.53796, 1353.29297, 10.47700,   0.00000, 0.00000, 335.99997);
	CreateDynamicObject(19086, 2033.12195, 1351.38599, 11.27400,   0.00000, 0.00000, 30.00000);
	CreateDynamicObject(19123, 2020.87695, 1339.98401, 10.27800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19123, 2020.85938, 1345.99902, 10.25300,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19123, 2027.09302, 1346.03601, 10.25300,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19123, 2027.14453, 1340.05371, 10.27800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19128, 2023.87598, 1342.93201, 9.78300,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19130, 2028.70801, 1345.16101, 9.76900,   0.00000, 90.00000, 190.00000);
	CreateDynamicObject(19130, 2030.78003, 1345.94604, 9.76900,   0.00000, 90.00000, 211.99756);
	CreateDynamicObject(19130, 2030.72205, 1340.35706, 9.76900,   0.00000, 90.00000, 148.00781);
	CreateDynamicObject(19130, 2028.77405, 1341.20105, 9.76900,   0.00000, 90.00000, 170.00244);
	CreateDynamicObject(19130, 2028.74597, 1343.24597, 9.76900,   0.00000, 90.00000, 180.00000);
	CreateDynamicObject(19130, 2031.46997, 1343.25500, 9.76900,   0.00000, 90.00000, 179.99451);
	CreateDynamicObject(19300, 0.00000, 0.00000, 0.00000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19425, 2027.22998, 1341.47498, 9.82000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(19425, 2027.23096, 1344.60706, 9.82000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(19425, 2025.45605, 1346.06604, 9.82000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(19425, 2022.31396, 1346.06897, 9.82000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(19425, 2020.81897, 1344.53894, 9.82000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(19425, 2020.82800, 1341.38794, 9.82000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(19425, 2022.38098, 1339.98901, 9.81300,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(19425, 2025.54395, 1339.98303, 9.81300,   0.00000, 0.00000, 179.99451);

	// Famous - The Abandoned Paintball Arena
	CreateDynamicObject(12814, 3113.30005, -1450.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3143.10010, -1450.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3172.80005, -1450.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3172.80005, -1499.90002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3143.10010, -1499.90002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3113.39990, -1499.90002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3113.39990, -1549.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3143.30005, -1549.69995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3172.69995, -1549.69995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3172.60010, -1599.40002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3142.89990, -1599.40002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3113.39990, -1599.59998, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3113.30005, -1400.40002, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3143.19995, -1400.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3173.10010, -1400.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10828, 3186.80005, -1392.80005, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.80005, -1426.50000, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.80005, -1461.09998, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.60010, -1496.19995, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.60010, -1531.00000, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.69995, -1566.30005, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.69995, -1601.19995, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3186.69995, -1606.69995, 22.40000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10828, 3170.19995, -1623.40002, 22.40000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(10828, 3135.10010, -1623.30005, 22.40000,   0.00000, 0.00000, 179.99451);
	CreateDynamicObject(10828, 3116.19995, -1623.50000, 22.40000,   0.00000, 0.00000, 179.99451);
	CreateDynamicObject(10828, 3099.39990, -1607.19995, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.50000, -1572.40002, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.60010, -1537.50000, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.69995, -1502.40002, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.50000, -1467.40002, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.60010, -1432.19995, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.69995, -1397.09998, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.60010, -1392.80005, 22.40000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3115.89990, -1376.59998, 22.40000,   0.00000, 0.00000, 359.99451);
	CreateDynamicObject(10828, 3150.19995, -1376.40002, 22.40000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(10828, 3171.00000, -1376.40002, 22.40000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(3374, 3134.39990, -1486.09998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1490.09998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1494.09998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1498.09998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1501.80005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1505.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1509.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1513.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.39990, -1517.59998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3134.50000, -1482.30005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.00000, -1513.59998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.00000, -1513.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.00000, -1513.40002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3150.00000, -1513.30005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3150.10010, -1517.09998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.89990, -1509.30005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.69995, -1505.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.80005, -1501.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.89990, -1497.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.69995, -1493.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.80005, -1489.50000, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.80005, -1485.69995, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3149.69995, -1482.90002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.19995, -1485.90002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3141.50000, -1485.90002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3145.00000, -1485.90002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.00000, -1485.80005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3153.19995, -1485.69995, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3153.19995, -1513.30005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3130.50000, -1513.59998, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3130.80005, -1486.30005, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.39990, -1488.50000, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.39990, -1492.40002, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.50000, -1495.80005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.60010, -1499.80005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.69995, -1503.40002, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.39990, -1507.30005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3136.60010, -1511.09998, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.60010, -1511.09998, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1511.09998, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.39990, -1511.09998, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.39990, -1507.30005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.19995, -1503.30005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.19995, -1499.30005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3147.89990, -1495.50000, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3147.89990, -1491.50000, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3148.00000, -1488.30005, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.19995, -1488.19995, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.39990, -1488.40002, 14.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1509.09998, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1505.09998, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1501.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1497.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1493.50000, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3146.50000, -1490.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.50000, -1490.40002, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.50000, -1490.50000, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.50000, -1494.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.50000, -1498.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.50000, -1502.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.69995, -1506.30005, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3138.60010, -1509.19995, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.69995, -1509.09998, 17.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.30005, -1492.50000, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.39990, -1496.19995, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.50000, -1500.19995, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.30005, -1504.00000, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3140.39990, -1507.19995, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1507.09998, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1503.09998, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1499.09998, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1495.09998, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3144.39990, -1492.59998, 20.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.50000, -1505.09998, 23.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.60010, -1501.09998, 23.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.39990, -1497.09998, 23.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.39990, -1494.80005, 23.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.60010, -1503.09998, 26.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.50000, -1497.00000, 26.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.39990, -1499.69995, 26.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3374, 3142.60010, -1500.09998, 29.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10828, 3099.80005, -1505.80005, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3100.10010, -1470.40002, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3100.00000, -1436.69995, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.89990, -1402.50000, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.69995, -1393.09998, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3099.89990, -1540.09998, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3100.00000, -1574.69995, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3100.30005, -1607.19995, 37.30000,   0.00000, 0.00000, 89.99451);
	CreateDynamicObject(10828, 3117.89990, -1623.69995, 37.30000,   0.00000, 0.00000, 359.99451);
	CreateDynamicObject(10828, 3153.00000, -1623.69995, 37.30000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(10828, 3170.19995, -1623.59998, 37.30000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(10828, 3186.89990, -1607.00000, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3187.00000, -1572.50000, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3187.10010, -1538.40002, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3186.89990, -1503.90002, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3186.69995, -1469.69995, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3186.80005, -1435.19995, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3186.60010, -1401.00000, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3186.60010, -1392.80005, 37.30000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(10828, 3170.50000, -1376.40002, 37.30000,   0.00000, 0.00000, 179.98901);
	CreateDynamicObject(10828, 3135.30005, -1376.59998, 37.30000,   0.00000, 0.00000, 179.98352);
	CreateDynamicObject(10828, 3116.00000, -1376.59998, 37.30000,   0.00000, 0.00000, 179.98352);
	CreateDynamicObject(1508, 3142.00000, -1377.50000, 11.80000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(1508, 3143.30005, -1622.40002, 11.80000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(10397, 3147.00000, -1516.09998, 14.00000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3157.39990, -1525.40002, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3128.19995, -1525.30005, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3128.19995, -1475.19995, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3158.00000, -1474.59998, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3158.10010, -1425.40002, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3128.39990, -1425.40002, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3157.69995, -1574.40002, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3128.39990, -1574.09998, 10.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(13637, 3120.89990, -1540.19995, 12.20000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(13637, 3166.00000, -1538.50000, 12.20000,   0.00000, 0.00000, 96.00000);
	CreateDynamicObject(13637, 3166.10010, -1464.40002, 12.20000,   0.00000, 0.00000, 165.99854);
	CreateDynamicObject(13637, 3120.39990, -1464.30005, 12.20000,   0.00000, 0.00000, 277.99792);
	CreateDynamicObject(3261, 3144.19995, -1428.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3144.30005, -1431.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3144.19995, -1434.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3144.10010, -1437.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3144.00000, -1440.30005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3143.00000, -1443.69995, 10.10000,   0.00000, 0.00000, 340.00000);
	CreateDynamicObject(3261, 3140.80005, -1446.69995, 10.10000,   0.00000, 0.00000, 321.99939);
	CreateDynamicObject(3261, 3137.89990, -1448.69995, 10.10000,   0.00000, 0.00000, 305.99829);
	CreateDynamicObject(3261, 3134.39990, -1449.80005, 10.10000,   0.00000, 0.00000, 283.99670);
	CreateDynamicObject(3261, 3131.10010, -1450.30005, 10.10000,   0.00000, 0.00000, 277.99658);
	CreateDynamicObject(3261, 3127.80005, -1450.40002, 10.10000,   0.00000, 0.00000, 269.99255);
	CreateDynamicObject(3261, 3136.39990, -1605.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3136.30005, -1602.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3136.19995, -1599.00000, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3136.10010, -1595.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3136.19995, -1592.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3136.10010, -1589.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3261, 3135.89990, -1586.30005, 10.10000,   0.00000, 0.00000, 348.00000);
	CreateDynamicObject(3261, 3136.89990, -1583.00000, 10.10000,   0.00000, 0.00000, 329.99744);
	CreateDynamicObject(3261, 3138.89990, -1580.00000, 10.10000,   0.00000, 0.00000, 311.99634);
	CreateDynamicObject(3261, 3141.89990, -1577.50000, 10.10000,   0.00000, 0.00000, 287.99524);
	CreateDynamicObject(3261, 3145.60010, -1576.50000, 10.10000,   0.00000, 0.00000, 265.99011);
	CreateDynamicObject(3261, 3148.60010, -1576.69995, 10.10000,   0.00000, 0.00000, 265.98999);
	CreateDynamicObject(3261, 3151.60010, -1576.90002, 10.10000,   0.00000, 0.00000, 265.98999);
	CreateDynamicObject(12911, 3111.10010, -1591.90002, 10.10000,   0.00000, 0.00000, 10.00000);
	CreateDynamicObject(3279, 3170.30005, -1577.00000, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3279, 3173.80005, -1422.80005, 10.10000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(3268, 3171.80005, -1394.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3268, 3172.30005, -1602.50000, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3763, 3112.60010, -1422.69995, 43.40000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17063, 3113.00000, -1386.09998, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17060, 3135.69995, -1411.80005, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17060, 3121.89990, -1415.90002, 10.10000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(17060, 3120.00000, -1430.19995, 10.10000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(17060, 3108.50000, -1442.90002, 10.10000,   0.00000, 0.00000, 267.99451);
	CreateDynamicObject(17060, 3159.50000, -1432.19995, 10.10000,   0.00000, 0.00000, 268.00000);
	CreateDynamicObject(17060, 3168.00000, -1440.00000, 10.10000,   0.00000, 0.00000, 177.99500);
	CreateDynamicObject(17060, 3157.89990, -1455.19995, 10.10000,   0.00000, 0.00000, 89.98950);
	CreateDynamicObject(17060, 3144.19995, -1464.09998, 10.10000,   0.00000, 0.00000, 1.98901);
	CreateDynamicObject(17060, 3116.39941, -1481.00000, 10.10000,   0.00000, 0.00000, 359.98352);
	CreateDynamicObject(17060, 3112.60010, -1489.50000, 10.10000,   0.00000, 0.00000, 269.98352);
	CreateDynamicObject(17060, 3107.19995, -1505.19995, 10.10000,   0.00000, 0.00000, 269.97803);
	CreateDynamicObject(17060, 3117.00000, -1512.19995, 10.10000,   0.00000, 0.00000, 179.97803);
	CreateDynamicObject(17060, 3136.39990, -1528.50000, 10.10000,   0.00000, 0.00000, 179.97253);
	CreateDynamicObject(17060, 3156.19995, -1536.40002, 10.10000,   0.00000, 0.00000, 89.97253);
	CreateDynamicObject(17060, 3152.19995, -1550.09998, 10.10000,   0.00000, 0.00000, 89.96704);
	CreateDynamicObject(17060, 3135.60010, -1552.50000, 10.10000,   0.00000, 0.00000, 357.96704);
	CreateDynamicObject(17060, 3121.69995, -1556.69995, 10.10000,   0.00000, 0.00000, 267.96204);
	CreateDynamicObject(1457, 3181.00000, -1454.80005, 11.80000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8885, 3180.50000, -1480.09998, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8885, 3180.60010, -1487.69995, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8885, 3180.69995, -1495.09998, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7040, 3176.10010, -1506.30005, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7040, 3175.79980, -1520.19922, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7040, 3164.59961, -1495.50000, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3796, 3166.19995, -1591.19995, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3630, 3171.89990, -1614.90002, 11.60000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3630, 3180.00000, -1599.40002, 11.60000,   0.00000, 0.00000, 266.00000);
	CreateDynamicObject(2669, 3105.60010, -1499.40002, 11.40000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2359, 3167.10010, -1406.90002, 10.30000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1348, 3110.60010, -1382.30005, 10.80000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18260, 3170.80005, -1402.69995, 11.70000,   0.00000, 0.00000, 354.00000);
	CreateDynamicObject(3066, 3175.89990, -1392.50000, 11.20000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3363, 3177.80005, -1565.09998, 10.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7040, 3111.39990, -1570.40002, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7040, 3111.50000, -1558.40002, 13.50000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3881, 3113.60010, -1616.30005, 12.00000,   0.00000, 0.00000, 274.00000);
	CreateDynamicObject(7040, 3107.39990, -1410.90002, 13.50000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(7040, 3107.19995, -1400.50000, 13.50000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(17060, 3100.19995, -1463.19995, 10.10000,   0.00000, 0.00000, 269.98352);
	CreateDynamicObject(3819, 3181.10010, -1435.59998, 11.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3819, 3181.69995, -1445.09998, 11.10000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8613, 3147.80005, -1421.40002, 14.50000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(8613, 3137.89990, -1427.90002, 14.50000,   0.00000, 0.00000, 359.99451);
	CreateDynamicObject(1454, 3138.89990, -1387.90002, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3134.19995, -1393.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3140.80005, -1398.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3147.69995, -1393.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3156.10010, -1402.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3147.80005, -1407.69995, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3160.00000, -1392.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3125.00000, -1402.09998, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3120.39990, -1391.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3128.19995, -1384.90002, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3151.19995, -1383.09998, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3155.10010, -1413.59998, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3133.89990, -1570.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3139.60010, -1564.40002, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3145.89990, -1569.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3153.19995, -1564.00000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3159.30005, -1570.09998, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3168.30005, -1564.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3119.00000, -1581.00000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3124.10010, -1585.00000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3129.30005, -1590.00000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3120.30005, -1593.00000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3128.69995, -1598.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3122.00000, -1602.09998, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3128.30005, -1607.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3128.29980, -1607.50000, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3143.19995, -1592.30005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3151.50000, -1587.19995, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3157.80005, -1593.69995, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3149.69995, -1598.80005, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3156.19995, -1606.90002, 10.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1454, 3144.39990, -1605.40002, 10.90000,   0.00000, 0.00000, 0.00000);

	// LeGGGeNNdA - SMALL TDM MAP
	CreateDynamicObject(18259, 2425.10107, -644.38922, 124.77437,   357.42169, 10.31320, 0.00000);
	CreateDynamicObject(18228, 2400.19727, -682.52209, 121.59275,   0.00000, 0.00000, 339.37350);
	CreateDynamicObject(18228, 2431.04492, -669.08911, 119.75653,   0.00000, 0.00000, 358.49435);
	CreateDynamicObject(18228, 2443.50513, -643.24670, 116.64348,   0.00000, 0.00000, 55.43596);
	CreateDynamicObject(18228, 2418.62646, -621.54706, 119.37595,   0.00000, 0.00000, 127.29868);
	CreateDynamicObject(18228, 2428.14111, -628.00360, 117.20713,   0.00000, 0.00000, 121.35394);
	CreateDynamicObject(18228, 2393.54907, -619.82037, 119.29471,   0.00000, 0.00000, 141.15813);
	CreateDynamicObject(18228, 2359.41162, -621.47107, 120.89922,   0.00000, 0.00000, 151.57753);
	CreateDynamicObject(18228, 2337.33887, -633.64612, 124.64491,   0.00000, 0.00000, 193.24933);
	CreateDynamicObject(18228, 2331.75977, -653.77838, 125.40748,   0.00000, 0.00000, 238.06430);
	CreateDynamicObject(18228, 2361.14551, -686.10919, 127.67089,   347.10840, 0.00000, 310.25659);
	CreateDynamicObject(18228, 2343.52832, -677.74823, 124.29242,   347.10840, 0.00000, 285.23663);
	CreateDynamicObject(744, 2392.18628, -637.09332, 123.55434,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(744, 2391.18140, -665.29504, 125.74555,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(744, 2372.61963, -663.55530, 126.58006,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2367.96313, -638.75348, 126.31836,   0.00000, 0.00000, -31.32000);
	CreateDynamicObject(696, 2356.77539, -670.54584, 126.64001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2380.69824, -662.10223, 126.33701,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2410.61865, -666.18408, 125.48333,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2409.65063, -636.44757, 124.74747,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2393.17285, -649.56433, 124.74747,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2432.68677, -651.96790, 124.34144,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2349.66577, -641.23816, 126.31836,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(696, 2367.45386, -658.51123, 126.64001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(647, 2357.47168, -670.48486, 130.63683,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(647, 2363.55103, -661.52032, 127.17470,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(762, 2372.48486, -622.38281, 137.32590,   0.00000, 0.00000, -76.43998);
	CreateDynamicObject(762, 2347.79126, -626.96344, 138.63260,   0.00000, 0.00000, -76.43998);
	CreateDynamicObject(762, 2385.98926, -620.38666, 139.00020,   0.00000, 0.00000, 241.60193);
	CreateDynamicObject(762, 2403.90503, -622.79102, 137.32512,   0.00000, 0.00000, 215.68192);
	CreateDynamicObject(762, 2412.57666, -624.01746, 137.32512,   0.00000, 0.00000, 215.68192);
	CreateDynamicObject(762, 2426.98511, -626.97162, 136.91908,   0.00000, 0.00000, 183.88190);
	CreateDynamicObject(762, 2435.48462, -631.71313, 136.91908,   0.00000, 0.00000, 183.88190);
	CreateDynamicObject(762, 2440.46558, -639.76843, 136.91908,   0.00000, 0.00000, 183.88190);
	CreateDynamicObject(762, 2441.93848, -653.81262, 135.40938,   0.00000, 0.00000, 183.88190);
	CreateDynamicObject(762, 2436.03442, -664.40143, 135.40938,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2420.32715, -675.35608, 135.40938,   0.00000, 0.00000, 149.02191);
	CreateDynamicObject(762, 2407.75171, -680.28101, 136.13074,   0.00000, 0.00000, 149.02191);
	CreateDynamicObject(762, 2384.92236, -685.94318, 137.17166,   0.00000, 0.00000, 149.02191);
	CreateDynamicObject(762, 2369.39185, -687.33752, 139.49561,   0.00000, 0.00000, 149.02191);
	CreateDynamicObject(762, 2350.87720, -679.36365, 142.68619,   0.00000, 0.00000, 220.24191);
	CreateDynamicObject(762, 2336.56519, -670.70361, 142.68619,   0.00000, 0.00000, 220.24191);
	CreateDynamicObject(762, 2332.71191, -661.71515, 144.21100,   0.00000, 0.00000, 220.24191);
	CreateDynamicObject(762, 2331.87549, -641.46667, 142.00908,   0.00000, 0.00000, 179.44191);
	CreateDynamicObject(759, 2367.01270, -640.60431, 126.69006,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(759, 2374.22803, -644.59790, 126.28402,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(759, 2378.58691, -656.06451, 126.69006,   0.00000, 0.00000, 55.20000);
	CreateDynamicObject(759, 2389.09424, -661.49170, 126.58501,   0.00000, 0.00000, 55.20000);
	CreateDynamicObject(762, 2410.59570, -666.59406, 127.81405,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2393.25708, -668.41748, 127.81405,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2369.54956, -671.52380, 129.08231,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2379.09937, -636.43231, 126.20120,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2410.52148, -637.58423, 126.20120,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(762, 2393.66992, -645.62726, 126.20120,   0.00000, 0.00000, 164.80191);
	CreateDynamicObject(744, 2377.54053, -641.06689, 124.22988,   0.00000, 0.00000, -10.92000);
	CreateDynamicObject(744, 2361.00586, -641.85406, 126.88437,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1558, 2359.31860, -652.54413, 127.60378,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1558, 2359.32129, -651.36945, 127.60378,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1558, 2359.31567, -650.20630, 127.60378,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(745, 2370.77490, -649.55798, 126.19540,   0.00000, 0.00000, -99.78000);
	CreateDynamicObject(745, 2407.88086, -651.44263, 125.90962,   0.00000, 0.00000, 116.26184);
	CreateDynamicObject(745, 2382.56592, -653.64453, 125.40359,   0.00000, 0.00000, 116.26184);

	// TheYoungCapone - cs_compound
	CreateDynamicObject(16501, 2026.77002, 328.31000, 250.00999,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 2033.68005, 328.31000, 250.00999,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 2037.06006, 324.89999, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2037.15002, 317.82001, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2037.23999, 310.79001, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2037.32996, 303.72000, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2037.43994, 296.91000, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2034.12000, 293.45001, 250.00999,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 2023.39001, 293.41000, 250.00999,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 2023.05005, 328.29999, 250.00999,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 2019.62000, 324.76999, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2019.70996, 312.19000, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2019.78003, 305.26001, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2019.84998, 296.92001, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2019.84998, 299.69000, 250.00999,   0.00000, 0.00000, 0.75000);
	CreateDynamicObject(16501, 2021.98999, 296.89999, 252.19000,   0.00000, 90.00000, 0.75000);
	CreateDynamicObject(16501, 2026.33997, 296.94000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2030.73999, 297.00000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2035.12000, 297.12000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2035.00000, 304.19000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2030.65002, 304.04001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2026.25000, 303.98999, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2021.89001, 303.98999, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2021.77002, 311.10001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2026.17004, 311.09000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2030.52002, 311.13000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2034.90002, 311.17001, 252.19000,   0.00000, 90.00000, 0.75000);
	CreateDynamicObject(16501, 2034.76001, 318.26001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2030.38000, 318.20001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2026.01001, 318.13000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2021.63000, 318.07001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2021.69995, 324.78000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2026.09998, 324.91000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2030.46997, 325.01999, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 2034.69995, 325.09000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(3761, 2033.89001, 317.26001, 249.82001,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(3761, 2033.87000, 306.48999, 249.81000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(18451, 2015.82996, 313.67999, 248.33000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18451, 2016.12000, 297.76999, 248.33000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(13591, 2006.94995, 325.14999, 248.03000,   0.00000, 2.00000, 266.00000);
	CreateDynamicObject(12814, 2023.41003, 324.82001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 2023.41003, 274.82001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1993.43005, 274.82001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1993.42004, 324.81000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1963.46997, 324.76999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18451, 2001.71997, 299.31000, 248.33000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(12814, 1933.78003, 324.79999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1985.75000, 340.56000, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1982.58997, 340.60001, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1961.13000, 352.29999, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1957.76001, 352.32999, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1954.32996, 352.45001, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1961.13000, 352.29999, 252.20000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1957.75000, 352.32999, 252.10001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 1954.32996, 352.45001, 252.12000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1903.84998, 324.62000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1873.87000, 324.69000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(7236, 1911.71997, 321.94000, 272.22000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3050, 2006.87000, 262.63000, 250.06000,   0.00000, 0.00000, 60.00000);
	CreateDynamicObject(3050, 2004.58997, 268.12000, 250.06000,   0.00000, 0.00000, 89.50000);
	CreateDynamicObject(2935, 1923.64001, 340.64999, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1920.23999, 340.72000, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1920.23999, 340.72000, 252.20000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1923.64001, 340.64999, 252.10001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1890.85999, 340.60001, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1887.35999, 340.63000, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1890.85999, 340.60001, 252.14999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2932, 1901.28003, 352.14999, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2932, 1906.59998, 352.20001, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2932, 1912.41003, 351.97000, 249.03999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2932, 1895.69995, 352.84000, 249.19000,   0.00000, 0.00000, 351.95001);
	CreateDynamicObject(1345, 1868.60999, 338.32001, 248.59000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(1345, 2005.93994, 275.70999, 248.59000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(1345, 2006.35999, 277.50000, 248.59000,   0.00000, 0.00000, 358.00000);
	CreateDynamicObject(2934, 1985.75000, 340.56000, 252.20000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1963.47998, 274.79999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1903.54004, 274.67999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1873.59998, 274.69000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16501, 1988.26001, 291.07001, 250.00999,   0.00000, 0.00000, 90.75000);
	CreateDynamicObject(12991, 2000.37000, 282.51999, 247.82001,   0.00000, 0.00000, 88.00000);
	CreateDynamicObject(16501, 1991.71997, 294.64001, 250.00999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1984.90002, 284.01001, 250.00999,   0.00000, 0.00000, 0.74000);
	CreateDynamicObject(16501, 1981.45996, 280.39001, 250.00999,   0.00000, 0.00000, 271.73999);
	CreateDynamicObject(16501, 1977.94995, 283.75000, 250.00999,   0.00000, 0.00000, 0.74000);
	CreateDynamicObject(16501, 1977.88000, 290.73001, 250.00999,   0.00000, 0.00000, 0.74000);
	CreateDynamicObject(16501, 1991.60999, 301.70001, 250.00999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.53003, 308.76999, 250.00999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.44995, 315.64999, 250.00999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1987.89001, 319.06000, 250.00999,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1981.09998, 318.95001, 250.00999,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1977.59998, 315.39999, 250.00999,   0.00000, 0.00000, 0.74000);
	CreateDynamicObject(16501, 1977.68005, 308.41000, 250.00999,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.77002, 301.51999, 250.00999,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.83997, 297.32999, 250.00999,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1982.71997, 287.57001, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 1980.05005, 287.50000, 252.19000,   0.00000, 90.00000, 0.74000);
	CreateDynamicObject(16501, 1981.46997, 282.45001, 252.19000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1988.26001, 291.07001, 254.36000,   0.00000, 0.00000, 90.74000);
	CreateDynamicObject(16501, 1991.71997, 294.64001, 254.41000,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.60999, 301.70001, 254.39000,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.53003, 308.76999, 254.41000,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.44995, 315.64999, 254.39000,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1987.89001, 319.06000, 254.41000,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1981.09998, 318.95001, 254.39000,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1977.59998, 315.39999, 254.39000,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.77002, 301.51999, 254.39000,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.83997, 297.32999, 254.39000,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.69995, 294.39001, 254.41000,   0.00000, 0.00000, 0.74000);
	CreateDynamicObject(16501, 1983.22998, 291.01001, 254.39000,   0.00000, 0.00000, 90.74000);
	CreateDynamicObject(16501, 1981.23999, 290.97000, 254.39000,   0.00000, 0.00000, 90.74000);
	CreateDynamicObject(16501, 1988.20996, 293.20999, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1977.77002, 301.51999, 258.76001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.59998, 315.39999, 258.79001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1974.19995, 305.04001, 254.34000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1974.22998, 305.00000, 258.73999,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1977.68005, 308.39001, 252.14000,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1967.66003, 304.92001, 258.73999,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1968.50000, 304.95999, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1974.13000, 307.14999, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1965.13000, 304.89001, 257.59000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1974.26001, 305.00000, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1961.59998, 304.89001, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1967.07996, 307.07999, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1977.62000, 313.00000, 254.39000,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.62000, 313.00000, 258.79001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1977.67004, 307.32999, 258.79001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1974.22998, 309.35001, 254.34000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1967.65002, 309.26999, 254.34000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1960.81995, 309.17999, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1967.65002, 309.26999, 253.19000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1974.22998, 309.35001, 253.16000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1955.83997, 309.12000, 257.59000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1954.05005, 309.06000, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1964.98999, 309.23999, 257.60999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1960.00000, 306.98001, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1960.81995, 309.17999, 258.73999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1974.22998, 309.35001, 258.69000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1967.65002, 309.26999, 258.69000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1947.12000, 308.98001, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1949.00000, 309.01999, 257.59000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1940.08997, 308.89999, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1940.08997, 308.89999, 257.64001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1944.62000, 308.97000, 258.73999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1955.83997, 309.12000, 258.76001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1949.00000, 309.01999, 258.73999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1940.08997, 308.89999, 258.76001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1974.13000, 307.14999, 251.02000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1952.93994, 306.89001, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1945.90002, 306.79999, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1938.93994, 306.67999, 254.22000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1954.70996, 304.81000, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1948.10999, 304.72000, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1941.31995, 304.60001, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1967.07996, 307.07999, 251.02000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1960.00000, 306.98001, 250.99001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1952.93994, 306.89001, 250.99001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1945.90002, 306.79999, 250.99001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1938.93994, 306.67999, 250.99001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1958.18005, 304.82999, 257.56000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1951.18994, 304.73001, 257.54001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1944.13000, 304.63000, 257.54001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1941.31995, 304.60001, 257.54001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1965.13000, 304.89001, 258.56000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1958.18005, 304.82999, 258.59000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1951.18994, 304.73001, 258.59000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1944.13000, 304.63000, 258.64001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1941.31995, 304.60001, 258.66000,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1974.13000, 307.17001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1967.05005, 307.07999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1959.98999, 306.98999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1952.90002, 306.89999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1945.87000, 306.81000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1938.93994, 306.73999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1977.85999, 294.51001, 258.76001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1981.23999, 290.97000, 258.76001,   0.00000, 0.00000, 90.74000);
	CreateDynamicObject(16501, 1988.26001, 291.07001, 258.76001,   0.00000, 0.00000, 90.74000);
	CreateDynamicObject(16501, 1991.71997, 294.64001, 258.70999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.60999, 301.70001, 258.70999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.53003, 308.76999, 258.73999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1991.44995, 315.64999, 258.70999,   0.00000, 0.00000, 180.74001);
	CreateDynamicObject(16501, 1987.89001, 319.06000, 258.81000,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1981.09998, 318.95001, 258.79001,   0.00000, 0.00000, 270.73999);
	CreateDynamicObject(16501, 1988.18994, 297.62000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1988.12000, 302.00000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1988.06995, 306.39001, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1988.01001, 310.81000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1988.01001, 315.17001, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1987.97998, 316.92001, 260.95999,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.14001, 316.89001, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.18994, 312.59000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.22998, 308.28000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.29004, 303.87000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.35999, 299.47000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.42004, 295.06000, 260.94000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1981.38000, 293.14001, 260.91000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(3761, 1988.21997, 312.89999, 249.82001,   0.00000, 0.00000, 274.00000);
	CreateDynamicObject(3761, 1988.08997, 305.01001, 249.82001,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(2633, 1978.96997, 307.23001, 252.70000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(2633, 1978.98999, 314.20001, 252.70000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(2633, 1982.26001, 317.54999, 252.70000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2633, 1986.52002, 317.54999, 252.70000,   0.00000, 0.00000, 179.99001);
	CreateDynamicObject(2633, 1989.81006, 314.51001, 252.70000,   0.00000, 0.00000, 89.99000);
	CreateDynamicObject(2633, 1979.03003, 310.06000, 252.73000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(2633, 1989.80005, 310.41000, 252.70000,   0.00000, 0.00000, 89.99000);
	CreateDynamicObject(2633, 1989.79004, 307.20999, 251.89999,   0.00000, 332.00000, 89.99000);
	CreateDynamicObject(2633, 1989.81006, 303.51001, 249.92999,   0.00000, 332.00000, 89.99000);
	CreateDynamicObject(2633, 1989.82996, 299.78000, 247.92999,   0.00000, 332.00000, 89.99000);
	CreateDynamicObject(2633, 1989.84998, 296.07999, 245.95000,   0.00000, 332.00000, 89.99000);
	CreateDynamicObject(3117, 1989.29004, 317.70001, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3117, 1979.56995, 317.44000, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2633, 1978.08997, 306.35001, 252.67999,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(16501, 1938.92004, 304.57999, 253.24001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1938.92004, 304.57999, 257.64001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16501, 1938.92004, 304.57999, 258.76001,   0.00000, 0.00000, 270.73001);
	CreateDynamicObject(16644, 1933.68005, 298.91000, 254.27000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 1935.46997, 300.67999, 253.24001,   0.00000, 0.00000, 0.73000);
	CreateDynamicObject(16501, 1935.55005, 294.01999, 253.24001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.43005, 295.23001, 248.99001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.48999, 305.31000, 248.99001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.64001, 287.14001, 253.25999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.78003, 277.04999, 253.39000,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.72998, 280.60001, 253.39000,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1932.28003, 273.54001, 248.99001,   0.00000, 0.00000, 270.72000);
	CreateDynamicObject(16501, 1932.30005, 273.54001, 253.32001,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1925.21997, 273.44000, 249.03999,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1925.23999, 273.45001, 253.32001,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1933.06006, 308.81000, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1933.06006, 308.81000, 257.54001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1933.09998, 308.85001, 258.76001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1932.03003, 308.79001, 248.84000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1935.41003, 305.34000, 252.09000,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.71997, 284.45999, 249.25999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.79004, 278.95001, 249.25999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.55005, 294.01999, 258.73999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.64001, 287.14001, 258.59000,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.72998, 280.60001, 258.70999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.78003, 277.04999, 258.70999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1932.30005, 273.54001, 258.67999,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1925.23999, 273.45001, 257.72000,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1935.50000, 300.70001, 258.76001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16644, 1933.60999, 281.41000, 254.27000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16501, 1932.29004, 280.01001, 249.99001,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1932.29004, 280.01001, 251.99001,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1925.32996, 280.17001, 249.99001,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1925.32996, 280.17001, 252.02000,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16644, 1930.65002, 278.26001, 248.49001,   0.00000, 324.00000, 179.00000);
	CreateDynamicObject(16501, 1919.06006, 273.35001, 249.03999,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1919.06006, 273.35001, 253.39000,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1919.06006, 273.35001, 258.79001,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1915.50000, 278.70999, 249.03999,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.53003, 276.79001, 253.39000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.53003, 276.79001, 258.59000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1925.32996, 280.17001, 256.23999,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16644, 1925.59998, 274.82001, 254.27000,   0.00000, 0.00000, 180.75000);
	CreateDynamicObject(3117, 1917.29004, 277.01001, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3117, 1917.32996, 279.04999, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3117, 1920.83997, 279.04999, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3117, 1920.81006, 277.01999, 254.17999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16501, 1915.41003, 285.70999, 249.03999,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.41003, 285.70999, 253.42000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.41003, 285.70999, 257.79001,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.50000, 278.70999, 253.42000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.50000, 278.70999, 258.62000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.31995, 292.67999, 249.03999,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.31995, 292.67999, 253.44000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.31995, 292.67999, 257.84000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.23999, 299.70001, 249.03999,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.23999, 299.70001, 253.42000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.18005, 305.07999, 249.03999,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1924.95996, 308.69000, 248.84000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1918.60999, 308.60001, 248.84000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1915.18005, 305.07999, 253.42000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.18005, 305.07999, 258.64001,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1932.03003, 308.79001, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1924.95996, 308.67999, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1918.60999, 308.60001, 253.24001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1918.60999, 308.60001, 257.60999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1924.95996, 308.67999, 257.64001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1932.03003, 308.79001, 257.64001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1932.03003, 308.79001, 258.82001,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1924.97998, 308.73001, 258.84000,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1918.60999, 308.60001, 258.85999,   0.00000, 0.00000, 90.73000);
	CreateDynamicObject(16501, 1925.34998, 280.16000, 257.94000,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1918.93005, 280.31000, 259.35999,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1929.16003, 280.07001, 256.34000,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(16501, 1929.16003, 280.07001, 257.94000,   0.00000, 0.00000, 88.71000);
	CreateDynamicObject(12814, 1904.06006, 364.59000, 247.81000,   0.00000, 0.00000, 269.98999);
	CreateDynamicObject(12814, 1954.02002, 364.75000, 247.81000,   0.00000, 0.00000, 269.98999);
	CreateDynamicObject(12814, 2003.94995, 364.76999, 247.81000,   0.00000, 0.00000, 89.99000);
	CreateDynamicObject(7191, 1905.57996, 335.57001, 249.80000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(7191, 1850.55005, 335.57999, 249.80000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(1345, 1868.30005, 340.82999, 248.59000,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(7191, 1879.14001, 371.29001, 253.73000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(7191, 1856.28003, 349.42999, 253.50999,   0.00000, 0.00000, 90.36000);
	CreateDynamicObject(7191, 1858.87000, 327.13000, 248.82001,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(7191, 1858.71997, 282.19000, 248.77000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(7191, 1858.53003, 237.91000, 248.75000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(7191, 1881.07996, 249.73000, 248.75000,   0.00000, 0.00000, 269.75000);
	CreateDynamicObject(7191, 1923.70996, 249.81000, 248.77000,   0.00000, 0.00000, 269.98999);
	CreateDynamicObject(7191, 1968.64001, 250.20000, 248.62000,   0.00000, 0.00000, 269.98999);
	CreateDynamicObject(7191, 1981.55005, 250.17999, 248.64999,   0.00000, 0.00000, 269.98999);
	CreateDynamicObject(2934, 1992.58997, 254.92000, 249.27000,   0.00000, 0.00000, 80.00000);
	CreateDynamicObject(2934, 1972.01001, 254.24001, 249.27000,   0.00000, 0.00000, 310.00000);
	CreateDynamicObject(4100, 1997.79004, 258.23001, 249.45000,   0.00000, 0.00000, 322.00000);
	CreateDynamicObject(4100, 1984.08997, 257.78000, 249.45000,   0.00000, 0.00000, 322.00000);
	CreateDynamicObject(4100, 1967.06006, 257.48001, 249.45000,   0.00000, 0.00000, 322.00000);
	CreateDynamicObject(4100, 1954.77002, 253.17000, 249.45000,   0.00000, 0.00000, 358.00000);
	CreateDynamicObject(3980, 2077.76001, 313.45001, 257.54999,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(3980, 1976.09998, 396.04001, 257.54999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 2030.42004, 353.35999, 249.12000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 2033.45996, 353.32999, 249.12000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 2036.54004, 353.35999, 249.12000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 2039.67004, 353.34000, 249.12000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2934, 2032.40002, 357.54001, 249.12000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2934, 2038.65002, 357.98999, 249.12000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(3980, 1819.87000, 286.10001, 253.05000,   0.00000, 0.00000, 89.75000);
	CreateDynamicObject(6930, 1896.56995, 368.31000, 255.00000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(3980, 1911.83997, 210.71001, 253.05000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(3980, 1982.77002, 211.21001, 253.05000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(7191, 1856.37000, 349.70001, 249.80000,   0.00000, 0.00000, 89.75000);
	CreateDynamicObject(7191, 1879.09998, 371.38000, 249.80000,   0.00000, 0.00000, 179.75000);
	CreateDynamicObject(18259, 1875.78003, 303.72000, 248.81000,   0.00000, 0.00000, 177.82001);
	CreateDynamicObject(16644, 1916.66003, 287.79999, 254.27000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16644, 1916.66003, 298.19000, 254.27000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(16644, 1926.06006, 306.92001, 254.27000,   0.00000, 0.00000, 180.83000);
	CreateDynamicObject(3594, 1932.64001, 296.04001, 248.34000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3594, 1929.37000, 296.23001, 248.34000,   0.00000, 0.00000, 23.67000);
	CreateDynamicObject(12930, 1947.80005, 255.10001, 248.67000,   0.00000, 0.00000, 88.66000);
	CreateDynamicObject(3675, 1929.17004, 271.91000, 254.14999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3675, 1931.20996, 272.01999, 254.14999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1934.56006, 272.51001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1934.58997, 271.14999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1933.39001, 271.82001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3675, 1927.66003, 271.82001, 254.14999,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6933, 2035.71997, 252.39000, 247.80000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 2006.43994, 271.04999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 2005.93005, 270.01001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1986.08997, 284.14001, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1986.38000, 282.09000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, 1986.43994, 280.47000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1887.35999, 340.63000, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1911.76001, 292.56000, 249.14000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2567, 1979.18005, 296.82999, 249.72000,   0.00000, 0.00000, 87.62000);
	CreateDynamicObject(3594, 1869.30005, 260.31000, 248.34000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3594, 1866.94995, 305.73001, 248.34000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2935, 1880.81006, 258.32999, 248.87000,   0.00000, 0.00000, 20.76000);
	CreateDynamicObject(2935, 1876.39001, 269.17999, 249.14000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3594, 1881.21997, 269.97000, 248.34000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(818, 1892.43005, 253.34000, 246.98000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(818, 1890.21997, 256.69000, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1885.17004, 258.10001, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1967.25000, 280.39999, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1962.63000, 283.60001, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1963.58997, 280.31000, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1940.73999, 333.95001, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1939.39001, 333.76999, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 1930.71997, 335.14999, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(13591, 1983.35999, 328.04999, 248.03000,   0.00000, 2.00000, 266.00000);
	CreateDynamicObject(2934, 1992.35999, 329.70001, 249.27000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(818, 2015.89001, 325.97000, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 2014.75000, 323.53000, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(818, 2017.57996, 320.31000, 245.82001,   0.00000, 0.00000, 59.61000);
	CreateDynamicObject(761, 2011.84998, 296.87000, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1329, 1976.68994, 273.48001, 248.14000,   84.00000, 0.00000, 259.06000);
	CreateDynamicObject(1329, 1976.46997, 269.95001, 248.14000,   84.00000, 0.00000, 0.00000);
	CreateDynamicObject(1329, 1926.26001, 291.95999, 248.14000,   84.00000, 0.00000, 259.06000);
	CreateDynamicObject(1329, 1937.13000, 333.59000, 248.14000,   84.00000, 0.00000, 259.06000);
	CreateDynamicObject(1529, 2004.90002, 306.32001, 248.96001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1530, 2004.88000, 311.92999, 248.96001,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1530, 2004.92004, 311.39999, 248.86000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1531, 2004.89001, 297.75000, 249.17000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(18662, 2004.85999, 272.51999, 249.42000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 1933.51001, 274.82999, 247.81000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16501, 1931.83997, 306.57999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1924.77002, 306.50000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.31995, 306.38000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.37000, 302.14999, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.43005, 297.81000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.50000, 293.47000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.56006, 289.09000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.64001, 284.72000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.70996, 280.35999, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.77002, 276.01999, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1918.78003, 275.32001, 260.91000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1924.83997, 302.14001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1924.92004, 297.72000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1924.97998, 293.26001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1925.03003, 288.89999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1925.06995, 284.54999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1925.14001, 280.28000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1925.18005, 275.88000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1925.31006, 275.41000, 260.89001,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1931.88000, 302.20001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1931.94995, 297.78000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.13000, 293.37000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.18005, 289.00000, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.25000, 284.57001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.29004, 280.14999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.33997, 275.73999, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.38000, 275.48001, 260.87000,   0.00000, 90.00000, 90.74000);
	CreateDynamicObject(16501, 1932.30005, 273.54001, 257.67001,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1925.23999, 273.45001, 258.72000,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1919.06006, 273.35001, 257.76999,   0.00000, 0.00000, 270.70999);
	CreateDynamicObject(16501, 1915.53003, 276.79001, 257.79001,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.50000, 278.70999, 257.81000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.41003, 285.70999, 258.59000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.31995, 292.67999, 258.75000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.23999, 299.70001, 258.75000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.23999, 299.70001, 257.82001,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1915.18005, 305.07999, 257.81000,   0.00000, 0.00000, 180.71001);
	CreateDynamicObject(16501, 1935.46997, 300.67999, 257.64001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.56995, 294.01999, 257.60999,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.64001, 287.12000, 257.66000,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(16501, 1935.76001, 277.07001, 257.79001,   0.00000, 0.00000, 0.72000);
	CreateDynamicObject(7191, 2004.79004, 313.41000, 249.07001,   0.00000, 0.00000, 179.71001);
	CreateDynamicObject(7191, 2004.67004, 290.29001, 249.07001,   0.00000, 0.00000, 179.71001);
	CreateDynamicObject(7191, 2004.40002, 235.97000, 249.07001,   0.00000, 0.00000, 179.71001);
	CreateDynamicObject(7191, 1982.87000, 336.28000, 249.07001,   0.00000, 0.00000, 269.45001);
	CreateDynamicObject(3498, 1935.28003, 304.54999, 256.39001,   0.00000, 0.00000, 0.00000);

	// Tobias100500 - aim_headshot
	CreateDynamicObject(5172,3098.69995117,-2002.69995117,26.20000076,0.00000000,351.50000000,0.00000000); //object(beach1spt_las2) (1)
	CreateDynamicObject(5172,3100.10009766,-1989.59997559,5.00000000,0.00000000,72.49645996,0.00000000); //object(beach1spt_las2) (2)
	CreateDynamicObject(5172,3120.30004883,-1956.69995117,5.00000000,0.00000000,72.49328613,269.75000000); //object(beach1spt_las2) (3)
	CreateDynamicObject(5172,3143.10009766,-2048.19995117,5.00000000,0.00000000,72.49328613,0.00000000); //object(beach1spt_las2) (4)
	CreateDynamicObject(5172,3117.10009766,-1921.69995117,32.70000076,0.00000000,352.73779297,269.74731445); //object(beach1spt_las2) (5)
	CreateDynamicObject(5172,3118.19995117,-2070.39990234,4.69999981,0.00000000,85.73785400,269.74731445); //object(beach1spt_las2) (6)
	CreateDynamicObject(18360,3117.30004883,-1962.80004883,40.29999924,279.03161621,175.21533203,1.77505493); //object(cs_landbit_75) (1)
	CreateDynamicObject(18360,3106.80004883,-2051.80004883,39.20000076,296.58825684,174.96533203,180.75085449); //object(cs_landbit_75) (2)
	CreateDynamicObject(5172,3130.80004883,-2095.89990234,35.79999924,0.00000000,341.48254395,270.24182129); //object(beach1spt_las2) (7)
	CreateDynamicObject(18257,3099.69995117,-2038.00000000,22.89999962,0.00000000,0.00000000,182.00000000); //object(crates) (1)
	CreateDynamicObject(18257,3130.50000000,-1981.50000000,22.89999962,0.00000000,0.00000000,355.99951172); //object(crates) (2)
	CreateDynamicObject(2991,3111.10009766,-1976.59997559,23.39999962,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (1)
	CreateDynamicObject(2991,3111.10009766,-1976.59997559,24.70000076,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (2)
	CreateDynamicObject(2991,3115.19995117,-2038.00000000,23.60000038,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (3)
	CreateDynamicObject(2991,3115.19995117,-2038.09997559,24.89999962,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (4)
	CreateDynamicObject(2973,3122.19995117,-2038.80004883,23.00000000,0.00000000,0.00000000,340.00000000); //object(k_cargo2) (1)
	CreateDynamicObject(2973,3125.50000000,-2039.19995117,23.00000000,0.00000000,0.00000000,5.99938965); //object(k_cargo2) (2)
	CreateDynamicObject(2973,3102.69995117,-1976.69995117,22.70000076,0.00000000,0.00000000,0.00000000); //object(k_cargo2) (4)
	CreateDynamicObject(2973,3099.60009766,-1977.30004883,22.70000076,0.00000000,0.00000000,22.00000000); //object(k_cargo2) (5)
	CreateDynamicObject(18257,3116.80004883,-1965.50000000,22.70000076,0.00000000,0.00000000,351.99548340); //object(crates) (3)
	CreateDynamicObject(2912,3125.10009766,-1980.80004883,26.89999962,0.00000000,0.00000000,0.00000000); //object(temp_crate1) (2)
	CreateDynamicObject(2912,3110.00000000,-1976.69995117,25.29999924,0.00000000,0.00000000,0.00000000); //object(temp_crate1) (3)
	CreateDynamicObject(1271,3131.30004883,-1978.90002441,25.20000076,0.00000000,0.00000000,0.00000000); //object(gunbox) (2)
	CreateDynamicObject(1271,3110.10009766,-1964.30004883,27.10000038,0.00000000,0.00000000,0.00000000); //object(gunbox) (3)
	CreateDynamicObject(18257,3115.80004883,-2053.39990234,22.89999962,0.00000000,0.00000000,171.99951172); //object(crates) (4)
	CreateDynamicObject(1271,3125.60009766,-2038.80004883,25.79999924,0.00000000,0.00000000,0.00000000); //object(gunbox) (4)
	CreateDynamicObject(1271,3114.69995117,-2038.09997559,25.89999962,0.00000000,0.00000000,0.00000000); //object(gunbox) (5)
	CreateDynamicObject(1271,3120.80004883,-2054.00000000,27.29999924,0.00000000,0.00000000,0.00000000); //object(gunbox) (6)
	CreateDynamicObject(1431,3124.19995117,-2037.19995117,23.60000038,0.00000000,0.00000000,0.00000000); //object(dyn_box_pile) (1)
	CreateDynamicObject(2038,3125.60009766,-2039.00000000,26.20000076,0.00000000,0.00000000,0.00000000); //object(ammo_box_s2) (1)
	CreateDynamicObject(3798,3133.80004883,-2040.19995117,23.10000038,0.00000000,0.00000000,346.00000000); //object(acbox3_sfs) (1)
	CreateDynamicObject(3798,3131.19995117,-2039.59997559,23.10000038,0.00000000,0.00000000,25.99792480); //object(acbox3_sfs) (2)
	CreateDynamicObject(10244,3096.60009766,-2055.10009766,25.39999962,0.00000000,0.00000000,270.00000000); //object(vicjump_sfe) (1)
	CreateDynamicObject(10244,3136.19995117,-2054.69995117,24.29999924,0.00000000,0.00000000,270.00000000); //object(vicjump_sfe) (2)
	CreateDynamicObject(10244,3133.39990234,-1962.59997559,25.20000076,0.00000000,0.00000000,90.00000000); //object(vicjump_sfe) (3)
	CreateDynamicObject(10244,3095.89990234,-1963.19995117,24.79999924,0.00000000,0.00000000,92.00000000); //object(vicjump_sfe) (4)
	CreateDynamicObject(8651,3113.10009766,-1960.19995117,28.70000076,0.00000000,0.00000000,91.00000000); //object(shbbyhswall07_lvs) (1)
	CreateDynamicObject(8651,3116.60009766,-1960.09997559,28.70000076,0.00000000,0.00000000,91.00000000); //object(shbbyhswall07_lvs) (2)
	CreateDynamicObject(2991,3100.19995117,-1958.69995117,29.39999962,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (6)
	CreateDynamicObject(2991,3100.30004883,-1958.69995117,30.70000076,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (7)
	CreateDynamicObject(2991,3123.80004883,-1958.40002441,29.29999924,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (8)
	CreateDynamicObject(2991,3123.69995117,-1958.40002441,30.60000038,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (9)
	CreateDynamicObject(2973,3115.80004883,-1957.69995117,28.70000076,0.00000000,0.00000000,21.99462891); //object(k_cargo2) (6)
	CreateDynamicObject(8651,3119.19995117,-2057.80004883,29.00000000,0.00000000,0.00000000,90.75000000); //object(shbbyhswall07_lvs) (3)
	CreateDynamicObject(8651,3113.80004883,-2057.80004883,29.00000000,0.00000000,0.00000000,90.74707031); //object(shbbyhswall07_lvs) (4)
	CreateDynamicObject(3798,3121.10009766,-2059.89990234,28.89999962,0.00000000,0.00000000,345.99792480); //object(acbox3_sfs) (3)
	CreateDynamicObject(3798,3120.80004883,-2060.00000000,30.89999962,0.00000000,0.00000000,345.99792480); //object(acbox3_sfs) (4)
	CreateDynamicObject(3798,3106.80004883,-2060.00000000,28.89999962,0.00000000,0.00000000,43.99792480); //object(acbox3_sfs) (5)
	CreateDynamicObject(2991,3113.19995117,-2059.69995117,29.50000000,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (10)
	CreateDynamicObject(2991,3113.19995117,-2059.80004883,30.79999924,0.00000000,0.00000000,0.00000000); //object(imy_bbox) (11)
	CreateDynamicObject(372,3104.30004883,-2043.69995117,23.20000076,276.00756836,134.92077637,145.07855225); //object(1)
	CreateDynamicObject(372,3107.30004883,-2048.30004883,23.20000076,276.00402832,134.91760254,145.07446289); //object(2)
	CreateDynamicObject(372,3111.89990234,-2044.80004883,23.20000076,276.00402832,134.91760254,145.07446289); //object(3)
	CreateDynamicObject(372,3108.89990234,-2043.90002441,23.20000076,276.00402832,134.91760254,145.07446289); //object(4)
	CreateDynamicObject(372,3102.69995117,-2048.30004883,23.10000038,276.00402832,134.91760254,145.07446289); //object(5)
	CreateDynamicObject(372,3112.00000000,-2048.30004883,23.20000076,276.00402832,134.91760254,145.07446289); //object(6)
	CreateDynamicObject(372,3119.19995117,-2048.69995117,23.20000076,276.00402832,134.91760254,145.07446289); //object(7)
	CreateDynamicObject(372,3120.80004883,-2045.09997559,23.20000076,276.00402832,134.91760254,145.07446289); //object(8)
	CreateDynamicObject(372,3131.60009766,-2045.40002441,23.29999924,276.00402832,134.91760254,145.07446289); //object(9)
	CreateDynamicObject(372,3127.69995117,-2048.60009766,23.29999924,276.00402832,134.91760254,145.07446289); //object(10)
	CreateDynamicObject(372,3102.60009766,-1968.69995117,22.89999962,276.00402832,134.91760254,145.07446289); //object(11)
	CreateDynamicObject(372,3102.89990234,-1973.00000000,23.00000000,276.00402832,134.91760254,145.07446289); //object(12)
	CreateDynamicObject(372,3109.10009766,-1972.00000000,23.00000000,276.00402832,134.91760254,145.07446289); //object(13)
	CreateDynamicObject(372,3112.80004883,-1969.40002441,23.00000000,276.00402832,134.91760254,145.07446289); //object(14)
	CreateDynamicObject(372,3117.69995117,-1973.69995117,23.00000000,276.00402832,134.91760254,145.07446289); //object(15)
	CreateDynamicObject(372,3122.30004883,-1969.00000000,23.10000038,276.00402832,134.91760254,145.07446289); //object(16)
	CreateDynamicObject(372,3127.50000000,-1973.90002441,23.10000038,276.00402832,134.91760254,145.07446289); //object(17)
	CreateDynamicObject(372,3129.69995117,-1968.40002441,23.10000038,276.00402832,134.91760254,145.07446289); //object(18)

	// Kuddy - Cidade Abandonada
	CreateDynamicObject(3997, 711.49646, -2229.36499, 293.32486,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4012, 757.16095, -2320.48242, 293.39984,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4012, 695.73724, -2321.39404, 293.39984,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3253, 680.40088, -2245.06274, 293.32486,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3362, 690.44678, -2247.34058, 293.32486,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3418, 684.29706, -2266.50806, 295.49307,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3457, 752.54236, -2184.68555, 296.40424,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3580, 744.53296, -2271.77173, 297.96387,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3639, 698.34070, -2191.08960, 297.72879,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3640, 704.27209, -2241.46729, 297.83649,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3641, 652.43140, -2228.87524, 295.41751,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3642, 731.94543, -2238.71240, 296.27597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3644, 748.73767, -2231.54028, 295.98773,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3648, 757.69293, -2280.41504, 296.06866,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5520, 658.04901, -2249.63623, 298.46957,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5892, 656.87488, -2287.11499, 294.24365,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11490, 719.70923, -2260.78174, 293.32486,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11491, 719.69867, -2271.82690, 294.82434,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3644, 773.01471, -2252.41553, 295.98773,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3580, 697.89667, -2213.13110, 296.68918,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3644, 737.36255, -2208.58228, 295.91275,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3641, 716.77094, -2224.52539, 295.74243,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3639, 715.00604, -2204.82251, 297.40387,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3655, 635.81964, -2198.00732, 296.25360,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3655, 635.78345, -2186.29907, 296.25360,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3655, 648.79248, -2173.26953, 296.25360,   0.00000, 0.00000, 270.00000);
	CreateDynamicObject(3655, 660.74152, -2173.25488, 296.25360,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(3655, 672.47528, -2173.25635, 296.25360,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(3655, 684.38330, -2173.21094, 296.25360,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(3655, 696.28308, -2173.21631, 296.25360,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(3655, 707.99707, -2173.24072, 296.25360,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(3641, 672.55103, -2229.00098, 295.41751,   0.00000, 0.00000, 268.00000);
	CreateDynamicObject(3644, 656.25391, -2206.59644, 295.98773,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3644, 680.50525, -2201.76245, 295.98773,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(3648, 649.12177, -2180.37427, 296.06866,   0.00000, 0.00000, 88.00000);
	CreateDynamicObject(3648, 662.96539, -2180.07031, 296.06866,   0.00000, 0.00000, 87.99500);
	CreateDynamicObject(12991, 688.07117, -2225.48901, 293.27487,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5299, 707.93762, -2278.24756, 293.32486,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16006, 695.88989, -2312.51660, 292.26636,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6962, 731.28094, -2330.42798, 299.79102,   0.00000, 0.00000, 314.00000);
	CreateDynamicObject(8397, 725.84125, -2300.21558, 303.40756,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11426, 722.72272, -2242.82349, 293.22488,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11427, 662.48712, -2262.88892, 300.28976,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11428, 727.00629, -2284.68774, 298.47852,   0.00000, 0.00000, 266.00000);
	CreateDynamicObject(11440, 763.12482, -2214.68726, 292.60004,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11441, 733.47241, -2223.57861, 293.22488,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11442, 691.06433, -2283.34619, 293.32486,   0.00000, 0.00000, 88.00000);
	CreateDynamicObject(11443, 689.58270, -2236.32031, 293.17490,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11444, 699.47675, -2227.56445, 293.12491,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11445, 742.02014, -2246.10303, 293.19989,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11457, 774.66351, -2286.09277, 292.84998,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(11458, 735.00684, -2315.63721, 293.17807,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8072, 716.72375, -2083.63623, 302.71140,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8072, 632.33936, -2082.49658, 302.71140,   0.00000, 0.00000, 10.00000);
	CreateDynamicObject(8072, 546.62567, -2266.80664, 302.71140,   0.00000, 0.00000, 87.99759);
	CreateDynamicObject(8072, 544.50342, -2266.45605, 302.71140,   0.00000, 2.00000, 123.99503);
	CreateDynamicObject(8072, 598.83679, -2388.72314, 302.71140,   0.00000, 1.99951, 141.99170);
	CreateDynamicObject(8072, 698.52997, -2443.02295, 301.06143,   0.00000, 1.99951, 191.98730);
	CreateDynamicObject(8072, 874.54987, -2275.56812, 302.56143,   0.00000, 1.99951, 279.98608);
	CreateDynamicObject(17143, 749.96942, -2290.31616, 279.60550,   0.00000, 10.00000, 0.00000);
	CreateDynamicObject(17143, 688.93494, -2369.54443, 284.55563,   0.00000, 13.99756, 0.00000);
	CreateDynamicObject(6959, 656.48340, -2193.14307, 293.40421,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 697.75317, -2193.14307, 293.40421,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 656.47174, -2233.05371, 293.40421,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 697.85828, -2233.06177, 293.40421,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3640, 747.22986, -2297.25293, 297.33661,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3640, 761.29413, -2332.47803, 298.31137,   0.00000, 358.00000, 68.00000);

	// saawan - swat4samp dm map
	CreateDynamicObject(3095,1937.0999800,-2569.5000000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (8)
	CreateDynamicObject(3095,1937.0999800,-2558.8000500,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (9)
	CreateDynamicObject(3095,1937.0999800,-2547.1001000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (10)
	CreateDynamicObject(3095,1937.0999800,-2533.3000500,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (11)
	CreateDynamicObject(3095,1937.0999800,-2519.8999000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (12)
	CreateDynamicObject(3095,1950.0000000,-2526.8000500,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (13)
	CreateDynamicObject(3095,1950.0000000,-2540.3000500,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (14)
	CreateDynamicObject(3095,1950.0000000,-2553.1001000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (15)
	CreateDynamicObject(3095,1950.0000000,-2563.8999000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (16)
	CreateDynamicObject(3095,1962.0999800,-2569.5000000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (17)
	CreateDynamicObject(3095,1962.0999800,-2558.8999000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (18)
	CreateDynamicObject(3095,1962.0999800,-2546.8000500,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (19)
	CreateDynamicObject(3095,1962.0999800,-2533.3999000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (20)
	CreateDynamicObject(3095,1962.0999800,-2520.1001000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (21)
	CreateDynamicObject(3095,1976.3000500,-2566.5000000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (22)
	CreateDynamicObject(3095,1976.3000500,-2553.0000000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (23)
	CreateDynamicObject(3095,1976.3000500,-2540.1001000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (24)
	CreateDynamicObject(3095,1976.3000500,-2526.5000000,12.5000000,0.0000000,90.0000000,0.0000000); //object(a51_jetdoor) (25)
	CreateDynamicObject(3095,1986.4000200,-2566.3999000,12.5000000,0.0000000,90.0000000,180.0000000); //object(a51_jetdoor) (26)
	CreateDynamicObject(3095,1986.4000200,-2553.0000000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (27)
	CreateDynamicObject(3095,1986.4000200,-2540.1001000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (28)
	CreateDynamicObject(3095,1986.4000200,-2526.5000000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (29)
	CreateDynamicObject(3095,2001.9000200,-2569.6999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (30)
	CreateDynamicObject(3095,2001.9000200,-2557.6999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (31)
	CreateDynamicObject(3095,2001.9000200,-2545.6999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (32)
	CreateDynamicObject(3095,2001.9000200,-2533.1001000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (33)
	CreateDynamicObject(3095,2001.9000200,-2518.3000500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (34)
	CreateDynamicObject(3095,2015.0000000,-2564.5000000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (35)
	CreateDynamicObject(3095,2015.0000000,-2551.3999000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (36)
	CreateDynamicObject(3095,2015.0000000,-2539.3000500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (37)
	CreateDynamicObject(3095,2015.0000000,-2525.1999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (38)
	CreateDynamicObject(3095,2027.8000500,-2569.6999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (39)
	CreateDynamicObject(3095,2027.8000500,-2556.3000500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (40)
	CreateDynamicObject(3095,2027.8000500,-2544.1999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (41)
	CreateDynamicObject(3095,2027.8000500,-2531.3999000,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (42)
	CreateDynamicObject(3095,2027.8000500,-2517.1999500,12.5000000,0.0000000,90.0000000,179.9950000); //object(a51_jetdoor) (43)
	CreateDynamicObject(4023,2059.5000000,-2534.8999000,24.2000000,0.0000000,0.0000000,270.0000000); //object(newdbbuild_lan04) (1)
	CreateDynamicObject(4023,2059.5000000,-2553.5000000,24.2000000,0.0000000,0.0000000,270.0000000); //object(newdbbuild_lan04) (2)
	CreateDynamicObject(4023,1944.1999500,-2593.8999000,24.2000000,0.0000000,0.0000000,180.0000000); //object(newdbbuild_lan04) (3)
	CreateDynamicObject(4023,1988.0999800,-2593.8999000,24.2000000,0.0000000,0.0000000,179.9950000); //object(newdbbuild_lan04) (4)
	CreateDynamicObject(4023,2028.5999800,-2593.8999000,24.2000000,0.0000000,0.0000000,179.9950000); //object(newdbbuild_lan04) (5)
	CreateDynamicObject(4023,2018.5000000,-2493.6999500,24.2000000,0.0000000,0.0000000,0.0000000); //object(newdbbuild_lan04) (6)
	CreateDynamicObject(4023,1974.8000500,-2493.6999500,24.2000000,0.0000000,0.0000000,0.0000000); //object(newdbbuild_lan04) (7)
	CreateDynamicObject(4023,1936.4000200,-2493.6999500,24.2000000,0.0000000,0.0000000,0.0000000); //object(newdbbuild_lan04) (8)
	CreateDynamicObject(4023,1902.4000200,-2551.8999000,24.2000000,0.0000000,0.0000000,89.9950000); //object(newdbbuild_lan04) (9)
	CreateDynamicObject(4023,1902.4000200,-2521.5000000,24.2000000,0.0000000,0.0000000,89.9950000); //object(newdbbuild_lan04) (10)

	// ZM_Italy
	CreateDynamicObject(17859, -4002.69995, -1114.07996, 108.35399,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17859, -4020.68481, -1128.65295, 108.26917,   0.00000, 0.00000, 269.86365);
	CreateDynamicObject(17859, -4010.47949, -1105.69617, 108.11655,   0.00000, -0.85944, 182.20081);
	CreateDynamicObject(17859, -4010.32666, -1140.19250, 108.30827,   0.00000, 0.00000, -1.71887);
	CreateDynamicObject(4012, -4019.63086, -1124.77283, 106.25523,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4209, -3978.33691, -1092.71375, 98.60830,   0.00000, 45.55009, 0.00000);
	CreateDynamicObject(17859, -3997.90112, -1082.90002, 108.15755,   0.00000, 0.00000, -177.90363);
	CreateDynamicObject(17859, -3984.58691, -1080.72937, 108.53672,   0.00000, 0.00000, 89.48501);
	CreateDynamicObject(4148, -3981.76831, -1091.69275, 103.82860,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(4163, -3984.57568, -1130.47864, 99.16902,   -42.11240, 0.00000, 90.24080);
	CreateDynamicObject(4012, -3945.56641, -1138.15686, 106.03540,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17859, -3960.40259, -1126.53259, 107.97050,   0.00000, 0.00000, -180.48183);
	CreateDynamicObject(17859, -3963.11548, -1154.16687, 107.92931,   0.00000, 0.00000, -90.24085);
	CreateDynamicObject(17859, -3992.81445, -1150.85730, 107.94264,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5153, -4001.81299, -1136.48816, 110.88361,   0.00000, 23.20479, 89.38136);
	CreateDynamicObject(5153, -4004.81201, -1135.21179, 110.90862,   0.00000, 23.20479, 177.90346);
	CreateDynamicObject(5153, -4009.08594, -1135.06189, 110.88361,   0.00000, 24.92366, 177.90346);
	CreateDynamicObject(1221, -3992.58496, -1145.50671, 108.46012,   0.00000, 0.00000, -18.04817);
	CreateDynamicObject(17859, -3950.03296, -1138.03210, 107.86024,   -1.71887, 0.00000, 88.52192);
	CreateDynamicObject(17859, -3963.36841, -1112.47839, 107.95524,   0.00000, 0.00000, -89.38136);
	CreateDynamicObject(4012, -3962.86914, -1058.74622, 106.66981,   -0.85944, 0.00000, 178.76289);
	CreateDynamicObject(17859, -3919.80957, -1085.22644, 108.00526,   0.00000, 0.00000, -91.10029);
	CreateDynamicObject(4012, -4031.21729, -1059.43665, 106.65551,   0.00000, 0.85944, 273.30093);
	CreateDynamicObject(17859, -4031.34839, -1084.06946, 108.30767,   0.00000, 0.00000, 93.67860);
	CreateDynamicObject(17859, -4022.10718, -1049.81873, 108.30767,   0.00000, 0.00000, 266.42538);
	CreateDynamicObject(17859, -4003.62622, -1035.14246, 108.50767,   0.00000, 0.00000, -0.75625);
	CreateDynamicObject(17859, -3974.66431, -1043.48181, 108.53048,   0.00000, 0.00000, 269.00351);
	CreateDynamicObject(17859, -3934.72046, -1050.76892, 108.63839,   0.00000, 0.00000, -91.10023);
	CreateDynamicObject(17859, -3963.45142, -1021.44672, 108.55656,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17859, -3972.87134, -1085.71155, 108.47322,   0.00000, 0.00000, -179.62221);
	CreateDynamicObject(17859, -3927.54053, -1105.89880, 107.95525,   0.00000, 0.00000, 89.38142);
	CreateDynamicObject(17859, -3925.74561, -1124.07458, 107.95525,   0.00000, 0.00000, -0.85944);
	CreateDynamicObject(1558, -3996.78369, -1048.95959, 107.12076,   0.00000, 0.00000, 35.23690);
	CreateDynamicObject(1438, -3969.38696, -1131.09021, 105.82160,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1438, -3970.56787, -1065.93542, 106.50342,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17859, -3963.34009, -1070.97375, 108.43827,   0.00000, 0.00000, -269.00330);
	CreateDynamicObject(1419, -3956.92749, -1105.98792, 111.19955,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1419, -3952.85669, -1105.98792, 111.19955,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1419, -3948.78198, -1105.98792, 111.19955,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1419, -3945.48999, -1105.98792, 111.19955,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1419, -3943.46216, -1103.93591, 111.14955,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(1299, -3995.50781, -1139.31165, 111.48965,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3981.23071, -1111.70032, 104.20634,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3981.60889, -1128.56824, 104.18134,   0.00000, 0.00000, 91.95961);
	CreateDynamicObject(1299, -3955.95923, -1136.31262, 106.24599,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1558, -3974.17480, -1135.51379, 106.35779,   0.00000, 0.00000, 42.11240);
	CreateDynamicObject(1299, -4005.71680, -1118.92859, 106.60460,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -4007.99219, -1102.93323, 106.63343,   0.00000, 0.00000, 30.08028);
	CreateDynamicObject(1221, -4007.89771, -1126.56482, 106.62516,   0.00000, 0.00000, -18.04817);
	CreateDynamicObject(1221, -4016.94043, -1092.00623, 106.64049,   0.00000, 0.00000, -18.04817);
	CreateDynamicObject(1221, -4016.94043, -1092.00623, 107.56549,   0.00000, 0.00000, 33.51803);
	CreateDynamicObject(1221, -3970.39478, -1068.54089, 106.90228,   0.00000, 0.00000, 33.51803);
	CreateDynamicObject(1221, -3970.42871, -1068.39636, 107.83021,   0.00000, 0.00000, 96.25685);
	CreateDynamicObject(1438, -3962.29858, -1055.42029, 111.19005,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1438, -3955.74072, -1055.13684, 111.19005,   0.00000, 0.00000, -119.46175);
	CreateDynamicObject(1221, -3990.45483, -1088.04651, 106.61542,   0.00000, 0.00000, 33.51803);
	CreateDynamicObject(1221, -3992.15332, -1109.90881, 106.63890,   0.00000, 0.00000, 73.05206);
	CreateDynamicObject(1221, -3992.22803, -1109.95886, 107.53890,   0.00000, 0.00000, 122.89944);
	CreateDynamicObject(17859, -3946.64209, -1089.55676, 107.96734,   0.00000, -0.00006, 270.72263);
	CreateDynamicObject(2395, -3979.01123, -1098.28528, 110.89284,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3982.73633, -1098.28528, 110.89284,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3986.42773, -1098.28528, 110.89284,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3988.02148, -1098.28528, 110.89284,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3988.02148, -1098.28528, 112.29282,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3984.30127, -1098.26013, 112.29282,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3980.60498, -1098.26013, 112.29282,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3976.85889, -1098.23523, 112.29282,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3798, -3958.75220, -1040.93176, 104.90828,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3798, -3993.64111, -1131.55676, 104.26939,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3951.72510, -1039.34851, 107.34669,   0.00000, 0.00000, 33.51803);
	CreateDynamicObject(1299, -3967.80737, -1038.96252, 107.31335,   0.00000, 0.00000, 33.51803);
	CreateDynamicObject(1438, -3964.45068, -1038.16589, 106.90105,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1438, -3970.14502, -1051.22058, 106.69434,   0.00000, 0.00000, 177.90350);
	CreateDynamicObject(1438, -3949.94653, -1070.38123, 106.41331,   0.00000, 0.00000, 270.72263);
	CreateDynamicObject(939, -3941.17969, -1076.91394, 107.16923,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(1437, -3942.40039, -1099.60535, 106.24654,   0.00000, 0.00000, 89.38142);
	CreateDynamicObject(1419, -3986.33301, -1112.90735, 111.61121,   0.00000, 0.00000, 91.10029);
	CreateDynamicObject(1419, -3986.30811, -1116.18176, 111.61121,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(1419, -3986.30811, -1120.25842, 111.61121,   0.00000, 0.00000, 89.38142);
	CreateDynamicObject(1419, -3986.33301, -1124.33362, 111.58621,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(1419, -3988.33203, -1126.35876, 111.58621,   0.00000, 0.00000, -179.62244);
	CreateDynamicObject(1419, -3992.40674, -1126.38367, 111.58621,   0.00000, 0.00000, -179.62244);
	CreateDynamicObject(1419, -3996.53027, -1126.38367, 111.58621,   0.00000, 0.00000, -179.62244);
	CreateDynamicObject(1419, -3970.86304, -1129.32996, 111.21246,   0.00000, 0.00000, -179.62244);
	CreateDynamicObject(1419, -3974.88501, -1129.32996, 111.21246,   0.00000, 0.00000, -179.62244);
	CreateDynamicObject(1419, -3976.95190, -1127.28088, 111.21246,   0.00000, 0.00000, -269.86313);
	CreateDynamicObject(1419, -3976.95190, -1123.20544, 111.21246,   0.00000, 0.00000, -269.86313);
	CreateDynamicObject(1419, -3976.95190, -1119.12927, 111.21246,   0.00000, 0.00000, -269.86313);
	CreateDynamicObject(1419, -3976.95190, -1116.25403, 111.21246,   0.00000, 0.00000, -269.86313);
	CreateDynamicObject(1419, -3974.88013, -1114.32825, 111.21246,   0.00000, 0.00000, -360.96313);
	CreateDynamicObject(1299, -4013.71021, -1129.47571, 106.61641,   0.00000, 0.00000, 48.12846);
	CreateDynamicObject(1299, -4013.43628, -1130.97522, 106.59142,   0.00000, 0.00000, 91.10029);
	CreateDynamicObject(5153, -3985.64600, -1133.25134, 106.90105,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(5153, -3981.47266, -1133.25134, 107.80106,   0.00000, 23.20479, 0.00000);
	CreateDynamicObject(5153, -3977.41675, -1133.25281, 106.86596,   0.00000, 51.56614, 0.00000);
	CreateDynamicObject(1419, -3985.86426, -1128.87976, 106.71025,   0.00000, 0.00000, -269.00369);
	CreateDynamicObject(1419, -3985.64014, -1132.98157, 106.48524,   0.00000, 0.00000, -269.00369);
	CreateDynamicObject(1419, -3985.49072, -1137.08264, 106.68525,   0.00000, 0.00000, -269.00369);
	CreateDynamicObject(1419, -3977.06226, -1130.14636, 106.46355,   0.00000, 0.00000, -269.00369);
	CreateDynamicObject(1419, -3976.01880, -1136.20203, 106.46005,   0.00000, 0.00000, -59.30119);
	CreateDynamicObject(1419, -3985.46582, -1141.13342, 106.68525,   0.00000, 0.00000, -269.00369);
	CreateDynamicObject(971, -3931.41626, -1079.09656, 106.21923,   0.00000, 0.00000, -93.67860);
	CreateDynamicObject(971, -3931.11523, -1107.67395, 106.00214,   0.00000, 0.00000, -90.24080);
	CreateDynamicObject(971, -3942.93628, -1087.68347, 106.21042,   0.00000, 0.00000, 91.10023);
	CreateDynamicObject(971, -3957.31348, -1136.79407, 107.43469,   0.00000, 0.85944, 180.48199);
	CreateDynamicObject(971, -4018.62646, -1089.24426, 106.17337,   0.00000, 0.00000, 92.81916);
	CreateDynamicObject(971, -4016.05322, -1136.55969, 106.22710,   0.00000, 0.00000, -3.43775);
	CreateDynamicObject(971, -4009.66406, -1047.43152, 106.76395,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(971, -3967.97876, -1073.18152, 106.68128,   0.00000, 0.00000, 22.34535);
	CreateDynamicObject(971, -3946.62012, -1048.72864, 106.70445,   0.00000, 0.00000, 87.66248);
	CreateDynamicObject(17859, -3964.44189, -1028.50696, 108.60133,   0.00000, 0.00000, 179.72609);
	CreateDynamicObject(971, -3971.13989, -1041.66321, 106.85071,   0.00000, 0.00000, 92.81916);
	CreateDynamicObject(17859, -3915.22729, -1070.65393, 113.21584,   0.00000, 0.00000, -540.58490);
	CreateDynamicObject(17859, -4034.09888, -1058.91565, 113.05243,   0.00000, 0.00000, 91.10035);
	CreateDynamicObject(639, -4014.48535, -1136.58069, 108.34725,   0.00000, 0.00000, -89.38136);
	CreateDynamicObject(639, -3956.90210, -1136.71033, 109.22948,   0.00000, 5.15662, -89.38136);
	CreateDynamicObject(639, -3931.26978, -1109.71838, 107.99787,   0.00000, 5.15662, 0.00000);
	CreateDynamicObject(639, -3931.72290, -1081.43958, 108.00119,   0.00000, 5.15662, 2.57831);
	CreateDynamicObject(639, -3942.80249, -1085.13708, 108.03945,   0.00000, 5.15662, 181.34137);
	CreateDynamicObject(639, -3946.74268, -1046.88147, 108.67161,   0.00000, 0.00000, -2.57831);
	CreateDynamicObject(639, -3971.09888, -1039.48767, 108.90916,   0.00000, 0.00000, 181.34131);
	CreateDynamicObject(639, -3966.83887, -1033.49622, 108.68319,   0.85944, 1.71887, 95.39771);
	CreateDynamicObject(639, -3968.46240, -1073.19836, 108.24750,   0.85944, 1.71887, 291.34909);
	CreateDynamicObject(639, -4024.57227, -1062.86584, 113.04224,   0.85944, 1.71887, 2.68202);
	CreateDynamicObject(639, -4018.61792, -1086.81848, 108.24813,   0.85944, 1.71887, 183.16383);
	CreateDynamicObject(639, -3981.34082, -1097.48938, 104.89536,   0.85944, 1.71887, 89.58894);
	CreateDynamicObject(639, -3981.38794, -1147.87024, 103.82489,   0.85944, 1.71887, 270.07059);
	CreateDynamicObject(14600, -4032.02197, -1060.96838, 112.54033,   0.00000, 0.00000, 181.34126);
	CreateDynamicObject(639, -4007.48267, -1047.50281, 108.90816,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(639, -3988.74731, -1146.63196, 113.26974,   0.00000, 0.00000, -90.24085);
	CreateDynamicObject(639, -3977.06885, -1119.88269, 108.78809,   0.00000, 1.71887, -0.85938);
	CreateDynamicObject(639, -3952.99414, -1032.88464, 113.85548,   0.00000, 1.71887, 90.24091);
	CreateDynamicObject(639, -4017.99683, -1053.12268, 113.61700,   0.00000, 1.71887, 176.18459);
	CreateDynamicObject(639, -3931.83154, -1105.22156, 113.24849,   0.00000, 1.71887, -0.85944);
	CreateDynamicObject(639, -3938.34619, -1058.07751, 113.97346,   0.00000, 1.71887, 88.52198);
	CreateDynamicObject(17859, -3921.94482, -1097.97620, 112.66076,   0.00000, 0.00000, 89.38136);
	CreateDynamicObject(17859, -3980.58716, -1019.95819, 113.18838,   0.00000, 0.00000, 2.68150);
	CreateDynamicObject(17859, -4033.28027, -1126.70520, 117.08618,   0.00000, 0.00000, 359.34854);
	CreateDynamicObject(1299, -4014.45337, -1130.08264, 111.40742,   0.00000, 0.00000, -19.76704);
	CreateDynamicObject(17859, -3985.34375, -1165.30627, 112.51235,   0.00000, 0.00000, 90.24108);
	CreateDynamicObject(17859, -4016.05566, -1112.27356, 117.22848,   0.00000, 0.00000, 1.06742);
	CreateDynamicObject(17859, -4017.78296, -1154.01086, 117.09635,   0.00000, 0.00000, 88.73013);
	CreateDynamicObject(17859, -4008.93628, -1163.33289, 117.07135,   0.00000, 0.00000, 89.58957);
	CreateDynamicObject(1299, -4014.17944, -1133.85779, 111.43243,   0.00000, 0.00000, 25.78310);
	CreateDynamicObject(1419, -4003.05078, -1138.32727, 116.14301,   0.00000, 0.00000, -91.95984);
	CreateDynamicObject(1419, -4003.17529, -1142.40393, 116.14301,   0.00000, 0.00000, -91.95984);
	CreateDynamicObject(1419, -4003.37451, -1146.50427, 116.14301,   0.00000, 0.00000, -91.95984);
	CreateDynamicObject(1299, -3957.28906, -1125.91101, 106.40549,   0.00000, 0.00000, 60.16057);
	CreateDynamicObject(1299, -3954.79297, -1116.78625, 106.40549,   0.00000, 0.00000, 89.38136);
	CreateDynamicObject(971, -3950.93921, -1067.89807, 113.00185,   0.00000, 0.00000, -89.38142);
	CreateDynamicObject(1419, -3940.46631, -1114.27942, 110.52421,   0.00000, 0.00000, 178.76294);
	CreateDynamicObject(1419, -3936.39160, -1114.37976, 110.49921,   0.00000, 0.00000, 178.76294);
	CreateDynamicObject(2395, -3967.47949, -1130.45813, 116.37359,   0.85944, -269.86313, 88.52198);
	CreateDynamicObject(2395, -4001.94653, -1146.87048, 117.83462,   181.34126, 89.38142, 178.76271);
	CreateDynamicObject(2395, -3992.71558, -1109.12634, 115.37328,   181.34126, 269.10733, 2.68184);
	CreateDynamicObject(2395, -3959.43286, -1107.45764, 112.81467,   181.34126, 90.24085, 91.10012);
	CreateDynamicObject(8990, -4008.45459, -1126.38416, 116.18499,   0.00000, 0.00000, 179.62233);
	CreateDynamicObject(8990, -3980.99805, -1148.28870, 111.24976,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8990, -3951.96045, -1033.26135, 111.82263,   0.00000, 0.00000, 179.62233);
	CreateDynamicObject(8990, -3991.63550, -1047.20422, 111.86112,   0.00000, 0.00000, 1.82269);
	CreateDynamicObject(8990, -3937.17700, -1120.12756, 115.84826,   0.00000, 0.00000, 179.62233);
	CreateDynamicObject(971, -3981.27954, -1147.63489, 103.79530,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3993.26855, -1145.87878, 106.63016,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(636, -3987.64746, -1098.92468, 114.20183,   179.62244, 92.81916, -90.24085);
	CreateDynamicObject(636, -3947.17749, -1071.75110, 113.69804,   179.62244, 89.38142, 90.24085);
	CreateDynamicObject(636, -3972.22559, -1136.31677, 113.67978,   179.62244, 91.10029, 90.24085);
	CreateDynamicObject(636, -4016.51587, -1134.51819, 118.31034,   179.62244, 89.38142, 0.00000);
	CreateDynamicObject(639, -3992.71094, -1105.70398, 113.14118,   0.00000, 0.00000, 181.34131);
	CreateDynamicObject(644, -3976.22217, -1128.67468, 110.98006,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(644, -3955.01660, -1035.36951, 107.16088,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2395, -3995.52344, -1126.65735, 113.42326,   180.48183, 90.34467, 91.20382);
	CreateDynamicObject(3095, -3945.39526, -1118.37805, 109.43904,   0.00000, 0.00000, -0.85944);
	CreateDynamicObject(3095, -3936.46802, -1118.52820, 109.43904,   0.00006, 0.00000, -0.85944);
	CreateDynamicObject(3361, -3933.20825, -1111.31970, 107.90608,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(3095, -4015.81982, -1131.63904, 110.41209,   0.00000, 0.00000, -0.85944);
	CreateDynamicObject(1419, -4011.42798, -1127.76868, 111.46938,   0.00000, 0.00000, 89.38130);
	CreateDynamicObject(1419, -4011.45288, -1131.84436, 111.46938,   0.00000, 0.00000, 89.38130);
	CreateDynamicObject(3095, -3970.92432, -1137.03284, 110.36378,   -90.24085, 0.00000, -0.85944);
	CreateDynamicObject(3095, -3963.30469, -1137.15857, 110.36378,   -90.24085, 0.00000, -0.85944);
	CreateDynamicObject(17859, -3971.31665, -1086.07874, 107.93024,   0.00000, 0.00000, 0.00006);
	CreateDynamicObject(639, -3980.21826, -1098.86584, 113.75388,   0.00000, 0.00000, 89.38147);
	CreateDynamicObject(3095, -3993.71167, -1097.08386, 110.53524,   0.00000, 91.10029, 0.85944);
	CreateDynamicObject(3095, -3993.51245, -1104.80920, 110.53524,   0.00000, 91.10029, 1.71887);
	CreateDynamicObject(3095, -3947.10669, -1072.50549, 110.64385,   -91.95967, 0.00000, 0.00000);
	CreateDynamicObject(971, -3947.11646, -1072.04675, 113.00185,   -1.71887, 0.00000, 0.00000);
	CreateDynamicObject(1594, -3936.00415, -1116.71448, 110.47140,   0.00000, 0.00000, 39.53409);
	CreateDynamicObject(1594, -3938.96021, -1116.73938, 110.47140,   0.00000, 0.00000, 79.92761);
	CreateDynamicObject(626, -3932.80664, -1118.39685, 111.99300,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(626, -3941.45605, -1118.52209, 111.96800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3515, -4004.52710, -1059.54993, 105.86552,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3862, -3992.08838, -1051.08459, 107.86093,   0.00000, 0.00000, -39.53409);
	CreateDynamicObject(3862, -3989.91260, -1056.12927, 107.78044,   0.00000, 0.00000, -89.38142);
	CreateDynamicObject(3860, -3991.07788, -1065.81677, 107.68504,   0.00000, 0.00000, -177.90356);
	CreateDynamicObject(3863, -3999.64893, -1066.95667, 107.61278,   0.00000, 0.00000, 181.34131);
	CreateDynamicObject(3861, -3997.56201, -1058.35291, 107.77659,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(3860, -4000.73267, -1054.04016, 107.81964,   0.00000, 0.00000, -213.99985);
	CreateDynamicObject(3861, -4012.49023, -1067.79382, 107.61577,   0.00000, 0.00000, 181.34137);
	CreateDynamicObject(3863, -4017.06445, -1060.73865, 107.72796,   0.00000, 0.00000, 86.80322);
	CreateDynamicObject(1338, -3989.07471, -1058.74011, 107.28561,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1338, -4016.44141, -1057.75525, 107.30548,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1438, -4006.46240, -1050.39465, 106.71413,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1438, -4008.82178, -1067.53552, 106.44464,   0.00000, 0.00000, 98.83522);
	CreateDynamicObject(1438, -3989.29565, -1052.55090, 106.70283,   0.00000, 0.00000, 47.26902);
	CreateDynamicObject(1441, -4001.93677, -1067.10657, 107.07864,   0.00000, 0.00000, -90.24085);
	CreateDynamicObject(1441, -3990.69751, -1068.00183, 107.09383,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1441, -3994.91333, -1050.29944, 107.33204,   0.00000, 0.00000, -135.79106);
	CreateDynamicObject(1558, -4016.99927, -1053.59192, 107.23181,   0.00000, 0.00000, -3.43775);
	CreateDynamicObject(3810, -4019.04761, -1064.94592, 110.17023,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3810, -3988.20874, -1059.46619, 110.41456,   0.00000, 0.00000, 181.34120);
	CreateDynamicObject(3810, -3988.43286, -1064.56653, 110.41456,   0.00000, 0.00000, 181.34120);
	CreateDynamicObject(3861, -3961.18701, -1048.00476, 107.84595,   0.00000, 0.00000, 179.62244);
	CreateDynamicObject(3861, -3956.28516, -1048.01331, 107.85603,   0.00000, 0.00000, 181.34126);
	CreateDynamicObject(1438, -3958.32349, -1047.50330, 106.75451,   0.00000, -1.71887, 86.80311);
	CreateDynamicObject(1299, -3949.73706, -1050.49182, 107.15823,   0.00000, 0.00000, -2.57831);
	CreateDynamicObject(644, -3962.24365, -1035.34460, 107.16088,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3993.95313, -1074.86780, 106.78428,   0.00000, 0.00000, 3.43775);
	CreateDynamicObject(3810, -4005.49536, -1069.35193, 110.01023,   0.00000, 0.00000, 92.81916);
	CreateDynamicObject(3810, -4004.00854, -1048.86438, 110.33446,   0.00000, 0.00000, 268.14420);
	CreateDynamicObject(3810, -3995.81201, -1127.80627, 110.19837,   0.00000, 0.00000, -89.38142);
	CreateDynamicObject(3810, -3995.91162, -1136.60535, 110.14837,   0.00000, 0.00000, 88.52198);
	CreateDynamicObject(3810, -3967.07544, -1131.50696, 109.93497,   0.00000, 0.00000, 267.28470);
	CreateDynamicObject(3806, -3956.20654, -1106.83386, 109.03062,   0.00000, 0.00000, -88.52198);
	CreateDynamicObject(971, -3981.46606, -1100.11658, 102.09533,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(644, -3977.07617, -1099.66272, 106.22195,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3095, -3973.68457, -1098.60461, 105.37460,   89.38142, 0.00000, -0.85944);
	CreateDynamicObject(3095, -3943.19995, -1118.72839, 110.66404,   0.00000, 90.24085, -0.85944);
	CreateDynamicObject(3806, -3958.79077, -1053.72668, 110.24277,   0.00000, 0.00000, 91.10029);
	CreateDynamicObject(3806, -3989.78760, -1146.12781, 110.08192,   0.00000, 0.00000, 90.24085);
	CreateDynamicObject(3810, -3948.62085, -1055.92346, 110.49482,   0.00000, 0.00000, 179.62239);
	CreateDynamicObject(3810, -3932.54663, -1103.45422, 109.86383,   0.00000, 0.00000, 173.60603);
	CreateDynamicObject(3095, -3981.09375, -1074.35925, 110.63390,   0.00006, 90.24085, 1.71887);
	CreateDynamicObject(5064, -3933.90210, -1119.81189, 108.23910,   90.24091, 0.00000, -0.85944);
	CreateDynamicObject(1438, -3970.28882, -1076.78918, 106.32035,   0.00000, 0.00000, 85.08424);
	CreateDynamicObject(635, -4011.29175, -1130.88611, 110.42959,   0.00000, -85.94367, 179.62239);
	CreateDynamicObject(5064, -4020.66772, -1126.09167, 110.05276,   85.94373, 0.00000, 180.48183);
	CreateDynamicObject(2395, -3980.76709, -1069.75281, 115.33472,   180.48183, 269.96683, 91.20382);
	CreateDynamicObject(3471, -4021.95020, -1062.48792, 112.30774,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8990, -3986.57837, -1052.78186, 111.85893,   0.00000, 0.00000, 88.52198);
	CreateDynamicObject(8990, -3987.17603, -1071.20618, 111.85893,   0.00000, 0.00000, 88.52198);
	CreateDynamicObject(5064, -3942.87915, -1126.01282, 108.33910,   90.24091, 0.00000, -90.24085);
	CreateDynamicObject(5064, -3932.40112, -1179.86169, 108.13920,   90.24091, 0.00000, 89.38142);
	CreateDynamicObject(2395, -3942.56665, -1096.63171, 115.58283,   181.34126, 269.86307, 0.96326);
	CreateDynamicObject(5064, -4007.59668, -1149.37927, 113.04671,   72.19274, 0.00000, 269.00351);
	CreateDynamicObject(3040, -4013.88965, -1050.65735, 109.00549,   0.00000, 0.00000, 88.52198);
	CreateDynamicObject(1594, -3939.99121, -1114.53528, 106.43327,   0.00000, 0.00000, 132.35336);
	CreateDynamicObject(923, -3935.56787, -1113.02063, 106.83771,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1299, -3937.08862, -1115.14856, 106.41299,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3860, -3968.16138, -1042.37708, 107.95983,   0.00000, 0.00000, -270.72250);

	// CS_RockWar by Amirab
	CreateDynamicObject(634, 1163.036987, 2100.312012, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1169.172974, 2098.108887, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1181.322266, 2098.350586, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1190.448975, 2100.044922, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1202.291992, 2100.681885, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1151.043945, 2100.406006, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1150.401001, 2067.218994, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1163.055054, 2067.218994, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1168.518555, 2069.554688, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1180.165039, 2070.039063, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1187.640991, 2068.558105, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1199.154053, 2067.989990, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1145.915039, 2092.050781, 160.024002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1139.989258, 2069.301758, 159.714996, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1144.635010, 2108.629883, 160.024002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1197.412964, 2114.564941, 160.024002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1151.192017, 2053.596924, 160.024002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1205.276001, 2098.562012, 159.550003, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1204.706055, 2079.335938, 159.550003, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(634, 1204.900024, 2061.518066, 159.550003, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(647, 1151.517944, 2077.396973, 143.828003, 0.000000, 0.000000, 284.000000);
	CreateDynamicObject(647, 1193.796997, 2078.243896, 143.528000, 0.000000, 0.000000, 283.996582);
	CreateDynamicObject(647, 1148.083008, 2092.719971, 143.904999, 0.000000, 0.000000, 273.996582);
	CreateDynamicObject(647, 1188.382813, 2085.234375, 143.653000, 0.000000, 0.000000, 283.996582);
	CreateDynamicObject(650, 1156.630981, 2083.532959, 142.496002, 0.000000, 0.000000, 300.000000);
	CreateDynamicObject(650, 1171.031006, 2083.069092, 142.496002, 0.000000, 0.000000, 299.998169);
	CreateDynamicObject(650, 1202.670044, 2078.291016, 142.496002, 0.000000, 0.000000, 209.998169);
	CreateDynamicObject(650, 1173.592041, 2092.035889, 142.496002, 0.000000, 0.000000, 129.998199);
	CreateDynamicObject(650, 1191.985352, 2089.950195, 142.496002, 0.000000, 0.000000, 129.995728);
	CreateDynamicObject(864, 1168.973999, 2078.202881, 142.496002, 0.000000, 0.000000, 342.000000);
	CreateDynamicObject(864, 1177.631836, 2086.079102, 142.470993, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(864, 1143.791016, 2088.710938, 142.496002, 0.000000, 0.000000, 341.998901);
	CreateDynamicObject(864, 1143.617188, 2078.878906, 142.496002, 0.000000, 0.000000, 341.998901);
	CreateDynamicObject(864, 1152.057617, 2083.090820, 142.496002, 0.000000, 0.000000, 341.998901);
	CreateDynamicObject(864, 1201.322021, 2091.166992, 142.496002, 0.000000, 0.000000, 341.998901);
	CreateDynamicObject(1225, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1178.515015, 2080.881104, 148.296997, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1184.697021, 2081.782959, 145.598999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1170.436035, 2084.778076, 148.296997, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1147.338013, 2084.106934, 142.901993, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1153.687988, 2078.914063, 145.598999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1150.286011, 2084.909912, 148.296997, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1145.015015, 2091.210938, 142.901993, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1172.239990, 2111.285889, 148.854996, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1200.645996, 2090.104004, 142.901993, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1174.113037, 2057.097900, 148.779999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1154.913086, 2059.333008, 145.505005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1155.879883, 2108.987305, 145.505005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1170.119019, 2117.549072, 166.897995, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1173.448242, 2051.324219, 166.130997, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1159.552002, 2053.264893, 166.125000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1187.665039, 2115.150879, 166.897995, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1191.797852, 2051.735352, 166.130005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1225, 1155.463013, 2117.446045, 166.897995, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(1460, 1171.952148, 2090.999023, 143.307007, 0.000000, 0.000000, 181.999512);
	CreateDynamicObject(1460, 1189.627930, 2087.113281, 143.307007, 0.000000, 0.000000, 181.999512);
	CreateDynamicObject(1460, 1172.442383, 2076.693359, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(1460, 1181.695313, 2088.181641, 143.307007, 0.000000, 0.000000, 91.994019);
	CreateDynamicObject(1460, 1172.238281, 2084.429688, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(1460, 1167.777954, 2076.808105, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(1460, 1157.812012, 2076.566895, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(1460, 1144.124023, 2079.590088, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(1460, 1143.865967, 2091.977051, 143.307007, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(1460, 1152.009033, 2092.180908, 143.307007, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(1460, 1201.463013, 2079.483887, 143.307007, 0.000000, 0.000000, 359.994507);
	CreateDynamicObject(2939, 2808.395020, 464.984894, 100.400002, 156.000000, 0.000000, 0.000000);
	CreateDynamicObject(3053, 2810.277100, 462.299988, 100.214798, 180.000000, 0.000000, 360.000000);
	CreateDynamicObject(3066, 1150.297974, 2058.958984, 143.550003, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(3066, 1151.807007, 2109.299072, 143.550003, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(3261, 1178.729492, 2076.606445, 145.194000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1167.266602, 2084.274414, 147.891006, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1177.796021, 2089.120117, 145.192993, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1160.120117, 2081.050781, 147.889999, 0.000000, 0.000000, 271.999512);
	CreateDynamicObject(3261, 1189.816406, 2079.098633, 147.891006, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1151.316406, 2087.073242, 147.891006, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(3261, 1162.880981, 2081.572998, 142.496002, 0.000000, 0.000000, 89.999512);
	CreateDynamicObject(3261, 1150.683594, 2081.995117, 145.194000, 0.000000, 0.000000, 181.999512);
	CreateDynamicObject(3261, 1165.932007, 2081.583008, 142.496002, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1168.932007, 2081.573975, 142.496002, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1184.353027, 2079.055908, 145.194000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1184.350952, 2082.054932, 145.194000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1197.509033, 2081.976074, 145.194000, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1194.462036, 2081.986084, 145.194000, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1195.191040, 2085.845947, 143.218994, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1198.197998, 2085.815918, 143.218994, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1171.208008, 2089.780273, 145.100998, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1168.198975, 2089.738037, 145.100998, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1165.196045, 2089.742920, 145.100998, 0.000000, 0.000000, 89.994507);
	CreateDynamicObject(3261, 1151.880981, 2089.195068, 142.796005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1151.896973, 2086.194092, 142.796005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3261, 1147.663940, 2089.628906, 145.194000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(3261, 1155.535156, 2089.675781, 147.891006, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(3279, 1175.514038, 2058.374023, 140.695999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3279, 1171.124023, 2109.912109, 140.770996, 0.000000, 0.000000, 178.747559);
	CreateDynamicObject(3570, 1163.869995, 2077.729004, 143.843994, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3571, 1161.984009, 2081.218994, 146.541000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(3572, 1178.171997, 2090.591064, 143.843994, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3573, 1163.561523, 2088.270508, 145.188004, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3574, 1183.060547, 2081.763672, 145.188004, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(3575, 1150.500000, 2084.278320, 145.188004, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(3575, 1200.191040, 2084.330078, 145.188004, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(3920, 1147.848022, 2107.860107, 144.880997, 5.000000, 0.000000, 180.000000);
	CreateDynamicObject(3920, 1160.321289, 2107.789063, 144.880997, 4.993286, 0.000000, 179.994507);
	CreateDynamicObject(3920, 1173.071045, 2107.714111, 144.880997, 4.998779, 0.000000, 179.994507);
	CreateDynamicObject(3920, 1185.551025, 2107.791992, 144.880997, 4.987793, 0.000000, 179.994507);
	CreateDynamicObject(3920, 1198.312012, 2107.718994, 144.880997, 4.993286, 0.000000, 179.994507);
	CreateDynamicObject(3920, 1197.750000, 2060.350098, 144.880997, 4.998779, 0.000000, 359.994507);
	CreateDynamicObject(3920, 1185.176025, 2060.366943, 144.880997, 4.993286, 0.000000, 0.489014);
	CreateDynamicObject(3920, 1173.385010, 2060.368896, 144.880997, 4.987793, 0.000000, 0.736084);
	CreateDynamicObject(3920, 1161.333008, 2060.350098, 144.880997, 4.987793, 0.000000, 0.488892);
	CreateDynamicObject(3920, 1149.182007, 2060.363037, 144.880997, 4.987793, 0.000000, 0.488892);
	CreateDynamicObject(3920, 1137.005981, 2060.232910, 144.880997, 4.987793, 0.000000, 0.488892);
	CreateDynamicObject(4812, 1221.906250, 2074.726563, 150.791000, 0.000000, 0.000000, 3.993530);
	CreateDynamicObject(4812, 1199.555054, 2135.666016, 150.791000, 0.000000, 0.000000, 95.999023);
	CreateDynamicObject(4812, 1123.612305, 2095.625000, 150.791000, 0.000000, 0.000000, 181.983032);
	CreateDynamicObject(4812, 1147.390015, 2032.840942, 150.791000, 0.000000, 0.000000, 275.993042);
	CreateDynamicObject(7301, 1167.386963, 2051.842041, 162.449997, 0.000000, 0.000000, 307.744751);
	CreateDynamicObject(7301, 1184.213989, 2051.135010, 162.449997, 0.000000, 0.000000, 317.994751);
	CreateDynamicObject(7416, 1176.636719, 2134.586914, 142.496002, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(7416, 1177.692383, 2033.879883, 142.496002, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(7619, 1210.088013, 2136.250000, 145.917007, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(7619, 1212.392944, 2031.968018, 145.789001, 180.000000, 0.000000, 90.000000);
	CreateDynamicObject(7910, 1163.277954, 2117.447021, 163.162994, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(7910, 1180.083984, 2116.291992, 163.162994, 0.000000, 0.000000, 352.000000);
	CreateDynamicObject(7933, 1173.376953, 2096.425049, 143.005005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(7933, 1154.738281, 2099.117188, 143.005005, 0.000000, 0.000000, 357.994995);
	CreateDynamicObject(7933, 1194.629883, 2098.464844, 143.005005, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(7933, 1191.556641, 2069.975586, 143.005005, 0.000000, 0.000000, 177.989502);
	CreateDynamicObject(7933, 1155.208008, 2069.041016, 143.005005, 0.000000, 0.000000, 179.989014);
	CreateDynamicObject(7933, 1172.575195, 2071.201172, 143.005005, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(13831, 1209.560059, 2081.625000, 170.432007, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(18691, 2032.287964, 1352.272949, 17.094999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(18691, 2032.392944, 1334.464966, 17.094999, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(18761, 2032.387939, 1343.343994, 14.570000, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(18857, 77.719002, -903.320984, 451.213989, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19055, 2033.564941, 1334.697998, 10.477000, 0.000000, 0.000000, 60.000000);
	CreateDynamicObject(19055, 2031.396484, 1351.898438, 10.477000, 0.000000, 0.000000, 59.996338);
	CreateDynamicObject(19056, 2032.411011, 1333.295044, 10.477000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19057, 2033.368042, 1351.519043, 10.477000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19057, 2031.578979, 1334.932007, 10.477000, 0.000000, 0.000000, 40.000000);
	CreateDynamicObject(19058, 2032.537964, 1353.292969, 10.477000, 0.000000, 0.000000, 335.999969);
	CreateDynamicObject(19086, 2033.121948, 1351.385986, 11.274000, 0.000000, 0.000000, 30.000000);
	CreateDynamicObject(19123, 2020.876953, 1339.984009, 10.278000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19123, 2020.859375, 1345.999023, 10.253000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19123, 2027.093018, 1346.036011, 10.253000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19123, 2027.144531, 1340.053711, 10.278000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19128, 2023.875977, 1342.932007, 9.783000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19130, 2028.708008, 1345.161011, 9.769000, 0.000000, 90.000000, 190.000000);
	CreateDynamicObject(19130, 2030.780029, 1345.946045, 9.769000, 0.000000, 90.000000, 211.997559);
	CreateDynamicObject(19130, 2030.722046, 1340.357056, 9.769000, 0.000000, 90.000000, 148.007813);
	CreateDynamicObject(19130, 2028.774048, 1341.201050, 9.769000, 0.000000, 90.000000, 170.002441);
	CreateDynamicObject(19130, 2028.745972, 1343.245972, 9.769000, 0.000000, 90.000000, 180.000000);
	CreateDynamicObject(19130, 2031.469971, 1343.255005, 9.769000, 0.000000, 90.000000, 179.994507);
	CreateDynamicObject(19300, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19300, 0.000000, 0.000000, 0.100000, 0.000000, 0.000000, 96.000000);
	CreateDynamicObject(19300, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000);
	CreateDynamicObject(19364, 1200.829102, 2060.512695, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1194.492188, 2060.507813, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1188.109375, 2060.510742, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1181.797852, 2060.502930, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1162.660034, 2060.517090, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1175.451050, 2060.496094, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1169.058960, 2060.506104, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1202.674805, 2107.666016, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1196.359375, 2107.666016, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1189.953003, 2107.678955, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1183.544922, 2107.694336, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1177.211060, 2107.697021, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1170.826050, 2107.698975, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19364, 1164.449951, 2107.715088, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1191.300781, 2060.516602, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1172.250977, 2060.511963, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1156.296997, 2060.500000, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1193.160034, 2107.675049, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1174.022949, 2107.696045, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19393, 1158.067993, 2107.706055, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1143.496948, 2060.486084, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1197.659180, 2060.507813, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1184.970703, 2060.514648, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1165.847046, 2060.523926, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1178.629028, 2060.495117, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1159.442993, 2060.511963, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1199.485352, 2107.681641, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1186.741211, 2107.688477, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1180.350952, 2107.698975, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1167.646973, 2107.705078, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1161.260986, 2107.717041, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19410, 1145.280029, 2107.694092, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19425, 2027.229980, 1341.474976, 9.820000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(19425, 2027.230957, 1344.607056, 9.820000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(19425, 2025.456055, 1346.066040, 9.820000, 0.000000, 0.000000, 180.000000);
	CreateDynamicObject(19425, 2022.313965, 1346.068970, 9.820000, 0.000000, 0.000000, 180.000000);
	CreateDynamicObject(19425, 2020.818970, 1344.538940, 9.820000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(19425, 2020.828003, 1341.387939, 9.820000, 0.000000, 0.000000, 270.000000);
	CreateDynamicObject(19425, 2022.380981, 1339.989014, 9.813000, 0.000000, 0.000000, 180.000000);
	CreateDynamicObject(19425, 2025.543945, 1339.983032, 9.813000, 0.000000, 0.000000, 179.994507);
	CreateDynamicObject(19456, 1149.892944, 2060.498047, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19456, 1137.118042, 2060.511963, 144.100006, 0.000000, 0.000000, 90.000000);
	CreateDynamicObject(19456, 1151.670898, 2107.702148, 144.100006, 0.000000, 0.000000, 90.000000);

	// Leo - Terminal Island
	CreateDynamicObject(12814, 11931.58008, -1299.66772, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12054.34375, -1089.84644, 11.38340,   0.00000, 0.00000, -90.00000);
	CreateDynamicObject(12814, 12076.35156, -1100.12183, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11961.48242, -1269.73242, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12076.20313, -1269.09302, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11962.35352, -1219.49036, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(8547, 12004.78906, -1199.03491, 11.68009,   0.00000, 0.00000, 89.99998);
	CreateDynamicObject(12814, 11954.60156, -1090.30640, 11.38340,   0.00000, 0.00000, -90.00000);
	CreateDynamicObject(12814, 12004.50293, -1090.02234, 11.38340,   0.00000, 0.00000, -90.00000);
	CreateDynamicObject(12814, 11931.16309, -1099.99866, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11931.23535, -1149.99231, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11931.38086, -1199.84204, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11931.46191, -1249.82495, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12076.66211, -1149.82837, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12076.47656, -1199.71375, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12076.17969, -1249.61548, 11.40340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11971.46582, -1309.68896, 11.38340,   0.00000, 0.00000, -90.23997);
	CreateDynamicObject(12814, 12066.46777, -1309.89600, 11.40309,   0.00000, 0.00000, -90.23997);
	CreateDynamicObject(12814, 12021.39844, -1309.85559, 11.38340,   0.00000, 0.00000, -90.24000);
	CreateDynamicObject(12814, 12000.46582, -1179.82324, 11.38340,   0.00000, 0.00000, 89.46005);
	CreateDynamicObject(12814, 12023.49023, -1140.52527, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11993.81543, -1140.47791, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 11968.99609, -1136.15979, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12066.94531, -1288.69482, 10.57555,   0.00000, 0.00000, 89.57998);
	CreateDynamicObject(12814, 11976.83691, -1269.94556, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12004.37988, -1270.02234, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(12814, 12036.63574, -1270.25793, 11.38340,   0.00000, 0.00000, 0.12000);
	CreateDynamicObject(19313, 12063.54883, -1230.93909, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12056.46680, -1293.84631, 15.07640,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 12042.49512, -1293.77856, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 12028.47656, -1293.88586, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 12014.50586, -1293.90698, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 12000.52246, -1293.95349, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 11986.54199, -1293.89648, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 11972.56055, -1293.91077, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 11958.58691, -1293.90540, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 11952.86816, -1294.02954, 15.14910,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, 12063.43945, -1286.84192, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.41016, -1272.84070, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.49316, -1258.90344, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.48730, -1244.93616, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.54395, -1216.98657, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.62500, -1202.99194, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.56152, -1189.04651, 15.14910,   0.00000, 0.00000, 91.14001);
	CreateDynamicObject(19313, 12063.43652, -1175.08423, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.47852, -1161.15088, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.50977, -1147.13965, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.53613, -1133.12549, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.68262, -1111.05042, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 12063.64063, -1119.14539, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.06836, -1111.09143, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.10547, -1119.01892, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.15625, -1133.02441, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.16797, -1147.02417, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.19434, -1161.00476, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.18262, -1175.00500, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.12891, -1189.02527, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.10742, -1203.04541, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.10547, -1217.04663, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.09766, -1231.06665, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.06152, -1245.07373, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11946.02539, -1259.05701, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11945.99902, -1272.97754, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11945.95117, -1286.98865, 15.14910,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(19313, 11953.05371, -1104.18213, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(19313, 11972.80566, -1104.33020, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(19313, 12056.65430, -1104.15552, 15.14910,   0.00000, 0.00000, 180.24004);
	CreateDynamicObject(19313, 12042.63770, -1104.21130, 15.14910,   0.00000, 0.00000, 180.24004);
	CreateDynamicObject(19313, 12028.65625, -1104.21582, 15.14910,   0.00000, 0.00000, 180.24004);
	CreateDynamicObject(19313, 12014.73340, -1104.20410, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(19313, 11986.68750, -1104.17871, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(19313, 12000.71094, -1104.21191, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(19313, 11958.84668, -1104.26978, 15.14910,   0.00000, 0.00000, 180.24001);
	CreateDynamicObject(18250, 11961.16699, -1119.06396, 17.53415,   0.00000, 0.00000, 0.00211);
	CreateDynamicObject(1327, 11968.75098, -1119.53076, 12.32695,   0.00000, 0.00000, 270.83621);
	CreateDynamicObject(1327, 11966.58398, -1119.59448, 12.32695,   0.00000, 0.00000, 270.83621);
	CreateDynamicObject(1327, 11964.29688, -1119.63086, 12.32695,   0.00000, 0.00000, 270.83621);
	CreateDynamicObject(1327, 11965.44043, -1119.71167, 13.71170,   0.00000, 0.00000, 267.08939);
	CreateDynamicObject(1327, 11962.10938, -1119.71362, 12.32695,   0.00000, 0.00000, 270.83621);
	CreateDynamicObject(1327, 11963.23633, -1119.78503, 13.58666,   0.00000, 0.00000, 270.62286);
	CreateDynamicObject(1327, 11966.71680, -1119.75159, 15.12825,   0.00000, 0.00000, 269.45193);
	CreateDynamicObject(1327, 11967.72656, -1119.40442, 13.79170,   0.00000, 0.00000, 270.26819);
	CreateDynamicObject(1327, 11964.37988, -1119.66370, 15.12825,   0.00000, 0.00000, 269.45193);
	CreateDynamicObject(1327, 11965.49609, -1119.73340, 16.40595,   0.00000, 0.00000, 269.45193);
	CreateDynamicObject(854, 11968.26953, -1119.70862, 11.75571,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(854, 11969.75586, -1120.36438, 11.75571,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(854, 11966.85742, -1120.36133, 11.75571,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(854, 11965.49316, -1119.52100, 11.75571,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(851, 11963.28906, -1120.29370, 11.97554,   0.00000, 0.00000, 318.03790);
	CreateDynamicObject(851, 11963.54688, -1118.13318, 11.97554,   0.00000, 0.00000, 351.99808);
	CreateDynamicObject(805, 11949.59863, -1107.90088, 12.42703,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11952.58691, -1106.86877, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11952.03809, -1109.50354, 11.70880,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11948.59668, -1110.42664, 12.42806,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11948.94336, -1113.40503, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11948.35840, -1116.75977, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11950.08789, -1115.75781, 11.67051,   0.00000, 0.00000, 343.00583);
	CreateDynamicObject(805, 11949.16016, -1119.81616, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11949.59277, -1122.58691, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11950.05664, -1125.81433, 12.32400,   0.00000, 0.00000, 327.44562);
	CreateDynamicObject(805, 11950.12988, -1118.03796, 11.81390,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11955.21680, -1108.61597, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11956.79395, -1107.23462, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11958.47363, -1108.74487, 11.87992,   0.00000, 0.00000, 338.69263);
	CreateDynamicObject(805, 11960.76172, -1108.01208, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11962.09473, -1108.27014, 11.86225,   0.00000, 0.00000, 46.13411);
	CreateDynamicObject(805, 11963.69043, -1107.81665, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11965.51563, -1109.15942, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11967.65332, -1107.45825, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11969.25000, -1109.38599, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11972.22168, -1110.21143, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11972.72070, -1107.81335, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11950.62305, -1113.08167, 10.06121,   0.00000, 0.00000, 4.89432);
	CreateDynamicObject(728, 11950.52246, -1121.93689, 10.36903,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11956.85840, -1108.36084, 10.25679,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11971.93750, -1125.95117, 10.67204,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11970.32813, -1122.85730, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(805, 11970.39551, -1125.68713, 12.32400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11970.12891, -1120.91125, 10.67204,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(851, 11952.12402, -1123.49939, 11.97554,   0.00000, 0.00000, 318.03790);
	CreateDynamicObject(805, 11952.93555, -1121.68298, 11.91796,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(625, 11969.46875, -1130.49255, 12.15873,   0.00000, 0.00000, 324.22009);
	CreateDynamicObject(625, 11971.99316, -1130.47583, 12.15873,   0.00000, 0.00000, 324.22009);
	CreateDynamicObject(625, 11974.15820, -1130.94958, 12.11386,   0.00000, 0.00000, 289.99768);
	CreateDynamicObject(824, 11978.10742, -1106.26611, 10.69341,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(824, 11978.04980, -1107.75769, 10.66049,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(824, 11981.74316, -1105.86780, 10.85540,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(3287, 11985.40918, -1121.76184, 15.92446,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 11984.14063, -1127.80701, 11.41935,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 11986.54297, -1127.92578, 11.41935,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 11986.55371, -1127.89990, 11.41935,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 11985.77246, -1119.15601, 11.41935,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(801, 11984.76465, -1129.30933, 11.31448,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(801, 11986.52051, -1129.20178, 11.09788,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(801, 11986.50000, -1118.01587, 10.74658,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 11968.05859, -1128.98242, 11.74557,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(880, 11952.15918, -1129.54004, 10.25151,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(880, 11952.10742, -1131.56165, 10.55452,   0.00000, 0.00000, 345.14075);
	CreateDynamicObject(880, 11954.05273, -1133.19849, 10.14848,   0.00000, 0.00000, 345.14075);
	CreateDynamicObject(880, 11956.93555, -1133.57788, 10.14848,   0.00000, 0.00000, 345.14075);
	CreateDynamicObject(816, 11961.61621, -1133.42529, 11.65998,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11974.79492, -1134.19910, 11.96299,   0.00000, 0.00000, 258.33701);
	CreateDynamicObject(816, 11962.91504, -1135.66919, 11.51531,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11962.73438, -1134.20911, 11.56300,   0.00000, 0.00000, 354.19540);
	CreateDynamicObject(816, 11971.88281, -1129.87500, 11.62604,   0.00000, 0.00000, 247.72183);
	CreateDynamicObject(816, 11964.41992, -1134.85974, 11.72300,   0.00000, 0.00000, 258.61090);
	CreateDynamicObject(816, 11960.11328, -1131.94958, 11.64705,   0.00000, 0.00000, 340.41779);
	CreateDynamicObject(816, 11975.48633, -1134.20984, 11.96299,   0.00000, 0.00000, 253.34586);
	CreateDynamicObject(816, 11971.10742, -1134.12256, 11.84496,   0.00000, 0.00000, 253.87628);
	CreateDynamicObject(816, 11969.90430, -1134.00586, 11.96299,   0.00000, 0.00000, 252.25574);
	CreateDynamicObject(816, 11969.03906, -1135.46765, 11.45898,   0.00000, 0.00000, 253.61166);
	CreateDynamicObject(816, 11963.51563, -1134.17188, 11.56300,   0.00000, 0.00000, 354.19540);
	CreateDynamicObject(816, 11962.47363, -1132.01587, 11.54618,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11963.66113, -1134.28052, 11.22178,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11974.91602, -1133.32776, 11.54195,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11971.21777, -1133.71387, 11.65363,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11972.60059, -1133.50354, 11.54981,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11981.27246, -1135.02515, 11.64425,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11974.10742, -1131.16504, 11.96299,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11971.11523, -1134.14087, 11.43892,   0.00000, 0.00000, 253.87628);
	CreateDynamicObject(816, 11968.12012, -1136.68665, 11.54438,   0.00000, 0.00000, 253.73166);
	CreateDynamicObject(816, 11974.80566, -1129.34375, 11.96299,   0.00000, 0.00000, 253.34586);
	CreateDynamicObject(816, 11974.46289, -1134.34973, 11.55695,   0.00000, 0.00000, 253.07730);
	CreateDynamicObject(816, 11982.39258, -1135.42090, 11.53584,   0.00000, 0.00000, 232.51505);
	CreateDynamicObject(816, 11987.20508, -1129.88135, 11.96299,   0.00000, 0.00000, 258.33701);
	CreateDynamicObject(816, 11986.39063, -1132.72656, 11.96299,   0.00000, 0.00000, 252.25574);
	CreateDynamicObject(816, 11972.69531, -1133.86902, 11.55695,   0.00000, 0.00000, 253.07730);
	CreateDynamicObject(816, 11979.70801, -1134.75305, 11.65053,   0.00000, 0.00000, 258.61093);
	CreateDynamicObject(816, 11985.33594, -1135.46423, 11.64106,   0.00000, 0.00000, 253.34586);
	CreateDynamicObject(816, 11984.11426, -1135.15173, 11.54297,   0.00000, 0.00000, 324.56537);
	CreateDynamicObject(816, 11957.45605, -1122.65686, 11.72300,   0.00000, 0.00000, 354.19540);
	CreateDynamicObject(816, 11957.37500, -1138.65063, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11961.03906, -1138.10010, 11.49690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11950.24121, -1133.35168, 11.55695,   0.00000, 0.00000, 171.94501);
	CreateDynamicObject(816, 11953.81641, -1149.64368, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11957.58398, -1128.28015, 11.65389,   0.00000, 0.00000, 258.61093);
	CreateDynamicObject(816, 11965.56641, -1126.54333, 11.65998,   0.00000, 0.00000, 253.07730);
	CreateDynamicObject(816, 11971.98730, -1135.90161, 11.44641,   0.00000, 0.00000, 253.73166);
	CreateDynamicObject(816, 11965.70703, -1134.22852, 11.55490,   0.00000, 0.00000, 253.07730);
	CreateDynamicObject(816, 11976.68457, -1135.90369, 11.65053,   0.00000, 0.00000, 258.61093);
	CreateDynamicObject(897, 12015.03418, -1120.18372, 9.38189,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(897, 12014.51367, -1127.92139, 8.76721,   0.00000, 0.00000, 336.72855);
	CreateDynamicObject(897, 12021.17285, -1119.88879, 9.38189,   0.00000, 0.00000, 270.40503);
	CreateDynamicObject(897, 12018.62793, -1121.48633, 9.38189,   0.00000, 0.00000, 270.40503);
	CreateDynamicObject(897, 12022.42578, -1125.99170, 8.87179,   0.00000, 0.00000, 244.75542);
	CreateDynamicObject(897, 12036.94238, -1131.32690, 8.87179,   0.00000, 0.00000, 244.75542);
	CreateDynamicObject(897, 12031.24023, -1131.04163, 8.49671,   0.00000, 0.00000, 239.56749);
	CreateDynamicObject(897, 12025.78711, -1130.20825, 8.49671,   0.00000, 0.00000, 19.74062);
	CreateDynamicObject(897, 12021.71191, -1131.71997, 8.13785,   0.00000, 0.00000, 18.95630);
	CreateDynamicObject(897, 12017.76855, -1130.37488, 8.13785,   0.00000, 0.00000, 270.53870);
	CreateDynamicObject(897, 12014.23828, -1130.14453, 8.03785,   0.00000, 0.00000, 285.27002);
	CreateDynamicObject(880, 11976.03125, -1131.07715, 10.55452,   0.00000, 0.00000, 345.14075);
	CreateDynamicObject(880, 11976.17188, -1132.28870, 10.55452,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 11977.93164, -1131.51538, 10.55452,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 11979.27930, -1129.55554, 11.13921,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 11984.17188, -1131.73145, 10.39600,   0.00000, 0.00000, 232.31807);
	CreateDynamicObject(880, 11985.00098, -1128.89954, 11.13921,   0.00000, 0.00000, 232.31807);
	CreateDynamicObject(868, 11988.98047, -1132.47546, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(868, 11992.66602, -1127.89026, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(868, 11987.66895, -1129.86719, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(868, 11987.00293, -1133.39404, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(868, 11991.16309, -1132.77930, 11.38597,   0.00000, 0.00000, 44.40000);
	CreateDynamicObject(868, 11992.87012, -1130.67456, 11.38597,   0.00000, 0.00000, 153.65999);
	CreateDynamicObject(868, 11990.76758, -1130.71155, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(880, 11988.34180, -1129.76868, 11.13921,   0.00000, 0.00000, 232.31807);
	CreateDynamicObject(880, 11991.04883, -1131.48523, 11.13921,   0.00000, 0.00000, 353.27811);
	CreateDynamicObject(868, 11990.08594, -1132.87817, 11.38597,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(868, 11992.34180, -1133.54443, 11.38597,   0.00000, 0.00000, 82.80000);
	CreateDynamicObject(868, 11994.66797, -1133.31213, 11.38597,   0.00000, 0.00000, 31.92002);
	CreateDynamicObject(880, 11995.85840, -1130.73804, 11.13921,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 11998.54004, -1132.18176, 10.55452,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(3865, 12005.95313, -1130.12256, 13.27780,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(880, 11997.45898, -1129.27771, 11.13921,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 12000.86621, -1130.05859, 10.83620,   0.00000, 0.00000, 313.95718);
	CreateDynamicObject(868, 12003.37500, -1133.00659, 11.38597,   0.00000, 0.00000, 82.80000);
	CreateDynamicObject(897, 12010.64160, -1128.06360, 8.03785,   0.00000, 0.00000, 283.88992);
	CreateDynamicObject(880, 12007.04785, -1131.88000, 11.13921,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(824, 12001.23145, -1127.49963, 11.59861,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(880, 12016.27832, -1131.56445, 11.13921,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(880, 12012.92969, -1129.63379, 12.16425,   0.00000, 0.00000, 311.23550);
	CreateDynamicObject(3565, 11982.01563, -1159.92175, 12.74370,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3565, 11970.73828, -1154.74829, 12.76372,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3565, 11981.98340, -1154.88977, 12.76372,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3865, 11965.10449, -1157.90515, 13.27780,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3570, 11970.70410, -1159.83765, 12.69900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3565, 11990.09375, -1154.88574, 12.76370,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3570, 11981.98926, -1157.38745, 12.69900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11967.59082, -1160.41589, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 11967.31055, -1161.43066, 11.56304,   0.00000, 0.00000, 329.85135);
	CreateDynamicObject(816, 11963.34570, -1161.32104, 11.55479,   0.00000, 0.00000, 310.98569);
	CreateDynamicObject(816, 11962.60254, -1162.68896, 11.56200,   0.00000, 0.00000, 223.35310);
	CreateDynamicObject(728, 11971.98438, -1133.37708, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11970.28906, -1133.42798, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 11968.07324, -1133.80750, 9.11687,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(728, 11964.16699, -1133.61304, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11966.15723, -1134.08679, 11.49690,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3865, 11976.49805, -1157.78027, 13.27780,   0.00000, 0.00000, 1.02000);
	CreateDynamicObject(3565, 11959.27832, -1154.72229, 12.76372,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3570, 11959.28320, -1157.33435, 12.75900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3565, 11959.26953, -1159.82336, 12.74370,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 12004.40430, -1192.04138, 11.38340,   0.00000, 0.00000, 89.46005);
	CreateDynamicObject(3565, 11990.10547, -1157.41345, 12.70370,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3565, 11970.73926, -1157.22729, 12.76372,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3570, 11990.08887, -1159.95337, 12.69900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11963.55469, -1159.93994, 11.55479,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11966.44922, -1161.15088, 11.23947,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11966.41113, -1160.78748, 11.23947,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11966.33105, -1154.54858, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11963.43164, -1154.39136, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11963.24219, -1153.80518, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11966.71582, -1152.93054, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.81836, -1154.52698, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.80762, -1154.56116, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.88281, -1155.10193, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.65527, -1155.04565, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11978.81641, -1155.37634, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.89551, -1155.70215, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.88477, -1161.36255, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.61816, -1161.26624, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.64258, -1160.82605, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.64551, -1160.34570, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.94922, -1160.68262, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11974.99219, -1160.16260, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11975.36328, -1154.78564, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.27930, -1154.66174, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11975.46094, -1161.00586, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(816, 11977.09473, -1160.75964, 11.54663,   0.00000, 0.00000, 321.66147);
	CreateDynamicObject(8078, 12018.15625, -1171.53992, 15.24780,   0.00000, 0.00000, 179.35831);
	CreateDynamicObject(8883, 12015.39941, -1157.31726, 14.99080,   0.00000, 0.00000, 269.15851);
	CreateDynamicObject(816, 12005.55664, -1160.74500, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12005.66992, -1159.83008, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.34180, -1159.13391, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.77246, -1158.48303, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.88672, -1157.48535, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.67383, -1153.81897, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.53613, -1154.73059, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.71289, -1155.90674, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.20898, -1155.78882, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12005.87500, -1152.21008, 11.76199,   0.00000, 0.00000, 352.81442);
	CreateDynamicObject(816, 12004.05371, -1151.39307, 11.68200,   0.00000, 0.00000, 352.81439);
	CreateDynamicObject(819, 12005.02344, -1150.48132, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(819, 12005.25684, -1159.14685, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(819, 12005.36133, -1155.01123, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(819, 12005.15527, -1154.84802, 10.53499,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(819, 12000.93750, -1150.10657, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(819, 11993.45605, -1151.09595, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(823, 12013.54102, -1157.63098, 11.59916,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(823, 12014.39844, -1154.84082, 11.59916,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(823, 12018.41211, -1155.18823, 11.59916,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(823, 12018.03613, -1156.55518, 11.59916,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(880, 12018.72461, -1155.09497, 11.74322,   0.00000, 0.00000, 232.41808);
	CreateDynamicObject(880, 12015.24414, -1157.82520, 11.74322,   0.00000, 0.00000, 232.41808);
	CreateDynamicObject(728, 12005.88867, -1154.50269, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.36035, -1155.29260, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.59375, -1156.65881, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.74512, -1157.33142, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.63477, -1160.81360, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12010.07910, -1163.32556, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12007.14063, -1160.08679, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.17578, -1158.95630, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12006.13477, -1157.92419, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12004.24316, -1162.56714, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(728, 12003.40430, -1161.70911, 9.64768,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3722, 12039.18652, -1161.82263, 15.77180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(897, 11984.58301, -1163.53711, 7.14772,   0.00000, 0.00000, 248.47525);
	CreateDynamicObject(897, 11987.03711, -1164.08374, 6.15323,   0.00000, 0.00000, 278.63483);
	CreateDynamicObject(897, 11987.19434, -1165.56604, 6.56134,   0.00000, 0.00000, 248.56674);
	CreateDynamicObject(897, 11984.96582, -1167.08484, 6.56134,   0.00000, 0.00000, 248.56674);
	CreateDynamicObject(897, 11986.01367, -1168.47729, 7.26653,   0.00000, 0.00000, 227.47557);
	CreateDynamicObject(897, 11986.69531, -1172.83521, 7.55034,   0.00000, 0.00000, 211.37300);
	CreateDynamicObject(13590, 12010.04785, -1208.09851, 12.39470,   0.00000, 0.00000, 275.54700);
	CreateDynamicObject(897, 11997.19238, -1209.56580, 7.89734,   0.00000, 0.00000, 265.95691);
	CreateDynamicObject(816, 12007.29004, -1198.83289, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12015.80176, -1197.67041, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12016.37598, -1200.47632, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12014.08301, -1199.15588, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12010.79199, -1200.22205, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12023.85059, -1210.14453, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12024.31250, -1208.23218, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12027.08008, -1210.16101, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12027.35938, -1208.11316, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12021.78906, -1208.25842, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12018.69043, -1208.37878, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12018.17285, -1210.29272, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12021.34473, -1210.31104, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12024.82617, -1200.07507, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12024.21777, -1197.91077, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12025.97363, -1197.08569, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(816, 12032.88574, -1199.79871, 11.76199,   0.00000, 0.00000, 354.19537);
	CreateDynamicObject(874, 12043.97461, -1200.52905, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12032.72754, -1199.15686, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12019.04199, -1199.92114, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12000.92188, -1203.11768, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12005.81543, -1213.84631, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12045.16211, -1209.57104, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(824, 11982.33301, -1106.63977, 10.67619,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(824, 11985.00195, -1106.74182, 10.77004,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(824, 11987.13574, -1105.19543, 10.70139,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(824, 11989.20898, -1106.21143, 10.86458,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(824, 11991.68945, -1106.57983, 11.18211,   0.00000, 0.00000, 343.74722);
	CreateDynamicObject(824, 11995.60840, -1106.63904, 10.85864,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 11999.12305, -1106.63184, 11.59861,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12003.83594, -1105.90332, 11.10375,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12005.36328, -1106.88477, 10.77688,   0.00000, 0.00000, 249.15504);
	CreateDynamicObject(824, 11998.97852, -1106.26001, 11.03555,   0.00000, 0.00000, 333.16940);
	CreateDynamicObject(824, 12007.87598, -1106.67590, 10.92621,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12012.53711, -1106.83655, 10.87391,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12017.41992, -1106.44885, 11.12936,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12021.80469, -1106.02002, 11.59861,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12017.54102, -1104.84924, 11.14966,   0.00000, 0.00000, 250.54483);
	CreateDynamicObject(824, 12011.14063, -1105.91296, 10.85613,   0.00000, 0.00000, 249.85344);
	CreateDynamicObject(824, 12026.08008, -1106.95239, 10.72778,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12030.02441, -1106.00525, 11.01226,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12033.05957, -1106.81689, 10.65573,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12022.38867, -1107.07129, 10.66531,   0.00000, 0.00000, 251.23077);
	CreateDynamicObject(824, 12037.28320, -1106.21362, 10.89561,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12042.03320, -1106.20300, 10.88956,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12038.66016, -1107.65247, 10.49057,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12028.93066, -1107.05042, 10.52250,   0.00000, 0.00000, 251.92809);
	CreateDynamicObject(824, 12046.56641, -1106.08215, 11.19661,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12043.53125, -1107.56311, 10.59260,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12050.19629, -1106.88745, 10.89360,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12052.92480, -1105.65369, 10.78653,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12054.86816, -1107.43860, 10.98851,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12057.65430, -1105.72302, 10.88956,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12061.06836, -1105.05432, 10.89565,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12060.87988, -1107.43030, 10.69159,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12060.66113, -1110.89087, 11.29560,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12060.37402, -1114.39514, 11.59861,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12058.46484, -1117.66028, 10.59059,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12060.39453, -1124.06567, 11.59861,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.80078, -1117.98608, 11.19761,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12058.94434, -1111.53052, 11.19761,   0.00000, 0.00000, 333.67953);
	CreateDynamicObject(824, 12061.09375, -1120.69055, 11.09761,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.29199, -1127.44507, 11.19761,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12061.14551, -1132.07202, 10.99460,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12061.39844, -1135.40857, 10.99761,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.87402, -1139.39612, 11.09661,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.87988, -1144.50146, 11.09661,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12061.00586, -1148.84387, 11.09761,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.73633, -1153.98657, 11.19661,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.40723, -1158.03088, 10.89561,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.69727, -1161.91321, 11.59861,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.61523, -1165.36902, 10.99259,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.61230, -1169.03479, 11.09460,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12060.56934, -1172.80042, 11.05171,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(824, 12062.25391, -1175.22205, 10.44193,   0.00000, 0.00000, 333.85953);
	CreateDynamicObject(827, 12058.70020, -1171.69690, 10.10184,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12058.28027, -1160.59143, 10.58856,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12058.43945, -1149.92908, 10.38957,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12058.84863, -1141.69092, 10.18756,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12058.75195, -1132.59277, 10.59157,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12048.21484, -1109.02356, 9.87846,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12053.32324, -1108.73950, 9.37437,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12040.87305, -1108.79321, 10.08047,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(827, 12021.99707, -1108.10901, 10.31237,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3268, 12030.96875, -1266.62671, 11.38680,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(8483, 11959.93457, -1279.24976, 17.04272,   0.00000, 0.00000, 45.29813);
	CreateDynamicObject(897, 11951.70605, -1279.88452, 15.20721,   0.00000, 0.00000, 183.96663);
	CreateDynamicObject(897, 11958.70898, -1278.03442, 15.20721,   0.00000, 0.00000, 145.77673);
	CreateDynamicObject(897, 11962.63867, -1284.27283, 15.20721,   0.00000, 0.00000, 145.77673);
	CreateDynamicObject(897, 11954.09375, -1286.78979, 15.20721,   0.00000, 0.00000, 224.57410);
	CreateDynamicObject(897, 11951.94336, -1287.59949, 15.20721,   0.00000, 0.00000, 183.96663);
	CreateDynamicObject(897, 11961.43359, -1278.76636, 18.28930,   0.00000, 0.00000, 185.69244);
	CreateDynamicObject(878, 11960.79395, -1269.61816, 12.50304,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, 11970.53125, -1288.52734, 12.50304,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, 11967.92285, -1278.29639, 12.50304,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, 11949.83496, -1269.01306, 12.50304,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11952.74023, -1269.22571, 11.65180,   0.00000, 0.00000, 10.74815);
	CreateDynamicObject(816, 11951.87988, -1264.47009, 11.65180,   0.00000, 0.00000, 10.85563);
	CreateDynamicObject(816, 11955.78027, -1265.39661, 11.65180,   0.00000, 0.00000, 10.96419);
	CreateDynamicObject(816, 11956.50684, -1270.38232, 11.65180,   0.00000, 0.00000, 10.64173);
	CreateDynamicObject(816, 11972.18164, -1268.27209, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11968.11914, -1267.69141, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11966.97070, -1263.51917, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11970.58887, -1265.03491, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11977.97656, -1285.28711, 11.65180,   0.00000, 0.00000, 10.64173);
	CreateDynamicObject(816, 11973.98828, -1284.90063, 11.65180,   0.00000, 0.00000, 10.74815);
	CreateDynamicObject(816, 11972.91113, -1280.92358, 11.65180,   0.00000, 0.00000, 10.85563);
	CreateDynamicObject(816, 11976.58105, -1282.63770, 11.65180,   0.00000, 0.00000, 10.96419);
	CreateDynamicObject(3399, 12028.05078, -1282.69104, 13.97170,   0.00000, 0.00000, 180.14191);
	CreateDynamicObject(3279, 12045.50586, -1250.10205, 11.41580,   0.00000, 0.00000, 270.66577);
	CreateDynamicObject(13648, 12044.14258, -1242.13037, 10.17627,   0.00000, 0.00000, 269.23874);
	CreateDynamicObject(3136, 12187.54395, -1213.81909, 5.53270,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(10230, 12190.95605, -1215.53284, 7.02542,   0.00000, 0.00000, 93.53346);
	CreateDynamicObject(7621, 12194.10254, -1227.09167, 5.69158,   0.00000, 0.00000, 94.46518);
	CreateDynamicObject(8078, 12188.53027, -1193.77039, 5.80601,   0.00000, 0.00000, 3.78371);
	CreateDynamicObject(16093, 12027.15039, -1244.55396, 11.45750,   0.00000, 0.00000, 177.74130);
	CreateDynamicObject(3885, 12011.84668, -1242.88293, 12.04186,   0.00000, 0.00000, 167.36879);
	CreateDynamicObject(3885, 11985.75391, -1242.87476, 12.04186,   0.00000, 0.00000, 167.36879);
	CreateDynamicObject(3885, 11999.45508, -1242.67102, 12.04186,   0.00000, 0.00000, 167.36879);
	CreateDynamicObject(3267, 11986.05762, -1242.84302, 12.07990,   0.00000, 0.00000, 18.42786);
	CreateDynamicObject(3267, 12011.83301, -1242.70386, 12.07990,   0.00000, 0.00000, 317.83871);
	CreateDynamicObject(3267, 11999.55664, -1242.50745, 12.07990,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(689, 11931.04297, -1289.60852, -11.78521,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11929.26855, -1274.06982, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11927.77148, -1258.04236, -11.54320,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11927.78418, -1241.61719, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11930.83301, -1227.42615, 1.56365,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.04199, -1205.33167, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.12500, -1188.90637, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.32715, -1172.14136, -4.06187,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11930.57031, -1153.58704, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11930.16309, -1139.94434, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11929.79395, -1124.23730, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.52734, -1110.66809, 1.75287,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11935.01563, -1093.11194, 1.86084,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11952.25781, -1088.44836, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11967.17480, -1088.25574, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11982.07129, -1087.96594, 1.96773,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11997.09668, -1088.42542, 2.07357,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12012.56152, -1087.83008, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12031.01367, -1086.13684, 2.17836,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12046.92676, -1086.21252, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12062.06543, -1091.90918, 2.28212,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12077.53320, -1097.48340, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12080.26074, -1112.60022, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12079.81250, -1128.42310, 2.38484,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.09375, -1218.72034, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11931.73730, -1310.62024, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11948.38281, -1309.46802, -3.30265,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11962.96973, -1313.74390, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11978.12109, -1309.59387, -3.46226,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 11994.52539, -1314.41431, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12009.07617, -1304.01245, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12021.70020, -1312.34875, -3.62344,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12036.80859, -1303.22144, 10.65731,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12048.76465, -1311.05212, -3.78625,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12065.22070, -1304.49475, -4.11677,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12072.32520, -1291.43628, -3.95069,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(689, 12078.57520, -1273.86548, 10.65731,   0.00000, 0.00000, 354.81061);
	CreateDynamicObject(655, 12075.38477, -1262.71350, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12070.51758, -1250.95984, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12072.82520, -1233.51331, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12069.10742, -1225.35535, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12077.47949, -1222.83862, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12072.51465, -1240.29163, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12079.38770, -1209.87500, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12070.50000, -1205.11780, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12068.74219, -1216.14307, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12079.36426, -1195.03442, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12069.76563, -1194.75842, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(655, 12066.75879, -1170.64783, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(689, 12076.09082, -1155.05005, 2.48655,   0.00000, 0.00000, 0.61520);
	CreateDynamicObject(655, 12079.99219, -1172.09705, 11.36659,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 12029.07227, -1237.83691, 11.65180,   0.00000, 0.00000, 296.15186);
	CreateDynamicObject(816, 12033.75879, -1231.77087, 11.65180,   0.00000, 0.00000, 296.78412);
	CreateDynamicObject(816, 12020.08984, -1220.43481, 11.65180,   0.00000, 0.00000, 297.40997);
	CreateDynamicObject(816, 11983.91992, -1255.51050, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11997.44727, -1267.09521, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11992.64063, -1273.41211, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11983.91992, -1210.35791, 11.65180,   0.00000, 0.00000, 349.87698);
	CreateDynamicObject(816, 11997.44727, -1221.49194, 11.65180,   0.00000, 0.00000, 349.77576);
	CreateDynamicObject(816, 11992.64063, -1227.35217, 11.65180,   0.00000, 0.00000, 349.67349);
	CreateDynamicObject(816, 11961.55664, -1210.55334, 11.65180,   0.00000, 0.00000, 339.75397);
	CreateDynamicObject(816, 11974.70313, -1221.85022, 11.65180,   0.00000, 0.00000, 339.55151);
	CreateDynamicObject(816, 11969.50488, -1227.87769, 11.65180,   0.00000, 0.00000, 339.34698);
	CreateDynamicObject(816, 12008.20801, -1231.33203, 11.65180,   0.00000, 0.00000, 349.77576);
	CreateDynamicObject(816, 12013.38086, -1275.97180, 11.65180,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(816, 11961.72559, -1238.27747, 11.65180,   0.00000, 0.00000, 339.34698);
	CreateDynamicObject(896, 12086.69238, -1179.45679, 5.83295,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12090.31543, -1121.75354, 6.44388,   0.00000, 0.00000, 316.26212);
	CreateDynamicObject(896, 12091.22949, -1081.97131, 5.63408,   0.00000, 0.00000, 353.54742);
	CreateDynamicObject(896, 12093.32813, -1305.96423, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12092.50488, -1313.61621, 6.75142,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12089.78906, -1321.37256, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12094.82129, -1282.60974, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12094.00781, -1289.99658, 6.75142,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12091.31348, -1297.48230, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12092.91504, -1258.16113, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12092.00684, -1265.22131, 6.75142,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12089.21484, -1272.37549, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12094.50488, -1233.46606, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12093.58691, -1240.09668, 6.75142,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12090.79004, -1246.81262, 5.93858,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12089.90137, -1210.47729, 5.10730,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12088.96484, -1216.82483, 5.91183,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12086.15332, -1223.25305, 5.09059,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12091.30371, -1190.50586, 5.10730,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12090.42676, -1196.56042, 5.91183,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12087.68555, -1202.69128, 5.09059,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12090.26074, -1108.62354, 6.87726,   0.00000, 0.00000, 352.26108);
	CreateDynamicObject(896, 12090.36523, -1090.33960, 6.43773,   0.00000, 0.00000, 316.06442);
	CreateDynamicObject(896, 12089.00098, -1098.56006, 5.62591,   0.00000, 0.00000, 353.35196);
	CreateDynamicObject(896, 12090.37500, -1133.17517, 5.83503,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12089.47070, -1173.52832, 6.64683,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12090.24414, -1163.34033, 7.08225,   0.00000, 0.00000, 358.84329);
	CreateDynamicObject(896, 12088.32910, -1154.43506, 5.83295,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(896, 12089.56641, -1143.81177, 6.64683,   0.00000, 0.00000, 322.77905);
	CreateDynamicObject(896, 12060.37891, -1075.09314, 5.63408,   0.00000, 0.00000, 353.54742);
	CreateDynamicObject(896, 12090.31543, -1121.75354, 6.44388,   0.00000, 0.00000, 316.26212);
	CreateDynamicObject(896, 11973.36523, -1074.27368, 6.31906,   0.00000, 0.00000, 267.47693);
	CreateDynamicObject(896, 11963.56836, -1073.66235, 5.06213,   0.00000, 0.00000, 268.41855);
	CreateDynamicObject(896, 11927.35059, -1078.07227, 5.88505,   0.00000, 0.00000, 231.44632);
	CreateDynamicObject(896, 12060.37891, -1075.09314, 5.63408,   0.00000, 0.00000, 353.54742);
	CreateDynamicObject(896, 11953.51074, -1077.46021, 6.29639,   0.00000, 0.00000, 266.87515);
	CreateDynamicObject(896, 11936.86133, -1074.49878, 5.98665,   0.00000, 0.00000, 225.54112);
	CreateDynamicObject(896, 12073.16895, -1322.39941, 7.37471,   0.00000, 0.00000, 1.93896);
	CreateDynamicObject(896, 12040.00781, -1077.41406, 6.43773,   0.00000, 0.00000, 316.06442);
	CreateDynamicObject(896, 12086.55371, -1073.63611, 6.87726,   0.00000, 0.00000, 352.26108);
	CreateDynamicObject(896, 12077.26270, -1073.05151, 5.62591,   0.00000, 0.00000, 353.35196);
	CreateDynamicObject(896, 12055.18164, -1075.68494, 6.43773,   0.00000, 0.00000, 316.06442);
	CreateDynamicObject(896, 12046.91113, -1076.16052, 5.62591,   0.00000, 0.00000, 353.35196);
	CreateDynamicObject(896, 12068.78418, -1076.93921, 6.87726,   0.00000, 0.00000, 352.26108);
	CreateDynamicObject(896, 11983.65430, -1077.67322, 6.83528,   0.00000, 0.00000, 311.99509);
	CreateDynamicObject(896, 12029.87402, -1073.89966, 7.27880,   0.00000, 0.00000, 348.15112);
	CreateDynamicObject(896, 12020.27734, -1073.31348, 6.03146,   0.00000, 0.00000, 349.20087);
	CreateDynamicObject(896, 11997.88281, -1075.94458, 6.84733,   0.00000, 0.00000, 311.87189);
	CreateDynamicObject(896, 11989.29492, -1076.41699, 6.03961,   0.00000, 0.00000, 349.11740);
	CreateDynamicObject(896, 12010.84277, -1077.19238, 7.29510,   0.00000, 0.00000, 347.98422);
	CreateDynamicObject(896, 11946.50586, -1076.14014, 6.29639,   0.00000, 0.00000, 266.87515);
	CreateDynamicObject(896, 11918.68262, -1312.18921, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(896, 11920.24707, -1290.85938, 7.37471,   0.00000, 0.00000, 291.28506);
	CreateDynamicObject(896, 11918.83594, -1301.88196, 5.71545,   0.00000, 0.00000, 282.64923);
	CreateDynamicObject(896, 11917.72363, -1076.56604, 5.05079,   0.00000, 0.00000, 268.11835);
	CreateDynamicObject(896, 11920.58398, -1278.80042, 7.37471,   0.00000, 0.00000, 291.12854);
	CreateDynamicObject(896, 11917.06543, -1108.73755, 5.71545,   0.00000, 0.00000, 257.14676);
	CreateDynamicObject(896, 11921.08301, -1084.07336, 7.37471,   0.00000, 0.00000, 265.47098);
	CreateDynamicObject(896, 11919.13281, -1097.29028, 7.37471,   0.00000, 0.00000, 265.47098);
	CreateDynamicObject(896, 11918.53613, -1126.81360, 7.37471,   0.00000, 0.00000, 322.71280);
	CreateDynamicObject(896, 11915.19531, -1118.88208, 5.05079,   0.00000, 0.00000, 324.79355);
	CreateDynamicObject(896, 11918.65625, -1246.83374, 5.71545,   0.00000, 0.00000, 270.93771);
	CreateDynamicObject(896, 11921.79883, -1138.43848, 7.37471,   0.00000, 0.00000, 276.85791);
	CreateDynamicObject(896, 11919.89844, -1152.12061, 7.37471,   0.00000, 0.00000, 276.97189);
	CreateDynamicObject(896, 11919.35156, -1182.11243, 7.37471,   0.00000, 0.00000, 334.32877);
	CreateDynamicObject(896, 11916.06934, -1174.65515, 5.05079,   0.00000, 0.00000, 336.52567);
	CreateDynamicObject(896, 11917.16406, -1236.61108, 7.37471,   0.00000, 0.00000, 348.68515);
	CreateDynamicObject(896, 11917.61328, -1227.70398, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(896, 11917.76758, -1217.04614, 5.71545,   0.00000, 0.00000, 282.64923);
	CreateDynamicObject(896, 11919.18262, -1205.67004, 7.37471,   0.00000, 0.00000, 291.28506);
	CreateDynamicObject(896, 11919.52344, -1193.25439, 7.37471,   0.00000, 0.00000, 291.12854);
	CreateDynamicObject(896, 11917.72656, -1162.62561, 5.71545,   0.00000, 0.00000, 268.48111);
	CreateDynamicObject(896, 11919.31738, -1272.82202, 7.37471,   0.00000, 0.00000, 291.12854);
	CreateDynamicObject(896, 11918.18750, -1263.26074, 7.37471,   0.00000, 0.00000, 291.12854);
	CreateDynamicObject(896, 11918.37988, -1260.63708, 7.37471,   0.00000, 0.00000, 291.12854);
	CreateDynamicObject(896, 12082.31738, -1323.58264, 5.05079,   0.00000, 0.00000, 4.56644);
	CreateDynamicObject(896, 12086.58887, -1323.63464, 6.43173,   0.00000, 0.00000, 29.53106);
	CreateDynamicObject(896, 12047.84277, -1323.73657, 7.37471,   0.00000, 0.00000, 1.55957);
	CreateDynamicObject(896, 12061.64648, -1323.17151, 6.43173,   0.00000, 0.00000, 29.14778);
	CreateDynamicObject(896, 12054.18066, -1323.19580, 5.05079,   0.00000, 0.00000, 3.61322);
	CreateDynamicObject(896, 11917.98047, -1322.53845, 7.37471,   0.00000, 0.00000, 348.68515);
	CreateDynamicObject(896, 11924.18555, -1322.01111, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(896, 12010.63086, -1322.59595, 6.43173,   0.00000, 0.00000, 28.16128);
	CreateDynamicObject(896, 12021.79590, -1321.81494, 7.37471,   0.00000, 0.00000, 1.00452);
	CreateDynamicObject(896, 12034.10449, -1322.97888, 6.43173,   0.00000, 0.00000, 28.02195);
	CreateDynamicObject(896, 12029.94336, -1322.95850, 5.05079,   0.00000, 0.00000, 3.42813);
	CreateDynamicObject(896, 11954.52637, -1322.33826, 6.43173,   0.00000, 0.00000, 16.08464);
	CreateDynamicObject(896, 11930.79883, -1321.93530, 6.43173,   0.00000, 0.00000, 16.02464);
	CreateDynamicObject(896, 11941.72070, -1321.13416, 7.37471,   0.00000, 0.00000, 348.68515);
	CreateDynamicObject(896, 11949.62793, -1322.25610, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(896, 11973.61719, -1322.47192, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(896, 11967.04199, -1322.99146, 7.37471,   0.00000, 0.00000, 348.68515);
	CreateDynamicObject(896, 11980.59180, -1322.40430, 6.43173,   0.00000, 0.00000, 16.08464);
	CreateDynamicObject(896, 11991.86621, -1321.61108, 7.37471,   0.00000, 0.00000, 348.68515);
	CreateDynamicObject(896, 12005.03613, -1322.82349, 6.43173,   0.00000, 0.00000, 16.08464);
	CreateDynamicObject(896, 12000.50195, -1322.74963, 5.05079,   0.00000, 0.00000, 350.92560);
	CreateDynamicObject(819, 12007.91309, -1198.24475, 10.12895,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(874, 12058.50488, -1238.90991, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12046.04199, -1237.76428, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12054.39648, -1248.47546, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12052.93555, -1287.60852, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12058.20313, -1290.35925, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12058.66113, -1282.07129, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12008.69434, -1289.55518, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 12017.43066, -1249.70605, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(874, 11988.22266, -1267.93970, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(16093, 11971.20508, -1242.61353, 11.45750,   0.00000, 0.00000, 177.74130);
	CreateDynamicObject(3565, 12026.29102, -1257.40503, 12.79070,   0.00000, 0.00000, 269.27905);
	CreateDynamicObject(874, 12021.43359, -1283.51233, 11.56462,   0.00000, 0.00000, 239.14496);
	CreateDynamicObject(1225, 11990.32031, -1243.12561, 11.91258,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 11975.12012, -1241.01978, 11.81217,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 12015.70410, -1210.10254, 12.00503,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 11978.59277, -1152.98059, 11.90697,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 11951.34766, -1129.13232, 11.82890,   0.00000, 0.00000, 0.00000);

	// Leo - Carrabien War
	CreateDynamicObject(18751, -266.23047, 9348.50781, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -274.17719, 9384.26563, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -138.39578, 9426.62793, -3.08523,   0.00000, 0.00000, 2.29731);
	CreateDynamicObject(18751, -122.69980, 9351.19434, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -129.21146, 9386.97266, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -179.08643, 9425.86230, -3.08523,   0.00000, 0.00000, 2.23731);
	CreateDynamicObject(18751, -163.79727, 9350.42285, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -170.70039, 9386.19531, -3.06520,   0.00000, 0.00000, 2.41730);
	CreateDynamicObject(18751, -220.16286, 9425.09082, -3.08523,   0.00000, 0.00000, 2.29731);
	CreateDynamicObject(18751, -205.28442, 9349.64648, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -212.62180, 9385.41406, -3.08523,   0.00000, 0.00000, 2.35731);
	CreateDynamicObject(18751, -251.13411, 9424.51074, -3.08523,   0.00000, 0.00000, 2.17731);
	CreateDynamicObject(18751, -236.56549, 9349.06250, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -244.18210, 9384.76563, -3.08523,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(9958, -259.31491, 9385.49805, 8.52030,   -4.00000, 4.00000, 43.57040);
	CreateDynamicObject(18751, -137.86740, 9470.98633, -7.79058,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -181.79228, 9471.66797, -7.28918,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -222.36931, 9470.79785, -7.11869,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -339.73862, 9359.58398, -7.57279,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -333.86734, 9311.74902, -7.47838,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -300.39838, 9274.44824, -7.28918,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -256.44910, 9272.93652, -7.22275,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -207.52660, 9280.30273, -7.32578,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -159.72284, 9287.48340, -7.63089,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -120.75961, 9289.08887, -7.22275,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -54.40243, 9296.28125, -7.11662,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -51.90670, 9343.71973, -7.28918,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -60.66424, 9386.67773, -7.10951,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -70.36985, 9420.79688, -7.06334,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(18751, -123.22417, 9466.73145, -4.77902,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(19463, -125.40120, 9361.74707, 6.14500,   0.00000, 0.00000, 5.72020);
	CreateDynamicObject(19463, -127.17370, 9380.88086, 6.14500,   0.00000, 0.00000, 5.03750);
	CreateDynamicObject(19463, -124.44020, 9352.15918, 6.14500,   0.00000, 0.00000, 5.72020);
	CreateDynamicObject(19463, -126.32590, 9371.33398, 6.14500,   0.00000, 0.00000, 5.33750);
	CreateDynamicObject(19463, -127.17370, 9380.82129, 2.64480,   0.00000, 0.00000, 5.03750);
	CreateDynamicObject(19463, -126.32590, 9371.25391, 2.64480,   0.00000, 0.00000, 5.03750);
	CreateDynamicObject(19463, -125.38590, 9361.63379, 9.63220,   0.00000, 0.00000, 5.69880);
	CreateDynamicObject(19463, -124.44020, 9352.17871, 2.64480,   0.00000, 0.00000, 5.72020);
	CreateDynamicObject(19463, -124.92220, 9375.01172, 7.69270,   0.00000, 90.00000, 184.43040);
	CreateDynamicObject(19463, -123.47240, 9342.60645, 6.14500,   0.00000, 0.00000, 5.93570);
	CreateDynamicObject(19463, -123.47240, 9342.60645, 2.64480,   0.00000, 0.00000, 5.93570);
	CreateDynamicObject(19463, -120.57880, 9388.10156, 6.14070,   0.00000, 0.00000, 268.23331);
	CreateDynamicObject(19463, -108.85920, 9339.52930, 6.14110,   0.00000, -0.08000, 276.65161);
	CreateDynamicObject(19463, -117.63930, 9357.82227, 4.82190,   -37.00000, 90.00000, 276.70111);
	CreateDynamicObject(19463, -122.11600, 9346.42578, 7.68970,   0.00000, 90.00000, 185.20010);
	CreateDynamicObject(19463, -118.25180, 9338.42676, 6.14110,   0.00000, -0.08000, 276.65161);
	CreateDynamicObject(19463, -118.25180, 9338.42676, 2.64480,   0.00000, 0.00000, 276.65161);
	CreateDynamicObject(19463, -108.86850, 9339.53125, 2.64480,   0.00000, 0.00000, 276.65161);
	CreateDynamicObject(19463, -120.54964, 9388.12891, 2.70480,   0.00000, 0.00000, 268.26801);
	CreateDynamicObject(19463, -104.46430, 9344.79492, 2.66480,   0.00000, 0.00000, 183.69730);
	CreateDynamicObject(19463, -104.45520, 9344.79492, 6.14070,   0.00000, 0.00000, 183.73730);
	CreateDynamicObject(19463, -105.07760, 9354.32324, 2.68480,   0.00000, 0.00000, 183.73730);
	CreateDynamicObject(19463, -105.06410, 9354.41016, 6.14070,   0.00000, 0.00000, 183.73730);
	CreateDynamicObject(19463, -105.68350, 9363.89551, 6.14070,   0.00000, 0.00000, 183.73730);
	CreateDynamicObject(19463, -105.68880, 9363.70801, 2.66480,   0.00000, 0.00000, 183.73730);
	CreateDynamicObject(19463, -106.07540, 9373.23340, -0.67886,   0.00000, 0.00000, 180.91040);
	CreateDynamicObject(19463, -106.05740, 9373.42188, 6.14070,   0.00000, 0.00000, 180.88210);
	CreateDynamicObject(19463, -106.22330, 9382.85645, -0.75350,   0.00000, 0.00000, 180.91040);
	CreateDynamicObject(19463, -106.22050, 9382.88281, 6.14070,   0.00000, 0.00000, 180.88210);
	CreateDynamicObject(19463, -111.00200, 9387.81934, -0.79420,   0.00000, 0.00000, 268.26801);
	CreateDynamicObject(19463, -111.00340, 9387.81934, 6.14070,   0.00000, 0.00000, 268.27328);
	CreateDynamicObject(19463, -111.00200, 9387.81934, 2.68480,   0.00000, 0.00000, 268.26801);
	CreateDynamicObject(19463, -106.22330, 9382.85645, 2.70480,   0.00000, 0.00000, 180.91040);
	CreateDynamicObject(19463, -106.07540, 9373.23340, 2.70480,   0.00000, 0.00000, 180.91040);
	CreateDynamicObject(19463, -123.04370, 9355.99219, 7.68970,   0.00000, 90.00000, 185.91420);
	CreateDynamicObject(19463, -124.04280, 9365.50879, 7.68970,   0.00000, 90.00000, 186.15109);
	CreateDynamicObject(3524, -127.56911, 9385.73047, 5.91272,   0.00000, 0.00000, 205.53258);
	CreateDynamicObject(3524, -125.39449, 9388.24902, 5.91272,   0.00000, 0.00000, 263.08102);
	CreateDynamicObject(19417, -125.08910, 9358.53418, 2.67440,   0.00000, 0.00000, 5.94850);
	CreateDynamicObject(19417, -125.72240, 9364.88477, 2.66630,   0.00000, 0.00000, 5.28240);
	CreateDynamicObject(19417, -125.43570, 9361.70313, 2.66430,   0.00000, 0.00000, 5.91130);
	CreateDynamicObject(19417, -115.12620, 9338.76563, 9.63220,   0.00000, 0.00000, 276.56589);
	CreateDynamicObject(19417, -121.44040, 9338.06348, 9.63220,   0.00000, 0.00000, 276.40591);
	CreateDynamicObject(19417, -118.28270, 9338.41895, 9.63220,   0.00000, 0.00000, 276.56589);
	CreateDynamicObject(19417, -123.47380, 9342.55469, 9.63220,   0.00000, 0.00000, 4.94290);
	CreateDynamicObject(19417, -123.16350, 9339.40527, 9.63220,   0.00000, 0.00000, 6.14290);
	CreateDynamicObject(19417, -123.79020, 9345.73242, 9.63220,   0.00000, 0.00000, 6.02290);
	CreateDynamicObject(19417, -124.11060, 9348.91504, 9.63220,   0.00000, 0.00000, 5.44290);
	CreateDynamicObject(19417, -124.42170, 9352.08008, 9.63220,   0.00000, 0.00000, 5.82290);
	CreateDynamicObject(19417, -124.74410, 9355.25000, 9.63220,   0.00000, 0.00000, 5.70290);
	CreateDynamicObject(19417, -125.98650, 9367.96777, 9.63220,   0.00000, 0.00000, 5.46290);
	CreateDynamicObject(19417, -126.28620, 9371.13281, 9.63220,   0.00000, 0.00000, 5.50290);
	CreateDynamicObject(19417, -126.57790, 9374.27246, 9.63220,   0.00000, 0.00000, 5.12150);
	CreateDynamicObject(19417, -126.86870, 9377.42090, 9.63220,   0.00000, 0.00000, 4.99180);
	CreateDynamicObject(906, -105.20586, 9370.58496, -0.20459,   0.00000, -342.00000, 86.06364);
	CreateDynamicObject(906, -125.08412, 9362.82910, -0.04590,   0.00000, -342.00000, 86.06364);
	CreateDynamicObject(18751, -60.66434, 9386.71777, -7.10951,   0.00000, 0.00000, 2.41731);
	CreateDynamicObject(19463, -118.43800, 9340.20801, 7.68970,   0.00000, 91.00000, 276.00000);
	CreateDynamicObject(19312, -194.21065, 9378.79688, 3.15656,   0.00000, 0.00000, 185.08008);
	CreateDynamicObject(18751, -138.26068, 9456.70410, -4.77902,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(18751, -160.22379, 9460.03516, -4.77902,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(18751, -185.42268, 9455.06445, -4.77902,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(18751, -214.79976, 9458.30566, -4.77902,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(18751, -242.74477, 9457.56836, -4.79133,   0.00000, 0.00000, 5.20495);
	CreateDynamicObject(18751, -300.81213, 9345.34961, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -289.05804, 9321.61816, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -271.62256, 9316.70703, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -207.05598, 9318.84082, -4.74332,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -230.08206, 9310.61914, -4.99131,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -210.51941, 9312.97168, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -191.75877, 9318.70801, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -167.75470, 9320.70410, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -147.47723, 9318.10547, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -126.78502, 9317.20801, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -109.02751, 9321.35254, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -93.83227, 9332.01270, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -91.06723, 9351.91113, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -90.45621, 9373.41211, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -96.14186, 9391.91895, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -99.90556, 9408.00879, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -105.87647, 9431.10840, -5.44649,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -106.02422, 9451.72754, -4.46238,   0.00000, 0.00000, 319.16089);
	CreateDynamicObject(18751, -190.37759, 9428.85547, -2.50682,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -92.78098, 9355.85938, -4.92614,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(19304, -95.70309, 9336.89941, 2.38331,   0.00000, 0.00000, 276.51367);
	CreateDynamicObject(19304, -95.70309, 9336.89941, 1.18274,   0.00000, 0.00000, 276.45987);
	CreateDynamicObject(11556, -298.25867, 9402.52832, -5.98525,   0.00000, 0.00000, 101.44650);
	CreateDynamicObject(11556, -299.88815, 9476.86426, -6.79996,   0.00000, 0.00000, 203.14389);
	CreateDynamicObject(11556, -294.02795, 9366.25781, -7.61468,   0.00000, 0.00000, 125.52126);
	CreateDynamicObject(11556, -289.32245, 9337.47461, -8.13660,   0.00000, 0.00000, 125.52126);
	CreateDynamicObject(11556, -251.64009, 9308.65430, -6.85568,   0.00000, 0.00000, 134.09213);
	CreateDynamicObject(19313, -293.52408, 9417.59082, 1.29580,   4.00000, -47.00000, 285.00000);
	CreateDynamicObject(19313, -293.08017, 9423.64258, 0.88531,   4.00000, -47.00000, 263.04483);
	CreateDynamicObject(11556, -276.85864, 9318.88086, -8.28752,   0.00000, 0.00000, 125.52126);
	CreateDynamicObject(11556, -201.30878, 9301.75488, -5.00000,   0.00000, 0.00000, 204.46590);
	CreateDynamicObject(11556, -232.03632, 9278.04004, -5.63156,   0.00000, 0.00000, 254.14774);
	CreateDynamicObject(11556, -148.21494, 9298.18750, -6.94005,   0.00000, 0.00000, 269.74936);
	CreateDynamicObject(11556, -91.15370, 9334.45898, -7.91094,   0.00000, 0.00000, 246.03369);
	CreateDynamicObject(11556, -87.55209, 9389.63281, -7.91094,   0.00000, 0.00000, 246.03369);
	CreateDynamicObject(11556, -95.07047, 9422.49805, -6.82868,   0.00000, 0.00000, 249.49918);
	CreateDynamicObject(11556, -134.09415, 9483.57324, -7.09903,   0.00000, 0.00000, 246.02066);
	CreateDynamicObject(11556, -185.57660, 9479.12500, -6.44450,   0.00000, 0.00000, 239.05919);
	CreateDynamicObject(11556, -231.48723, 9476.13965, -6.33112,   0.00000, 0.00000, 218.70007);
	CreateDynamicObject(11556, -302.57767, 9456.04590, -8.09585,   0.00000, 0.00000, 190.13391);
	CreateDynamicObject(16675, -150.13873, 9234.77832, -10.15495,   0.00000, 0.00000, 259.98523);
	CreateDynamicObject(6052, -215.90096, 9318.35156, 2.70354,   0.00000, 0.00000, 104.84555);
	CreateDynamicObject(619, -196.56903, 9445.94824, -1.41539,   0.00000, 0.00000, 332.87323);
	CreateDynamicObject(619, -204.07195, 9309.05859, -0.05847,   0.00000, 0.00000, 343.85944);
	CreateDynamicObject(619, -184.51022, 9448.02246, 0.38067,   0.00000, 0.00000, 252.26260);
	CreateDynamicObject(619, -126.37904, 9315.02637, -0.96851,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(619, -233.63324, 9309.16699, -1.04956,   0.00000, 0.00000, 50.98328);
	CreateDynamicObject(624, -124.84432, 9452.66406, -0.52869,   0.00000, 0.00000, 5.96263);
	CreateDynamicObject(624, -102.84715, 9397.73145, -0.12265,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(624, -214.05258, 9444.91797, -0.52869,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(624, -283.39496, 9332.83984, -1.41861,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(620, -159.87241, 9313.30078, -3.28199,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(620, -108.64201, 9316.05371, -1.24509,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(624, -284.54340, 9372.71777, -0.75872,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(619, -103.70287, 9388.03613, 0.29331,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(619, -257.51163, 9318.35254, -2.79701,   0.00000, 0.00000, 100.61223);
	CreateDynamicObject(619, -285.47195, 9384.69336, 1.74003,   0.00000, 0.00000, 316.30798);
	CreateDynamicObject(620, -190.08928, 9309.60645, -6.73473,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(3887, -139.73920, 9416.22559, 8.24443,   0.00000, 0.00000, 19.10810);
	CreateDynamicObject(6052, -203.47382, 9349.25684, 4.28979,   0.00000, 0.00000, 283.93979);
	CreateDynamicObject(6296, -259.82040, 9338.09082, 4.14740,   0.00000, 0.00000, 2.72030);
	CreateDynamicObject(619, -105.07854, 9408.61133, -0.79435,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(624, -104.88550, 9419.38379, -0.12265,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(624, -107.26735, 9443.98047, -0.12265,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(619, -107.19583, 9430.63574, -0.52193,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(619, -114.86282, 9450.60840, -2.26303,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(624, -148.84221, 9451.78711, -0.42566,   0.00000, 0.00000, 5.65962);
	CreateDynamicObject(619, -138.39294, 9453.20410, 1.08380,   0.00000, 0.00000, 204.48567);
	CreateDynamicObject(619, -161.99118, 9450.19043, -1.61292,   0.00000, 0.00000, 204.48567);
	CreateDynamicObject(624, -172.87181, 9450.67383, -0.32365,   0.00000, 0.00000, 5.96263);
	CreateDynamicObject(619, -228.52733, 9443.46777, 0.56644,   0.00000, 0.00000, 332.87323);
	CreateDynamicObject(624, -244.18781, 9443.15137, -1.16887,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(619, -283.24844, 9361.92090, -0.36827,   0.00000, 0.00000, 316.30798);
	CreateDynamicObject(624, -284.38956, 9351.39941, -1.66491,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(619, -282.60626, 9341.84277, -0.54416,   0.00000, 0.00000, 316.30798);
	CreateDynamicObject(619, -274.96603, 9326.70898, -1.51074,   0.00000, 0.00000, 355.93765);
	CreateDynamicObject(624, -265.22910, 9321.37695, -4.24293,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(624, -244.87962, 9312.83594, -0.32158,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(624, -222.07458, 9308.55078, -0.32158,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(619, -176.17509, 9311.04395, 0.24454,   0.00000, 0.00000, 64.92317);
	CreateDynamicObject(619, -137.40025, 9314.89844, -0.26556,   0.00000, 0.00000, 64.92317);
	CreateDynamicObject(619, -96.86150, 9317.70801, -1.93375,   0.00000, 0.00000, 123.42203);
	CreateDynamicObject(620, -95.91325, 9335.50977, -1.56674,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(619, -98.52988, 9349.28223, 0.52207,   0.00000, 0.00000, 123.22103);
	CreateDynamicObject(620, -97.98302, 9368.15820, -4.10104,   0.00000, 0.00000, 344.77158);
	CreateDynamicObject(6296, -260.23160, 9356.20117, 3.84439,   0.00000, 0.00000, 2.72030);
	CreateDynamicObject(12911, -182.35593, 9398.32910, -2.00017,   0.00000, 0.00000, 13.00337);
	CreateDynamicObject(3615, -136.88759, 9326.01953, 2.20239,   0.00000, 0.00000, 90.67270);
	CreateDynamicObject(3615, -137.24934, 9338.60840, 2.23402,   0.00000, 0.00000, 91.41063);
	CreateDynamicObject(1736, -125.93130, 9363.28516, 7.33490,   0.00000, 0.00000, 270.65280);
	CreateDynamicObject(1736, -123.52680, 9339.45117, 7.33490,   0.00000, 0.00000, 267.95541);
	CreateDynamicObject(1736, -124.61260, 9349.94922, 7.33490,   0.00000, 0.00000, 270.65280);
	CreateDynamicObject(1736, -127.74330, 9383.07227, 7.33490,   0.00000, 0.00000, 270.65280);
	CreateDynamicObject(1736, -126.98550, 9374.42578, 7.33490,   0.00000, 0.00000, 270.65280);
	CreateDynamicObject(12911, -181.81342, 9367.33398, -2.40217,   0.00000, 0.00000, 13.00337);
	CreateDynamicObject(8535, -226.50179, 9413.67969, 7.58130,   0.00000, 0.00000, 1.60210);
	CreateDynamicObject(2985, -213.61649, 9407.76465, 7.39480,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2985, -245.61986, 9370.94434, 8.06970,   0.00000, 0.00000, 16.78033);
	CreateDynamicObject(2985, -250.75020, 9376.38379, 7.57650,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3471, -213.19580, 9404.47754, 8.03470,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3471, -213.60370, 9427.25488, 8.03470,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2985, -213.96300, 9422.81934, 7.35900,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3264, -226.52547, 9366.65234, 1.36783,   0.00000, 0.00000, 135.36159);
	CreateDynamicObject(8550, -178.16785, 9326.51074, 4.88580,   0.00000, 0.00000, 320.86172);
	CreateDynamicObject(16770, -216.82487, 9414.06738, 9.06753,   0.00000, 0.00000, 1.23859);
	CreateDynamicObject(18248, -260.91791, 9417.50195, 10.35050,   0.00000, 0.00000, 6.43918);
	CreateDynamicObject(873, -157.89011, 9321.92285, 0.93526,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(873, -126.98786, 9320.97461, 0.93526,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(873, -112.10378, 9347.55957, 1.34028,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(873, -125.37969, 9320.98730, 0.93526,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(873, -201.72366, 9320.28613, 0.32005,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(873, -200.35066, 9317.00879, 0.32005,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, -247.81583, 9340.46191, 1.50216,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, -246.57970, 9338.40625, 1.50216,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(878, -248.61832, 9336.69336, 1.50216,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(856, -281.06589, 9375.93652, 0.11153,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(856, -283.01587, 9378.95605, 0.11153,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(856, -281.24353, 9336.66113, -1.37326,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(856, -280.82266, 9337.64941, -1.37326,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -117.35947, 9441.68164, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -115.82442, 9441.51953, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -115.19580, 9439.48438, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -117.47047, 9439.71191, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -117.35947, 9441.68164, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -107.36817, 9428.15820, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -117.47047, 9439.71191, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -105.65847, 9409.99414, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -102.85159, 9398.05664, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(761, -101.74245, 9389.54102, 0.93718,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(19313, -132.07928, 9312.79004, 4.40141,   0.00000, 0.00000, 5.18071);
	CreateDynamicObject(18751, -253.14662, 9315.36621, -4.79133,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -266.99527, 9361.65918, -3.83224,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -182.95888, 9389.80957, -3.52005,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -185.75833, 9408.66016, -2.52156,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -166.59784, 9319.48242, -4.05392,   0.00000, 0.00000, 29.89235);
	CreateDynamicObject(18751, -101.20339, 9397.44434, -5.39295,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -121.01234, 9329.60156, -3.82092,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -243.42598, 9330.78418, -3.92088,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -172.77226, 9426.99316, -2.50682,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -207.41061, 9433.28125, -3.11284,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -132.07495, 9422.44824, -3.21792,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -147.83510, 9391.12109, -3.21792,   0.00000, 0.00000, 348.24759);
	CreateDynamicObject(18751, -140.78011, 9367.64844, -3.21792,   0.00000, 0.00000, 348.24759);

	// Leo - Isla de Tierra
	CreateDynamicObject(6959, 3499.10010, 1279.69995, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3540.39941, 1279.69922, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3581.70020, 1279.69922, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3499.09546, 1239.83960, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3499.10010, 1199.89990, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3540.39941, 1239.79883, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3540.39941, 1199.89844, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3581.70020, 1239.79883, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(6959, 3581.70020, 1199.89844, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(2990, 3478.39990, 1284.50000, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1294.59998, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3493.39990, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3483.50000, 1179.90002, 33.80000,   0.00000, 0.00000, 179.99451);
	CreateDynamicObject(2990, 3602.39990, 1194.69995, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1184.80005, 33.80000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(2990, 3587.19995, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3597.30005, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98352);
	CreateDynamicObject(2990, 3503.29980, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3513.19971, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3523.09961, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3532.99951, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3542.89941, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3552.79932, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3562.69922, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3572.59912, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3582.49902, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3592.39893, 1179.90002, 33.80000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(2990, 3597.30005, 1179.90002, 33.80000,   0.00000, 0.00000, 179.99451);
	CreateDynamicObject(2990, 3602.39990, 1204.59985, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1214.49976, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1224.39966, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1234.29956, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1244.19946, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1254.09937, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1263.99927, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1273.89917, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39990, 1283.79907, 33.80000,   0.00000, 0.00000, 269.99451);
	CreateDynamicObject(2990, 3602.39941, 1293.69824, 33.80000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(2990, 3602.39990, 1294.59998, 33.80000,   0.00000, 0.00000, 269.98901);
	CreateDynamicObject(2990, 3577.09985, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3566.99976, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3556.89966, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3546.79956, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3536.69946, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3526.59937, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3516.49927, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3506.39917, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3496.29907, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3486.19897, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98901);
	CreateDynamicObject(2990, 3483.50000, 1299.69995, 33.80000,   0.00000, 0.00000, 359.98352);
	CreateDynamicObject(2990, 3478.39990, 1274.40002, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1264.30005, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1254.20007, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1244.10010, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1234.00012, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1223.90015, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1213.80017, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1203.70020, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1193.60022, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(2990, 3478.39990, 1184.80005, 33.80000,   0.00000, 0.00000, 90.00000);
	CreateDynamicObject(12814, 3463.50000, 1204.69995, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(12814, 3463.39990, 1254.69995, 29.90000,   0.00000, 0.00000, 180.25000);
	CreateDynamicObject(12814, 3463.30005, 1304.30005, 29.90000,   0.00000, 0.00000, 0.24719);
	CreateDynamicObject(12814, 3463.39990, 1174.80005, 29.90000,   0.00000, 0.00000, 180.00000);
	CreateDynamicObject(12814, 3503.19995, 1314.50000, 29.90000,   0.00000, 0.00000, 90.24719);
	CreateDynamicObject(12814, 3553.10010, 1314.69995, 29.90000,   0.00000, 0.00000, 270.24719);
	CreateDynamicObject(12814, 3603.10010, 1314.80005, 29.90000,   0.00000, 0.00000, 90.24719);
	CreateDynamicObject(12814, 3617.39990, 1275.00000, 29.90000,   0.00000, 0.00000, 180.24719);
	CreateDynamicObject(12814, 3607.30005, 1314.90002, 29.90000,   0.00000, 0.00000, 90.24719);
	CreateDynamicObject(12814, 3617.39990, 1225.00000, 29.90000,   0.00000, 0.00000, 0.24170);
	CreateDynamicObject(12814, 3617.39990, 1175.09998, 29.90000,   0.00000, 0.00000, 180.24170);
	CreateDynamicObject(12814, 3577.50000, 1165.00000, 29.90000,   0.00000, 0.00000, 270.24170);
	CreateDynamicObject(12814, 3527.60010, 1164.80005, 29.90000,   0.00000, 0.00000, 90.23621);
	CreateDynamicObject(12814, 3503.30005, 1165.00000, 29.90000,   0.00000, 0.00000, 270.23071);
	CreateDynamicObject(617, 3610.10010, 1168.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3467.69995, 1169.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3468.10010, 1307.90002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3609.69995, 1308.40002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3609.69995, 1279.59998, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3609.69995, 1250.79993, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3609.69995, 1221.99988, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3609.69995, 1193.19983, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3584.00000, 1168.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3557.89990, 1168.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3531.79980, 1168.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3505.69971, 1168.50000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3467.69995, 1199.69995, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3467.69995, 1229.89990, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3467.69995, 1260.09985, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3467.10010, 1283.00000, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3496.50000, 1307.90002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3524.89990, 1307.90002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3553.29980, 1307.90002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(617, 3581.69971, 1307.90002, 29.90000,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(16098, 3510.08765, 1238.27478, 34.41330,   0.00000, 0.00000, 0.71009);
	CreateDynamicObject(16098, 3571.26563, 1239.02527, 34.41330,   0.00000, 0.00000, 0.71010);
	CreateDynamicObject(16098, 3550.65479, 1238.77722, 34.41330,   0.00000, 0.00000, 0.71010);
	CreateDynamicObject(16098, 3530.27197, 1238.51782, 34.41330,   0.00000, 0.00000, 0.71009);
	CreateDynamicObject(11502, 3494.12549, 1209.58167, 29.85545,   0.00000, 0.00000, 359.57245);
	CreateDynamicObject(11502, 3493.17847, 1267.13025, 29.85545,   0.00000, 0.00000, 1.52947);
	CreateDynamicObject(3243, 3579.86548, 1282.02234, 29.75342,   0.00000, 0.00000, 280.64594);
	CreateDynamicObject(3243, 3502.61865, 1282.68945, 29.75342,   0.00000, 0.00000, 89.21557);
	CreateDynamicObject(3243, 3540.17432, 1282.36987, 29.75342,   0.00000, 0.00000, 177.52141);
	CreateDynamicObject(3243, 3580.76611, 1197.47461, 29.75340,   0.00000, 0.00000, 277.69009);
	CreateDynamicObject(3243, 3504.76660, 1197.48206, 29.75340,   0.00000, 0.00000, 69.44350);
	CreateDynamicObject(3243, 3540.95093, 1197.31140, 29.75340,   0.00000, 0.00000, 1.33010);
	CreateDynamicObject(16409, 3587.18506, 1261.89063, 29.54890,   0.00000, 0.00000, 88.92880);
	CreateDynamicObject(16409, 3589.91431, 1216.39771, 29.54890,   0.00000, 0.00000, 270.61719);
	CreateDynamicObject(19455, 3511.50659, 1221.23962, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19455, 3531.51050, 1227.72046, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19455, 3551.25366, 1227.50818, 29.56340,   0.00000, 0.00000, 0.51770);
	CreateDynamicObject(19455, 3531.26880, 1215.34924, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19455, 3565.48950, 1221.70471, 29.56340,   0.00000, 0.00000, 0.09705);
	CreateDynamicObject(19455, 3551.14893, 1215.51501, 29.56340,   0.00000, 0.00000, 0.51353);
	CreateDynamicObject(19455, 3563.93286, 1255.85632, 29.56340,   0.00000, 0.00000, 0.09705);
	CreateDynamicObject(19455, 3552.23706, 1249.75195, 29.56340,   0.00000, 0.00000, 0.09700);
	CreateDynamicObject(19455, 3552.22388, 1262.05542, 29.56340,   0.00000, 0.00000, 0.09700);
	CreateDynamicObject(19455, 3531.52808, 1261.76428, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19455, 3531.36133, 1249.56470, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19455, 3519.73047, 1255.82642, 29.56340,   0.00000, 0.00000, 359.07681);
	CreateDynamicObject(19336, 3540.05542, 1316.90625, 30.07590,   0.00000, 0.00000, 358.97971);
	CreateDynamicObject(826, 3490.15063, 1288.32178, 29.29576,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3486.12964, 1287.65430, 29.49054,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3487.86597, 1287.49841, 29.38648,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3492.91187, 1190.28271, 29.26647,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3489.87842, 1190.21631, 29.26647,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3488.60083, 1191.04932, 29.26647,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3490.21875, 1191.81470, 29.26647,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3591.63110, 1196.25305, 29.15615,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3589.92578, 1194.60339, 29.45916,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3592.17969, 1194.62939, 29.15615,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3591.91577, 1192.32031, 29.15615,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3590.77344, 1288.10742, 29.16081,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3589.95117, 1284.09314, 29.16081,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3592.81323, 1284.88611, 29.16081,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3591.56030, 1283.28235, 29.16081,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3560.86719, 1242.19617, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3561.63965, 1238.74512, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3561.16284, 1240.56213, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3560.93408, 1237.20020, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3559.49902, 1239.38708, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3562.80396, 1240.40857, 28.90913,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3524.34961, 1237.60083, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3520.11523, 1237.45557, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3520.06201, 1235.57434, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3519.64111, 1239.23657, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3521.08887, 1240.75806, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3518.45410, 1241.05518, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3518.14355, 1238.30090, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(864, 3521.60059, 1237.91089, 29.02313,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3472, 3478.54590, 1299.53540, 29.13270,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3472, 3602.33838, 1299.64209, 29.13270,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3472, 3478.51123, 1179.92578, 28.94420,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(3472, 3602.26587, 1179.92615, 28.97820,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3601.15723, 1232.75623, 29.79800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3601.18579, 1238.02637, 29.79800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3599.88257, 1235.11584, 29.79800,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3574.43311, 1266.01257, 29.80630,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3479.30103, 1205.49536, 29.82520,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(933, 3479.52002, 1208.67126, 29.82520,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3512.81738, 1245.13977, 30.16709,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3514.20850, 1245.23938, 30.16709,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3513.55981, 1245.21240, 30.16709,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3574.51270, 1245.91077, 30.20400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3575.39087, 1245.88977, 30.20200,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3576.22217, 1245.81323, 30.20400,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3577.01953, 1211.47583, 30.17472,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3576.12012, 1211.46143, 30.17472,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3575.40405, 1211.59741, 30.17472,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3507.17529, 1231.49780, 30.18078,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3505.87329, 1231.34644, 30.18078,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(1225, 3506.48193, 1231.76025, 30.18078,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(17030, 3451.85474, 1327.43298, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3451.99219, 1298.16565, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3451.86035, 1269.52002, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3451.89941, 1238.03918, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3452.05762, 1207.71631, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3460.98779, 1153.03723, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3450.41919, 1175.60303, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3489.97681, 1152.99353, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3450.84790, 1174.73596, 17.00706,   0.00000, 0.00000, 321.20203);
	CreateDynamicObject(17030, 3521.57251, 1152.74951, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3548.99072, 1152.56775, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3580.80151, 1153.36377, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3627.92993, 1189.56970, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3607.89893, 1152.95776, 15.36523,   0.00000, 0.00000, 49.51345);
	CreateDynamicObject(17030, 3626.80518, 1160.01318, 13.19488,   0.00000, 0.00000, 141.90233);
	CreateDynamicObject(17030, 3627.55225, 1166.81653, 13.19488,   0.00000, 0.00000, 141.90233);
	CreateDynamicObject(17030, 3628.08301, 1177.84778, 13.19488,   0.00000, 0.00000, 141.90233);
	CreateDynamicObject(17030, 3628.56470, 1211.39099, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3628.15063, 1216.14490, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3627.69971, 1242.19189, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3627.44531, 1251.30896, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3627.32227, 1274.44800, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3627.21118, 1286.02087, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3627.51758, 1305.20715, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3618.82275, 1323.88416, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3626.96411, 1309.02917, 13.19488,   0.00000, 0.00000, 138.25220);
	CreateDynamicObject(17030, 3608.62061, 1324.56226, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3593.37476, 1324.09583, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3571.48218, 1324.77649, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3560.04126, 1324.72876, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3536.32251, 1326.14539, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3510.10376, 1325.79089, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(17030, 3480.21069, 1325.93591, 14.19169,   0.00000, 0.00000, 224.09984);
	CreateDynamicObject(8397, 3559.83691, 1282.43604, 40.24788,   0.00000, 0.00000, 89.04458);
	CreateDynamicObject(8397, 3521.50952, 1196.89441, 40.24788,   0.00000, 0.00000, 89.04458);
	CreateDynamicObject(826, 3561.87207, 1198.55518, 29.38764,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3563.20752, 1197.34827, 29.38764,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3561.22974, 1194.02893, 29.38764,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3481.47266, 1237.69983, 29.04711,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3481.37671, 1235.93042, 29.04711,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3481.36865, 1240.21838, 29.04711,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3480.94873, 1242.44580, 29.04711,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3510.07373, 1264.50745, 28.87950,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3511.05835, 1264.99854, 28.57648,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3520.15576, 1283.73682, 29.05626,   0.00000, 0.00000, 359.69391);
	CreateDynamicObject(826, 3520.87939, 1283.87854, 29.05626,   0.00000, 0.00000, 359.69391);
	CreateDynamicObject(826, 3519.85278, 1286.52966, 29.05626,   0.00000, 0.00000, 359.69391);
	CreateDynamicObject(826, 3521.87695, 1286.54199, 29.05626,   0.00000, 0.00000, 359.69391);
	CreateDynamicObject(826, 3599.65405, 1246.37378, 28.98447,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3600.41797, 1246.75549, 28.98447,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3599.08301, 1247.38843, 28.98447,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3494.88306, 1261.17224, 28.88951,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3494.10620, 1262.16418, 28.88951,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3497.95459, 1261.76147, 28.88951,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3495.75903, 1218.59424, 28.76480,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3495.51367, 1217.52795, 28.76480,   0.00000, 0.00000, 0.00000);
	CreateDynamicObject(826, 3493.13916, 1218.23584, 28.76480,   0.00000, 0.00000, 0.00000);

	return 1;
}

RemoveBuildings(playerid)
{
	RemoveBuildingForPlayer(playerid, 785, 2431.3750, -657.0859, 119.6094, 0.25);
	RemoveBuildingForPlayer(playerid, 693, 2349.4844, -680.8750, 136.6328, 0.25);
	RemoveBuildingForPlayer(playerid, 694, 2358.8984, -616.1172, 130.6719, 0.25);
	RemoveBuildingForPlayer(playerid, 696, 2375.3047, -666.7266, 131.8828, 0.25);
	RemoveBuildingForPlayer(playerid, 791, 2431.3750, -657.0859, 119.6094, 0.25);

	return 1;
}

AntiDeAMX()
{
    new a[][] =
    {
        "Unarmed (Fist)",
        "Brass K"
    };
    #pragma unused a
}

Float:DistanceCameraTargetToLocation(Float:CamX, Float:CamY, Float:CamZ, Float:ObjX, Float:ObjY, Float:ObjZ, Float:FrX, Float:FrY, Float:FrZ) {

	new Float:TGTDistance;

	TGTDistance = floatsqroot((CamX - ObjX) * (CamX - ObjX) + (CamY - ObjY) * (CamY - ObjY) + (CamZ - ObjZ) * (CamZ - ObjZ));

	new Float:tmpX, Float:tmpY, Float:tmpZ;

	tmpX = FrX * TGTDistance + CamX;
	tmpY = FrY * TGTDistance + CamY;
	tmpZ = FrZ * TGTDistance + CamZ;

	return floatsqroot((tmpX - ObjX) * (tmpX - ObjX) + (tmpY - ObjY) * (tmpY - ObjY) + (tmpZ - ObjZ) * (tmpZ - ObjZ));
}

stock Float:GetPointAngleToPoint(Float:x2, Float:y2, Float:X, Float:Y) {

  new Float:DX, Float:DY;
  new Float:angle;

  DX = floatabs(floatsub(x2,X));
  DY = floatabs(floatsub(y2,Y));

  if (DY == 0.0 || DX == 0.0) {
    if(DY == 0 && DX > 0) angle = 0.0;
    else if(DY == 0 && DX < 0) angle = 180.0;
    else if(DY > 0 && DX == 0) angle = 90.0;
    else if(DY < 0 && DX == 0) angle = 270.0;
    else if(DY == 0 && DX == 0) angle = 0.0;
  }
  else {
    angle = atan(DX/DY);

    if(X > x2 && Y <= y2) angle += 90.0;
    else if(X <= x2 && Y < y2) angle = floatsub(90.0, angle);
    else if(X < x2 && Y >= y2) angle -= 90.0;
    else if(X >= x2 && Y > y2) angle = floatsub(270.0, angle);
  }

  return floatadd(angle, 90.0);
}

stock GetXYInFrontOfPoint(&Float:x, &Float:y, Float:angle, Float:distance) {
	x += (distance * floatsin(-angle, degrees));
	y += (distance * floatcos(-angle, degrees));
}

stock IsPlayerAimingAt(playerid, Float:x, Float:y, Float:z, Float:radius) {
  	new Float:camera_x,Float:camera_y,Float:camera_z,Float:vector_x,Float:vector_y,Float:vector_z;
  	GetPlayerCameraPos(playerid, camera_x, camera_y, camera_z);
  	GetPlayerCameraFrontVector(playerid, vector_x, vector_y, vector_z);

	new Float:vertical, Float:horizontal;

	switch (GetPlayerWeapon(playerid)) {
	  case 34,35,36: {
	  if (DistanceCameraTargetToLocation(camera_x, camera_y, camera_z, x, y, z, vector_x, vector_y, vector_z) < radius) return true;
	  return false;
	  }
	  case 30,31: {vertical = 4.0; horizontal = -1.6;}
	  case 33: {vertical = 2.7; horizontal = -1.0;}
	  default: {vertical = 6.0; horizontal = -2.2;}
	}

	new Float:angle = GetPointAngleToPoint(0, 0, floatsqroot(vector_x*vector_x+vector_y*vector_y), vector_z) - 270.0;
  	new Float:resize_x, Float:resize_y, Float:resize_z = floatsin(angle+vertical, degrees);
  	GetXYInFrontOfPoint(resize_x, resize_y, GetPointAngleToPoint(0, 0, vector_x, vector_y)+horizontal, floatcos(angle+vertical, degrees));

  	if (DistanceCameraTargetToLocation(camera_x, camera_y, camera_z, x, y, z, resize_x, resize_y, resize_z) < radius) return true;
  	return false;
}

stock IsPlayerAimingAtPlayer(playerid, targetplayerid) {
  new Float:x, Float:y, Float:z;
  GetPlayerPos(targetplayerid, x, y, z);
  return IsPlayerAimingAt(playerid, x, y, z, 30);
}

stock IPCheck(string[], type, playerid, undercheck = 0)
{
    new
        dotCount,
        underCount
    ;
    for(new i; string[i] != EOS; ++i)
    {
        if(('0' <= string[i] <= '9') || string[i] == '.' || string[i] == ':')
        {
            if((string[i] == '.') && (string[i + 1] != '.') && ('0' <= string[i - 1] <= '9'))
            {
                ++dotCount;
            }

            if(!undercheck) continue;

            else if((string[i] == '_') && (string[i + 1] != '_') && ('0' <= string[i - 1] <= '9'))
            {
                ++underCount;
            }
            continue;
        }
    }

    if(dotCount > 2 || underCount > 2)
    {
    	switch(type)
    	{
    		case 0:
    		{
    			formatex(g_string, "[SERVER]: "COL_GRAY"%s <%d> {FFFFFF}has been kicked from the server. Reason: "COL_YELLOW"Advertising in main chat{FFFFFF}.", playerName(playerid), playerid);
    			SendClientMessageToAll(COLOR_SERVER, g_string);
    		}

    		case 1:
    		{
    			formatex(g_string, "[SERVER]: "COL_GRAY"%s <%d> {FFFFFF}has been kicked from the server. Reason: "COL_YELLOW"Advertising in PM{FFFFFF}.", playerName(playerid), playerid);
    			SendClientMessageToAll(COLOR_SERVER, g_string);
    		}

    		case 2:
    		{
    			formatex(g_string, "[SERVER]: "COL_GRAY"%s <%d> {FFFFFF}has been kicked from the server. Reason: "COL_YELLOW"Advertising in team chat{FFFFFF}.", playerName(playerid), playerid);
    			SendClientMessageToAll(COLOR_SERVER, g_string);
    		}
    	}

    	Kick(playerid);
    	return 1;
   	}

    return 0;
}

public OnPlayerAchieve(playerid, achid)
{
	if((achid == sAchievements[aKill][0]) || (achid == sAchievements[aHeadshot][0]) || (achid == sAchievements[aMark][0]))
	{
		IncreasePlayerScore(playerid, 1);
		GivePlayerMoney(playerid, 1000);
	}

	else if((achid == sAchievements[aKill][1]) || (achid == sAchievements[aHeadshot][1]) || (achid == sAchievements[aMark][1]))
	{
		IncreasePlayerScore(playerid, 1);
		GivePlayerMoney(playerid, 1000);
	}

	else if((achid == sAchievements[aKill][2]) || (achid == sAchievements[aHeadshot][2]) || (achid == sAchievements[aMark][2]))
	{
		IncreasePlayerScore(playerid, 2);
		GivePlayerMoney(playerid, 1500);
	}

	else if((achid == sAchievements[aKill][3]) || (achid == sAchievements[aHeadshot][3]) || (achid == sAchievements[aMark][3]))
	{
		IncreasePlayerScore(playerid, 3);
		GivePlayerMoney(playerid, 2000);
	}

	else if((achid == sAchievements[aKill][4]) || (achid == sAchievements[aHeadshot][4]) || (achid == sAchievements[aMark][4]))
	{
		IncreasePlayerScore(playerid, 4);
		GivePlayerMoney(playerid, 2500);
	}

	else if((achid == sAchievements[aKill][5]) || (achid == sAchievements[aHeadshot][5]) || (achid == sAchievements[aMark][5]))
	{
		IncreasePlayerScore(playerid, 5);
		GivePlayerMoney(playerid, 2750);
	}

	else if((achid == sAchievements[aKill][6]) || (achid == sAchievements[aHeadshot][6]) || (achid == sAchievements[aMark][6]))
	{
		IncreasePlayerScore(playerid, 5);
		GivePlayerMoney(playerid, 3000);
	}

	else if((achid == sAchievements[aKill][7]) || (achid == sAchievements[aHeadshot][7]) || (achid == sAchievements[aMark][7]))
	{
		IncreasePlayerScore(playerid, 6);
		GivePlayerMoney(playerid, 3500);
	}

	else if((achid == sAchievements[aKill][8]) || (achid == sAchievements[aHeadshot][8]) || (achid == sAchievements[aMark][8]))
	{
		IncreasePlayerScore(playerid, 6);
		GivePlayerMoney(playerid, 3750);
	}

	else if((achid == sAchievements[aKill][9]) || (achid == sAchievements[aHeadshot][9]) || (achid == sAchievements[aMark][9]))
	{
		IncreasePlayerScore(playerid, 7);
		GivePlayerMoney(playerid, 4000);
	}

	else if((achid == sAchievements[aKill][10]) || (achid == sAchievements[aHeadshot][10]) || (achid == sAchievements[aMark][10]))
	{
		IncreasePlayerScore(playerid, 7);
		GivePlayerMoney(playerid, 4500);
	}

	else if((achid == sAchievements[aKill][11]) || (achid == sAchievements[aHeadshot][11]) || (achid == sAchievements[aMark][11]))
	{
		IncreasePlayerScore(playerid, 8);
		GivePlayerMoney(playerid, 5000);
	}

	else if((achid == sAchievements[aKill][12]) || (achid == sAchievements[aHeadshot][12]) || (achid == sAchievements[aMark][12]))
	{
		IncreasePlayerScore(playerid, 8);
		GivePlayerMoney(playerid, 6000);
	}

	else if((achid == sAchievements[aKill][13]) || (achid == sAchievements[aHeadshot][13]) || (achid == sAchievements[aMark][13]))
	{
		IncreasePlayerScore(playerid, 10);
		GivePlayerMoney(playerid, 10000);
	}

	else if((achid == sAchievements[aKill][14]) || (achid == sAchievements[aHeadshot][14]) || (achid == sAchievements[aMark][14]))
	{
		IncreasePlayerScore(playerid, 15);
		GivePlayerMoney(playerid, 15000);
	}

	else if((achid == sAchievements[aKill][15]) || (achid == sAchievements[aHeadshot][15]) || (achid == sAchievements[aMark][15]))
	{
		IncreasePlayerScore(playerid, 20);
		GivePlayerMoney(playerid, 20000);
	}

	else if((achid == sAchievements[aKill][16]) || (achid == sAchievements[aHeadshot][16]) || (achid == sAchievements[aMark][16]))
	{
		IncreasePlayerScore(playerid, 25);
		GivePlayerMoney(playerid, 30000);
	}

	else if((achid == sAchievements[aKill][17]) || (achid == sAchievements[aHeadshot][17]) || (achid == sAchievements[aMark][17]))
	{
		IncreasePlayerScore(playerid, 30);
		GivePlayerMoney(playerid, 40000);
	}

	else if((achid == sAchievements[aKill][18]) || (achid == sAchievements[aHeadshot][18]) || (achid == sAchievements[aMark][18]))
	{
		IncreasePlayerScore(playerid, 40);
		GivePlayerMoney(playerid, 50000);
	}

	else if((achid == sAchievements[aKill][19]) || (achid == sAchievements[aHeadshot][19]) || (achid == sAchievements[aMark][19]))
	{
		IncreasePlayerScore(playerid, 50);
		GivePlayerMoney(playerid, 50000);
	}

	else if((achid == sAchievements[aKill][20]) || (achid == sAchievements[aHeadshot][20]) || (achid == sAchievements[aMark][20]))
	{
		IncreasePlayerScore(playerid, 100);
		GivePlayerMoney(playerid, 50000);
	}

	else if((achid == sAchievements[aKill][21]) || (achid == sAchievements[aHeadshot][21]) || (achid == sAchievements[aMark][21]))
	{
		IncreasePlayerScore(playerid, 500);
		GivePlayerMoney(playerid, 50000);
	}

	else if((achid == sAchievements[aKill][22]) || (achid == sAchievements[aHeadshot][22]) || (achid == sAchievements[aMark][22]))
	{
		IncreasePlayerScore(playerid, 1000);
		GivePlayerMoney(playerid, 50000);
	}

	else if(achid == sAchievements[aTime][0])
	{
		IncreasePlayerScore(playerid, 1);
		GivePlayerMoney(playerid, 1000);
	}

	else if(achid == sAchievements[aTime][1])
	{
		IncreasePlayerScore(playerid, 2);
		GivePlayerMoney(playerid, 1500);
	}

	else if(achid == sAchievements[aTime][2])
	{
		IncreasePlayerScore(playerid, 3);
		GivePlayerMoney(playerid, 2000);
	}

	else if(achid == sAchievements[aTime][3])
	{
		IncreasePlayerScore(playerid, 4);
		GivePlayerMoney(playerid, 2500);
	}

	else if(achid == sAchievements[aTime][4])
	{
		IncreasePlayerScore(playerid, 5);
		GivePlayerMoney(playerid, 3000);
	}

	else if(achid == sAchievements[aTime][5])
	{
		IncreasePlayerScore(playerid, 6);
		GivePlayerMoney(playerid, 3500);
	}

	else if(achid == sAchievements[aTime][6])
	{
		IncreasePlayerScore(playerid, 10);
		GivePlayerMoney(playerid, 10000);
	}

	else if(achid == sAchievements[aTime][7])
	{
		IncreasePlayerScore(playerid, 20);
		GivePlayerMoney(playerid, 10000);
	}

	else if(achid == sAchievements[aTime][8])
	{
		IncreasePlayerScore(playerid, 45);
		GivePlayerMoney(playerid, 20000);
	}

	else if(achid == sAchievements[aTime][9])
	{
		IncreasePlayerScore(playerid, 75);
		GivePlayerMoney(playerid, 30000);
	}

	else if(achid == sAchievements[aTime][10])
	{
		IncreasePlayerScore(playerid, 100);
		GivePlayerMoney(playerid, 50000);
	}

	else if(achid == sAchievements[aTime][11])
	{
		IncreasePlayerScore(playerid, 250);
		GivePlayerMoney(playerid, 75000);
	}

	else if(achid == sAchievements[aTime][12])
	{
		IncreasePlayerScore(playerid, 500);
		GivePlayerMoney(playerid, 100000);
	}

	else if(achid == sAchievements[aTime][13])
	{
		IncreasePlayerScore(playerid, 2000);
		GivePlayerMoney(playerid, 500000);
	}

	else if(achid == sAchievements[aLowHealth])
	{
		IncreasePlayerScore(playerid, 5);
		GivePlayerMoney(playerid, 5000);
	}

	else if(achid == sAchievements[aFirstSpawn])
	{
		IncreasePlayerScore(playerid, 1);
		GivePlayerMoney(playerid, 5000);
	}

	return 1;
}

stock IsNumeric(const string[]) {
	new length=strlen(string);
	if (length==0) return false;
	for (new i = 0; i < length; i++) {
		if (
		(string[i] > '9' || string[i] < '0' && string[i]!='-' && string[i]!='+') // Not a number,'+' or '-'
		|| (string[i]=='-' && i!=0)                                             // A '-' but not at first.
		|| (string[i]=='+' && i!=0)                                             // A '+' but not at first.
		) return false;
	}
	if (length==1 && (string[0]=='-' || string[0]=='+')) return false;
	return true;
}

