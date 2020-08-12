#define PAI_HUD_SEC (1<<0)
#define PAI_HUD_MED (1<<0)

/mob/living/silicon/pai
	name = "pAI"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"
	density = FALSE
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	desc = "A generic pAI mobile hard-light holographics emitter. It seems to be deactivated."
	weather_immunities = list("ash")
	health = 500
	maxHealth = 500
	layer = BELOW_MOB_LAYER
	silicon_privileges = PRIVILEDGES_PAI
	mobility_flags = NONE

	/// Used as currency to purchase different abilities
	var/ram = 100
	/// Installed software
	var/list/software = list()
	/// The card we inhabit
	var/obj/item/paicard/card

	/// User vars
	
	/// Name of the one who commands us
	var/master
	/// DNA string for owner verification
	var/master_dna
	/// The DNA string of our assigned user
	var/userDNA

	var/speakStatement = "states"
	var/speakExclamation = "declares"
	var/speakDoubleExclamation = "alarms"
	var/speakQuery = "queries"


	/// HTML Ui vars

	/// General error reporting text contained here will typically be shown once and cleared
	var/temp
	/// Which screen our main window displays
	var/screen
	/// Which specific function of the main screen is being displayed
	var/subscreen

	/// Various software-specific vars
	
	/// Are we hacking a door?
	var/hacking = FALSE
	/// Instrument for it's own synth
	var/obj/item/instrument/piano_synth/internal_instrument

	/// The pAI's headset
	var/obj/item/radio/headset/headset
	/// The cable we produce and use when door or camera jacking		
	var/obj/item/pai_cable/cable

	/// Cammera network access
	var/network = "ss13"
	var/obj/machinery/camera/current = null

	/// The airlock being hacked
	var/obj/machinery/door/hackdoor
	/// 1-100, >= 100 means the hack is complete and will be reset upon next check
	var/hackprogress = 0

	/// Custom PDA
	var/obj/item/pda/ai/pai/pda = null

	/// Toggles whether the Security HUD is active or not
	var/secHUD = FALSE
	/// Toggles whether the Medical  HUD is active or not
	var/medHUD = FALSE

	/// pAI hud flags (PAI_HUD_SEC|PAI_HUD_MED)
	var/pAI_HUD_flags = NONE

	/// Datacore record declarations for record software
	var/datum/data/record/medicalActive1
	var/datum/data/record/medicalActive2

	/// Could probably just combine all these into one
	var/datum/data/record/securityActive1
	var/datum/data/record/securityActive2
	
	/// pAI's signaller
	var/obj/item/integrated_signaler/signaler 

	var/encryptmod = FALSE
	var/obj/item/card/id/access_card = null

	var/holoform = FALSE
	var/canholo = TRUE
	var/emitterhealth = 20
	var/emittermaxhealth = 20
	var/emitterregen = 0.25
	var/emitter_next_use = 0
	var/emitter_emp_cd = 300
	var/emittercd = 50
	var/emitteroverloadcd = 100

	var/chassis = "repairbot"
	var/dynamic_chassis
	var/dynamic_chassis_sit = FALSE			//whether we're sitting instead of resting spritewise
	var/dynamic_chassis_bellyup = FALSE		//whether we're lying down bellyup
	var/list/possible_chassis			//initialized in initialize.
	var/list/dynamic_chassis_icons		//ditto.
	var/list/chassis_pixel_offsets_x	//stupid dogborgs

	var/radio_short = FALSE
	var/radio_short_cooldown = 3 MINUTES
	var/radio_short_timerid

	var/silent = FALSE
	var/brightness_power = 5

	var/icon/custom_holoform_icon

/mob/living/silicon/pai/Destroy()
	QDEL_NULL(radio)
	QDEL_NULL(pda)
	QDEL_NULL(signaler)
	
	if(internal_instrument) //installed, and does not exist on init
		QDEL_NULL(internal_instrument)

	if (loc != card)
		card.forceMove(drop_location())

	card.pai = null
	card.cut_overlays()
	card.add_overlay("pai-off")
	GLOB.pai_list -= src

	return ..()

