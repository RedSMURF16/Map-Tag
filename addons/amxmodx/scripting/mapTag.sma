/*
*
*	Map Tag by RedSMURF
*
*
*	Description:
*   This plugin lets admins draw freehand lines on the map using beams, perfect for signatures, tags, or simple shapes.
*   Holding +drawline while moving draws a continuous stroke; releasing and pressing again starts a new stroke without
*   connecting it to the previous one. Drawings are saved per map and automatically loaded on every map start.
*
*	Cvars:
*		maptag_line                            "Enable/disable line rendering (0/1)."
*		maptag_beam_width                      "Beam width."
*		maptag_beam_noise                      "Beam noise/jitter."
*		maptag_beam_color                      "Beam color (R G B A)."
*		maptag_beam_color_random               "Enable random color cycling (0/1)."
*		maptag_beam_color_frequency            "Frequency (seconds) of random color change."
*		maptag_beam_color_mode                 "Color mode (0 - Unified, 1 - Random per segment)."
*
*	Commands:
*       +drawline / -drawline       "Hold to draw, release to lift the pen."
*       maptag_clear                "Clears the current drawing."
*       maptag_save                 "Saves the current drawing to file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define MAPTAG_TAG "^4[MAP TAG]^1"
#define MAX_POINTS 512

new g_cvarLine, g_cvarWidth, g_cvarNoise, g_cvarColor, g_cvarColorRandom, g_cvarColorFreq, g_cvarColorMode,
    bool:g_bLine, g_iWidth, g_iNoise, g_iColor[4], bool:g_bColorRandom, Float:g_fColorFreq, g_iColorMode

new Float:g_fPoints[MAX_POINTS][3], bool:g_bStroke[MAX_POINTS], g_iPoints
new g_szBeamSprite[] = "sprites/lgtning.spr"
new g_iBeamSprite
new bool:g_bDrawing[MAX_PLAYERS + 1], bool:g_bHolding[MAX_PLAYERS + 1], g_iCounter[MAX_PLAYERS + 1]
new Float:g_fNextRandom

public plugin_init()
{
    register_plugin("Map Tag", "1.0", "RedSMURF")

    register_clcmd("+maptag", "cmdMapTag", ADMIN_RCON)
    register_clcmd("-maptag", "cmdMapTag", ADMIN_RCON)
    register_clcmd("maptag_clear", "cmdClear", ADMIN_RCON)
    register_clcmd("maptag_save", "cmdSave", ADMIN_RCON)
    g_cvarLine          = register_cvar("maptag_line", "1")
    g_cvarWidth         = register_cvar("maptag_beam_width", "100")
    g_cvarNoise         = register_cvar("maptag_beam_noise", "0")
    g_cvarColor         = register_cvar("maptag_beam_color", "212 175 55 255")
    g_cvarColorRandom   = register_cvar("maptag_beam_color_random", "0")
    g_cvarColorFreq     = register_cvar("maptag_beam_color_frequency", "1.0")
    g_cvarColorMode     = register_cvar("maptag_beam_color_mode", "0")          // 0 - Unified, 1 - Random

    cvarCache()
    hook_cvar_change(g_cvarLine,        "cvarUpdate")
    hook_cvar_change(g_cvarWidth,       "cvarUpdate")
    hook_cvar_change(g_cvarNoise,       "cvarUpdate")
    hook_cvar_change(g_cvarColor,       "cvarUpdate")
    hook_cvar_change(g_cvarColorRandom, "cvarUpdate")
    hook_cvar_change(g_cvarColorFreq,   "cvarUpdate")
    hook_cvar_change(g_cvarColorMode,   "cvarUpdate")

    RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    set_task(0.1, "lineTask", .flags = "b")
    loadData()
}

public plugin_precache()
{
    g_iBeamSprite = precache_model(g_szBeamSprite)
}

public cmdMapTag(id, iLevel, iCid)
{
	if( !cmd_access(id, iLevel, iCid, 1)
    || !is_user_alive(id) )
		return PLUGIN_HANDLED

	static szArg[2]
	read_argv(0, szArg, 1)
	switch(szArg[0])
	{
		case '+': g_bDrawing[id] = true
		case '-': g_bDrawing[id] = false
	}

	return PLUGIN_HANDLED
}

public cmdClear(id, iLevel, iCid)
{
    if( !cmd_access(id, iLevel, iCid, 1) )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iPoints; i ++ )
        g_bStroke[i] = false
    g_iPoints = 0

    return PLUGIN_HANDLED
}

public cmdSave(id, iLevel, iCid)
{
    if( !cmd_access(id, iLevel, iCid, 1) )
        return PLUGIN_HANDLED

    new szFile[128], szData[64], iFile
    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_MapTag.ini", szFile)
    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iPoints; i ++ )
    {
        formatex(szData, charsmax(szData), "%.2f %.2f %.2f %d^n", g_fPoints[i][0], g_fPoints[i][1], g_fPoints[i][2], g_bStroke[i])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%s %s ^4%s", MAPTAG_TAG, "MapTag data saved in", szFile)
    fclose(iFile)

    return PLUGIN_HANDLED
}

stock loadData()
{
    new szFile[128], szData[64], szTemp[64], iFile
    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_MapTag.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return PLUGIN_HANDLED

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))
        if ( !szData[0] )
            continue

        strtok(szData, szData, charsmax(szData), szTemp, charsmax(szTemp), ' ')
        g_fPoints[g_iPoints][0] = str_to_float(szData)
        strtok(szTemp, szData, charsmax(szData), szTemp, charsmax(szTemp), ' ')
        g_fPoints[g_iPoints][1] = str_to_float(szData)
        strtok(szTemp, szData, charsmax(szData), szTemp, charsmax(szTemp), ' ')
        g_fPoints[g_iPoints][2] = str_to_float(szData)
        g_bStroke[g_iPoints] = bool:str_to_num(szTemp)
        g_iPoints ++
    }

    fclose(iFile)
    return PLUGIN_HANDLED
}

public lineTask()
{
    if ( !g_bLine )
        return

    for ( new i = 1; i < g_iPoints; i ++ )
    {
        if ( g_bStroke[i] )
            continue

        drawLine(g_fPoints[i - 1], g_fPoints[i])
    }

    if ( g_bColorRandom
    && g_iPoints > 0
    && get_gametime() >= g_fNextRandom )
    {
        g_iColor[0] = random(255)
        g_iColor[1] = random(255)
        g_iColor[2] = random(255)
        g_fNextRandom = get_gametime() + g_fColorFreq
    }
}

public cvarUpdate(pCvar, const OldValue[], const fNewValue[])
{
    cvarCache()
}

public cvarCache()
{
    g_bLine        = get_pcvar_num(g_cvarLine) == 1
    g_iWidth       = get_pcvar_num(g_cvarWidth)
    g_iNoise       = get_pcvar_num(g_cvarNoise)
    g_bColorRandom = get_pcvar_num(g_cvarColorRandom) == 1
    g_fColorFreq   = get_pcvar_float(g_cvarColorFreq)
    g_iColorMode   = get_pcvar_num(g_cvarColorMode)

    new szColor[64], r[4], g[4], b[4], a[4]
    get_pcvar_string(g_cvarColor, szColor, charsmax(szColor))
    parse(szColor, r, 3, g, 3, b, 3, a, 3)
    g_iColor[0] = str_to_num(r)
    g_iColor[1] = str_to_num(g)
    g_iColor[2] = str_to_num(b)
    g_iColor[3] = str_to_num(a)
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) || !g_bLine )
        return HAM_IGNORED

    if( g_iCounter[id]++ > 5 )
    {
        if( g_bDrawing[id] )
        {
            static Float:fOrigin[3]
            if( !g_bHolding[id] )
            {
                getEndPoint(id, fOrigin)
                g_bStroke[g_iPoints] = true
                xs_vec_copy(fOrigin, g_fPoints[g_iPoints ++])
                g_bHolding[id] = true

                return HAM_IGNORED
            }

            getEndPoint(id, fOrigin)
            if( xs_vec_distance(g_fPoints[g_iPoints - 1], fOrigin) > 2 )
                xs_vec_copy(fOrigin, g_fPoints[g_iPoints ++])
        }
        else
        {
            g_bHolding[id] = false
        }

        g_iCounter[id] = 0
    }

    return HAM_IGNORED
}

public getEndPoint(id, Float:fOrigin[3])
{
    static Float:fStart[3], Float:fEnd[3]

    pev(id, pev_origin, fStart)
    pev(id, pev_view_ofs, fEnd)
    xs_vec_add(fStart, fEnd, fStart)

    pev(id, pev_v_angle, fEnd)
    engfunc(EngFunc_MakeVectors, fEnd)
    global_get(glb_v_forward, fEnd)
    xs_vec_mul_scalar(fEnd, 9999.0, fEnd)
    xs_vec_add(fStart, fEnd, fEnd)

    engfunc(EngFunc_TraceLine, fStart, fEnd, IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, fOrigin)

    fOrigin[0] += (fStart[0] > fOrigin[0]) ? 1.0 : -1.0
    fOrigin[1] += (fStart[1] > fOrigin[1]) ? 1.0 : -1.0
    fOrigin[2] += (fStart[2] > fOrigin[2]) ? 1.0 : -1.0
}

public drawLine(Float:fStart[3], Float:fEnd[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fStart)
    write_byte(TE_BEAMPOINTS)
    write_coord_f(fStart[0])
    write_coord_f(fStart[1])
    write_coord_f(fStart[2])
    write_coord_f(fEnd[0])
    write_coord_f(fEnd[1])
    write_coord_f(fEnd[2])
    write_short(g_iBeamSprite)
    write_byte(0)
    write_byte(0)
    write_byte(1)
    write_byte(g_iWidth)
    write_byte(g_iNoise)
    if ( g_iColorMode == 0 )
    {
        write_byte(g_iColor[0])
        write_byte(g_iColor[1])
        write_byte(g_iColor[2])
        write_byte(g_iColor[3])
    }
    else if ( g_iColorMode == 1 )
    {
        write_byte(random(255))
        write_byte(random(255))
        write_byte(random(255))
        write_byte(255)
    }
    write_byte(0)
    message_end()
}
