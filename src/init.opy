#!mainFile "./Genji-Dodgeball.opy"

rule "Init global variables":
    targetedPlayer = -1
    previousTargetedPlayer = -1
    ballSpawnCountdown = 3
    disableScoring()
    disableGamemodeCompletion()
    disableMusic()
    disableAnnouncer()
    # disableInspector()
    if torbBall == 1 and getCurrentGamemode() == Gamemode.FFA and not multiTeam:
        ballHero = Hero.TORBJORN
        name = ballHero
    else:
        # No touchy. I'm talking to you, person thinking it's funny to put your name here. Only Torbjörn can steal credit for making my game.
        name = "u/Mazawrath"
        ballHero = null
    # TODO get this working
    # playerHero = [hero for hero in getAllHeroes() if hero != ballHero]
    playerHero = Hero.GENJI
    bouncePadStrength = 30
    ballSpeed = startingBallSpeed
    ballSpawnSpeed = 30
    maxBallSpeed = 1000
    if arenaType == 2:
        if (getCurrentMap() == Map.WORKSHOP_EXPANSE or getCurrentMap() == Map.WORKSHOP_EXPANSE_NIGHT) == true:
            centerOffLimitsSize = 20
        else: 
            centerOffLimitsSize = 12.5
    else:
        centerOffLimitsSize = 3.5
    isInFinalDuel = false
    bouncePadCooldownLengthStart = 3
    bouncePadCooldownLength = 3
    bouncePadSuperjumpNerf = 6
    ballPosition = vect(0, -1, 0)
    explosionSoundVolume = 30
    improvedExplosions = true
    randomExplosionSounds = true
    cooldownDashingEnabled = true
    passingDamage = 100
    isPassingTeam1 = false
    isPassingTeam2 = false
    passingPlayer = null
    currentRound = 1
    if getCurrentGamemode() == Gamemode.FFA:
        gameEndEnabled = true
    # Using passing with retro ruleset DOES NOT work
    if rulesetMode == 1 and passingEnabled and getCurrentGamemode() == Gamemode.FFA:
        passingEnabled = false
        hudSubtext(hostPlayer, "Hi host. Very clever idea but sorry retro rules totally breaks self passing. Like, what do you think it can even do? The ball can only go in a straight direction and self passing sends the ball away from you and then curves around so in this case where would it even go? In your head. That's where it goes. I tested it. So you don't have to.", HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
    if multiTeam and getCurrentGamemode() == Gamemode.FFA:
        for itt in range(0, getNumberOfSlots(Team.ALL) / multiTeamSize, 1):
            maxTeamSlot[itt] = ((itt + 1) * multiTeamSize) - 1
            teamPlayers[itt] = []
            multiTeamScores[itt] = 0
    elif multiTeam and getCurrentGamemode() != Gamemode.FFA:
        multiTeam = false


rule "Init player variables":
    @Event eachPlayer
    @Hero all
    
    eventPlayer.isDashEnabled = false
    eventPlayer.setStatusEffect(null, Status.INVINCIBLE, 9999)
    if cooldownDashingEnabled:
        goto lbl_0
    eventPlayer.setAbility1Enabled(false)
    lbl_0:
    eventPlayer.disableRespawn()
    eventPlayer.enableDeathSpectateAllPlayers()
    eventPlayer.enableDeathSpectateTargetHud()
    eventPlayer.bouncePadCooldown = bouncePadCooldownLengthStart
    eventPlayer.antiFloatProtection = false
    eventPlayer.antiStuckProtection = false
    eventPlayer.toggleHUD = true
    eventPlayer.dashNerf = false
    # Add a player to a team if multi teams is on
    if multiTeam:
        for itt in range(0, len(maxTeamSlot), 1):
            if (eventPlayer.getSlot() <= maxTeamSlot[itt]):
                eventPlayer.teamNum = itt
                break
        teamPlayers[eventPlayer.teamNum] = teamPlayers[eventPlayer.teamNum].concat(eventPlayer)
        eventPlayer.playerSlot = eventPlayer.getSlot()
    if invisiblePlayers:
        getAllPlayers().setInvisibility(Invis.ALL)
    waitUntil(eventPlayer.isAlive() and isGameInProgress(), 90)
    wait(3)
    smallMessage(eventPlayer, "Press interact to enable/disable the scoreboard")
    if (perspectiveMode == 2):
        wait(3)
        smallMessage(eventPlayer, "Press reload to toggle 1st/3rd person")


rule "Create game sphere":
    createEffect(getAllPlayers(), Effect.SPHERE, Color.BLACK, vect(circleCenter.x, circleCenter.y - 0, circleCenter.z), centerOffLimitsSize, EffectReeval.VISIBILITY)
    #Workshop Island doesn't need a circle.
    if getCurrentMap() != Map.WORKSHOP_ISLAND and getCurrentMap() != Map.WORKSHOP_ISLAND_NIGHT:
        createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.ORANGE, vect(circleCenter.x, circleCenter.y - 15, circleCenter.z), sphereSize, EffectReeval.VISIBILITY)
    else:
        createEffect([player for player in getAllPlayers() if distance(player.getPosition(), circleCenter) >= sphereSize - 10], Effect.LIGHT_SHAFT, Color.BLUE, vect(circleCenter.x, circleCenter.y - 15, circleCenter.z), sphereSize, EffectReeval.VISIBILITY)


