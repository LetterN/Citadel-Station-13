#define MAX_NTCORD_SERVER 100 //haha let's not crash the game.
#define MAX_NTCORD_MESSAGE_CHANNELS 30 //max channel IN the server
#define MAX_NTCORD_VOICE_CHANNELS 20 //max channel IN the server
#define WACKY_WELCOME_TEXT list("%USER has joined the channel.") //e

/datum/ntcord_server
	var/id
	/// Name of the channel. Len limit of ~40
	var/name = "Coderbus"
	/// fa-icon of the channel. Len limit of 20. If blank, the first letter will be the icon.
	var/icon = "some-fontawesome-shit"
	/// Server owner.
	var/datum/computer_file/program/ntcord/operator

	/// user on the server. list of /datum/computer_file/program/ntcord
	var/list/clients = list()
	/// user on the server. list of /datum/computer_file/program/ntcord
	var/list/clients_username = list() // for lazy regexing jsside. (pings)
	/// list of banned clients. they can use more tablets to proxy though.
	var/list/banned_clients = list()

	/// keyed list of channels: [name] = /datum/ntcord_channels
	var/list/message_channels = list()
	/// Main channel/landing channel thing.
	var/datum/ntcord_channels/main_channel
	/// Main channel/landing channel thing.
	var/datum/ntcord_channels/selected_channel
	/// Server logs mk1.
	var/list/server_logs = list()

/datum/ntcord_server/New(name)
	main_channel = new(src, "general", "messaging")
	message_channels["general"] = main_channel
	// if(SSnetworks.station_network)
	// 	SSnetworks.station_network.chat_channels.Add(src)
	..()

/datum/ntcord_server/Destroy()
	QDEL_LIST_NULL(server_logs)
	// if(SSnetworks.station_network)
	// 	SSnetworks.station_network.chat_channels.Remove(src)
	return ..()

//voice channel or messagies. (#) WILL BE APPENDED JS-SIDE!!
/datum/ntcord_server/proc/add_channel(name, type = "messaging")
	if(length(message_channels) >= (type = "messaging" ? MAX_NTCORD_MESSAGE_CHANNELS : MAX_NTCORD_VOICE_CHANNELS)) //based switch
		return FALSE

	var/datum/ntcord_channels/new_channel = new /datum/ntcord_channels(src, name, type)
	if(!new_channel)
		qdel(new_channel) //just to be sure
		return FALSE
	message_channels[name] = new_channel
	return TRUE

/datum/ntcord_server/proc/remove_channel(name, datum/ntcord_channels/channel_redir)
	var/datum/ntcord_channels/CH = message_channels[name]
	if(!istype(CH))
		return FALSE
	for(var/datum/computer_file/program/ntcord/NTC in clients)
		NTC.switch_channel(main_channel.name)
	qdel(CH)
	message_channels.Remove(name)
	return TRUE

/datum/ntcord_server/proc/welcome_user(name)
	if(!main_channel)
		return FALSE
	var/wacky_welcome = replacetext(pick(WACKY_WELCOME_TEXT), "%USER", "[name]")
	main_channel.to_channel(wacky_welcome) //tochat but with extra cheeze.

/datum/ntcord_server/proc/add_client(datum/computer_file/program/chatclient/C)
	if(!istype(C))
		return FALSE
	if(C.computer in banned_clients) //CID ban essencially
		return FALSE
	clients.Add(C)
	clients_username.Add("[C.username]#[C.usernumber]")
	add_log_message("JOIN", "SERVER", "[C.username]#[C.usernumber] has joined the channel.")
	welcome_user(C.username)
	// No operator, so we assume the channel was empty. Assign this user as operator.
	if(!operator)
		changeop(C)

/datum/ntcord_server/proc/remove_client(datum/computer_file/program/chatclient/C)
	if(!istype(C) || !(C in clients))
		return
	clients.Remove(C)
	clients_username.Remove("[C.username]#[C.usernumber]")
	add_log_message("LEAVE", "SERVER", "[C.username]#[C.usernumber] has left the channel.")

	// Channel operator left, pick new operator
	if(C == operator)
		operator = null
		if(clients.len)
			var/datum/computer_file/program/chatclient/newop = pick(clients)
			changeop(newop)

/datum/ntcord_server/proc/ban_client(datum/computer_file/program/chatclient/admin, datum/computer_file/program/chatclient/target, reason)
	banned_clients.Add(target.computer) /// CID ban, but your CID dosen't change.
	add_log_message("BAN", "[admin.username]#[admin.usernumber]", "[target.username]#[target.usernumber]")
	remove_client(target) //bye!

/datum/ntcord_server/proc/ban_client(datum/computer_file/program/chatclient/admin, datum/computer_file/program/chatclient/target)
	banned_clients.Remove(C.computer)
	add_log_message("UNBAN", "[admin.username]#[admin.usernumber]", "[target.username]#[target.usernumber]")

/datum/ntcord_server/proc/add_log_message(type, user, message)
	var/log = "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] \[[type]\] [username]: [message]"
	server_logs.Add(log)
	// trim_message_list()


/datum/ntcord_server/proc/changeop(datum/computer_file/program/chatclient/newop)
	if(istype(newop))
		operator = newop
		add_log_message("ADMIN", "SERVER", "Channel operator status transferred to [newop.username].")

/datum/ntcord_server/proc/change_title(newtitle, datum/computer_file/program/chatclient/client)
	if(operator != client)
		return FALSE // Not Authorised

	add_log_message("ADMIN", "SERVER", "[client.username] has changed channel title from [title] to [newtitle]")
	title = newtitle

/datum/ntcord_server/messaging
	var/static/ntnrc_uid = 0

/datum/ntcord_server/messaging/New()
	id = ntnrc_uid + 1
	if(id > MAX_NTCORD_SERVER)
		qdel(src)
		return
	ntnrc_uid = id
	..()

/datum/ntcord_server/private
	name = "@me"

/datum/ntcord_server/private/proc/direct_message(datum/computer_file/program/ntcord/target)
	if(!istype(target))
		return FALSE
	var/name_number = "[target.username]#[target.usernumber]"
	var/datum/ntcord_channels/direct_msg/new_dm = new /datum/ntcord_channels/direct_msg(src, name_number) //type need not.
	if(!new_dm)
		qdel(new_dm) //just to be sure
		return FALSE
	message_channels[name_number] = new_dm
	if(!selected_channel)
		selected_channel = message_channels[name_number]

/// Highlander style! There can only be ~~one~~ two
/datum/ntcord_server/private/add_client(datum/computer_file/program/chatclient/C)


//DO NOT CALL PARENT.
/datum/ntcord_server/private/New()
	return

//do not log either.
/datum/ntcord_server/private/add_log_message(type, user, message)
	return

#undef MAX_NTCORD_SERVER
#undef MAX_NTCORD_VOICE_CHANNELS
#undef MAX_NTCORD_MESSAGE_CHANNELS