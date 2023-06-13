import { session, socket, utils } from "./snmp.mjs"
// console.log(socket);

// socket.on("msg", (message) => {
//     // do something with the message.
//     console.log(message);
// })

    // Запрос одного параметра 
socket.on("get", (obj) => {
    console.log(obj)
    if (typeof utils.getOIDByName(obj.oid) !== 'string') { console.log(`${obj.oid} > Not Found `); return; }

    session.get([utils.getOIDByName(obj.oid)], function(error, varbinds) {
        if (error) {
            console.error(error);
        } else {
            for (var i = 0; i < varbinds.length; i++) {
                if (utils.isVarbindError(varbinds[i])) {
                    console.error(utils.varbindError(varbinds[i]));
                } else {
                    console.log(varbinds[i].oid + " = " + varbinds[i].value);
                    socket.emit("resp", {
                        type: utils.getNameByOID(varbinds[i].oid),
                        value: varbinds[i].value
                    });
                }
            }
        }
    });
})

    // Запрос на выполнение команды (установка значения)
socket.on("set", (obj) => {
    console.log(obj);

    var varbinds = [{
        oid: utils.getOIDByName(obj.oid),
        type: utils.ObjectType().Integer,
        value: obj.value
    }];
    console.log(varbinds);

    session.set(varbinds, function(error, varbinds) {
        if (error) {
            console.error(error.toString());
        } else {
            for (var i = 0; i < varbinds.length; i++) {
                // for version 1 we can assume all OIDs were successful
                console.log(varbinds[i].oid + "|" + varbinds[i].value);
                socket.emit("resp", {
                    type: utils.getNameByOID(varbinds[i].oid),
                    value: varbinds[i].value
                });
            }
        }
    });
});

socket.on("telemetry", () => {
    const oids = [
        utils.getOIDByName("pdmPowerRequestedState"),
        utils.getOIDByName("pdmDisplaySetInputSource"),
        utils.getOIDByName("pdmAudioVolume"),
        utils.getOIDByName("pdmAudioMute"),
        utils.getOIDByName("pdmGeneralProductName"), 
        utils.getOIDByName("pdmGeneralSerialNumber"), 
//        utils.getOIDByName("pdmTempSensorTemp"),
    ];

    session.get(oids, function(error, varbinds) {
        if (error) {
            console.error(error);
        } else {
            let tmp = {};
            for (var i = 0; i < varbinds.length; i++) {
                if (utils.isVarbindError(varbinds[i])) {
                    console.error(utils.varbindError(varbinds[i]));
                } else {
                    console.log(varbinds[i].oid + " = " + varbinds[i].value + " (" + utils.getNameByOID(varbinds[i].oid) + ")");
                    tmp[utils.getNameByOID(varbinds[i].oid)] =varbinds[i].value ;
                }
            }
            socket.emit("resp", {type: "telemetry", value: tmp});
        }

    });


})