rule "Teammate leaves":
    @Event playerLeft
    @Condition multiTeam

    # WHY DOES playerLeft KEEP THE EVENTPLAYER BUT STRIP THEIR VARIABLES I LITERALLY WOULDN'T HAVE TO DO THIS O(N*K) SEARCH PLOUHVWREAQRKHJ
    for itt in range(0, len(getAllPlayers()), 1):
        for itt2 in range(0, len(teamPlayers[itt]), 1):
            if eventPlayer == teamPlayers[itt][itt2]:
                teamPlayers[itt] = teamPlayers[itt].exclude(eventPlayer)


rule "Player changes team":
    @Event eachPlayer
    @Condition multiTeam
    @Condition eventPlayer.playerSlot != eventPlayer.getSlot()

    teamPlayers[eventPlayer.teamNum] = teamPlayers[eventPlayer.teamNum].exclude(eventPlayer)
    for itt in range(0, len(maxTeamSlot), 1):
        if (eventPlayer.getSlot() <= maxTeamSlot[itt]):
            eventPlayer.teamNum = itt
            break
    teamPlayers[eventPlayer.teamNum] = teamPlayers[eventPlayer.teamNum].concat(eventPlayer)
    eventPlayer.setScore(multiTeamScores[eventPlayer.teamNum])
    eventPlayer.playerSlot = eventPlayer.getSlot()


