/datum/computer_file/program/ntcord
	filename = "ntnrc_client"
	filedesc = "Chat Client"
	program_icon_state = "command"
	extended_desc = "This program allows communication over NTNRC network"
	size = 10 //100mb of pure, unoptimized JS
	requires_ntnet = TRUE
	requires_ntnet_feature = NTNET_COMMUNICATION
	ui_header = "ntnrc_idle.gif"
	available_on_ntnet = TRUE
	tgui_id = "NtosNetDiscord"

	/// Username (George Mellons)
	var/username
	/// Usernumber (George Mellons#1233)
	var/usernumber = 0000

	/// Ammount of pings the user has (max 100)
	var/last_pings //can we trust the JS departmet to not lie? perhaps.
	/// Currently selected server. Channel handled JSside
	var/active_server
	/// image attached. for catposting in thiscord.
	var/obj/item/image/attached_img

	var/operator_mode = FALSE		// Channel operator mode
	var/netadmin_mode = FALSE		// Administrator mode (invisible to other users + bypasses passwords)

/datum/computer_file/program/chatclient/New()
	var/obj/item/computer_hardware/card_slot/card_slot = computer?.all_components[MC_CARD]
	if(card_slot)
		var/obj/item/card/id/user_id_card = card_slot.stored_card
		username = user_id_card.name

	else
		username = "DefaultUser"
	usernumber = "[rand(1000, 9999)]"

/datum/computer_file/program/chatclient/ui_act(action, params)
	if(..())
		return


/datum/computer_file/program/chatclient/process_tick()
	. = ..()
	var/datum/ntnet_conversation/channel = SSnetworks.station_network.get_chat_channel_by_id(active_channel)
	if(program_state != PROGRAM_STATE_KILLED)
		ui_header = "ntnrc_idle.gif"
		if(channel)
			// Remember the last message. If there is no message in the channel remember null.
			last_message = length(channel.messages) ? channel.messages[length(channel.messages)] : null
		else
			last_message = null
		return TRUE
	if(channel?.messages?.len)
		ui_header = last_message == channel.messages[length(channel.messages)] ? "ntnrc_idle.gif" : "ntnrc_new.gif"
	else
		ui_header = "ntnrc_idle.gif"

/datum/computer_file/program/chatclient/kill_program(forced = FALSE)
	for(var/C in SSnetworks.station_network.chat_channels)
		var/datum/ntnet_conversation/channel = C
		channel.remove_client(src)
	..()

/datum/computer_file/program/chatclient/ui_static_data(mob/user)
	var/list/data = list()
	data["can_admin"] = can_run(user, FALSE, ACCESS_NETWORK)
	return data

/datum/computer_file/program/chatclient/ui_data(mob/user)
	if(!SSnetworks.station_network || !SSnetworks.station_network.chat_channels)
		return list()

	var/list/data = list()

	data = get_header_data()

	var/list/all_channels = list()
	for(var/C in SSnetworks.station_network.chat_channels)
		var/datum/ntnet_conversation/conv = C
		if(conv && conv.title)
			all_channels.Add(list(list(
				"chan" = conv.title,
				"id" = conv.id
			)))
	data["all_channels"] = all_channels

	data["active_channel"] = active_channel
	data["username"] = username
	data["adminmode"] = netadmin_mode
	var/datum/ntnet_conversation/channel = SSnetworks.station_network.get_chat_channel_by_id(active_channel)
	if(channel)
		data["title"] = channel.title
		var/authed = FALSE
		if(!channel.password)
			authed = TRUE
		if(netadmin_mode)
			authed = TRUE
		var/list/clients = list()
		for(var/C in channel.clients)
			if(C == src)
				authed = TRUE
			var/datum/computer_file/program/chatclient/cl = C
			clients.Add(list(list(
				"name" = cl.username
			)))
		data["authed"] = authed
		//no fishing for ui data allowed
		if(authed)
			data["clients"] = clients
			var/list/messages = list()
			for(var/M in channel.messages)
				messages.Add(list(list(
					"msg" = M
				)))
			data["messages"] = messages
			data["is_operator"] = (channel.operator == src) || netadmin_mode
		else
			data["clients"] = list()
			data["messages"] = list()
	else
		data["clients"] = list()
		data["authed"] = FALSE
		data["messages"] = list()

	return data