/mob/living/silicon/pai/Initialize()
	var/obj/item/paicard/P = loc
	if(!istype(P)) //when manually spawning a pai, we create a card to put it into.
		var/newcardloc = P
		P = new /obj/item/paicard(newcardloc)
		P.setPersonality(src)

	forceMove(P)
	card = P

	signaler = new(src)
	pda = new(src) //let it finish it's own init
	radio = new /obj/item/radio/headset/silicon/pai(src) //duh, radio dosen't exist on init

	make_laws()

	possible_chassis = typelist(NAMEOF(src, possible_chassis), 
		list("cat" = TRUE, "mouse" = TRUE, "monkey" = TRUE, "corgi" = FALSE,
			"fox" = FALSE, "repairbot" = TRUE, "rabbit" = TRUE, "borgi" = FALSE ,
			"parrot" = FALSE, "bear" = FALSE , "mushroom" = FALSE, "crow" = FALSE ,
			"fairy" = FALSE , "spiderbot" = FALSE))		//assoc value is whether it can be picked up.
	dynamic_chassis_icons = typelist(NAMEOF(src, dynamic_chassis_icons), initialize_dynamic_chassis_icons())
	chassis_pixel_offsets_x = typelist(NAMEOF(src, chassis_pixel_offsets_x), default_chassis_pixel_offsets_x())

	. = ..()
	// START_PROCESSING(SSfastprocess, src) //fire-off when the things has to init is done

	//PDA
	pda.ownjob = "pAI Messenger"
	pda.owner = "[src]"
	pda.name = "[pda.owner] ([pda.ownjob])"

	//Action buttons
	var/datum/action/innate/pai/software/SW = new
	SW.Grant(src)
	var/datum/action/innate/pai/shell/AS = new
	AS.Grant(src)
	var/datum/action/innate/pai/chassis/AC = new
	AC.Grant(src)
	var/datum/action/innate/pai/rest/AR = new
	AR.Grant(src)
	var/datum/action/innate/pai/light/AL = new
	AL.Grant(src)
	var/datum/action/language_menu/ALM = new
	ALM.Grant(src)

	emitter_next_use = world.time + (10 SECONDS)
	GLOB.pai_list |= src

/mob/living/silicon/pai/ComponentInitialize()
	. = ..()
	if(possible_chassis[chassis])
		AddElement(/datum/element/mob_holder, chassis, 'icons/mob/pai_item_head.dmi', 'icons/mob/pai_item_rh.dmi', 'icons/mob/pai_item_lh.dmi', ITEM_SLOT_HEAD)

/mob/living/silicon/pai/proc/process_hack()
	if(cable?.machine && istype(cable.machine, /obj/machinery/door) && cable.machine == hackdoor && get_dist(src, hackdoor) <= 1)
		hackprogress = clamp(hackprogress + 4, 0, 100)
	else
		temp = "Door Jack: Connection to airlock has been lost. Hack aborted."
		hackprogress = 0
		hacking = FALSE
		hackdoor = null
		return
	if(screen == "doorjack" && subscreen == 0) // Update our view, if appropriate
		paiInterface()
	if(hackprogress >= 100)
		hackprogress = 0
		var/obj/machinery/door/D = cable.machine
		D.open()
		hacking = FALSE

/mob/living/silicon/pai/make_laws()
	laws = new /datum/ai_laws/pai()
	return TRUE

/mob/living/silicon/pai/Login()
	..()
	usr << browse_rsc('html/paigrid.png')			// Go ahead and cache the interface resources as early as possible
	if(client)
		client.perspective = EYE_PERSPECTIVE
		if(holoform)
			client.eye = src
		else
			client.eye = card

/mob/living/silicon/pai/Stat()
	..()
	if(statpanel("Status"))
		if(!stat)
			stat(null, "Emitter Integrity: [emitterhealth * (100/emittermaxhealth)]")
		else
			stat(null, "Systems nonfunctional")

/mob/living/silicon/pai/restrained(ignore_grab)
	return FALSE

// See software.dm for Topic()

/mob/living/silicon/pai/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE)
	if(be_close && !in_range(M, src))
		to_chat(src, "<span class='warning'>You are too far away!</span>")
		return FALSE
	return TRUE

/// turn the current mob into a pAI
/mob/proc/makePAI(delold = FALSE)
	if(istype(src, /mob/living/silicon/pai))
		return FALSE
	var/obj/item/paicard/card = new(get_turf(src))
	var/mob/living/silicon/pai/pai = new(card)
	transfer_ckey(pai)
	pai.name = name
	card.setPersonality(pai)
	if(delold)
		qdel(src)
	return TRUE

/obj/item/paicard/attackby(obj/item/W, mob/user, params)
	..()
	user.set_machine(src)
	if(!W.tool_behaviour == TOOL_SCREWDRIVER && !istype(W, /obj/item/encryptionkey))
		return FALSE

	if(pai?.encryptmod)
		pai.radio.attackby(W, user, params)
	else
		to_chat(user, "Encryption Key ports not configured.")

/mob/living/silicon/pai/Process_Spacemove(movement_dir = NONE)
	if(!(. = ..()))
		add_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
		return TRUE
	remove_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
	return TRUE

/mob/living/silicon/pai/examine(mob/user)
	. = ..()
	. += "A personal AI in holochassis mode. Its master ID string seems to be [master]."