rule "Draw outlines":
    @Event eachPlayer
    @Hero all

    # please give for var in array this needs to be so unnecessarily long because of the range
    for itt in range(0, len(teamPlayers[eventPlayer.teamNum]), 1):
        # Nice variable naming. I know. It's amazing. You wonder how I have a full time developer position? No idea, honestly ¯\_(ツ)_/¯
        for itt2 in range(0, len(teamPlayers[eventPlayer.teamNum]), 1):
            teamPlayers[eventPlayer.teamNum][itt].startForcingOutlineFor(teamPlayers[eventPlayer.teamNum][itt2], true, Color.SKY_BLUE, OutlineVisibility.DEFAULT)
    createIcon([player for player in teamPlayers[eventPlayer.teamNum] if eventPlayer.isAlive() and player != eventPlayer], updateEveryTick(eventPlayer.getEyePosition()), Icon.DIAMOND, IconReeval.VISIBILITY_AND_POSITION, Color.LIME_GREEN, false)
    eventPlayer.playerOutlineArr =  [player for player in getAllPlayers() if player.teamNum != eventPlayer.teamNum]
    for itt in range (0, len(eventPlayer.playerOutlineArr), 1):
        switch eventPlayer.playerOutlineArr[itt].teamNum:
            case 0:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.LIME_GREEN, OutlineVisibility.DEFAULT)
                break
            case 1:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.RED, OutlineVisibility.DEFAULT)
                break
            case 2:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.YELLOW, OutlineVisibility.DEFAULT)
                break
            case 3:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.ORANGE, OutlineVisibility.DEFAULT)
                break
            case 4:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.VIOLET, OutlineVisibility.DEFAULT)
                break
            case 5:
                eventPlayer.playerOutlineArr[itt].startForcingOutlineFor(eventPlayer, true, Color.GREEN, OutlineVisibility.DEFAULT)
                break
    # Okay I gotta do this super weird but hopefully this should only loop if someone joins or switches a team. Yeah it's pretty inefficent, but what are you going to do about it? Fix this? pfft, nobody even reads this code! Except you that is...okay please do fix it please i don't know how much longer i can do this
    eventPlayer.playerOutlineArr = teamPlayers
    # so apparently Overwatch has a comment character limit that OverPy doesn't care about so if you want to read the rest of that you need to go to my GitHub repository. Go do that and fork the game
    waitUntil(eventPlayer.playerOutlineArr != teamPlayers, 9999)
    # https://github.com/Mazawrath/Overwatch-Genji-Dodgeball
    goto RULE_START


