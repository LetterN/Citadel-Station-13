/datum/ntcord_channels
	/// Name of the channel. Len limit of ~40
	var/name = "shitcode-general"
	/// Channel type (voice channel, messaging channel)
	var/type = "messaging"
	/// messages on the channel.
	var/list/messages = list()
	/// the server that owns this channel
	var/datum/ntcord_server/channel_owner

/datum/ntcord_channels/New(datum/ntcord_server/NTC, name, type)
	if(!NTC || !istype(NTC))
		return FALSE
	channel_owner = NTC
	if(name)
		src.name = name
	if(type)
		src.type = type
	..()

/datum/ntcord_channels/proc/to_channel(message, name)
	message = "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [username]: [message]"
	messages.Add(message)
	trim_message_list()

/datum/ntcord_channels/proc/add_status_message(message)
	messages.Add("[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] -!- [message]")
	trim_message_list()

/datum/ntcord_channels/proc/trim_message_list()
	if(messages.len <= 50)
		return
	messages = messages.Copy(messages.len-50 ,0)

/datum/ntcord_channels/proc/change_title(newtitle, datum/computer_file/program/chatclient/client)
	if(operator != client)
		return FALSE // Not Authorised

	add_status_message("[client.username] has changed channel title from [title] to [newtitle]")
	title = newtitle

/datum/ntcord_channels/direct_msg
	name = "direct-message#0000"

/datum/ntcord_channels/direct_msg/New(datum/ntcord_server/NTC, name)
	if(!NTC || !istype(NTC))
		return FALSE
	channel_owner = NTC
	if(name)
		src.name = name