/mob/living/silicon/pai/PhysicalLife()
	. = ..()
	if(cable)
		if(get_dist(src, cable) > 1)
			var/turf/T = get_turf(src.loc)
			T.visible_message("<span class='warning'>[src.cable] rapidly retracts back into its spool.</span>", "<span class='italics'>You hear a click and the sound of wire spooling rapidly.</span>")
			qdel(src.cable)
			cable = null

/mob/living/silicon/pai/BiologicalLife()
	if(!(. = ..()))
		return
	silent = max(silent - 1, 0)
	emitterhealth = clamp((emitterhealth + emitterregen), -50, emittermaxhealth) //biolife ticks the same as ssfastproccess right?
	if(hacking)
		process_hack()

/mob/living/silicon/pai/updatehealth()
	if(status_flags & GODMODE)
		return
	health = maxHealth - getBruteLoss() - getFireLoss()
	update_stat()

/mob/living/silicon/pai/proc/short_radio()
	if(radio_short_timerid)
		deltimer(radio_short_timerid)

	radio_short = TRUE
	to_chat(src, "<span class='danger'>Your radio shorts out!</span>")
	radio_short_timerid = addtimer(CALLBACK(src, .proc/unshort_radio), radio_short_cooldown, flags = TIMER_STOPPABLE)

/mob/living/silicon/pai/proc/unshort_radio()
	radio_short = FALSE
	to_chat(src, "<span class='danger'>You feel your radio is operational once more.</span>")
	if(radio_short_timerid)
		deltimer(radio_short_timerid)

/mob/living/silicon/pai/proc/initialize_dynamic_chassis_icons()
	. = list()
	var/icon/curr		//for inserts

	//This is a horrible system and I wish I was not as lazy and did something smarter, like just generating a new icon in memory which is probably more efficient.

	//Basic /tg/ cyborgs
	.["Cyborg - Engineering (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "engineer"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (loaderborg)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "loaderborg"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (handyeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "handyeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (sleekeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "sleekeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (marinaeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinaeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "medical"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (marinamed)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinamed"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (eyebotmed)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "eyebotmed"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "sec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (sleeksec)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "sleeksec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (marinasec)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinasec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Clown (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "clown"), HOLOFORM_FILTER_PAI, FALSE)

	//Citadel dogborgs
	//Engi
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (dog - valeeng)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (dog - pupdozer)"] = curr
	//Med
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "medihound")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - medihound)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - medihounddark)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valemed")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - valemed)"] = curr
	//Sec
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "k9")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - k9)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - k9dark)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valesec")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - valesec)"] = curr
	//Service
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Service (dog - valeserv)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Service (dog - valeservdark)"] = curr
	//Sci
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valesci")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Science (dog - valesci)"] = curr
	//Misc
	.["Cyborg - Misc (dog - blade)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/widerobot.dmi', "blade"), HOLOFORM_FILTER_PAI, FALSE)

/mob/living/silicon/pai/proc/default_chassis_pixel_offsets_x()
	. = list()
	//Engi
	.["Cyborg - Engineering (dog - valeeng)"] = -16
	.["Cyborg - Engineering (dog - pupdozer)"] = -16
	//Med
	.["Cyborg - Medical (dog - medihound)"] = -16
	.["Cyborg - Medical (dog - medihounddark)"] = -16
	.["Cyborg - Medical (dog - valemed)"] = -16
	//Sec
	.["Cyborg - Security (dog - k9)"] = -16
	.["Cyborg - Security (dog - valesec)"] = -16
	.["Cyborg - Security (dog - k9dark)"] = -16
	//Service
	.["Cyborg - Service (dog - valeserv)"] = -16
	.["Cyborg - Service (dog - valeservdark)"] = -16
	//Sci
	.["Cyborg - Security (dog - valesci)"] = -16
	//Misc
	.["Cyborg - Misc (dog - blade)"] = -16


/datum/action/innate/pai
	name = "PAI Action"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	var/mob/living/silicon/pai/P

/datum/action/innate/pai/Trigger()
	if(!ispAI(owner))
		return FALSE
	P = owner

/datum/action/innate/pai/software
	name = "Software Interface"
	button_icon_state = "pai"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/software/Trigger()
	..()
	P.paiInterface()

/datum/action/innate/pai/shell
	name = "Toggle Holoform"
	button_icon_state = "pai_holoform"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/shell/Trigger()
	..()
	if(P.holoform)
		P.fold_in(FALSE)
	else
		P.fold_out()

/datum/action/innate/pai/chassis
	name = "Holochassis Appearance Composite"
	button_icon_state = "pai_chassis"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/chassis/Trigger()
	..()
	P.choose_chassis()

/datum/action/innate/pai/rest
	name = "Rest"
	button_icon_state = "pai_rest"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/rest/Trigger()
	..()
	P.lay_down()

/datum/action/innate/pai/light
	name = "Toggle Integrated Lights"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "emp"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/light/Trigger()
	..()
	P.toggle_integrated_light()