rule "Create global HUD elements":
    # hudText(getAllPlayers(), null, null, "BETA BUILD - NOT FULLY TESTED - CHANGES ARE NOT FINAL", HudPosition.LEFT, -20, null, null, Color.AQUA, HudReeval.VISIBILITY, SpecVisibility.ALWAYS)
    if getCurrentGamemode() == Gamemode.FFA:
        #white normal
        hudSubtext([player for player in getAllPlayers() if player != targetedPlayer], "Current Player Targeted: {0}".format(targetedPlayer), HudPosition.LEFT, -2, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    if getCurrentGamemode() == Gamemode.TDM:
        #white normal
        hudSubtext([player for player in getAllPlayers() if player != targetedPlayer and player.getTeam() != targetedPlayer.getTeam()], "Current Player Targeted: {0}".format(targetedPlayer), HudPosition.LEFT, -2, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
        #sky blue targeting teammate
        hudSubtext([player for player in getAllPlayers() if player != targetedPlayer and player.getTeam() == targetedPlayer.getTeam()], "Current Player Targeted: {0}".format(targetedPlayer), HudPosition.LEFT, -2, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #red when you're targeted
    hudSubtext(targetedPlayer, "Current Player Targeted: {0}".format(targetedPlayer), HudPosition.LEFT, -2, Color.RED, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(getDeadPlayers(Team.ALL), "Waiting for next round", "You have been eliminated or joined during a round", "You will spawn once the next round starts", HudPosition.TOP, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
    if bouncepadDashingEnabled or cooldownDashingEnabled:
        goto lbl_0
    #hudSubtext(getAllPlayers(), "Current Dashing Mode: None", HudPosition.LEFT, -1, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #return
    lbl_0:
    #if cooldownDashingEnabled:
    #        goto lbl_1
    #hudSubtext(getAllPlayers(), "Current Dashing Mode: Bouncepad", HudPosition.LEFT, -1, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #return
    lbl_1:
    #hudSubtext(getAllPlayers(), "Current Dashing Mode: Cooldown", HudPosition.LEFT, -1, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #server load text for lobby owner only
    #hudText(hostPlayer, null, "Server Load", getServerLoad(), HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #hudText(hostPlayer, null, "Server Load Average", getAverageServerLoad(), HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #hudText(hostPlayer, null, "Server Load Peak", getPeakServerLoad(), HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #gameplay tips text
    #hudSubtext(getAllPlayers(), "Deflect or Dash will deflect the ball to an enemy", HudPosition.RIGHT, -10, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #hudSubtext(getAllPlayers(), "If you get hit, you die.  Last man standing wins!", HudPosition.RIGHT, -9, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #ball speed text color change with speed
    hudSubtext([player for player in getAllPlayers() if ballSpeed < 20], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.BLUE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext([player for player in getAllPlayers() if ballSpeed >= 20 and ballSpeed < 25], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.GREEN, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext([player for player in getAllPlayers() if ballSpeed >= 25 and ballSpeed < 30], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext([player for player in getAllPlayers() if ballSpeed >= 30 and ballSpeed < 35], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext([player for player in getAllPlayers() if ballSpeed >= 35 and ballSpeed < 55], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.RED, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext([player for player in getAllPlayers() if ballSpeed > 55], "Current Ball Speed: {0}".format(ballSpeed), HudPosition.LEFT, -3, Color.PURPLE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #hudSubheader(getAllPlayers(), "Updates by u/FearlessKat, u/Blink, u/TheRedstoneBlaze, tumtum9000#1232,david8686406#1523", HudPosition.LEFT, -10, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext(getAllPlayers(), "Discord.gg/GenjiDodgeball", HudPosition.LEFT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
    createInWorldText([player for player in getAllPlayers() if ballSpawnCountdown != 0], "Ball Spawning In: {0}".format(ceil(ballSpawnCountdown)), vect(circleCenter.x, circleCenter.y + 2.5, circleCenter.z), 2.5, Clip.SURFACES, WorldTextReeval.VISIBILITY_AND_STRING, Color.SKY_BLUE, SpecVisibility.DEFAULT)
    if rulesetMode == 1:
        if getCurrentGamemode() == Gamemode.FFA:
            hudSubtext(getAllPlayers(), "Retro ruleset. Dash deflecting is disabled.", HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
        else:
            hudSubtext(getAllPlayers(), "Retro ruleset. Dash deflecting & self passing are disabled.", HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
            
    if passingEnabled and rulesetMode == 0:
        if getCurrentGamemode() == Gamemode.TDM or multiTeam:
            hudSubtext(getAllPlayers(), "Hold secondary fire while deflecting to pass the ball to another teammate!", HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
        elif getCurrentGamemode() == Gamemode.FFA:
            hudSubtext(getAllPlayers(), "Hold secondary fire while deflecting to self pass the ball!", HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY, SpecVisibility.DEFAULT)
    hudSubtext([getAllPlayers() if teamPlayers[0] else null], "Team {0}: {1}".format(1, multiTeamScores[0]), HudPosition.RIGHT, -7, Color.LIME_GREEN, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)
    hudSubtext([getAllPlayers() if teamPlayers[1] else null], "Team {0}: {1}".format(2, multiTeamScores[1]), HudPosition.RIGHT, -6, Color.RED, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)
    hudSubtext([getAllPlayers() if teamPlayers[2] else null], "Team {0}: {1}".format(3, multiTeamScores[2]), HudPosition.RIGHT, -5, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)
    hudSubtext([getAllPlayers() if teamPlayers[3] else null], "Team {0}: {1}".format(4, multiTeamScores[3]), HudPosition.RIGHT, -4, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)
    hudSubtext([getAllPlayers() if teamPlayers[4] else null], "Team {0}: {1}".format(5, multiTeamScores[4]), HudPosition.RIGHT, -3, Color.VIOLET, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)
    hudSubtext([getAllPlayers() if teamPlayers[5] else null], "Team {0}: {1}".format(6, multiTeamScores[5]), HudPosition.RIGHT, -2, Color.GREEN, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.ALWAYS)


rule "Create player HUD elements":
    @Event eachPlayer
    @Hero all
    
    #hudText(eventPlayer, eventPlayer.playerDeflects, "Deflects", null, HudPosition.LEFT, 1, Color.YELLOW, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #eventPlayer.playerUI[1] = getLastCreatedEntity()
    #hudText(eventPlayer, eventPlayer.playerKills, "Kills", null, HudPosition.LEFT, 2, Color.ORANGE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #eventPlayer.playerUI[2] = getLastCreatedEntity()
    #hudText(eventPlayer, eventPlayer.playerDeaths, "Deaths", null, HudPosition.LEFT, 3, Color.SKY_BLUE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #eventPlayer.playerUI[3] = getLastCreatedEntity()
    #hudText(eventPlayer, eventPlayer.maxBallSpeed, "Max Deflect Speed", null, HudPosition.LEFT, 4, Color.RED, Color.WHITE, Color.TURQUOISE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #eventPlayer.playerUI[4] = getLastCreatedEntity()
    #hudText(eventPlayer, ceil(eventPlayer.bouncePadCooldown), "Bouncepad", "Cooldown", HudPosition.RIGHT, -1, Color.GREEN, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    #eventPlayer.playerUI[5] = getLastCreatedEntity()


rule "Create bounce pads":
    @Condition bouncePadToggle
    
    if arenaType == 0:
        bouncePadDistance = 12
        bouncePadRange = 2.75

        bouncePad1 = vect(circleCenter.x + bouncePadDistance, circleCenter.y, circleCenter.z)
        bouncePad2 = vect(circleCenter.x + bouncePadDistance * -1, circleCenter.y, circleCenter.z)
        bouncePad3 = vect(circleCenter.x, circleCenter.y, circleCenter.z + bouncePadDistance * 1)
        bouncePad4 = vect(circleCenter.x, circleCenter.y, circleCenter.z + bouncePadDistance * -1)

        # Bouncepad ready
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown == 0], Effect.RING, Color.SKY_BLUE, bouncePad1, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown == 0], Effect.RING, Color.SKY_BLUE, bouncePad2, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown == 0], Effect.RING, Color.SKY_BLUE, bouncePad3, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown == 0], Effect.RING, Color.SKY_BLUE, bouncePad4, 2, EffectReeval.VISIBILITY)

        # Bouncepad not ready
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown > 0], Effect.RING, Color.WHITE, bouncePad1, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown > 0], Effect.RING, Color.WHITE, bouncePad2, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown > 0], Effect.RING, Color.WHITE, bouncePad3, 2, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown > 0], Effect.RING, Color.WHITE, bouncePad4, 2, EffectReeval.VISIBILITY)
    elif arenaType == 1:
        bouncePadDistance = 0
        bouncePadRange = 20.75
        
        bouncePad1 = vect(circleCenter.x + bouncePadDistance, circleCenter.y, circleCenter.z)

        #Bouncepad ready
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown == 0], Effect.RING, Color.SKY_BLUE, bouncePad1, 20, EffectReeval.VISIBILITY)

        #Bouncepad not ready
        createEffect([player for player in getAllPlayers() if player.bouncePadCooldown > 0], Effect.RING, Color.WHITE, bouncePad1, 20, EffectReeval.VISIBILITY)


rule "Create ball & targeted effect":
    @Condition isGameInProgress() == true
    @Condition getCurrentGamemode() == Gamemode.FFA
    @Condition not invisibleBall
    
    if not ballHero:
        #Orb for when ball is not getting passed
        createEffect([player for player in getAllPlayers() if player != targetedPlayer], Effect.ORB, Color.WHITE, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    if not redGreenColorblindMode:
        if not ballHero:
            createEffect([i for i in targetedPlayer], Effect.ORB, Color.RED, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect([player for player in getAllPlayers() if player != targetedPlayer], Effect.GOOD_AURA, Color.RED, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.RED, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.RED, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    else:
        createEffect(targetedPlayer, Effect.ORB, Color.YELLOW, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(getAllPlayers(), Effect.GOOD_AURA, Color.YELLOW, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.YELLOW, targetedPlayer.getEyePosition(), 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ball trail change color with speed
    #createEffect(getAllPlayers(), Effect.BAD_AURA, Color.BLUE, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballSmoke = getLastCreatedEntity()
    #createBeam(getAllPlayers(), Beam.BAD, prevBallPos, ballPosition, Color.BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballTail1 = getLastCreatedEntity()
    #createBeam(getAllPlayers(), Beam.BAD, prevBallPos, prevBallPos2, Color.BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballTail2 = getLastCreatedEntity()
    createEffect([i for i in [player for player in getAllPlayers() if player != targetedPlayer] if isPassingTeam1 or isPassingTeam2], Effect.GOOD_AURA, Color.SKY_BLUE, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect([player for player in getAllPlayers() if player != targetedPlayer and (isPassingTeam1 or isPassingTeam2)], Effect.GOOD_AURA, Color.SKY_BLUE, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, prevBallPos, ballPosition, Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, prevBallPos, prevBallPos2, Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)


rule "Create ball & targeted effect - TEAMS":
    @Condition isGameInProgress() == true
    @Condition getCurrentGamemode() == Gamemode.TDM
    @Condition not invisibleBall
    
    #Team 1 standard targeting Team 2 ball
    createEffect([player for player in getPlayers(Team.1) if player != targetedPlayer and targetedPlayer.getTeam() != Team.1], Effect.ORB, Color.WHITE, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #Team 1 standard targeting Team 1 ball
    createEffect([player for player in getPlayers(Team.1) if player != targetedPlayer and targetedPlayer.getTeam() == Team.1], Effect.ORB, Color.SKY_BLUE, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
     #Team 2 standard targeting Team 1 ball
    createEffect([player for player in getPlayers(Team.2) if player != targetedPlayer and targetedPlayer.getTeam() != Team.2], Effect.ORB, Color.WHITE, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
     #Team 2 standard targeting Team 2 ball
    createEffect([player for player in getPlayers(Team.2) if player != targetedPlayer and targetedPlayer.getTeam() == Team.2], Effect.ORB, Color.SKY_BLUE, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    if not redGreenColorblindMode:
        #Team 1 Targeted Ball
        createEffect([i for i in targetedPlayer], Effect.ORB, Color.RED, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        #Team 2 Targeted Ball
        #createEffect([i for i in targetedPlayer if not isPassingTeam2], Effect.ORB, Color.RED, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect([player for player in getAllPlayers() if player != targetedPlayer], Effect.GOOD_AURA, Color.RED, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.RED, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.RED, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    else:
        createEffect(targetedPlayer, Effect.ORB, Color.YELLOW, ballPosition, 0.4, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(getAllPlayers(), Effect.GOOD_AURA, Color.YELLOW, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
        createEffect(targetedPlayer, Effect.GOOD_AURA, Color.YELLOW, targetedPlayer.getEyePosition(), 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ball trail change color with speed
    #createEffect(getAllPlayers(), Effect.BAD_AURA, Color.BLUE, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballSmoke = getLastCreatedEntity()
    #createBeam(getAllPlayers(), Beam.BAD, prevBallPos, ballPosition, Color.BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballTail1 = getLastCreatedEntity()
    #createBeam(getAllPlayers(), Beam.BAD, prevBallPos, prevBallPos2, Color.BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    #ballTail2 = getLastCreatedEntity()
    createEffect([i for i in [player for player in getAllPlayers() if player != targetedPlayer] if isPassingTeam1 or isPassingTeam2], Effect.GOOD_AURA, Color.SKY_BLUE, ballPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect([player for player in getAllPlayers() if player != targetedPlayer and (isPassingTeam1 or isPassingTeam2)], Effect.GOOD_AURA, Color.SKY_BLUE, targetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, prevBallPos, ballPosition, Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, prevBallPos, prevBallPos2, Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)