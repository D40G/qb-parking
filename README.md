## QB-Parking is a Advanced Parking system with a lot of stuff build in.
This is a very awesome parking mod, that i specially made for [qb-core](https://github.com/qbcore-framework/qb-core) 
This is just how you park in real live 😁 so park anywhere you want 👊😁👍
This mod is more intended for large servers, with VIP players, you can give this player an extra feature, to let them park in front of there own house, or you can use this, if you are a youtuber, and you don't want to mesh up and get your scene back togetter again, and getting al your vehicles from garage back on it place, you can also use this mod, so your scene stays how you put it, just a little thing I thought of what you also can do with this mod. 😁 you can also creaate parking spots for jobs or players you can create free parking places of paid parking places,
you can use the build in build mode to correctly place your markers.

This mod is also good if players crashes or if the server gets a reboot, and if you have permission to park,
and you have parked your vehicle, then you never have to get your vehicle from the garage again, but if you do forget to park your vehicle, your vehicle can be found in garage or impound.

This is my second mod i make public, so please by kind to my 😁 i still have much to learn.

## Read The Updates.md for updates and changes.

## 📸 Screenshot 👊😁👍
![foto1](https://www.madirc.nl/fivem/new7.png)
![foto1](https://www.madirc.nl/fivem/new1.png)
![foto1](https://www.madirc.nl/fivem/new2.png)
![foto1](https://www.madirc.nl/fivem/new3.png)
![foto1](https://www.madirc.nl/fivem/new4.png)
![foto1](https://www.madirc.nl/fivem/new5.png)
![foto1](https://www.madirc.nl/fivem/new8.png)
![foto1](https://www.madirc.nl/fivem/new9.png)
![foto1](https://www.madirc.nl/fivem/new10.png)
![foto1](https://www.madirc.nl/fivem/foto1.png)
![foto1](https://www.madirc.nl/fivem/foto9.png)
![foto1](https://www.madirc.nl/fivem/foto11.png)

## 🎥 Video 👊😁👍
[![Watch the video1](https://www.madirc.nl/fivem/video.png)](https://youtu.be/cLCthqPRLQQ)
[![Watch the video1](https://www.madirc.nl/fivem/foto11.png)](https://youtu.be/QRJZ2r7FD4w )


## 💪 Dependencies
- ✅ [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- ✅ [qb-core](https://github.com/qbcore-framework/qb-core)
- ✅ [qb-garages](https://github.com/MaDHouSe79/qb-garages)
- ✅ [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys)

Polyzone

## 💪 Optional
- ✅ [PolyZone](https://github.com/mkafrin/PolyZone)
- ✅ [qb-phone](https://github.com/qbcore-framework/qb-phone)
- ✅ [qb-target](https://github.com/qbcore-framework/qb-target)
- ✅ [cc-fuel](https://github.com/CQC-Scripting/cc-fuel)
- ✅ [interact-sound](https://github.com/qbcore-framework/interact-sound)
- ✅ you can also use other vehiclekey scripts, change this in the config file.


## 🙏 How to install and do not forget anything, or it will not work, or give many errors.
- 👉 Step 1: First stop your server. 😁
- 👉 Step 2: Copy the directory qb-parking to resources/[qb]/
- 👉 Step 3: Add the player_parking.sql with 2 tables to your correct database.
- 👉 Step 4: Add any recommended extra code what I say you should add.
- 👉 Step 5: If you are 100% sure, you have done all 4 steps correctly, go to step 6.😁
- 👉 Step 6: Start your server.  
- 👉 Step 7: Add your self or other as vip, you can use the command: /park-addvip [id]
- 👉 Step 8: Most important step -> Enjoy 👊😎👍

## 🎮 How To Use
- 👉 Typ "/park" to park or drive your vehicle where you are at that moment. (Users and Admins)
- 👉 Typ "/park-names if you want to display the names ontop of the vehicle that is parked. (Users and Admins)
- 👉 Typ "/park-notification" to turn on or of the phone notification (Users and Admins)
- 👉 Typ "/park-create" to create a new parking space (Admin only)
- 👉 Typ "/park-build" to go in to build mode (Admin only)
- 👉 Typ "/park-system" if you want to turn on or off the system. (Admin Only)
- 👉 Typ "/park-usevip" to turn on and of the vip system
- 👉 Typ "/park-addvip [id]" if you want to add a vip. (Admin Only)
- 👉 Typ "/park-removevip [id]" if you want to remove a vip. (Admin Only)
- 👉 If you want to use the F5 button, you must add it to your /binds and add on F5 the word "park"


## 💯 Police and Mechanic Impound Trigger
- ✅ You can impound this vehicles, if a user park their vehicle incorrectly, and you added the trigger correctly...
- ✅ You can give a fine, and then if you want, you can still impound this vehicle.
- ✅ If a player as police, if they can enable the hud to see the name and plate of this persons parked vehicle, by using /park-names.
- ✅ The Polices and Mechanics client side trigger event, for the police or mechanic to impount a vehicle correctly. 
- ✅ You MUST add this to your police impound trigger event.


## 👇 To keep things nice and clean for the qb-core system and database.
- ✅ Go to resources[qb]/qb-core/server/player.lua around line 506, and find, local playertables = {}. 
- ✅ This is, if we want to delete a character, we also want to delete the parked vehicles in the database,
- ✅ Place the line below at the bottom in playertables (there are more insite), so place this one at the bottom.
````lua
{ table = 'player_parking_vehicles' },
{ table = 'player_parking_vips' },

--NOT IN USE YET, YOU DONT HAVE TO ADD THIS
{ table = 'player_parking_reserved'}
````
## Impound Trigger, to unpark the vehicle.
```lua
 TriggerEvent("qb-parking:client:impound", plate) 
```

## Stolen Trigger, to unpark the vehicle for lockpicking.
```lua
 TriggerEvent("qb-parking:client:stolen", plate) 
```

## 🐞 Any bugs issues or suggestions, let my know.
- If you have any suggestions or nice ideas let me know and we can see what we can do 👊😎
- Keep it nice and clean for everybody and have fun with this awesome qb-parking mod 😎👍

## 🙈 Youtube & Discord & Twitter
- [Youtube](https://www.youtube.com/channel/UC6431XeIqHjswry5OYtim0A)
- [Discord](https://discord.gg/cEMSeE9dgS)

